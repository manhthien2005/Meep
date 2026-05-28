# Plan: Widget Android Module

> **Phụ thuộc vào:** Home/Camera/Feed — `/users/{uid}/feed` subcollection schema (fan-out, query từ Kotlin WorkManager); Auth — `FirebaseAuth` (token check trong Worker, không lưu vào SharedPreferences)
> **Được phụ thuộc bởi:** Settings (WidgetConfirmSheet trigger → `requestPinAppWidget()`)
> **Spec:** `docs/specs/2026-05-23-widget-android.md`
> **Tier:** T0 — Milestone M3 · Android only

---

## PART 1 — Contract artifacts (ThienPDM merge vào `develop` TRƯỚC khi giao dev)

| File path | Type | Key contents |
|-----------|------|-------------|
| `android/app/src/main/kotlin/.../MeepWidget.kt` | AppWidgetProvider stub | Skeleton class, `onUpdate()` stub |
| `android/app/src/main/kotlin/.../WidgetDataStore.kt` | SharedPreferences helper stub | Đọc 6 keys: `widget_post_id`, `widget_image_url`, `widget_author_avatar_url`, `widget_caption`, `widget_caption_type`, `widget_last_viewed_at` |
| `android/app/src/main/kotlin/.../WidgetSyncWorker.kt` | CoroutineWorker stub | `doWork()` returns `Result.success()` immediately |
| `android/app/src/main/res/layout/meep_widget.xml` | RemoteViews layout stub | Placeholder text only — impl cần thêm ImageView (photo), ImageView (avatar), TextView (caption pill), TextView (count badge) |
| `android/app/src/main/res/xml/meep_widget_info.xml` | AppWidget metadata | `minWidth/minHeight = 250dp`, `updatePeriodMillis = 900000` (15 phút schedule) |
| `android/app/src/main/AndroidManifest.xml` | update | Khai báo widget receiver |
| `lib/features/widget/application/widget_data_service.dart` | Flutter abstract stub | Interface: `updateWidgetData({postId, imageUrl, authorAvatarUrl, caption?, captionType?})`, `recordLastViewedAt()`, `clearData()` |
| `lib/core/router/app_router.dart` | update | Handle intent extras `action: OPEN_POST, postId: ...` từ widget tap |

> **Lưu ý WorkManager:** Schedule 15 phút nhưng Android có thể defer do Doze mode. Known limitation, document trong README.
> **Lưu ý Firebase count():** Yêu cầu `firebase-firestore-ktx ≥ 24.4.0`. Server-side only — không hoạt động offline.

---

## PART 2 — Tasks

---
**T1 · feat(widget): Android widget layout + AppWidget metadata + build.gradle deps**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/widget-android-layout` |
| Blocked by | contracts Part 1 |

Files:
- `android/app/src/main/res/layout/meep_widget.xml` — RemoteViews layout đầy đủ:
  - `ImageView#widget_photo` — fullscreen, centerCrop
  - `ImageView#widget_avatar` — 40×40dp, tròn (CircleDrawable background), bottom-left
  - `TextView#widget_caption` — pill bg `#39404166`, cornerRadius 30dp, Nunito SemiBold 14sp, bottom-left cạnh avatar
  - `TextView#widget_count` — circle bg `#00C9E3`, text trắng Bold 12sp, top-right
  - `Group#widget_placeholder` — visible khi không có data: Meep logo + "Mở Meep để bắt đầu"
- `android/app/src/main/res/xml/meep_widget_info.xml` — metadata: minWidth 250dp, minHeight 250dp, `updatePeriodMillis = 900000`
- `android/app/build.gradle.kts` — thêm deps:
  - `com.github.bumptech.glide:glide`
  - `com.google.firebase:firebase-firestore-ktx:24.4.0` (min version cho `count()`)
  - `com.google.firebase:firebase-auth-ktx`

Acceptance criteria:
- [ ] Widget 2×2 → khai báo đúng `minWidth/minHeight = 250dp` trong `appwidget-provider` XML
- [ ] `meep_widget.xml` có đủ 5 views: `widget_photo`, `widget_avatar`, `widget_caption`, `widget_count`, placeholder group
- [ ] Placeholder group hiện khi normal group bị GONE
- [ ] Glide, firebase-firestore-ktx (≥24.4.0), firebase-auth-ktx đã add vào `build.gradle.kts`
- [ ] Kotlin build clean

Cross-module imports: None

---
**T2 · feat(widget): MeepWidget.kt + WidgetDataStore.kt — AppWidgetProvider + RemoteViews render**

| | |
|---|---|
| Assignee | TBD |
| Estimate | M (~6h) |
| Branch | `feat/TBD/widget-android-provider` |
| Blocked by | T1 |

Files:
- `android/app/src/main/kotlin/.../MeepWidget.kt` — full `AppWidgetProvider`
- `android/app/src/main/kotlin/.../WidgetDataStore.kt` — helper đọc SharedPreferences (6 keys)

Acceptance criteria:
- [ ] `WidgetDataStore` đọc đúng 6 keys: `widget_post_id`, `widget_image_url`, `widget_author_avatar_url`, `widget_caption`, `widget_caption_type`, `widget_last_viewed_at`
- [ ] `onUpdate()`: đọc `WidgetDataStore` → nếu có data → render normal state; nếu không có → render placeholder
- [ ] `updateWidget(context, data, unreadCount)` static method:
  - Glide load `imageUrl` → fullscreen Bitmap → `setImageViewBitmap(widget_photo)`
  - Glide load `authorAvatarUrl` + `CircleCrop` → circular Bitmap → `setImageViewBitmap(widget_avatar)`; nếu `authorAvatarUrl == null` → hiện default avatar drawable, không crash
  - `setTextViewText(widget_caption, caption)` + `setViewVisibility(VISIBLE/GONE)` theo `caption == null`
  - `setTextViewText(widget_count, formatCount(unreadCount))` + `setViewVisibility(VISIBLE/GONE)` theo `unreadCount == 0`
  - `formatCount`: 1–9 → số thực, ≥10 → "9+"
- [ ] `AppWidgetManager.updateAppWidget(appWidgetIds, views)` — update tất cả instances

Cross-module imports: None (Kotlin native)

---
**T3 · feat(widget): WidgetSyncWorker.kt — auth + Firestore query + unread count + Glide + RemoteViews**

| | |
|---|---|
| Assignee | TBD |
| Estimate | L (~10h) |
| Branch | `feat/TBD/widget-sync-worker` |
| Blocked by | T2 |

Files:
- `android/app/src/main/kotlin/.../WidgetSyncWorker.kt` — `CoroutineWorker`, `PeriodicWorkRequest`

Acceptance criteria:
- [ ] **[H7]** Auth token KHÔNG lưu SharedPreferences — `FirebaseAuth.getInstance().currentUser?.getIdToken(false)?.await()` mỗi lần; `currentUser == null` → update placeholder, `Result.success()`
- [ ] Query `/users/{uid}/feed` ORDER BY `createdAt DESC` LIMIT 1 → fetch `/posts/{postId}` → lấy `imageUrl`, `authorAvatarUrl`, `caption`, `captionType`
- [ ] Đọc `widget_last_viewed_at` từ SharedPreferences → query `/users/{uid}/feed WHERE createdAt > lastViewedAt` dùng `count()` → `unreadCount`; nếu query fail (offline) → `unreadCount = 0`, không crash
- [ ] Glide download `imageUrl` + `authorAvatarUrl` (CircleCrop) → cache internal storage
- [ ] `MeepWidget.updateWidget(context, data, unreadCount)` với đúng data
- [ ] Network fail → giữ Glide cached image cũ, không crash, không clear widget
- [ ] `WorkManager.enqueueUniquePeriodicWork("widget_sync", KEEP, PeriodicWorkRequest(15 phút))` — không duplicate worker

Cross-module imports: None (Kotlin native + Firebase SDK)

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
- `android/app/src/main/kotlin/.../MainActivity.kt` — update: `onNewIntent()` → call `MethodChannel("meep/widget")` với `postId`
- `lib/core/router/app_router.dart` — update: nhận MethodChannel call → `GoRouter.go('/feed?highlight=$postId')`

Acceptance criteria:
- [ ] Tap widget (normal state) → `PendingIntent` với `Intent.putExtra("action", "OPEN_POST").putExtra("postId", postId)`
- [ ] Tap widget (placeholder state, `postId == null`) → mở app tại Home
- [ ] `MainActivity.onNewIntent()` xử lý cả foreground + background resume
- [ ] Flutter `MethodChannel("meep/widget")` nhận `postId` → `GoRouter.go('/feed?highlight=$postId')`
- [ ] Post đã xóa → navigate Home + toast "Khoảnh khắc này không còn tồn tại"

Cross-module imports: `FeedController` từ **home-camera-feed** (scroll đến postId)

---
**T5 · feat(widget): WidgetDataService (Flutter) — SharedPreferences write + lifecycle hook**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/widget-data-service` |
| Blocked by | T4 |

Files:
- `lib/features/widget/application/widget_data_service.dart` — full impl của abstract interface
- `lib/core/router/app_router.dart` hoặc `main.dart` — wire `recordLastViewedAt()` vào `AppLifecycleState.resumed`

Acceptance criteria:
- [ ] `updateWidgetData({postId, imageUrl, authorAvatarUrl, caption?, captionType?})`: lưu đúng 5 keys vào SharedPreferences + gọi `MethodChannel("meep/widget").invokeMethod("updateWidget")`
- [ ] `recordLastViewedAt()`: ghi `widget_last_viewed_at = DateTime.now().millisecondsSinceEpoch` vào SharedPreferences — được gọi mỗi khi `AppLifecycleState.resumed`
- [ ] `clearData()`: xóa tất cả `widget_*` keys → widget hiện placeholder
- [ ] `updateWidgetData()` được gọi từ `FeedController` (KhoaLND) sau mỗi lần fetch feed mới
- [ ] `clearData()` được gọi khi user logout

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
- `android/app/src/test/kotlin/.../WidgetSyncWorkerTest.kt` — JUnit + mock

Acceptance criteria:
- [ ] `WidgetSyncWorker` không có token → `Result.success()`, không crash, không throw
- [ ] `WidgetSyncWorker` có token → mock Firestore → `MeepWidget.updateWidget()` được gọi với đúng data
- [ ] `WidgetSyncWorker` có token, `authorAvatarUrl == null` → Glide load null → không crash, hiện default avatar
- [ ] `WidgetSyncWorker` có token, `count()` query fail → `unreadCount = 0`, widget vẫn update bình thường, không crash
- [ ] Manual smoke: widget thêm được vào home screen từ Android widget picker ✓
- [ ] Manual smoke: widget hiện ảnh mới nhất + avatar + caption sau khi đăng ảnh từ app ✓
- [ ] Manual smoke: badge hiện đúng count, ẩn khi count = 0 ✓
- [ ] Manual smoke: tap widget → app mở đúng post ✓
- [ ] Manual smoke: logout → widget hiện placeholder ✓

Cross-module imports: None

---

## PART 3 — Dependency graph

```
contracts Part 1 → T1 → T2 → T3 → T6
                           ↘
                        T2 → T4 (parallel với T3) → T5
```

T3 (Worker) và T4 (Deep link) có thể chạy song song sau T2 (MeepWidget) xong.

---

## PART 4 — Open questions

| # | Câu hỏi | Status |
|---|---|---|
| OQ1 | `workmanager` Flutter plugin hay native WorkManager? | ✅ **Native WorkManager** (Kotlin) |
| OQ2 | Glide hay Coil? | ✅ **Glide** — project không có Coil trong Android deps |
| OQ3 | Widget content hiện gì? | ✅ **Resolved 2026-05-27:** ảnh fullscreen + avatar (bottom-left) + caption pill + unread count badge (top-right, Turquoise/600) |
| OQ4 | `lastViewedAt` reset khi nào? | ✅ **Resolved 2026-05-27:** mỗi lần `AppLifecycleState.resumed` — Option A |
| OQ5 | Unread count badge format? | ✅ **Resolved 2026-05-27:** 1–9 số thực, ≥10 → "9+". Ẩn khi = 0 |
