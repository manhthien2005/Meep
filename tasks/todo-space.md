# TODO: Space

> Plan: `docs/plans/2026-05-23-space.md`
> Spec: `docs/specs/2026-05-23-space.md`
> Tier: T0+ · Milestone M3
> Blocked by: Friend (FriendRepository invite members), Feed (leader gate: Post model + FeedScreen spaceId param), Chat (Conversation schema — CF `createSpace` tạo `/conversations/{spaceId}`)

---

## Phase 1 — Data layer

- [ ] **T1** — `FirebaseSpaceRepository` (watchMySpaces arrayContains + getSpace + deleteSpace soft)

## Checkpoint: Data layer ✓
- [ ] `flutter test test/features/space/` — 0 failures

---

## Phase 2 — Application layer

- [ ] **T2** — `SpaceController` (createSpace validation ≤9 friends + loadMySpaces + leaveSpace creator-guard + deleteSpace soft-delete)

## Checkpoint: App layer ✓
- [ ] `flutter test test/features/space/` — 0 failures

---

## Phase 3 — UI

- [ ] **T3** — `SpaceCreateSheet` 3-step flow (FriendSelectStep + SpaceConfigStep + IconBuilderStep với emoji_picker_flutter)
- [ ] **T4** — `SpaceContextBottomSheet` + Camera context switch (viền/nút = colorHex) + `SpaceContextBadge`
- [ ] **T5** — Feed per Space (`FeedFilter.space(spaceId)` + `FeedScreen(spaceId)` — **leader gate change**)
- [ ] **T10b** — `SpaceManagementSheet` + Leave/Delete/Kick/Transfer dialogs (trigger từ `...` menu FeedScreen Space context)

---

## Phase 4 — Cloud Functions

- [ ] **T6** — CF `createSpace` (batch: /spaces + /space_members + group conversation)
- [ ] **T7** — CF `leaveSpace` + `kickMember` + `transferOwnership`
- [ ] **T8** — CF `onSpaceMemberAdded` + `onSpaceMemberRemoved` (memberCount + spaceCount)
- [ ] **T9** — CF `onSpacePostCreated` (guard spaceId!=null; FCM fan-out + feed fan-out tất cả members)
- [ ] **T10** — CF `onSpaceDeleted` (cleanup space_members + conversation status=deleted)

---

## Phase 5 — Rules

- [ ] **T11** — Firestore rules tests `/spaces` + `/space_members`

## Checkpoint: Space complete ✓
- [ ] CF tests pass
- [ ] `flutter analyze` clean
- [ ] Manual: tạo Space → invite friends → camera context switch (viền đổi màu) → chụp → Space feed; leave Space (member); kick member (creator); delete Space
