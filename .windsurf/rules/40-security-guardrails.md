---
trigger: always_on
---

# Security Guardrails

Meep handles **personal photos** of users and their friends. The privacy bar is high. These are non-negotiable.

## Secrets

### Never hardcode

No API key, OAuth client secret, signing secret, FCM server key, service-account JSON, or password may appear in:

- `lib/**/*.dart`
- `apps/widget/**`
- `firebase/functions/src/**/*.ts`
- `services/api/src/**/*.ts`
- `firebase.json`, `firestore.rules`, `storage.rules`
- README / docs / spec / plan

### Where secrets DO live

| Kind | Where |
|---|---|
| Mobile build-time secrets | `--dart-define` flags driven by a CI secret store, not committed |
| Firebase Functions runtime secrets | Firebase Secret Manager (`firebase functions:secrets:set`) |
| Local dev | `.env` (gitignored) loaded by `dotenv` / `flutter_dotenv` |
| Production runtime config that is not secret | Firebase Remote Config |

### Never commit

- `.env`, `.env.local`, `.envrc`
- `*-service-account.json`, `firebase-adminsdk-*.json`
- `google-services.json`, `GoogleService-Info.plist` (for production projects)
- `*.keystore`, `*.jks`, `key.properties`
- `.npmrc` (often contains tokens)

The `pre_read_code` and `pre_write_code` hooks block these by default. Don't disable them without a discussion.

## Firestore + Storage rules

Default deny everything. Open per collection / path with the smallest needed access.

### Firestore checklist

- [ ] No `allow read, write: if true` exists in the rules.
- [ ] Every collection with user data has explicit `isOwner()` / `isFriend()` checks.
- [ ] Field types and sizes are validated (e.g. `caption.size() <= 200`).
- [ ] Sensitive subcollections (`/users/{uid}/private/...`) are owner-only.
- [ ] Rules unit tests cover the matrix: owner / friend / stranger / unauthenticated.

### Storage checklist

- [ ] Read access requires authentication.
- [ ] Write requires `request.auth.uid == uid` for the user's own folder.
- [ ] `request.resource.size < 10 * 1024 * 1024` (10MB cap on uploads).
- [ ] `request.resource.contentType.matches('image/.*')` for image-only buckets.

## Authentication

- All Cloud Function callable handlers must check `request.auth` before any work.
- All HTTP endpoints (if you add a Node BE) must validate Firebase ID token via Admin SDK before trusting any claim.
- Don't trust `request.headers['x-user-id']` or similar client-controlled identifiers.

## Authorization

- Owner check: `isOwner(uid) := isAuthed() && request.auth.uid == uid`.
- Friend check: looks up `/friendships/{sortedPair}` document.
- Never just check "is authenticated" when you really mean "is owner / is friend".

## PII handling

Things considered PII for Meep:

- Email addresses
- Phone numbers
- Display names
- Photos and captions
- Friend graph (who knows whom)
- Device tokens (FCM)
- IP addresses

Rules:

- **Never log PII** in production logs. Log IDs only.
- **Never put PII into Cascade memories** (the `create_memory` tool). Names of features OK; user-specific data not OK.
- **Crashlytics:** scrub message body / caption from custom keys before reporting.
- **Analytics:** track event names, not raw user input.

## Image upload safety

- Validate MIME type and size **server-side** in a Cloud Function or in Storage rules. Never trust the client.
- Strip EXIF metadata in the resize Function (location data is sensitive).
- Reject unusually large dimensions even if file size is OK (decompression-bomb defence).

## Rate limiting / abuse

- Auth endpoints (login, password reset): rely on Firebase Auth's built-in throttling.
- Custom write endpoints: implement per-user rate limiting in the Function (e.g. token bucket in Firestore or a memory cache + back-off).

## Dependency hygiene

- New npm or pub package → ask the human before adding it. Check:
  - Maintained recently (last commit < 1 year).
  - License compatible (avoid AGPL / proprietary unless intentional).
  - Realistic download count (avoid typo-squat names).
- Pin versions in lockfiles. Don't `^` major-version bump silently.

## When something looks risky

If a request crosses one of these lines — **ask the user first**:

- Disabling a Firestore rule "temporarily for debugging".
- Committing a file that matches a secret pattern.
- Logging full request bodies "to investigate something".
- Adding a third-party SDK that needs analytics permissions.
- Granting a Function unrestricted IAM (`roles/owner`, `roles/editor`).
- Using `auth.currentUser?.uid ?? 'anonymous'` as a fallback (always fail-closed instead).
