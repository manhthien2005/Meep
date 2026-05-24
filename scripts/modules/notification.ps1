# scripts/modules/notification.ps1
# Module: Notification | Owner: KhoaLND | M3

function Create-NotificationModule {
    $parentBody = @'
> **Tier:** T0 | **Milestone:** M3 | **Assignee:** KhoaLND
> **Spec:** `docs/specs/2026-05-23-notification.md`
> **Plan:** `docs/plans/2026-05-23-notification.md`
> **Todo:** `tasks/todo-notification.md`
> **Phụ thuộc vào:** Feed (onPostCreated CF — FCM embedded), Friend (acceptFriendRequest CF)
> **Được phụ thuộc bởi:** Settings (deleteFcmToken khi logout), Widget (đọc /users/{uid}/fcmTokens)

## Mục tiêu
Push notification qua FCM cho 3 events: friend_request, friend_accepted, reaction. `new_post` FCM được xử lý trong `onPostCreated` của Feed module — **Notification module không tạo CF riêng cho new_post**.

## Data model
**`/users/{uid}/fcmTokens/{tokenId}`** — `tokenId = SHA-256(token)` (hex), `platform = 'android'`
**`/users/{uid}/notifications/{notifId}`** — `notifId, type, title, body, data, read, createdAt`

`NotificationType` enum: `friend_request`, `friend_accepted`, `reaction` — **KHÔNG có `new_post`** (không lưu doc).

## Contract artifacts (ThienPDM đã merge qua LX6)
- `lib/features/notification/data/app_notification.dart` — @freezed
- `lib/features/notification/data/notification_repository.dart` — abstract
- `lib/features/notification/application/notification_controller.dart` — stub
- `main.dart` — FCM init comment + NotificationController stub call
- `app_router.dart` — deep link handler slots
- CF stubs: `onFriendRequestCreated`, `onFriendRequestAccepted`, `onReactionCreated`
'@

    $subs = @(
        @{
            title = "[Notification] T1 — FirebaseNotificationRepository"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-notification.md` — Task T1
> **Estimate:** S (~4h) | **Branch:** `feat/<DevName>/notification-repository`
> **Bị block bởi:** LX6 contracts đã merge

## Files cần tạo
- `lib/features/notification/data/firebase_notification_repository.dart`
- `test/features/notification/data/firebase_notification_repository_test.dart`

## Acceptance criteria
- [ ] `saveFcmToken(uid, token)`: (1) xóa tất cả docs hiện có trong `/users/{uid}/fcmTokens/*` (1 token/user policy), (2) tạo doc mới với `tokenId = SHA-256(token)` (hex), `platform = 'android'`
- [ ] `deleteFcmToken(uid)`: xóa TẤT CẢ docs trong `/users/{uid}/fcmTokens/*` (logout cleanup)
- [ ] `getNotifications(uid)`: query ORDER BY `createdAt DESC` — **KHÔNG** include `new_post` type
- [ ] `markAsRead(notifId)`: update chỉ field `read = true`
- [ ] `flutter test test/features/notification/data/` — 0 failures

## Definition of Done
- [ ] Tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Notification] T2+3 — NotificationController.initFCM + foreground banner"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-notification.md` — Task T2, T3
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/notification-controller`
> **Bị block bởi:** {sub0} — T1 phải done
> **Figma:** Collapsed `765:4981`, Expanded `765:4766`

## Files cần tạo/sửa
- `lib/features/notification/application/notification_controller.dart` — full impl
- `lib/main.dart` — **update:** gọi `NotificationController.initFCM()` sau login
- `lib/features/notification/presentation/widgets/notification_banner.dart` — overlay component

## Acceptance criteria — initFCM
- [ ] `requestPermission()` → lấy token → `saveFcmToken()` → lắng nghe `onTokenRefresh` → tự update
- [ ] Android 13+ `POST_NOTIFICATIONS` denied → không crash, không push, hiện banner nhắc enable
- [ ] App terminated: `getInitialMessage()` → parse `data.type` → navigate đúng route sau open
- [ ] App background: `onMessageOpenedApp` → navigate khi user tap notification

## Acceptance criteria — Foreground banner
- [ ] Collapsed (h=65): Logo + senderName + timestamp + chevron + preview (Figma `765:4981`)
- [ ] Tap → Expanded (h=112): thêm [Trả lời] + [Tắt thông báo]
- [ ] "Tắt thông báo": lưu local preference (suppress banner) — **KHÔNG** unsubscribe FCM
- [ ] Banner tự dismiss sau 4s nếu không interact
- [ ] `FirebaseMessaging.onMessage` stream → `flutter_local_notifications` hiện local notification

## Definition of Done
- [ ] Manual (device): nhận push khi foreground → banner hiện đúng
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Notification] T4 — Deep link routing từ notification tap"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-notification.md` — Task T4
> **Estimate:** S (~4h) | **Branch:** `feat/<DevName>/notification-deep-link`
> **Bị block bởi:** {sub1} — T2+3 phải done (cần initFCM hoạt động)

## File cần sửa
- `lib/core/router/app_router.dart` — **update:** đọc `notification.data.type` → navigate đúng route

## Acceptance criteria
- [ ] `type == 'friend_request'` → navigate `FriendSheet`
- [ ] `type == 'friend_accepted'` → navigate `FriendSheet`
- [ ] `type == 'reaction'` → navigate Feed, scroll đến `postId` (highlight)
- [ ] `type == 'new_post'` → navigate Feed (top)
- [ ] Post đã bị xóa khi user tap → navigate Home + toast "Bài viết không còn tồn tại"
- [ ] Double-tap notification → navigate idempotent (không push duplicate routes)

## Cross-module imports
- `FriendSheet` từ **friend**, `FeedController` từ **home-camera-feed**

## Definition of Done
- [ ] Manual: send request → B tap notification → FriendSheet open
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Notification] T5+6+7 — Cloud Functions (3 CFs)"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-notification.md` — Task T5, T6, T7
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/notification-cloud-functions`
> **Bị block bởi:** LX6 contracts (song song với T1-T4)

## Files cần tạo
- `firebase/functions/src/notification/onFriendRequestCreated.ts` — Firestore onCreate `/friend_requests/{id}`
- `firebase/functions/src/notification/onFriendRequestAccepted.ts` — Firestore onUpdate (status → accepted)
- `firebase/functions/src/notification/onReactionCreated.ts` — Firestore onCreate `/posts/{postId}/reactions/{uid}`
- Tests tương ứng

## Acceptance criteria — `onFriendRequestCreated`
- [ ] Đọc FCM token của `receiverId` từ `/users/{receiverId}/fcmTokens/*`
- [ ] FCM: `title = "{senderName} muốn kết bạn với bạn"`, `data = { type: 'friend_request', requestId }`
- [ ] Tạo `/users/{receiverId}/notifications/{id}`
- [ ] Receiver không có token → skip gracefully
- [ ] Token stale (invalid-argument) → xóa token khỏi Firestore, không retry

## Acceptance criteria — `onFriendRequestAccepted`
- [ ] Guard: trigger chỉ khi `before.status != 'accepted' && after.status == 'accepted'`
- [ ] FCM cho `senderId`: `title = "{receiverName} đã chấp nhận lời mời kết bạn"`

## Acceptance criteria — `onReactionCreated`
- [ ] Guard: `reactorId == post.authorId` → skip (không tự notify mình)
- [ ] FCM cho `post.authorId`: `title = "{reactorName} đã react vào ảnh của bạn"`, `body = "{emoji}"`
- [ ] `npm test` PASS cả 3 CFs

## Definition of Done
- [ ] `npm test` + `npm run lint` PASS
- [ ] Manual (2 devices): push nhận đúng
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Notification] T8 — Firestore rules tests"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-notification.md` — Task T8
> **Estimate:** S (~4h) | **Branch:** `test/<DevName>/notification-rules`
> **Bị block bởi:** {sub0} — T1 phải done

## File cần tạo
- `firebase/functions/test/rules/notification.rules.test.ts`

## Acceptance criteria
- [ ] `/users/{uid}/notifications/{id}` read by owner ✓, stranger ✗
- [ ] `/users/{uid}/notifications/{id}` update field `read` by owner ✓, update other field ✗
- [ ] `/users/{uid}/notifications/{id}` create by client ✗ (CF Admin SDK only)
- [ ] `/users/{uid}/fcmTokens/{id}` read by owner ✓, write by owner ✓, stranger ✗

## Definition of Done
- [ ] Rules tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        }
    )

    New-Module "🔔 [Notification]" $parentBody $KhoaLND 3 $subs
}
