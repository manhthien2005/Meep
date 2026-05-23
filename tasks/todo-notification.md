# TODO: Notification

> Plan: `docs/plans/2026-05-23-notification.md`
> Spec: `docs/specs/2026-05-23-notification.md`
> Tier: T0 · Milestone M3
> Blocked by: Feed (onPostCreated CF [H10]), Friend (acceptFriendRequest CF)

---

## Phase 1 — Data layer

- [ ] **T1** — `FirebaseNotificationRepository` (saveFcmToken 1-token policy + SHA-256 tokenId + deleteFcmToken + getNotifications + markAsRead)

## Checkpoint: Data layer ✓
- [ ] `flutter test test/features/notification/` — 0 failures

---

## Phase 2 — Application layer

- [ ] **T2** — `NotificationController.initFCM` (requestPermission + token lifecycle + onTokenRefresh + background/terminated handlers) + wire vào `main.dart`
- [ ] **T3** — Foreground notification banner (Figma 765:4766 expanded / 765:4981 collapsed — collapsed/expanded states + auto-dismiss 4s)
- [ ] **T4** — Deep link routing từ notification tap (GoRouter: friend_request → FriendSheet; reaction → Feed scroll postId; new_post → Feed top)

## Checkpoint: App layer ✓
- [ ] `flutter test test/features/notification/` — 0 failures

---

## Phase 3 — Cloud Functions (song song nhau)

- [ ] **T5** — CF `onFriendRequestCreated` (FCM + notification doc; skip nếu không có token)
- [ ] **T6** — CF `onFriendRequestAccepted` (FCM cho sender; guard status transition)
- [ ] **T7** — CF `onReactionCreated` (FCM + notification doc; guard reactorId != authorId)

> ⚠️ `new_post` FCM **không** có CF riêng — được xử lý bên trong `onPostCreated` của Feed module ([H10]).

---

## Phase 4 — Rules

- [ ] **T8** — Firestore rules tests `/users/{uid}/notifications` + `/fcmTokens` + CF tests

## Checkpoint: Notification complete ✓
- [ ] CF tests pass
- [ ] `flutter analyze` clean
- [ ] Manual (device): send friend request → B nhận push; accept → A nhận push; react → author nhận push; foreground banner hiện + dismiss
