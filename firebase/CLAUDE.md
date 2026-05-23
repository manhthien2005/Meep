# Firestore / Storage Rules

> Loaded when working in `firebase/`. Supplements root `CLAUDE.md`.

## Firestore data modeling

- **Denormalize** when read frequency >> write frequency (e.g. copy `authorName` into `posts/{postId}`).
- Keep document size **< 100KB**.
- **Subcollections** for unbounded lists (`/users/{uid}/notifications/{notifId}`).
- `serverTimestamp()` for `createdAt` / `updatedAt` — **never trust client clocks**.

## Firestore security rules

- **Default deny everything**, then open per collection with smallest needed access.
- **Rules unit-tested** with `@firebase/rules-unit-testing` — run via `firebase emulators:exec`.
- **No `allow read, write: if true`** ever, even temporarily.
- Validate field types and lengths in rules.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthed() { return request.auth != null; }
    function isOwner(uid) { return isAuthed() && request.auth.uid == uid; }
    function isFriend(uidA, uidB) {
      let pairId = uidA < uidB ? uidA + '_' + uidB : uidB + '_' + uidA;
      return exists(/databases/$(database)/documents/friendships/$(pairId));
    }

    match /posts/{postId} {
      allow read: if isAuthed() && (
        isOwner(resource.data.authorId) ||
        isFriend(request.auth.uid, resource.data.authorId)
      );
      allow create: if isOwner(request.resource.data.authorId)
        && request.resource.data.caption.size() <= 200
        && request.resource.data.keys().hasAll(['authorId','caption','imageUrl','createdAt']);
      allow update, delete: if isOwner(resource.data.authorId);
    }
  }
}
```

## Storage security rules

- Read requires authentication.
- Write requires `request.auth.uid == uid`.
- Size cap: `request.resource.size < 10 * 1024 * 1024` (10MB).
- MIME check: `request.resource.contentType.matches('image/.*')`.

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /posts/{uid}/{filename} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid
        && request.resource.size < 10 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## Indexes

- Compound queries → declare in `firestore.indexes.json` (commit it).
- Don't manually create indexes in Console only — they'll get lost on re-deploy.

## Pre-deploy checklist

- [ ] No `allow read, write: if true`.
- [ ] Every collection with user data has explicit `isOwner()` / `isFriend()` checks.
- [ ] Field types and sizes validated.
- [ ] Sensitive subcollections are owner-only.
- [ ] Rules unit tests: owner / friend / stranger / unauthenticated.
- [ ] `firebase emulators:exec --only firestore "npm run test:rules"` passes.

## Common gotchas

| Issue | Fix |
|---|---|
| Rules pass locally but fail in prod | Emulator is sometimes more lenient — test against real staging Firestore |
| Query empty in prod, not local | Compound query missing index — check Firebase Console > Firestore > Indexes |
| Field name typo | Field names are case-sensitive — match Dart `fromJson` exactly |
| Rule recursion / lookup limit | Max 10 `get()` / `exists()` per rule eval — denormalize if you hit it |
