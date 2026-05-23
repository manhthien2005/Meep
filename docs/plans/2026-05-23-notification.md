# Plan: Push Notification Module

> **Phụ thuộc vào:** Home/Camera/Feed — `Post` model, `onPostCreated` CF (FCM logic embedded [H10]); Friend — `Friendship` model (fan-out recipients); Chat — `Conversation` model (token cleanup khi block/delete)
> **Được phụ thuộc bởi:** Settings (deleteFcmToken khi logout), Widget Android (đọc `/users/{uid}/fcmTokens` schema)
> **Spec:** `docs/specs/2026-05-23-notification.md`
> **Tier:** T0 — Milestone M3

---

## PART 1 — Contract artifacts (ThienPDM merge vào `develop` TRƯỚC khi giao dev)

| File path | Type | Key contents |
|-----------|------|-------------|
| `lib/features/notification/data/app_notification.dart` | freezed model | `notifId String`, `type NotificationType` enum (friend_request/friend_accepted/reaction), `title String`, `body String`, `data Map<String,String>`, `read bool`, `createdAt DateTime` |
| `lib/features/notification/data/notification_repository.dart` | abstract class | `Future<void> saveFcmToken(String uid, String token)`, `Future<void> deleteFcmToken(String uid)`, `Future<List<AppNotification>> getNotifications(String uid)`, `Future<void> markAsRead(String notifId)` |
| `lib/features/notification/application/notification_controller.dart` | Riverpod stub | `NotificationState`, methods: `initFCM`, `handleForeground`, `handleBackground`, `markAsRead` — throw `UnimplementedError` |
| `apps/mobile/lib/main.dart` | update | FCM init call, `NotificationController.initFCM()` trong `ProviderScope` setup |
| `lib/core/router/app_router.dart` | update | Deep link handler từ notification tap: `getInitialMessage()` + `onMessageOpenedApp` stream |
| `firebase/functions/src/index.ts` | CF stubs | `onFriendRequestCreated`, `onFriendRequestAccepted`, `onReactionCreated` |

> `new_post` FCM không có notification doc, và FCM fan-out logic được gọi TRONG `onPostCreated` của Feed module ([H10]) — Notification module KHÔNG tạo CF riêng cho new_post.

---

## PART 2 — Tasks

---
**T1 · feat(notification): NotificationRepository — FCM token lifecycle + notifications CRUD**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/notification-repository` |
| Blocked by | contracts Part 1 |

Files:
- `lib/features/notification/data/firebase_notification_repository.dart` — impl `NotificationRepository`
- `test/features/notification/firebase_notification_repository_test.dart` — test: saveFcmToken creates doc, deleteFcmToken deletes all docs, getNotifications sort DESC, markAsRead updates field

Acceptance criteria:
- [ ] `saveFcmToken(uid, token)`: (1) xóa tất cả docs hiện có trong `/users/{uid}/fcmTokens/*` (1 token/user policy), (2) tạo doc mới với `tokenId = SHA-256(token)` (hex), `platform = 'android'`
- [ ] `deleteFcmToken(uid)`: xóa tất cả docs trong `/users/{uid}/fcmTokens/*` (logout cleanup)
- [ ] `getNotifications(uid)`: query ORDER BY `createdAt DESC`, không bao gồm `new_post` type (không lưu)
- [ ] `markAsRead(notifId)`: update `read = true` — chỉ field này, không đổi field khác

Cross-module imports: None

---
**T2 · feat(notification): NotificationController — initFCM + permission + token lifecycle + background/terminated handlers**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/notification-controller` |
| Blocked by | T1 |

Files:
- `lib/features/notification/application/notification_controller.dart` — full impl
- `lib/main.dart` — update: `FirebaseMessaging.instance.requestPermission()`, `NotificationController.initFCM()` gọi trong init
- `test/features/notification/notification_controller_test.dart` — test: token save on init, permission denied → không crash, markAsRead updates state

Acceptance criteria:
- [ ] `initFCM()`: `requestPermission()` → lấy token → `saveFcmToken()` → lắng nghe `onTokenRefresh` → tự động update
- [ ] Android 13+ `POST_NOTIFICATIONS` bị denied → không crash, không push, hiện banner nhắc enable
- [ ] App terminated: `getInitialMessage()` → parse notification data → navigate đúng route sau app open
- [ ] App background: `onMessageOpenedApp` stream → navigate khi user tap notification
- [ ] `FirebaseMessaging.onTokenRefresh` → tự động gọi `saveFcmToken()` (cleanup + replace token cũ)

Cross-module imports: `NotificationRepository` từ Part 1

---
**T3 · feat(notification): Foreground notification banner component**

| | |
|---|---|
| Assignee | TBD |
| Estimate | M (~8h) |
| Branch | `feat/TBD/notification-banner` |
| Blocked by | T2 |

Files:
- `lib/features/notification/presentation/widgets/notification_banner.dart` — overlay component (Figma `765:4766` expanded / `765:4981` collapsed)
- `lib/features/notification/application/notification_controller.dart` — update: `handleForeground()` trigger banner
- `test/features/notification/notification_banner_test.dart` — widget tests: collapsed state render, tap expand, "Tắt thông báo" toggle

Acceptance criteria:
- [ ] Collapsed (h=65): Logo + senderName + timestamp + chevron-down + message preview (Figma `765:4981`)
- [ ] Tap → Expanded (h=112): thêm [Trả lời] + [Tắt thông báo] (Figma `765:4766`)
- [ ] "Tắt thông báo": local preference (suppress foreground banner) — KHÔNG unsubscribe FCM
- [ ] Banner tự dismiss sau 4s nếu không interact
- [ ] Foreground notification (`onMessage` stream) → `flutter_local_notifications` hiện local notification

Cross-module imports: None

---
**T4 · feat(notification): Deep link routing từ notification tap**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/notification-deep-link` |
| Blocked by | T2 |

Files:
- `lib/core/router/app_router.dart` — update: đọc `notification.data.type` → navigate đúng route

Acceptance criteria:
- [ ] `type == 'friend_request'` → navigate `FriendSheet`
- [ ] `type == 'friend_accepted'` → navigate `FriendSheet`
- [ ] `type == 'reaction'` → navigate Feed, scroll đến `postId` (highlight)
- [ ] `type == 'new_post'` → navigate Feed (top)
- [ ] Post đã bị xóa khi user tap notification → navigate Home + toast "Bài viết không còn tồn tại"
- [ ] Double-tap notification → navigate idempotent (không push duplicate routes)

Cross-module imports: `FriendSheet` từ **friend**, `FeedController` từ **home-camera-feed**

---
**T5 · feat(notification): CF `onFriendRequestCreated` — FCM + notification doc**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/notification-cf-friend-request` |
| Blocked by | contracts Part 1 |

Files:
- `firebase/functions/src/notification/onFriendRequestCreated.ts` — Firestore onCreate `/friend_requests/{id}`
- `firebase/functions/test/notification/onFriendRequestCreated.test.ts` — test: FCM gửi, notification doc tạo, receiver không có token → skip không crash

Acceptance criteria:
- [ ] Đọc FCM token của `receiverId` từ `/users/{receiverId}/fcmTokens/*`
- [ ] Gửi FCM: `title = "{senderName} muốn kết bạn với bạn"`, `body = "Tap để xem và chấp nhận"`, `data = { type: 'friend_request', requestId }`
- [ ] Tạo `/users/{receiverId}/notifications/{id}` với đúng fields
- [ ] Receiver không có FCM token → skip gracefully, không crash
- [ ] Receiver FCM token stale (invalid-argument) → xóa token khỏi Firestore, không retry

Cross-module imports: None (Admin SDK)

---
**T6 · feat(notification): CF `onFriendRequestAccepted` — FCM cho sender**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/notification-cf-friend-accepted` |
| Blocked by | T5 |

Files:
- `firebase/functions/src/notification/onFriendRequestAccepted.ts` — Firestore onUpdate `/friend_requests/{id}` (status → accepted)
- `firebase/functions/test/notification/onFriendRequestAccepted.test.ts`

Acceptance criteria:
- [ ] Trigger chỉ khi `status == 'accepted'` (onUpdate guard: `change.before.data().status != 'accepted' && change.after.data().status == 'accepted'`)
- [ ] Gửi FCM cho `senderId`: `title = "{receiverName} đã chấp nhận lời mời kết bạn"`, `body = "Các bạn giờ là bạn bè trên Meep!"`
- [ ] Tạo notification doc cho `senderId`

Cross-module imports: None

---
**T7 · feat(notification): CF `onReactionCreated` — FCM + notification doc cho post author**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/notification-cf-reaction` |
| Blocked by | contracts Part 1 |

Files:
- `firebase/functions/src/notification/onReactionCreated.ts` — Firestore onCreate `/posts/{postId}/reactions/{reactorUid}`
- `firebase/functions/test/notification/onReactionCreated.test.ts` — test: FCM gửi, self-react guard, notification doc tạo

Acceptance criteria:
- [ ] Guard: `reactorId == post.authorId` → skip (không tự notify mình)
- [ ] Gửi FCM cho `post.authorId`: `title = "{reactorName} đã react vào ảnh của bạn"`, `body = "{emoji}"`, `data = { type: 'reaction', postId }`
- [ ] Tạo `/users/{authorId}/notifications/{id}`

Cross-module imports: None

---
**T8 · test(notification): Firestore rules + CF tests**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `test/TBD/notification-rules` |
| Blocked by | T1 |

Files:
- `firebase/functions/test/rules/notification.rules.test.ts`

Acceptance criteria:
- [ ] `/users/{uid}/notifications/{id}` read by owner ✓, stranger ✗
- [ ] `/users/{uid}/notifications/{id}` update `read` field by owner ✓, update other field ✗
- [ ] `/users/{uid}/notifications/{id}` create by client ✗ (CF Admin SDK only)
- [ ] `/users/{uid}/fcmTokens/{id}` read by owner ✓, write by owner ✓, stranger ✗

Cross-module imports: None

---

## PART 3 — Dependency graph

```
contracts Part 1 → T1 → T2 → T3
                          ↘
                     T2 → T4 (parallel T3)
contracts Part 1 → T5 → T6 → T8
contracts Part 1 → T7 → T8
```

T5, T7 (Cloud Functions) có thể chạy song song với T1-T4 (Flutter).

---

## PART 4 — Open questions

| # | Câu hỏi | Status |
|---|---|---|
| OQ1 | In-app notification list screen | Foreground banner đã có. Full list screen: **Nice-to-have M3** — implement nếu còn thời gian sau T1-T8 |
