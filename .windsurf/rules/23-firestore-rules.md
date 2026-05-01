---
trigger: glob
globs: firebase/firestore.rules,firebase/storage.rules,firebase/firestore.indexes.json,firebase/firebase.json
---

# Firestore / Storage Rules

Loaded only when editing Firebase rules + indexes config. For general rules see `20-stack-conventions.md`. For security policy see `40-security-guardrails.md`.

## Firestore data modeling

- **Denormalize** when read frequency >> write frequency (e.g. copy `authorName` into `posts/{postId}` so feeds don't need joins).
- Keep document size **<100KB** (Firestore limit is 1MB, but big docs are slow).
- Use **subcollections** for unbounded lists (`/users/{uid}/notifications/{notifId}`).
- Use `serverTimestamp()` for `createdAt` and `updatedAt` — **never trust client clocks**.

## Firestore security rules

- **Default deny everything**, then open per collection with the smallest needed access.
- **Rules unit-tested** with `@firebase/rules-unit-testing` (npm) — run via `firebase emulators:exec`.
- **No `allow read, write: if true`** ever, even temporarily.
- **Validate field types and lengths** in rules — don't rely on client only.
- **Use helper functions** for recurring checks (`isAuthed()`, `isOwner(uid)`, `isFriend(a, b)`).

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

- **Read** requires authentication (minimum).
- **Write** requires `request.auth.uid == uid` for the user's own folder.
- **Size cap:** `request.resource.size < 10 * 1024 * 1024` (10MB).
- **MIME check:** `request.resource.contentType.matches('image/.*')` for image-only buckets.

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

- **Compound queries** → declare indexes in `firestore.indexes.json` (commit it).
- Don't manually create indexes through the Console only — they'll get lost on re-deploy.
- After adding a new compound query in Dart/TS code → verify the index is declared.

```json
{
  "indexes": [
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "authorId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

## Pre-deploy checklist (rules)

- [ ] No `allow read, write: if true`.
- [ ] Every collection with user data has explicit `isOwner()` / `isFriend()` checks.
- [ ] Field types and sizes validated.
- [ ] Sensitive subcollections (`/users/{uid}/private/...`) are owner-only.
- [ ] Rules unit tests cover: owner / friend / stranger / unauthenticated.
- [ ] `firebase emulators:exec --only firestore "npm run test:rules"` passes.

## Common gotchas

| Issue | Fix |
|---|---|
| Rules pass locally but fail in prod | Emulator is sometimes more lenient — test against real staging Firestore |
| Query empty in prod, not local | Compound query missing index — check Firebase Console > Firestore > Indexes |
| `field name` typo | Field names are case-sensitive — match Dart `fromJson` exactly |
| Rule recursion / lookup limit | Max 10 `get()` / `exists()` per rule eval — denormalize if you hit it |
