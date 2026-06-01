# TODO: Settings

> Plan: `docs/plans/2026-05-23-settings.md`
> Spec: `docs/specs/2026-05-23-settings.md`
> Tier: T0 (block/logout/delete) · Milestone M2/M3
> Blocked by: Auth, Friend, Notification (deleteFcmToken khi logout)

---

## Phase 1 — Data layer

- [ ] **T1** — `FirebaseBlockRepository` (blockUser via CF + unblockUser client + watchBlockedUsers + isBlocked 2 chiều)

## Checkpoint: Data layer ✓
- [ ] `flutter test test/features/settings/` — 0 failures

---

## Phase 2 — UI (song song Phase 1)

- [ ] **T2** — `SettingsSheet` full layout (Figma 572:4183): header + quick actions + SpaceQuickRow stub + menu sections + static pages (Terms/Privacy)
- [ ] **T4** — `BlockedAccountsPage` + `BlockConfirmDialog` + `UnblockConfirmDialog` + `WidgetConfirmSheet`

---

## Phase 3 — Application layer

- [ ] **T3** — `SettingsController` (`logout` + `copyProfileLink` + `shareProfile` + **`deleteAccount()`** gọi CF)
- [ ] **T6** — `DeleteAccountDialog` (2-step: confirm → re-auth inline) + `LogoutConfirmDialog`

## Checkpoint: App + UI ✓
- [ ] `flutter test test/features/settings/` — 0 failures

---

## Phase 4 — Cloud Functions

- [ ] **T5** — CF `blockUser` (atomic: /blocks create + /friendships delete + /conversations status update)
- [ ] **T7** — CF `deleteAccount` (cascade: Storage → Firestore subcollections → documents → Auth.deleteUser)

---

## Phase 5 — Rules

- [ ] **T8** — Firestore rules tests `/blocks` + CF tests (blockUser idempotent, deleteAccount cascade order)

## Checkpoint: Settings complete ✓
- [ ] CF tests pass
- [ ] `flutter analyze` clean
- [ ] Manual: block từ PhotoActionSheet → blocked list → unblock; logout; Settings sheet từ avatar tap; delete account (staging)
