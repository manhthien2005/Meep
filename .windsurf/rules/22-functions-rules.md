---
trigger: glob
globs: firebase/functions/**/*.ts,firebase/functions/**/*.js,services/api/**/*.ts,firebase/functions/package.json,firebase/functions/tsconfig.json
---

# Node.js + TypeScript Rules

Loaded only when editing Cloud Functions or the optional standalone Node BE. For general rules see `20-stack-conventions.md`.

## Strictness — non-negotiable

`tsconfig.json` must enable: `strict`, `noUncheckedIndexedAccess`, `noImplicitOverride`, `noFallthroughCasesInSwitch`, `exactOptionalPropertyTypes`. Target `ES2022`, module + moduleResolution `NodeNext`.

Don't downgrade these "to make TypeScript shut up". Fix the type.

**Full `tsconfig.json` template:** see skill `nodejs-ts-backend`.

## Input validation — every external boundary

All external input (HTTP body, query, callable function payload, Firestore trigger document) MUST be validated with **zod** before use. No "just trust the client".

Rule: every callable / HTTP handler starts with `if (!request.auth)` check, then `safeParse` of the input, then business logic on `parsed.data`. NEVER use `request.data` directly.

**Pattern reference:** see skill `nodejs-ts-backend` (`createPostSchema` + handler example + Express router pattern).

## Error model

- Define a small `AppError` class with `code`, `message`, `cause`, optional `statusCode`.
- HTTP / callable handlers map `AppError` to the right `HttpsError` code or HTTP status.
- Don't throw raw strings or numbers.
- Every async function that can throw → has a try/catch at the handler boundary.

## Logging

- Don't `console.log` in production code; use `pino` or Cloud Functions' built-in `logger`.
- **Never log PII** — no email, phone, caption body, full request body. Log IDs only.
- Structured logs: `logger.info({ uid, postId }, 'post created')` — not `console.log('post created for ' + uid)`.

## Testing — vitest

- 1 file per source file: `foo.ts` ↔ `foo.test.ts`.
- Use `vi.mock` sparingly — prefer dependency injection so you can pass an in-memory fake.
- Tests run in <5s baseline. If a test takes longer, it's an integration test → put it in `__tests__/integration/`.

```bash
npm test              # full suite
npm test -- file      # single file
npm test -- --coverage
npm run lint          # eslint
npm run typecheck     # tsc --noEmit (if scripted)
```

## Cloud Functions v2 specifics

- Use **v2 functions** (`onRequest`, `onCall`, `onDocumentCreated`, `onObjectFinalized`).
- Region: `asia-southeast1` (lower latency for VN users) unless there's a specific reason to differ.
- Set `timeoutSeconds` and `memory` explicitly per function.
- **Idempotency:** triggers can fire twice — make handlers safe to retry (check for existing doc before write, use `merge: true`, etc.).
- **Cold start:** lazy-import expensive packages (`sharp`, `firebase-admin/messaging`) inside the handler, not at top-level.

**Pattern reference:** see skill `nodejs-ts-backend` (lazy-import example + full Cloud Functions setup with `setGlobalOptions`).

## Secrets

- Use Firebase Secret Manager: `firebase functions:secrets:set <NAME>`.
- Access via `defineSecret('NAME')` and pass to function options.
- No hardcoded API keys.
- No `process.env.X` for sensitive values without zod validation at startup.

## Common gotchas

Full table lives in skill `nodejs-ts-backend`. Two that hit most often:

| Issue | Fix |
|---|---|
| `Cannot use import statement` | `"type": "module"` in package.json + `.js` extension on import paths |
| Firebase Admin SDK initialised multiple times | `initializeApp()` at module top once, not inside handlers |
