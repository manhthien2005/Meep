# Node.js + TypeScript Rules

> Loaded when working in `firebase/functions/`. Supplements root `CLAUDE.md`.

## Strictness — non-negotiable

`tsconfig.json` must enable: `strict`, `noUncheckedIndexedAccess`, `noImplicitOverride`, `noFallthroughCasesInSwitch`, `exactOptionalPropertyTypes`. Target `ES2022`, module + moduleResolution `NodeNext`.

Don't downgrade these "to make TypeScript shut up". Fix the type.

## Input validation — every external boundary

All external input (HTTP body, query, callable function payload, Firestore trigger document) MUST be validated with **zod** before use.

Rule: every callable / HTTP handler starts with `if (!request.auth)` check, then `safeParse` of input, then business logic on `parsed.data`. NEVER use `request.data` directly.

## Error model

```ts
export class AppError extends Error {
  constructor(
    public readonly code: string,
    public readonly message: string,
    public readonly statusCode: number,
    public readonly cause?: unknown,
  ) { super(message); this.name = 'AppError'; }
}
// Subclass: ValidationError, UnauthenticatedError, ForbiddenError, NotFoundError
```

- Don't throw raw strings or numbers.
- Every async function that can throw → has try/catch at the handler boundary.

## Logging

- Don't `console.log` in production code; use `pino` or Cloud Functions' built-in `logger`.
- **Never log PII** — no email, phone, caption body, full request body. Log IDs only.
- Structured logs: `logger.info({ uid, postId }, 'post created')`.

## Testing — vitest

```bash
npm test
npm test -- file.test.ts
npm test -- --coverage
npm run lint
npm run typecheck
```

- 1 file per source file: `foo.ts` ↔ `foo.test.ts`.
- Use `vi.mock` sparingly — prefer dependency injection + in-memory fakes.
- Tests run in < 5s baseline.

## Cloud Functions v2 specifics

- Use **v2 functions** (`onRequest`, `onCall`, `onDocumentCreated`, `onObjectFinalized`).
- Region: `asia-southeast1`.
- Set `timeoutSeconds` and `memory` explicitly per function.
- **Idempotency:** triggers can fire twice — make handlers safe to retry.
- **Cold start:** lazy-import expensive packages (`sharp`, `firebase-admin/messaging`) inside the handler, not top-level.

```ts
initializeApp();
setGlobalOptions({ region: 'asia-southeast1', maxInstances: 10 });

export const sendFriendRequest = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Login required');
  const parsed = schema.safeParse(request.data);
  if (!parsed.success) throw new HttpsError('invalid-argument', parsed.error.message);
  // ... business logic
});
```

## Secrets

- Firebase Secret Manager: `firebase functions:secrets:set <NAME>`.
- Access via `defineSecret('NAME')` and pass to function options.
- No hardcoded API keys.

## Common gotchas

| Issue | Fix |
|---|---|
| `Cannot use import statement` | `"type": "module"` in package.json + `.js` extension on import paths |
| Firebase Admin SDK initialised multiple times | `initializeApp()` at module top once |
| Cloud Function timeout | Set `timeoutSeconds` explicitly. Long task → Cloud Tasks / Pub/Sub |
