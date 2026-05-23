# TODO: Home / Camera / Feed

> Plan: `docs/plans/2026-05-23-home-camera-feed.md`
> Spec: `docs/specs/2026-05-22-home-camera-feed.md`
> Tier: T0 · Milestone M2
> Blocked by: Friend (FriendRepository audience avatars), Settings (BlockRepository feed filter)

---

## Phase 1 — Data layer

- [ ] **T1** — `FirebasePostRepository` (watchFeed fan-out subcollection + createPost + deletePost + getPostsByAuthor) + `FirebaseStorageRepository`

## Checkpoint: Data layer ✓
- [ ] `flutter test test/features/feed/` — 0 failures

---

## Phase 2 — Application layer (song song nhau)

- [ ] **T2** — `CaptionService` (Text + Location/Nominatim + Weather/OpenMeteo + Time + Mock)
- [ ] **T3** — `AppCameraController` + `CameraSection` UI (viewfinder 400×400 + controls + scroll behavior)
- [ ] **T5** — `PostController.createPost` (compress ≤1MB → upload → Firestore; rollback nếu Storage fail)
- [ ] **T6** — `FeedController` (fan-out query + cursor pagination limit 10 + prefetch index length-4 + FeedFilter)

## Checkpoint: App layer ✓
- [ ] `flutter test test/features/feed/` — 0 failures

---

## Phase 3 — UI

- [ ] **T4** — `CapturePreviewScreen` (caption cycle 7 types + audience selector + download in-place + send)
- [ ] **T7** — `FeedSection` UI (`FriendPostCard` + `OwnPostCard` + `ActTextBar` M2 disabled)
- [ ] **T8** — `GridViewScreen` + `ShareModal` + `PhotoActionSheet` (share + [Báo cáo stub] + [Chặn → BlockConfirmDialog])

---

## Phase 4 — Cloud Functions

- [ ] **T9** — CF `onPostCreated` (fan-out feed all-friends khi spaceId==null + postCount increment + FCM to friends; **skip** khi spaceId!=null)
- [ ] **T10** — CF `onPostDeleted` (batch delete feed docs + Storage delete + postCount decrement + reactions cleanup)

> ⚠️ CF `onFriendshipDeleted` (cross-feed cleanup) implement tại **Friend module T6** — không tạo CF riêng ở đây.

---

## Phase 5 — Rules

- [ ] **T11** — Firestore rules tests `/posts` + `/users/{uid}/feed` + Storage rules tests

## Checkpoint: Feed complete ✓
- [ ] `flutter test test/features/feed/` — 0 failures
- [ ] CF tests pass
- [ ] `flutter analyze` clean
- [ ] Manual: chụp ảnh → caption cycle → gửi → xuất hiện feed; grid view; save to gallery; download in-place
