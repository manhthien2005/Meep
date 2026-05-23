# TODO: Profile

> Plan: `docs/plans/2026-05-23-profile.md`
> Spec: `docs/specs/2026-05-22-profile.md`
> Tier: T0+ · Milestone M2
> Blocked by: Auth (UserProfile update), Friend (FriendRepository, FriendSheet), Diary (DiaryRepository.getPublicEntries — M3 only)

---

## Phase 1 — Data layer

- [ ] **T1** — `FirebaseProfileRepository` (getUserProfile + watchUserProfile + updateProfile allowlist + updateAvatar compress/upload + removeAvatar)

## Checkpoint: Data layer ✓
- [ ] `flutter test test/features/profile/` — 0 failures

---

## Phase 2 — Application layer

- [ ] **T2** — `ProfileController` (loadProfile + updateField + avatar ops + shareProfile + `isUsernameAvailable` delegate sang `UserRepository`)

## Checkpoint: App layer ✓
- [ ] `flutter test test/features/profile/` — 0 failures

---

## Phase 3 — UI Screens

- [ ] **T3** — `ProfileScreen` (avatar + stats Khoảnh khắc/Bạn bè/Space + 2 action buttons + tab bar scaffold)
- [ ] **T4** — `PhotoGrid` tab (3-column, cursor-paginated 9/batch) + `PhotoDetailScreen` (swipe carousel + thumbnail strip)
- [ ] **T5** — `EditProfileScreen` (tất cả fields + email re-auth + username uniqueness + **notification toggle → SharedPreferences**)
- [ ] **T6** — `AvatarPickerSheet` (gallery/camera/remove) + `ShareProfileSheet` integration
- [ ] **T7** — `FriendProfileScreen` (view-only: avatar + stats + bio + grid; isFriend gate)
- [ ] **T8** — Diary tab (M2: empty state "Tính năng sắp ra mắt"; M3: `DiaryMoodCard` grid từ `getPublicEntries`)

---

## Phase 4 — Rules

- [ ] **T9** — Firestore rules `/users/{uid}` canonical update rules + Storage rules `avatars/{uid}/` + rules tests

## Checkpoint: Profile complete ✓
- [ ] `flutter test test/features/profile/` — 0 failures
- [ ] `flutter analyze` clean
- [ ] Manual: xem profile → stats đúng; edit displayName/bio; đổi avatar; photo detail swipe; share profile link; friend profile view-only
