# TODO: Leader — Contract Creation + Infrastructure

> Plan: `docs/plans/2026-05-23-leader.md`
> Owner: ThienPDM
> Rule: Commit thẳng vào `develop` sau mỗi LX task. App phải compile sau mỗi commit.

---

## Phase 0 — Core infrastructure (trước tất cả)

- [ ] **LX0** — `AppError` hierarchy + `app_colors.dart` + `pairIdOf` util + `AppConfig` + `main.dart` skeleton

## Checkpoint: Core ✓
- [ ] `flutter analyze` clean

---

## Phase 1 — M1 contracts

- [ ] **LX1** — Auth contracts: `UserProfile` (full schema) + `AuthRepository` (9 methods) + `UserRepository` + controllers stubs + shared widgets (4) + router + screen stubs (10 màn auth)
- [ ] **LX-PUBSPEC** (partial) — Thêm packages cần cho M1: `google_sign_in` nếu chưa có

## Checkpoint: M1 contracts ✓
- [ ] `flutter analyze` clean, app launch về `/intro`

---

## Phase 2 — M2 contracts

- [ ] **LX2** — Friend contracts: `Friendship` + `FriendRequest` models + repositories + controller stub + sheet stubs + `isFriend()` rule helper + `/invite/:uid` route + CF stubs
- [ ] **LX3** — Settings contracts: `Block` model + `BlockRepository` (**canonical**) + controller stub + sheet/dialog stubs + `isBlocked()` rule helper + `ShareProfileSheet` + CF stubs
- [ ] **LX5** — Feed contracts: `Post` model (incl. `spaceId?`) + `PostRepository` + `StorageRepository` + `CaptionService` + controller stubs + shared widgets (5) + `HomeScreen` + `PhotoActionSheet` + CF stubs
- [ ] **LX8** — Diary contracts: `DiaryEntry` + `DiaryContentBlock` models + `DiaryRepository` (incl. `getPublicEntries`) + controller stub + screen stubs (6)
- [ ] **LX9** — Profile contracts: `ProfileRepository` + controller stub + screen stubs (5) + router routes
- [ ] **LX-PUBSPEC** (M2 packages) — `share_plus`, `camera`, `flutter_image_compress`, `gal`, `geolocator`, `cached_network_image`, `http`, `intl`, `image_picker`

## Checkpoint: M2 contracts ✓
- [ ] `flutter analyze` clean, app navigate được tới `/home` stub

---

## Phase 3 — M3 contracts

- [ ] **LX4** — Chat contracts: `Conversation` + `Message` models + `ConversationRepository` + controller stub + screen stubs (4) + router routes
- [ ] **LX6** — Notification contracts: `AppNotification` model + `NotificationRepository` + controller stub + CF stubs (3) + router deep link slots
- [ ] **LX7** — Reaction contracts: `Reaction` model + `ReactionRepository` (incl. `getMyReaction`) + controller stub + sheet stubs + update `ActTextBar` stub với optional controller param
- [ ] **LX10** — Space contracts: `Space` + `SpaceMember` models + `SpaceRepository` + controller stub + widget stubs (4) + **gate changes** (verify `Post.spaceId`, update `FeedScreen`) + CF stubs (8) + router routes
- [ ] **LX11** — Widget contracts: Android Kotlin stubs (3 files) + `AndroidManifest` update + `WidgetDataService` Flutter stub + router intent handler
- [ ] **LX12** — Streak contracts: `StreakController` stub + screen stubs (2) + router routes
- [ ] **LX-PUBSPEC** (M3 packages) — `firebase_messaging`, `flutter_local_notifications`, `emoji_picker_flutter`, `flutter_svg`, `shared_preferences` + Android `build.gradle` WorkManager + Glide

## Checkpoint: M3 contracts ✓
- [ ] `flutter analyze` clean, Android build clean
- [ ] `flutter pub get` không conflict

---

## Phase 4 — Shared infrastructure (sau tất cả contracts)

- [ ] **LX-RULES** — `firestore.rules` hoàn chỉnh: merge 7 helper functions + tất cả match blocks (12 modules) + `/posts` rule là 1 block duy nhất; `storage.rules` (avatars + posts + diary)

## Checkpoint: Rules ✓
- [ ] `firebase emulators:exec --only firestore "npm run test:rules"` — tất cả rules tests pass
- [ ] Không có `allow read, write: if true`

---

## Gate changes (ongoing — khi module dev request)

- [ ] **Space:** Confirm `Post.spaceId` field + `FeedFilter.space` case trong `FeedController` (đã handle ở LX10 nhưng verify khi Space dev start)
- [ ] **Reaction M3:** Update `ActTextBar` M2 stub → M3 stub khi Reaction dev start T3
- [ ] **Profile M3:** Cập nhật Diary tab từ empty state → `getPublicEntries` khi Diary module xong
- [ ] **Chat Group:** Confirm `GroupChatScreen` stub sẵn sàng khi Space dev cần (LX4 đã tạo)

---

## Pre-handoff checklist (per module)

Trước khi nói "go" với dev:
- [ ] `flutter analyze` clean
- [ ] App launch được (không crash)
- [ ] Providers throw `UnimplementedError` với hint
- [ ] TODO markers: `// TODO(<prefix>/T<N>/TBD): <mô tả> — see docs/plans/...`
- [ ] PR merged vào `develop`
