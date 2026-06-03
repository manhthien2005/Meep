# TODO: Diary

> Plan: `docs/plans/2026-05-23-diary.md`
> Spec: `docs/specs/2026-05-23-diary.md`
> Tier: T0+ · Milestone M3
> Blocked by: Auth (UserProfile, currentUid); HanDHG (export 11 assets trước T3)

---

## Phase 1 — Data layer

- [x] **T1** — `FirebaseDiaryRepository` (createEntry + watchEntries + **getPublicEntries(authorUid)** + getEntry + updateEntry + deleteEntry + searchEntries in-memory)

## Checkpoint: Data layer ✓
- [x] `flutter test test/features/diary/` — 0 failures

---

## Phase 2 — Application layer

- [ ] **T2** — `DiaryController` (saveEntry create/update mode + upload sequence cover→inline→Firestore + deleteEntry + updatePrivacy)

## Checkpoint: App layer ✓
- [ ] `flutter test test/features/diary/` — 0 failures

---

## Phase 3 — Assets (blocked trên HanDHG export)

- [ ] **T3** — 11 assets export: 5 SVG icons + 5 bg PNG + 1 polaroid PNG → `assets/moods/` + `assets/frames/`; implement `MoodZoneBlock` + `MoodClipper` per mood; add `flutter_svg`

> ⚠️ T3 không thể bắt đầu cho đến khi HanDHG export đủ 11 assets.

---

## Phase 4 — UI Screens

- [ ] **T4** — `DiaryCreateScreen` (mood picker overlay 5 frames + fallback khi gallery trống)
- [ ] **T5** — `DiaryCanvasScreen` (`DiaryCanvasMode` enum + Column block editor + TextStylePicker + PrivacySheet + DiscardDialog; canvas bg hardcode `#f9fcfc`)
- [ ] **T6** — `DiaryListScreen` (grid 2 columns Figma 656:1831 + empty state + FAB)
- [ ] **T7** — `DiarySearchScreen` (in-memory filter case-insensitive + keyword highlight)

---

## Phase 5 — Rules

- [ ] **T8** — Firestore rules `/diary/{id}` + Storage rules `diary/{uid}/` + rules tests

## Checkpoint: Diary complete ✓
- [ ] `flutter test test/features/diary/` — 0 failures
- [ ] `flutter analyze` clean
- [ ] Manual: tạo → mood picker → canvas gõ text → lưu → card list → search → xem → đổi privacy public/private
