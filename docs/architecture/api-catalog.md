# Meep — API Catalog (Cloud Functions)

Catalog đầy đủ Cloud Functions cho Tier 0 + Tier 0+. Mỗi function có signature, trigger, side effects, owner feature.

> **Convention:** Function names `camelCase`. Region: `asia-southeast1`. Runtime: Node 20 + TypeScript strict.
>
> Detail conventions: `.windsurf/rules/22-functions-rules.md`.

## Functions overview

| Function | Type | Trigger | Tier | Feature owner |
|---|---|---|---|---|
| `onUserCreated` | Auth trigger | `auth.user().onCreate` | T0 | Auth |
| `onPostCreated` | Firestore trigger | `posts/{postId}` onCreate | T0 | Share photo |
| `onPostDeleted` | Firestore trigger | `posts/{postId}` onDelete | T0 | Share photo |
| `onReactionCreated` | Firestore trigger | `posts/{postId}/reactions/{rid}` onCreate | T0 | Reaction |
| `onReactionDeleted` | Firestore trigger | `posts/{postId}/reactions/{rid}` onDelete | T0 | Reaction |
| `onFriendRequestAccepted` | Firestore trigger | `friend_requests/{rid}` onUpdate | T0 | Friends |
| `onFriendshipDeleted` | Firestore trigger | `friendships/{pair}` onDelete | T0 | Friends |
| `findFriendsByPhone` | HTTPS callable | Manual call from client | T0 (defer M2) | Friends |
| `rollcallScheduler` | Scheduled (cron) | Sunday 8pm Vietnam | T0+ | RollCall |
| `onSpaceCreated` | Firestore trigger | `spaces/{spaceId}` onCreate | T0+ | Space |
| `onSpaceMemberRemoved` | Firestore trigger | `spaces/{spaceId}` onUpdate (memberUids change) | T0+ | Space |

---

## Tier 0 — Auth functions

### `onUserCreated`

**Type:** Auth trigger
**Trigger:** `functions.auth.user().onCreate(...)`
**Mục đích:** Initialize user document trong Firestore khi Firebase Auth tạo user mới.

**Flow:**
```
Firebase Auth user created (signup email/Google)
  ↓
onUserCreated trigger
  ↓
Create users/{uid} document với fields default:
  - uid, email (từ auth)
  - emailVerified (false ban đầu)
  - createdAt = serverTimestamp
  - displayName, username chưa có (set sau qua signup flow 5-screen)
  ↓
(Client tiếp tục flow signup, set displayName + username)
```

**Side effects:**
- Write `users/{uid}` doc

**Error handling:**
- Nếu Firestore write fail → log error, function retry (Firestore trigger auto-retry 3x)

---

## Tier 0 — Share photo functions

### `onPostCreated`

**Type:** Firestore trigger
**Trigger:** `functions.firestore.document('posts/{postId}').onCreate(...)`
**Mục đích:** Resize ảnh, fan-out feed, send push notifications, update widget.

**Flow:**
```
Client uploads photo to Storage `posts/{uid}/{postId}/original.jpg`
Client writes posts/{postId} document
  ↓
onPostCreated trigger
  ↓
1. Read post doc, get authorUid + recipientUids + spaceId
2. Resize ảnh:
   - Read `posts/{uid}/{postId}/original.jpg`
   - Generate medium (1080p) + thumbnail (256x256)
   - Strip EXIF location tags (privacy)
   - Save `posts/{uid}/{postId}/medium.jpg` + `posts/{uid}/{postId}/thumbnail.jpg`
3. Update post doc với `thumbnailUrl` + `mediumUrl`
4. Fan-out feed_items:
   - For each recipientUid:
     - Write `users/{recipientUid}/feed_items/{postId}` (denormalized)
5. Send push notifications:
   - Read FCM tokens từ `users/{recipientUid}/devices`
   - Batch send FCM `new_photo` notification
6. Send widget update (silent FCM data message):
   - Send FCM `widget_update` data-only message → trigger widget refresh
```

**Side effects:**
- Cloud Storage write (medium, thumbnail)
- Firestore write (post doc update + feed_items per recipient)
- FCM messages sent

**Error handling:**
- Resize fail → retry (max 3) → if still fail, mark post `status: 'resize_failed'`, alert author
- Fan-out partial fail → log per recipient fail, continue others

**Performance:**
- Cold start: ~2s (Sharp library init)
- Warm: ~3-5s for 5MB image (resize + fan-out 10 recipients)
- Memory: 512MB
- Timeout: 60s

---

### `onPostDeleted`

**Type:** Firestore trigger
**Trigger:** `functions.firestore.document('posts/{postId}').onDelete(...)`
**Mục đích:** Cleanup khi post bị delete (rare in MVP — chưa có UI delete cho user, chỉ admin/automated).

**Flow:**
```
1. Delete `users/{recipientUid}/feed_items/{postId}` for all recipients
2. Delete reactions subcollection
3. Delete Storage objects (`posts/{uid}/{postId}/*`)
```

**Note:** MVP scope không có user-facing delete post. Cloud Function vẫn set up để defensive (e.g. admin cleanup).

---

## Tier 0 — Reaction functions

### `onReactionCreated`

**Type:** Firestore trigger
**Trigger:** `functions.firestore.document('posts/{postId}/reactions/{reactionId}').onCreate(...)`
**Mục đích:** Update denormalized count + send push notification.

**Flow:**
```
Client writes reaction doc
  ↓
onReactionCreated trigger
  ↓
1. Read parent post doc → get authorUid + reactionCounts
2. Increment reactionCounts[emoji] (atomic transaction)
3. Update `posts/{postId}.reactionCounts`
4. Send FCM `new_reaction` push:
   - To: post author
   - Body: "{reactor displayName} react {emoji} ảnh của bạn"
```

**Side effects:**
- Firestore write (post doc)
- FCM message

**Performance:** <500ms typical.

---

### `onReactionDeleted`

**Type:** Firestore trigger
**Trigger:** `functions.firestore.document('posts/{postId}/reactions/{reactionId}').onDelete(...)`
**Mục đích:** Decrement denormalized count khi user unreact.

**Flow:**
```
1. Read deleted reaction doc emoji
2. Decrement posts/{postId}.reactionCounts[emoji] (atomic transaction)
3. KHÔNG send push notification (unreact silent)
```

---

## Tier 0 — Friends functions

### `onFriendRequestAccepted`

**Type:** Firestore trigger
**Trigger:** `functions.firestore.document('friend_requests/{requestId}').onUpdate(...)`
**Trigger condition:** `oldStatus !== 'accepted' && newStatus === 'accepted'`
**Mục đích:** Tạo friendship doc khi user accept.

**Flow:**
```
Receiver client updates `friend_requests/{requestId}.status` = 'accepted'
  ↓
onFriendRequestAccepted trigger
  ↓
1. Validate status change accepted
2. Tạo `friendships/{sortedPair}` doc
3. Send FCM push cả 2 user "Đã trở thành bạn bè!"
4. Delete friend_requests/{requestId} (cleanup)
```

**Side effects:**
- Firestore write (friendships) + delete (friend_requests)
- FCM messages cả 2

---

### `onFriendshipDeleted`

**Type:** Firestore trigger
**Trigger:** `functions.firestore.document('friendships/{pair}').onDelete(...)`
**Mục đích:** Cascade cleanup khi unfriend (hide cũ posts, etc.).

**Flow:**
```
1. Get uidA, uidB từ deleted doc
2. (Optional defer) Remove uidA's feed_items posts FROM uidB và vice versa
   - MVP có thể KHÔNG cascade — chỉ stop NEW posts đến nhau (đơn giản hơn)
3. Log unfriend event analytics
```

**MVP simplification:** KHÔNG cascade delete old feed_items. New posts mới sẽ không fan-out vì friendship gone. User có thể vẫn thấy ảnh cũ trên feed → acceptable cho MVP.

---

### `findFriendsByPhone` (defer M2)

**Type:** HTTPS callable
**Signature:**
```typescript
function findFriendsByPhone(data: {
  phoneHashes: string[]  // SHA-256 + salt từ device contacts
}): Promise<{
  matches: Array<{ uid: string, displayName: string, avatarUrl?: string }>
}>
```

**Mục đích:** Match contacts với existing Meep users (signup screen "Tìm bạn từ danh bạ").

**Flow:**
```
1. Verify request.auth (must be logged in)
2. Validate input: max 1000 hashes per call (rate limit)
3. Query users where phoneHash in (phoneHashes) — Firestore IN max 30 → batch
4. Return matched users (chỉ display public fields)
```

**Privacy:**
- Hash phone client-side với salt cố định + uid → server không biết raw phone
- Match by hash equality only

**Note:** Defer M2 vì optional trong signup flow. M1 user "Để sau" → skip.

---

## Tier 0+ — Space functions

### `onSpaceCreated`

**Type:** Firestore trigger
**Trigger:** `functions.firestore.document('spaces/{spaceId}').onCreate(...)`
**Mục đích:** Send invitation push tới members khi space được tạo.

**Flow:**
```
1. Read spaces/{spaceId} doc
2. For each member (except owner):
   - Send FCM push: "Bạn được mời vào Space '{spaceName}' bởi {ownerDisplayName}"
3. Log analytics event
```

---

### `onSpaceMemberRemoved`

**Type:** Firestore trigger
**Trigger:** `functions.firestore.document('spaces/{spaceId}').onUpdate(...)`
**Trigger condition:** `memberUids` array shrunk
**Mục đích:** Cleanup khi member leave space (hoặc bị remove).

**Flow:**
```
1. Diff old memberUids vs new memberUids → find removed uid
2. Remove `users/{removedUid}/feed_items` documents có spaceId == this spaceId
   - Optional: skip cho MVP (cascade complex)
3. (Optional) Send FCM tới removed user "Bạn đã rời Space '{spaceName}'"
```

**MVP simplification:** KHÔNG cascade delete feed_items (acceptable cho MVP — user vẫn thấy ảnh cũ space đã rời, đơn giản hơn).

---

## Tier 0+ — RollCall functions

### `rollcallScheduler`

**Type:** Scheduled (cron)
**Schedule:** `0 20 * * 0` (Sunday 8pm Vietnam timezone, UTC+7)
**Region:** asia-southeast1
**Mục đích:** Trigger weekly RollCall notification cho all active users.

**Flow:**
```
Cron trigger Sunday 8pm
  ↓
1. Query active users:
   firestore.collection('users')
     .where('lastSeenAt', '>=', sevenDaysAgo)
     .get()
   (Active = login last 7 days)
2. For each user:
   - Read FCM tokens from users/{uid}/devices
3. Batch send FCM push (max 500 messages per batch):
   - Title: "RollCall hôm nay"
   - Body: "Chia sẻ khoảnh khắc tuần này của bạn 📸"
   - Data: { type: 'rollcall', timestamp: now }
4. Log batch result
```

**Performance:**
- Memory: 256MB
- Timeout: 540s (9 min — defensive cho large batches)
- Expected runtime: <30s for 500 users

**Idempotency:** Function chạy 1 lần Sunday. Nếu fail → manual trigger qua Cloud Functions Console.

---

## Future functions (Tier 1+, defer)

### Chat 1-1 (Tier 1 stretch)

- `onChatMessageCreated` — denormalize lastMessage + send push
- `onChatRead` — update unreadCount

### RollCall 168h archive (Tier 2 — won't have)

- `archiveExpiredRollCallPosts` — scheduled hourly cron, query posts type=rollcall createdAt > 168h, set `archived: true`, copy to Diary

---

## Function lifecycle conventions

### Naming

- Triggers: `on<Event><Action>` vd `onPostCreated`, `onReactionDeleted`
- Callables: action verb vd `findFriendsByPhone`, `inviteToSpace`
- Scheduled: `<feature>Scheduler` vd `rollcallScheduler`

### Code organization

```
firebase/functions/src/
├── index.ts                    # Export all functions
├── auth/
│   └── onUserCreated.ts
├── posts/
│   ├── onPostCreated.ts
│   ├── onPostDeleted.ts
│   └── helpers/
│       ├── resize.ts
│       └── fanOut.ts
├── reactions/
│   ├── onReactionCreated.ts
│   └── onReactionDeleted.ts
├── friends/
│   ├── onFriendRequestAccepted.ts
│   ├── onFriendshipDeleted.ts
│   └── findFriendsByPhone.ts
├── spaces/
│   ├── onSpaceCreated.ts
│   └── onSpaceMemberRemoved.ts
├── rollcall/
│   └── rollcallScheduler.ts
└── shared/
    ├── fcm.ts                  # FCM helper
    ├── validation.ts           # input validation
    └── errors.ts               # AppError types
```

### Testing

Per `.windsurf/rules/22-functions-rules.md`:
- Vitest unit tests cho mỗi function
- Mock Firestore với `firebase-functions-test`
- Test happy path + error path + edge case

### Deployment

- Region: `asia-southeast1` cho all functions
- Memory default: 256MB; bump 512MB cho image processing (`onPostCreated`)
- Timeout default: 60s; bump 540s cho scheduled batch (`rollcallScheduler`)

## Liên quan

- **Function rules:** `.windsurf/rules/22-functions-rules.md`
- **Data model:** [`data-model.md`](data-model.md)
- **Security model:** [`security-model.md`](security-model.md)
