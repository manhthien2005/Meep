# TODO: Streak / Kỷ niệm

> Plan: `docs/plans/2026-05-23-streak.md`
> Spec: `docs/specs/2026-05-22-streak.md`
> Tier: T1 Stretch · Unlock sau retro 27/5
> Blocked by: Feed (PostRepository, ShareModal)

---

## Phase 1 — Application layer

- [ ] **T1** — `StreakController` (loadMonth + loadAllPostDates cache + calculateStreak timezone-aware UTC+7 + streak/totalMoments global stats)

## Checkpoint: App layer ✓
- [ ] `flutter test test/features/streak/` — timezone edge cases pass (see T4)

---

## Phase 2 — UI Screens

- [ ] **T2** — `StreakScreen` (custom `GridView` 7 columns — KHÔNG `table_calendar`; glassmorphism ô sáng; swipe tháng; StreakStatsPill; empty states)
- [ ] **T3** — `StreakPhotoDetailScreen` (carousel 350×350 + thumbnail strip 50/60px + ShareModal reuse + Xoá chỉ khi isAuthor)

---

## Phase 3 — Tests

- [ ] **T4** — Extend `streak_controller_test.dart`: edge cases calculateStreak (today only=1, gap=1, empty=0, timezone post 23:00 UTC → đúng ngày UTC+7)

## Checkpoint: Streak complete ✓
- [ ] `flutter test test/features/streak/` — 0 failures, timezone tests PASS
- [ ] `flutter analyze` clean
- [ ] Manual: calendar ô sáng/tối; swipe tháng; tap ngày → carousel; swipe cuối tháng → bounce; share ảnh từ calendar

> ℹ️ Streak không có Firestore collection riêng — read-only từ `/posts`. Không cần rules mới.
