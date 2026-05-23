# Spec: Push Notification Module

**Date:** 2026-05-23
**Status:** Locked
**Owner:** ThienPDM (leader assign trước khi giao)
**Epic:** [T0] Push Notification — FCM Android · Milestone M3

---

## Goal

Gửi push notification đến thiết bị Android của user khi có sự kiện liên quan (friend request, post mới, reaction). Lưu notification history trong Firestore để user xem lại.

---

## User stories

- Là user, tôi muốn nhận push notification khi có người gửi friend request cho tôi.
- Là user, tôi muốn nhận push notification khi friend request của tôi được chấp nhận.
- Là user, tôi muốn nhận push notification khi bạn bè đăng ảnh mới.
- Là user, tôi muốn nhận push notification khi có người react vào ảnh của tôi.
- Là user, tôi muốn xem lại danh sách notification gần đây trong app.

---

## Scope

### In-scope (M3)

1. **FCM token management** — lưu/cập nhật FCM token khi user login, xoá khi logout
2. **4 notification events:**
   - `friend_request_received` — A gửi friend request cho B
   - `friend_request_accepted` — B chấp nhận friend request của A
   - `new_post` — bạn bè đăng ảnh mới (fan-out theo friend list)
   - `reaction_received` — ai đó react vào post của mình
3. **Notification history** — lưu vào Firestore, đọc trong app (in-app notification list)
4. **Notification toggle** — bật/tắt từ Profile (lưu local preference, unsubscribe FCM)
5. **Deep link tap** — tap notification → navigate đúng màn hình trong app

### Out-of-scope

- Space post notification — defer sang Space module nếu cần
- RollCall notification — **cut** (RollCall module bị loại)
- Notification settings granular (per-type toggle) — post-MVP
- Badge count trên app icon — post-MVP
- Notification grouping — post-MVP

---

## Màn hình & Figma IDs

| Màn hình | Figma ID | Ghi chú |
|---|---|---|
| In-app notification list screen | _(chưa có — xem OQ1)_ | Optional M3; minimum = push only |
| **Foreground notification banner (component)** | `765:4766` (expanded) / `765:4981` (collapsed) | Overlay khi app đang mở |

> M3 minimum viable: push notification hoạt động đúng. In-app list là nice-to-have.

### Foreground notification banner spec

**Component `Noti`** — overlay slide down từ top khi app foreground:

```
Container: bg #2d2d2fe0 (semi-transparent dark), cornerRadius 20, width 364

Collapsed state (h=65, Figma 765:4981):
  [ Logo ] [senderName . timestamp    ] [chevron-down]
                [message preview]

Expanded state (h=112, Figma 765:4766):
  [ Logo ] [senderName . timestamp    ] [chevron-up]
                [message preview]
  [Trả lời]  |  [Tắt thông báo]
```

Typography:
- `senderName`: Roboto Medium 13px, `#dee5e6` (BW300)
- `timestamp`: Roboto Light 11px, `#656c6d` (BW600)  
- `message preview`: Roboto Light 13px, `#8d999b` (BW500)
- Actions: Roboto Regular 12px, `#8d999b` (BW500)

> **Tắt thông báo** = local preference toggle (không phải unsubscribe FCM — chỉ suppress foreground banner).

---

## Luồng đầy đủ

### FCM token lifecycle

```
App khởi động + user đã login
    → FirebaseMessaging.getToken() → lưu vào /users/{uid}/fcmTokens/{tokenId}
        **[OQ3] 1 token/user policy:** saveFcmToken() phải:
        1. Xóa tất cả token docs hiện có trong /users/{uid}/fcmTokens/*
        2. Rồi tạo doc mới với tokenId mới
        (Thực hiện bằng Firestore batch: delete all + create new)
    → FirebaseMessaging.onTokenRefresh → gọi lại saveFcmToken() — tự cleanup + replace

User logout (Settings module)
    → Xoá token khỏi Firestore (xóa tất cả docs trong /users/{uid}/fcmTokens/*)
    → FirebaseAuth.signOut()
```

### friend_request_received

```
User A gửi friend request → Firestore /friend_requests/{id} created
    → Cloud Function onFriendRequestCreated trigger
        → Đọc FCM token của receiverId
        → Gửi FCM notification:
            title: "{senderName} muốn kết bạn với bạn"
            body:  "Tap để xem và chấp nhận"
            data:  { type: 'friend_request', requestId }
        → Tạo /users/{receiverId}/notifications/{id}
    → User B nhận push → tap → app mở FriendSheet (deep link)
```

### friend_request_accepted

```
User B chấp nhận → acceptFriendRequest Cloud Function
    → Gửi FCM notification cho User A:
            title: "{receiverName} đã chấp nhận lời mời kết bạn"
            body:  "Các bạn giờ là bạn bè trên Meep!"
            data:  { type: 'friend_accepted', friendUid }
    → Tạo /users/{senderOfRequest}/notifications/{id}
```

### new_post (fan-out)

```
User đăng ảnh → /posts/{postId} created
    → Cloud Function onPostCreated (đã có trong index.ts)
        → Đọc friendUids từ /friendships (arrayContains authorId)
        → Batch gửi FCM cho từng friendUid (max 20)
        → KHÔNG tạo notification doc (spam nếu lưu tất cả)
    → Bạn bè nhận push → tap → app mở Feed (scroll đến post đó)
```

### reaction_received

```
User react → /posts/{postId}/reactions/{id} created
    → Cloud Function onReactionCreated trigger
        → Đọc post.authorId, FCM token của author
        → Guard: nếu reactorId == authorId → skip (không tự notify mình)
        → Gửi FCM:
            title: "{reactorName} đã react vào ảnh của bạn"
            body:  "{emoji}"
            data:  { type: 'reaction', postId }
        → Tạo /users/{authorId}/notifications/{id}
```

### Deep link navigation

```
User tap notification payload
    → App mở (foreground / background / terminated)
    → GoRouter đọc notification data.type:
        'friend_request' → FriendSheet
        'friend_accepted' → FriendSheet
        'reaction'        → Feed (scroll đến postId)
        'new_post'        → Feed (top)
```

---

## Data model

### `/users/{uid}/fcmTokens/{tokenId}`

```
{
  token:     string,    // FCM device token
  platform:  'android', // MVP: Android only
  updatedAt: Timestamp,
}
```

> **[H6-FIX] `tokenId` = SHA-256 hash (hex) của token** để tránh duplicate khi đăng nhập lại cùng thiết bị.  
> Dart: `sha256.convert(utf8.encode(token)).toString()` (package `crypto` — đã có vì Firebase SDK depend on it).  
> Kotlin Worker: `MessageDigest.getInstance("SHA-256").digest(token.toByteArray()).joinToString("") { "%02x".format(it) }`.

### `/users/{uid}/notifications/{notifId}`

```
{
  type:      'friend_request' | 'friend_accepted' | 'reaction',  // new_post không lưu
  title:     string,
  body:      string,
  data:      Map<string, string>,  // deep link params
  read:      boolean,   // default false
  createdAt: Timestamp,
}
```

---

## Architecture

```
Presentation            Application                 Data
────────────────        ──────────────────          ───────────────────────────
(in-app list            NotificationController      NotificationRepository
 optional M3)            ├─ initFCM()               ├─ saveFcmToken()
                         ├─ handleForeground()       ├─ deleteFcmToken()
                         ├─ handleBackground()       ├─ getNotifications()
                         └─ markAsRead()             └─ markAsRead()
```

**Cloud Functions liên quan:**

| Function | Trigger | Việc làm |
|---|---|---|
| `onFriendRequestCreated` | Firestore onCreate `/friend_requests/{id}` | Gửi FCM cho receiver, tạo notification doc |
| `onFriendRequestAccepted` | Firestore onUpdate `/friend_requests/{id}` (status → accepted) | Gửi FCM cho sender |
| `onPostCreated` | Firestore onCreate `/posts/{id}` | **[H10-NOTE] Function này được define trong `home-camera-feed.md` — không tạo function mới.** Logic FCM fan-out cho friends được gọi bên trong `onPostCreated` của Camera/Feed spec. |
| `onReactionCreated` | Firestore onCreate `/posts/{id}/reactions/{id}` | Gửi FCM cho post author, tạo notification doc |

---

## Dependencies

| Package | Lý do | Có sẵn? |
|---|---|---|
| `firebase_messaging` | FCM token + receive push | ❌ cần thêm |
| `flutter_local_notifications` | Hiện notification khi app foreground | ❌ cần thêm |
| `go_router` | Deep link navigation từ notification tap | ✅ |

---

## Security

```javascript
match /users/{uid}/notifications/{notifId} {
  allow read:   if isAuthed() && request.auth.uid == uid;
  allow update: if isAuthed() && request.auth.uid == uid
                && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read']);
  allow create: if false;  // Cloud Function Admin SDK only
  allow delete: if false;
}

match /users/{uid}/fcmTokens/{tokenId} {
  allow read:   if isAuthed() && request.auth.uid == uid;
  allow write:  if isAuthed() && request.auth.uid == uid;
}
```

---

## Testing strategy

### Unit tests

| Test | Target |
|---|---|
| `saveFcmToken(uid, token)` → doc tạo đúng | `NotificationRepository` |
| `deleteFcmToken(uid)` → doc xoá | `NotificationRepository` |
| `getNotifications(uid)` → list sort by createdAt DESC | `NotificationRepository` |
| `markAsRead(notifId)` → `read = true` | `NotificationRepository` |

### Cloud Function tests

| Test | Expected |
|---|---|
| `onFriendRequestCreated`: receiver có FCM token → FCM gửi + notification doc tạo | ✅ |
| `onFriendRequestCreated`: receiver không có FCM token → skip, không crash | ✅ |
| `onReactionCreated`: reactorId == authorId → skip (không self-notify) | ✅ |
| `onPostCreated`: fan-out đúng số friendUids (max 20) | ✅ |

### Firestore rules tests

- `/users/{uid}/notifications/{id}` read by owner ✓
- `/users/{uid}/notifications/{id}` read by stranger ✗
- `/users/{uid}/notifications/{id}` update `read` field by owner ✓
- `/users/{uid}/notifications/{id}` update other field ✗
- `/users/{uid}/notifications/{id}` create by client ✗ (CF only)

---

## Contract bàn giao

| Artifact | File | Status |
|---|---|---|
| `AppNotification` freezed model | `lib/features/notification/data/app_notification.dart` | ❌ |
| `NotificationRepository` abstract | `lib/features/notification/data/notification_repository.dart` | ❌ |
| `NotificationController` stub | `lib/features/notification/application/notification_controller.dart` | ❌ |
| FCM init trong `main.dart` | `apps/mobile/lib/main.dart` | ❌ |
| Deep link handler trong router | `lib/core/router/app_router.dart` | ❌ |
| Cloud Function `onFriendRequestCreated` stub | `firebase/functions/src/index.ts` | ❌ |
| Cloud Function `onFriendRequestAccepted` stub | `firebase/functions/src/index.ts` | ❌ |
| Cloud Function `onReactionCreated` stub | `firebase/functions/src/index.ts` | ❌ |
| Firestore rules `/users/{uid}/notifications` + `/fcmTokens` | `firestore.rules` | ❌ |
| TODO markers trên mọi stub | — | ⏳ |

---

## Open questions

| # | Câu hỏi | Status |
|---|---|---|
| OQ1 | In-app notification list screen | ⏳ **Foreground banner đã có** (Figma `765:4766`/`765:4981`). Full notification list screen vẫn pending — MVP acceptable bằng banner only. |
| OQ2 | `new_post` notification — có lưu notification doc không? | **✅ Không** — tránh spam, chỉ push FCM |
| OQ3 | Multiple devices per user? | **MVP: 1 token/user** — overwrite khi login lại |

---

## Worst path

| Scenario | Expected behavior |
|---|---|
| `saveFcmToken` Firestore fail khi login | Retry tự động khi `onTokenRefresh` trigger; nếu không save được, notification không gửi được — chấp nhận (non-blocking) |
| FCM token stale (user reinstall app) | `onTokenRefresh` callback ghi token mới vào Firestore; CF phát hiện FCM invalid-argument error → xoá token cũ khỏi Firestore |
| `onFriendRequestCreated` CF fail | Notification không gửi; không retry tự động (non-blocking); user vẫn nhìn thấy request trong Friend module |
| `onPostCreated` fan-out CF fail giữa chừng | Một số friends không nhận push; không retry (fan-out là best-effort); bài post vẫn lưu đúng |
| User tap notification khi app killed → deep link fail | `go_router` initial route nhận `initialLocation` từ `getInitialMessage()`; nếu post đã xoá → navigate home + toast "Bài viết không còn tồn tại" |
| User tap notification khi app background → navigate sai màn | `onMessageOpenedApp` stream xử lý deep link; fallback: navigate home nếu route không giải quyết được |
| Android 13+ `POST_NOTIFICATIONS` permission bị denied | `firebase_messaging.requestPermission()` trả `denied`; chạy in-app only mode (không có push); không crash; hiện banner nhắc enable lại trong Settings |
| `markAsRead` Firestore fail | Notification badge/dot giữ nguyên; retry khi user re-open notification list; non-blocking |
| User logout nhưng `deleteFcmToken` fail | Token orphan trong Firestore; CF gửi notification cho token cũ → FCM trả invalid → CF catch + xoá token; tự clean up |
| `onReactionCreated` với `reactorId == authorId` (self-react) | CF skip (đã có guard); không gửi notification; không tạo doc |
| Notification doc tạo thất bại (Admin SDK error) | Log lỗi server-side; FCM vẫn đã gửi (push và notification doc độc lập); in-app list thiếu item nhưng push đã hiện |
| Multiple notifications tap nhanh (double tap) | `go_router` navigate idempotent; nếu đang ở đúng route rồi → no-op; không push duplicate screens |

---

## Risks

- **FCM token stale:** user reinstall app → token đổi nhưng Firestore vẫn có token cũ → FCM delivery fail. Mitigation: `onTokenRefresh` cập nhật token, server catch FCM invalid token error và xoá token cũ.
- **Fan-out 20 friends:** Firestore batch FCM với 20 tokens/post — nằm trong giới hạn FCM batch (500). OK.
- **Foreground notification:** FCM mặc định không hiện UI khi app foreground → cần `flutter_local_notifications` để show local notification.
- **Android 13+ notification permission:** `POST_NOTIFICATIONS` runtime permission bắt buộc từ Android 13. `firebase_messaging` tự request nhưng cần handle denied state gracefully.
