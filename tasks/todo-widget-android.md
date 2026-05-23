# TODO: Widget Android

> Plan: `docs/plans/2026-05-23-widget-android.md`
> Spec: `docs/specs/2026-05-23-widget-android.md`
> Tier: T0 · Milestone M3 · Android only
> Blocked by: Feed (/users/{uid}/feed subcollection schema), Auth (FirebaseAuth token)

---

## Phase 1 — Android native

- [ ] **T1** — `meep_widget.xml` (RemoteViews layout: normal + placeholder states) + `meep_widget_info.xml` (2×2 metadata) + `AndroidManifest.xml` khai báo
- [ ] **T2** — `MeepWidget.kt` (`AppWidgetProvider`: đọc SharedPreferences → render RemoteViews; placeholder khi không có data)
- [ ] **T3** — `WidgetSyncWorker.kt` (`CoroutineWorker`: [H7] auth token gọi trực tiếp không lưu SharedPreferences; query feed subcollection; Glide download; update RemoteViews)

## Checkpoint: Android native ✓
- [ ] Kotlin build clean
- [ ] `WidgetSyncWorker` không có token → Result.success() không crash

---

## Phase 2 — Integration

- [ ] **T4** — Deep link tap (`PendingIntent` extras → `MainActivity.onNewIntent` → `MethodChannel("meep/widget")` → GoRouter `/feed?highlight={postId}`)
- [ ] **T5** — `WidgetDataService` Flutter (SharedPreferences write 3 keys + MethodChannel trigger + `clearWidgetData()` khi logout)

## Checkpoint: Integration ✓
- [ ] Flutter build clean, MethodChannel không crash

---

## Phase 3 — Tests

- [ ] **T6** — Kotlin unit tests (`WidgetSyncWorkerTest`) + manual smoke test checklist

## Checkpoint: Widget complete ✓
- [ ] Manual smoke (device required):
  - [ ] Thêm widget vào home screen từ Android widget picker
  - [ ] Widget hiện ảnh mới nhất sau khi đăng ảnh từ app
  - [ ] Tap widget → app mở đúng post
  - [ ] Logout → widget hiện placeholder "Mở Meep để bắt đầu"
  - [ ] Widget tự update sau ≤15 phút
