# TODO: Streak / Kỷ niệm

> Plan: `docs/plans/2026-05-23-streak.md`
> Spec: `docs/specs/2026-05-22-streak.md` (v2, 2026-06-04)
> Tier: T1 Stretch · M3 ship
> Owner: HanDHG
> Branch: `feature/HanDHG/streak-module`

---

## Part 1 — Contract update (leader)

- [ ] **L1** — leader thêm `StreakRepository` abstract, update `StreakState` schema, delete `streak_photo_detail_screen.dart` stub, bỏ route `/streak/photo/:postId`

## Checkpoint: Contracts ready ✓
- [ ] `flutter analyze --no-pub` clean trên `develop`

---

## Phase 1 — Data + Application

- [ ] **ST1** — `StreakRepository` abstract + `FirebaseStreakRepository` (watchUserMonth + getUserAllDates, filter `spaceId == null`)
- [ ] **ST2** — `StreakController` + `StreakState` + pure `calculateStreak(dates, now)` (timezone-aware UTC+7)

## Checkpoint: Data + App layer ✓
- [ ] `flutter test test/features/streak/data/` — 0 failures
- [ ] `flutter test test/features/streak/application/` — 0 failures
- [ ] Coverage controller ≥ 80%, pure fn ≥ 95%

---

## Phase 2 — Shared widgets relocate (leader-gated)

- [ ] **ST3** — Move `PhotoDetailScreen` + `SharePhotoSheet` từ `features/profile/` → `lib/shared/widgets/`, parameterize PhotoDetailScreen, wire SharePhotoSheet logic (Share/Save/Delete), update Profile imports

## Checkpoint: Shared widgets ready ✓
- [ ] `flutter test test/features/profile/` — 0 failures (Profile không regress)
- [ ] `flutter test test/shared/widgets/` — 0 failures
- [ ] Manual: Profile flow trên emulator — Photo detail + share sheet hoạt động đúng

---

## Phase 3 — Streak UI

- [ ] **ST4** — `StreakScreen` + `StreakCalendar` (7 cols, không weekday header, thumbnail cell có post) + `CalendarDayCell` (3 states) + `StreakStatsPill` + `EmptyStateOverlay` (subtitle + 2 arrow vectors)

## Checkpoint: UI complete ✓
- [ ] `flutter test test/features/streak/presentation/` — 0 failures
- [ ] `flutter analyze` clean
- [ ] Manual emulator: calendar render thumbnail ngày có post, dot ngày không có, outline ngày hôm nay, swipe tháng, tap ngày → photo detail

---

## Phase 4 — Wiring + E2E

- [ ] **ST5** — Route `/streak` + Taskbar tab calendar-days wire + integration test E2E happy path

## Checkpoint: Module ship-ready ✓
- [ ] `flutter test integration_test/streak_flow_test.dart` — pass
- [ ] `flutter analyze --no-pub` clean
- [ ] `dart format --set-exit-if-changed --output none lib test` clean
- [ ] Manual smoke test full flow: login → Taskbar → Streak → swipe → tap → share → save → delete → ô tắt sáng
- [ ] PR merged vào `develop` qua leader review

---

## Open questions — defer post-MVP (KHÔNG block)

- [ ] **OQ4** — `CaptionType.streak` integration vào Feed CaptionService → giữ mock M3, integration post-MVP
- [ ] **OQ5** — Streak milestone notification (7/30/100 ngày) → defer post-MVP
- [ ] **OQ7** — `getUserAllDates` cost khi user >1000 posts → monitor, mitigation post-MVP (denormalize `currentStreakDays` vào `/users/{uid}`)

---

> ℹ️ Streak KHÔNG có Firestore collection riêng — read-only từ `/posts`. Không cần rules/CF mới.
