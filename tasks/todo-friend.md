# TODO: Friend

> Plan: `docs/plans/2026-05-23-friend.md`
> Spec: `docs/specs/2026-05-22-friend.md`
> Tier: T0 · Milestone M2
> Blocked by: Auth (UserProfile, currentUidProvider)

---

## Phase 1 — Data layer

- [ ] **T1** — `FirebaseFriendRepository` + `FirebaseFriendRequestRepository` + `pairIdOf()` util

## Checkpoint: Data layer ✓
- [ ] `flutter test test/features/friend/` — 0 failures

---

## Phase 2 — Application layer

- [ ] **T2** — `FriendController` (search debounce 500ms + loadFriends + pending requests + send/accept/decline/cancel/unfriend)

## Checkpoint: App layer ✓
- [ ] `flutter test test/features/friend/` — 0 failures

---

## Phase 3 — UI

- [ ] **T3** — `FriendSheet` bottom sheet (search + pending requests + friend list + unfriend confirm dialog)
- [ ] **T4** — `FriendFilterDropdown` + invite link section + deep link `/invite/:uid`

---

## Phase 4 — Cloud Functions

- [ ] **T5** — CF `acceptFriendRequest` (validate + atomic batch: friendship + conversation + friendCount cả 2 user)
- [ ] **T6** — CF `onFriendshipDeleted` (friendCount decrement + conversation status + cross-feed cleanup)

---

## Phase 5 — Rules

- [ ] **T7** — Firestore rules tests `/friendships` + `/friend_requests`

## Checkpoint: Friend complete ✓
- [ ] `flutter test test/features/friend/` — 0 failures
- [ ] CF tests pass
- [ ] `flutter analyze` clean
- [ ] Manual: search → send request → accept → friend list cập nhật; unfriend confirm dialog; invite link copy
