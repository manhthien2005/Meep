# Plan: Widget Android Module

> **Phụ thuộc vào:** Home/Camera/Feed — `/users/{uid}/feed` subcollection schema (fan-out, query từ Kotlin WorkManager); Auth — `FirebaseAuth` (token check trong Worker, không lưu vào SharedPreferences)
> **Được phụ thuộc bởi:** Settings (WidgetConfirmSheet trigger → `requestPinAppWidget()`)
> **Spec:** `docs/specs/2026-05-23-widget-android.md`
> **Tier:** T0 — Milestone M3 · Android only

---

## PART 1 — Contract artifacts (ThienPDM merge vào `develop` TRƯỚC khi giao dev)

| File path | Type | Key contents |
|-----------|------|-------------|
| `android/app/src/main/kotlin/.../MeepWidget.kt` | AppWidgetProvider stub | Skeleton class, `onUpdate()` throws unimplemented |
| `android/app/src/main/kotlin/.../WidgetSyncWorker.kt` | Worker stub | `doWork()` returns `Result.success()` immediately |
| `android/app/src/main/res/layout/meep_widget.xml` | RemoteViews layout stub | Placeholder text only |
| `android/app/src/main/res/xml/meep_widget_info.xml` | AppWidget metadata | `minWidth/minHeight = 2×2`, `updatePeriodMillis = 1800000` (30 phút — Android thực ra cap ở 30 phút, không 15 phút) |
| `android/app/src/main/AndroidManifest.xml` | update | Khai báo widget receiver + WorkManager |
| `lib/features/widget/application/widget_data_service.dart` | Flutter service stub | `updateWidgetData({postId, imageUrl, authorName})` → throws unimplemented |
| `lib/core/router/app_router.dart` | update | Handle intent extras `action: OPEN_POST, postId: ...` từ widget tap |

> **Lưu ý Android WorkManager:** Minimum interval = 15 phút nhưng Android thường defer. Widget có thể stale tối đa 30+ phút trên devices tiết kiệm pin (Doze mode). Đây là known limitation, document trong README.

---

## PART 2 — Tasks

---
**T1 · feat(widget): Android widget layout + AppWidget metadata + AndroidManifest**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/widget-android-layout` |
| Blocked by | contracts Part 1 |

Files:
- `android/app/src/main/res/layout/meep_widget.xml` — RemoteViews layout: `RelativeLayout` → `ImageView` (ảnh 2×2) + `TextView` (authorName) + placeholder state
- `android/app/src/main/res/xml/meep_widget_info.xml` — metadata: minWidth 250dp, minHeight 250dp, `previewImage`, `updatePeriodMillis`
- `android/app/src/main/AndroidManifest.xml` — update: `<receiver android:name=".MeepWidget">` với intent filter + `<meta-data android:name="android.appwidget.provider">`

Acceptance criteria:
- [ ] Widget 2×2 cells → khai báo đúng `minWidth/minHeight` trong `appwidget-provider` XML
- [ ] `meep_widget.xml` có 2 states: normal (ImageView + TextView) + placeholder (Meep logo + "Mở Meep để bắt đầu")
- [ ] Widget khai báo trong `AndroidManifest.xml` với đúng `ACTION_APPWIDGET_UPDATE` intent filter
- [ ] WorkManager dependency trong `android/app/build.gradle`: `androidx.work:work-runtime-ktx`
- [ ] Glide dependency trong `build.gradle`: `com.github.bumptech.glide:glide` (hoặc Coil nếu đã có)

Cross-module imports: None

---
**T2 · feat(widget): MeepWidget.kt — AppWidgetProvider + RemoteViews render + placeholder**

| | |
|---|---|
| Assignee | TBD |
| Estimate | M (~8h) |
| Branch | `feat/TBD/widget-android-provider` |
| Blocked by | T1 |

Files:
- `android/app/src/main/kotlin/.../MeepWidget.kt` — full `AppWidgetProvider`
- `android/app/src/main/kotlin/.../WidgetDataStore.kt` — helper đọc `SharedPreferences` (widget_post_id, widget_image_url, widget_author_name)

Acceptance criteria:
- [ ] `onUpdate()`: đọc `SharedPreferences` → nếu có data → render ảnh + authorName; nếu không có → render placeholder
- [ ] `updateWidget(context, postId, imageUrl, authorName)` static method: Glide load `imageUrl` → Bitmap → `RemoteViews.setImageViewBitmap()` → `AppWidgetManager.updateAppWidget()`
- [ ] Placeholder state: Meep logo + "Mở Meep để bắt đầu" text (khi `imageUrl == null` hoặc chưa login)
- [ ] `AppWidgetManager.updateAppWidget(appWidgetIds, views)` — update tất cả instances đồng thời (nhiều widget trên home screen)

Cross-module imports: None (Kotlin native)

---
**T3 · feat(widget): WidgetSyncWorker.kt — auth check + Firestore query + Glide + RemoteViews update**

| | |
|---|---|
| Assignee | TBD |
| Estimate | M (~8h) |
| Branch | `feat/TBD/widget-sync-worker` |
| Blocked by | T2 |

Files:
- `android/app/src/main/kotlin/.../WidgetSyncWorker.kt` — `CoroutineWorker`, `PeriodicWorkRequest`
- Cần register WorkManager trong `Application.onCreate()` hoặc Flutter plugin initialization

Acceptance criteria:
- [ ] **[H7] Auth token KHÔNG lưu SharedPreferences** — Worker gọi `FirebaseAuth.getInstance().currentUser?.getIdToken(false)?.await()` mỗi lần chạy; nếu `currentUser == null` → update placeholder, return `Result.success()`
- [ ] Query Firestore (Kotlin): `/users/{currentUid}/feed` ORDER BY `createdAt DESC` LIMIT 1 → lấy `postId` → fetch `/posts/{postId}` → lấy `imageUrl`
- [ ] Glide download `imageUrl` → cache vào app's files directory → `MeepWidget.updateWidget()` với Bitmap
- [ ] Network fail → giữ Glide cached image cũ (không crash, không clear widget)
- [ ] `WorkManager.enqueueUniquePeriodicWork("widget_sync", KEEP, PeriodicWorkRequest)` — không duplicate worker

Cross-module imports: None (Kotlin native + Firebase SDK cho Android)

---
**T4 · feat(widget): Deep link tap — PendingIntent + MainActivity + MethodChannel + GoRouter**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/widget-deep-link` |
| Blocked by | T2 |

Files:
- `android/app/src/main/kotlin/.../MeepWidget.kt` — update: `setOnClickPendingIntent()` với extras `action=OPEN_POST, postId=...`
- `android/app/src/main/kotlin/.../MainActivity.kt` — update: handle `intent.action == "OPEN_POST"` → call `MethodChannel` với `postId`
- `lib/core/router/app_router.dart` — update: handle method channel call → `GoRouter.go('/feed?highlight=$postId')`

Acceptance criteria:
- [ ] Tap widget → `PendingIntent` với `Intent(context, MainActivity::class.java).putExtra("action", "OPEN_POST").putExtra("postId", postId)`
- [ ] `MainActivity.onNewIntent()` override: xử lý cả foreground + background app resume
- [ ] `MethodChannel("meep/widget")` Flutter side nhận `postId` → `GoRouter.go('/feed?highlight=$postId')`
- [ ] Post đã xóa → navigate Home + toast "Khoảnh khắc này không còn tồn tại"
- [ ] Widget tap khi `postId == null` (placeholder state) → mở app tại Home

Cross-module imports: `FeedController` từ **home-camera-feed** (scroll đến postId)

---
**T5 · feat(widget): WidgetDataService (Flutter) — SharedPreferences write + trigger update**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/widget-data-service` |
| Blocked by | T4 |

Files:
- `lib/features/widget/application/widget_data_service.dart` — full impl
- Gọi `updateWidgetData()` từ `FeedController` sau mỗi lần fetch feed mới

Acceptance criteria:
- [ ] `updateWidgetData({latestPostId, latestImageUrl, authorName})`: lưu 3 keys vào `SharedPreferences` + gọi `MethodChannel("meep/widget").invokeMethod("updateWidget")`
- [ ] `MethodChannel` trigger Kotlin side → `MeepWidget.onUpdate()` → re-render
- [ ] User logout → `WidgetDataService.clearWidgetData()` → SharedPreferences xóa tất cả widget keys → widget hiện placeholder
- [ ] `shared_preferences` package đã có (cũng dùng bởi Profile notification toggle — không add 2 lần)

Cross-module imports: `FeedController` từ **home-camera-feed** (gọi `updateWidgetData` sau fetch)

---
**T6 · test(widget): Kotlin unit tests + manual smoke test checklist**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `test/TBD/widget-tests` |
| Blocked by | T3 |

Files:
- `android/app/src/test/kotlin/.../WidgetSyncWorkerTest.kt` — JUnit + Robolectric (hoặc mock)
- `docs/plans/widget-smoke-tests.md` — manual test checklist

Acceptance criteria:
- [ ] `WidgetSyncWorker` không có token → return `Result.success()`, không crash, không throw
- [ ] `WidgetSyncWorker` có token → mock Firestore → `MeepWidget.updateWidget()` được gọi với đúng data
- [ ] Manual smoke: widget thêm được vào home screen từ Android widget picker ✓
- [ ] Manual smoke: widget hiện ảnh mới nhất sau khi đăng ảnh từ app ✓
- [ ] Manual smoke: tap widget → app mở đúng post ✓
- [ ] Manual smoke: widget hiện placeholder khi logout ✓

Cross-module imports: None

---

## PART 3 — Dependency graph

```
contracts Part 1 → T1 → T2 → T3 → T6
                      ↘
                   T2 → T4 (parallel T3) → T5
```

T3 (Worker) và T4 (Deep link) có thể chạy song song sau T2 (AppWidgetProvider) xong.

---

## PART 4 — Open questions

| # | Câu hỏi | Status |
|---|---|---|
| OQ1 | `workmanager` Flutter plugin hay native WorkManager? | ✅ **Native WorkManager** (Kotlin) — tránh thêm plugin, logic đơn giản |
| OQ2 | Glide hay Coil? | Nếu project đã có Coil trong Android deps → dùng Coil để tránh duplicate. Kiểm tra `build.gradle` trước khi add Glide |
