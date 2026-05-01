# Meep — Security Model

Authorization + access control cho Tier 0 + 0+. Implementation chi tiết: `firebase/firestore.rules`, `firebase/storage.rules`. Conventions: `.windsurf/rules/23-firestore-rules.md` + `.windsurf/rules/40-security-guardrails.md`.

> **Default principle:** Deny by default. Whitelist per resource. Fail-closed on errors.

## Authorization model

### Roles

Meep KHÔNG có RBAC complex. Chỉ 4 implicit role per resource:

| Role | Definition |
|---|---|
| **Owner** | `request.auth.uid == resource.data.<ownerField>` |
| **Friend** | `friendships/{sortedPair(currentUid, otherUid)}` exists |
| **Space member** | `currentUid in spaces/{spaceId}.memberUids` |
| **Stranger** | none of the above |

### Permission matrix per collection (Tier 0 + 0+)

#### `users/{uid}`

| Action | Owner | Friend | Stranger |
|---|---|---|---|
| Read full doc | ✅ | ⚠️ Public fields only (displayName, username, avatarUrl, bio) | ⚠️ username search only |
| Write | ✅ | ❌ | ❌ |
| Delete | ⚠️ Defer Tier 2 (account deletion) | ❌ | ❌ |

**Public fields:** `username`, `displayName`, `avatarUrl`, `bio`. Email/phoneHash/fcmTokens chỉ owner.

#### `users/{uid}/devices/{deviceId}`

| Action | Owner | Other |
|---|---|---|
| Read | ✅ | ❌ |
| Write | ✅ | ❌ |

**Note:** FCM tokens cực sensitive. Chỉ owner.

#### `users/{uid}/feed_items/{postId}`

| Action | Owner (uid) | Other |
|---|---|---|
| Read | ✅ | ❌ |
| Write | ❌ (only Cloud Function via Admin SDK) | ❌ |

**Note:** Client KHÔNG ghi feed_items. Cloud Function `onPostCreated` fan-out write qua Admin SDK (bypass rules).

#### `friend_requests/{requestId}`

| Action | Sender | Receiver | Stranger |
|---|---|---|---|
| Create | ✅ (must `senderUid == auth.uid`) | ❌ | ❌ |
| Read | ✅ | ✅ | ❌ |
| Update status to `accepted`/`declined` | ❌ | ✅ | ❌ |
| Delete | ✅ (cancel) | ✅ (decline) | ❌ |

#### `friendships/{sortedPair}`

| Action | uidA, uidB | Other |
|---|---|---|
| Read | ✅ | ❌ |
| Create | ❌ (only Cloud Function `onFriendRequestAccepted`) | ❌ |
| Delete (unfriend) | ✅ | ❌ |

#### `posts/{postId}`

| Action | Author | Recipient | Friend (not recipient) | Stranger |
|---|---|---|---|---|
| Read | ✅ | ✅ | ❌ | ❌ |
| Create | ✅ (validate fields) | — | — | — |
| Update (caption, recipientUids) | ⚠️ Defer (immutable post MVP) | ❌ | ❌ | ❌ |
| Delete | ✅ (defer UI) | ❌ | ❌ | ❌ |

**Recipient check:** `request.auth.uid in resource.data.recipientUids`.

**Validation on create:**
- `authorUid == request.auth.uid`
- `caption.size() <= 200`
- `recipientUids` length ≤ 100 (anti-spam)
- `type` in `['photo', 'rollcall']`

#### `posts/{postId}/reactions/{reactionId}`

| Action | Reactor | Post Author | Other |
|---|---|---|---|
| Read | ✅ (anyone với access post) | ✅ | ✅ if friend of author |
| Create | ✅ (must `userUid == auth.uid`) | — | — |
| Delete | ✅ (only own reaction) | ❌ | ❌ |

**Multi-react logic (RollCall):**
- Cho post `type == 'rollcall'`: `reactionId == "${userUid}_${emoji}"` cho phép multi
- Cho post `type == 'photo'`: `reactionId == userUid` (1 reaction per user)

#### `diary_entries/{entryId}`

| Action | Owner | Friend | Stranger |
|---|---|---|---|
| Read (private) | ✅ | ❌ | ❌ |
| Read (public) | ✅ | ✅ | ❌ |
| Create | ✅ (must `ownerUid == auth.uid`) | — | — |
| Update | ✅ | ❌ | ❌ |
| Delete | ✅ | ❌ | ❌ |

#### `spaces/{spaceId}`

| Action | Owner | Member | Other |
|---|---|---|---|
| Read | ✅ | ✅ | ❌ |
| Create | ✅ (must `ownerUid == auth.uid`) | — | — |
| Update (add/remove members) | ✅ | ⚠️ Self-leave only | ❌ |
| Delete | ✅ | ❌ | ❌ |

**Validation:**
- `memberUids` length ≤ 50 (MVP scale)
- All `memberUids` must be friends of `ownerUid` (validate on create)
- `name.size() <= 30`

---

## Storage rules

### Path: `posts/{authorUid}/{postId}/{filename}.jpg`

| Action | Author | Recipient | Friend (not recipient) | Stranger |
|---|---|---|---|---|
| Read | ✅ | ✅ | ❌ | ❌ |
| Write | ✅ (validate size + MIME) | ❌ | ❌ | ❌ |
| Delete | ✅ | ❌ | ❌ | ❌ |

**Validation on write:**
- `request.auth.uid == authorUid`
- `request.resource.size < 10 * 1024 * 1024` (10MB)
- `request.resource.contentType.matches('image/.*')`

**Read check:** Lookup post doc Firestore → check recipientUids.

### Path: `avatars/{uid}/{filename}.jpg`

| Action | Owner | Other |
|---|---|---|
| Read | ✅ | ✅ (avatars là public fields) |
| Write | ✅ (validate) | ❌ |
| Delete | ✅ | ❌ |

**Validation on write:**
- `request.auth.uid == uid`
- `request.resource.size < 2 * 1024 * 1024` (2MB)
- `request.resource.contentType.matches('image/.*')`

### Path: `diary/{ownerUid}/{entryId}/{filename}.jpg`

| Action | Owner | Friend (entry public) | Stranger |
|---|---|---|---|
| Read | ✅ | ⚠️ Need lookup `diary_entries/{entryId}.privacy` | ❌ |
| Write | ✅ (validate) | ❌ | ❌ |

**Note:** Storage rules KHÔNG support cross-document lookup easily. Workaround: lưu privacy state trong file metadata khi upload, check qua `request.resource.metadata.privacy`. Hoặc đơn giản: tất cả diary images public (chỉ Firestore doc gating discovery — practical OK cho MVP).

---

## Authentication enforcement

### Cloud Functions

Mọi callable function check `request.auth` trước:

```typescript
export const findFriendsByPhone = functions.https.onCall((data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in')
  }
  // ... logic
})
```

### HTTP endpoints (nếu add Node BE Phase 2)

Validate Firebase ID token via Admin SDK:

```typescript
const decodedToken = await admin.auth().verifyIdToken(req.headers.authorization?.split('Bearer ')[1])
req.uid = decodedToken.uid
```

KHÔNG trust client-controlled headers (vd `x-user-id`).

---

## Privacy controls

### PII handling

PII = email, phone, displayName, photos, captions, friend graph, FCM tokens, IP.

- ❌ KHÔNG log PII production logs (Cloud Functions, app logs). Log uid IDs only.
- ❌ KHÔNG put PII vào Cascade memories.
- Crashlytics: scrub message body, caption trước khi report.
- Analytics: track event names không raw user input.

### EXIF stripping

`onPostCreated` Cloud Function strip GPS EXIF tags từ uploaded images. Mitigation cho location leak.

```typescript
import sharp from 'sharp'

const stripped = await sharp(buffer)
  .withMetadata({ exif: { IFD0: undefined, GPS: undefined } })
  .toBuffer()
```

### Phone hash for friend discovery

Client hash phone trước khi gửi server:

```typescript
// Client (Dart)
final salt = 'meep-salt-2026'  // hardcoded, không sensitive
final phoneClean = phone.replaceAll(RegExp(r'\D'), '')  // digits only
final hash = sha256.convert(utf8.encode(salt + phoneClean)).toString()
```

Server lookup `users.where('phoneHash', '==', hash)`.

---

## Validation guards

### Client-side (Flutter)

- Email: regex + Firebase Auth
- Username: regex `^[a-z][a-z0-9_]{2,19}$`
- Password: ≥8 ký tự
- Caption: ≤200 chars
- Image: chọn từ `image_picker`, MIME check

### Server-side (Cloud Functions)

Mọi field input verify lại:

```typescript
function validateUsername(username: string): void {
  if (!/^[a-z][a-z0-9_]{2,19}$/.test(username)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid username')
  }
}
```

### Firestore rules validation

```javascript
// Example rule for posts/{postId}
allow create: if request.auth != null
  && request.resource.data.authorUid == request.auth.uid
  && request.resource.data.caption is string
  && request.resource.data.caption.size() <= 200
  && request.resource.data.recipientUids is list
  && request.resource.data.recipientUids.size() <= 100
  && request.resource.data.type in ['photo', 'rollcall']
  && request.resource.data.createdAt == request.time;
```

---

## Rate limiting

### Firebase Auth

Firebase Auth có built-in throttling cho login attempts. KHÔNG cần custom.

### Cloud Functions

MVP scope không cần custom rate limit. Nếu Phase 2 cần:

- Token bucket trong Firestore: `users/{uid}/rateLimits/{action}`
- Per action: `signFriendRequest`, `postPhoto`, etc.
- Decrement token per request, refill periodic.

### Storage uploads

10MB cap per file (Storage rules) là first defense.

---

## Audit & monitoring

- **Crashlytics:** Crash + non-fatal errors (production)
- **Cloud Logging:** Firestore + Functions logs (30 days retention free tier)
- **Firebase Auth events:** signup/login/delete (built-in)
- **Custom analytics events:** signup_complete, post_created, react, widget_tap, friend_added, space_created, diary_created, rollcall_post

---

## Threat model (MVP scope)

### Threats considered

| Threat | Mitigation |
|---|---|
| Stranger truy cập photos | Firestore rules friend check |
| Stranger truy cập profile | Public fields only |
| EXIF location leak | Server-side strip |
| Phone number leak | Hash before transmit |
| Malicious upload (decompression bomb) | Image dimensions check Cloud Function |
| Brute force login | Firebase Auth throttling |
| Token theft | Token expire 1h + refresh |
| MITM | HTTPS only |
| SQL injection | NoSQL Firestore (low risk), validate input |
| XSS | Flutter renders text safe by default |

### Threats NOT in scope (defer post-MVP)

| Threat | Why deferred |
|---|---|
| DDoS | Firebase has built-in defense |
| Account takeover via Google compromise | Out of Meep scope |
| Insider threat | Capstone trust model OK |
| Compliance (GDPR cascade delete) | Defer Tier 2 |

---

## Liên quan

- **Implementation rules:** `firebase/firestore.rules`, `firebase/storage.rules`
- **Conventions:** `.windsurf/rules/23-firestore-rules.md`
- **Security guardrails:** `.windsurf/rules/40-security-guardrails.md`
- **NFR security section:** [`../product/non-functional.md`](../product/non-functional.md) §Security
- **Data model:** [`data-model.md`](data-model.md)
