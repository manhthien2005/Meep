# scripts/modules/widget.ps1
# Module: Widget Android | Owner: ThienPDM | M3

function Create-WidgetModule {
    $parentBody = @'
> **Tier:** T0 | **Milestone:** M3 | **Assignee:** ThienPDM | **Android only**
> **Spec:** `docs/specs/2026-05-23-widget-android.md`
> **Plan:** `docs/plans/2026-05-23-widget-android.md`
> **Todo:** `tasks/todo-widget-android.md`
> **Phụ thuộc vào:** Feed (/users/{uid}/feed subcollection schema), Auth (FirebaseAuth token)
> **Được phụ thuộc bởi:** Settings (WidgetConfirmSheet trigger → requestPinAppWidget)

## Mục tiêu
2×2 home-screen widget hiển thị ảnh mới nhất từ feed, tap để mở bài viết đó trong app.

## Architecture
- **Android native (Kotlin):** `MeepWidget.kt` (AppWidgetProvider) + `WidgetSyncWorker.kt` (CoroutineWorker)
- **Flutter:** `WidgetDataService` (SharedPreferences write + MethodChannel trigger)
- **Luồng:** WorkManager → `WidgetSyncWorker` → query Firestore → Glide download → `MeepWidget.updateWidget()`
- **Tap widget:** PendingIntent → `MainActivity.onNewIntent` → `MethodChannel("meep/widget")` → GoRouter `/feed?highlight={postId}`

## ⚠️ Known limitation
Android WorkManager minimum interval = 15 phút, nhưng thực tế defer. Widget có thể stale tối đa 30+ phút trên Doze mode devices.

## Contract artifacts (ThienPDM đã merge qua LX11)
- Kotlin stubs: `MeepWidget.kt`, `WidgetSyncWorker.kt`, `meep_widget.xml`
- `lib/features/widget/application/widget_data_service.dart` — stub
- `AndroidManifest.xml` update, router intent handler

## ⚠️ Auth token policy ([H7])
Worker **KHÔNG** lưu auth token vào SharedPreferences. Gọi `FirebaseAuth.getInstance().currentUser?.getIdToken(false)?.await()` mỗi lần chạy.
'@

    $subs = @(
        @{
            title = "[Widget] T1+2+3 — Android native (layout + MeepWidget + WidgetSyncWorker)"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-widget-android.md` — Task T1, T2, T3
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/widget-android-native`
> **Bị block bởi:** LX11 contracts đã merge; Feed /users/{uid}/feed schema done

## Files cần tạo
- `android/app/src/main/res/layout/meep_widget.xml` — RemoteViews: 2 states (normal + placeholder)
- `android/app/src/main/res/xml/meep_widget_info.xml` — minWidth 250dp, minHeight 250dp, `updatePeriodMillis = 1800000`
- `android/app/src/main/AndroidManifest.xml` — **update:** `<receiver android:name=".MeepWidget">` + intent filter
- `android/app/src/main/kotlin/.../MeepWidget.kt` — full `AppWidgetProvider` + `WidgetDataStore.kt`
- `android/app/src/main/kotlin/.../WidgetSyncWorker.kt` — `CoroutineWorker`
- `android/app/build.gradle` — `androidx.work:work-runtime-ktx` + Glide

## Acceptance criteria — MeepWidget
- [ ] `onUpdate()`: đọc SharedPreferences → normal state (ảnh + authorName) hoặc placeholder ("Mở Meep để bắt đầu")
- [ ] `updateWidget()` static: Glide load `imageUrl` → Bitmap → `RemoteViews.setImageViewBitmap()` → `AppWidgetManager.updateAppWidget(appWidgetIds, views)`

## Acceptance criteria — WidgetSyncWorker
- [ ] **[H7]** Auth token **KHÔNG** lưu SharedPreferences — `currentUser?.getIdToken(false)?.await()` mỗi lần
- [ ] `currentUser == null` → update placeholder, return `Result.success()` (không crash)
- [ ] Query `/users/{currentUid}/feed` ORDER BY `createdAt DESC` LIMIT 1 → fetch `/posts/{postId}` → `imageUrl`
- [ ] Glide download → cache → `MeepWidget.updateWidget()` với Bitmap
- [ ] Network fail → giữ Glide cached image cũ (không clear widget)
- [ ] `WorkManager.enqueueUniquePeriodicWork("widget_sync", KEEP, ...)` — không duplicate worker
- [ ] Kotlin build clean

## Definition of Done
- [ ] Kotlin build clean
- [ ] Manual smoke: add widget từ picker → placeholder hiện
- [ ] PR merged
'@
        },
        @{
            title = "[Widget] T4+5 — Deep link + WidgetDataService Flutter"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-widget-android.md` — Task T4, T5
> **Estimate:** S (~4h) | **Branch:** `feat/<DevName>/widget-deeplink-service`
> **Bị block bởi:** {sub0} — T1+2+3 phải done (MeepWidget.kt phải có)

## Files cần sửa/tạo
- `android/app/src/main/kotlin/.../MeepWidget.kt` — **update:** `setOnClickPendingIntent()` với extras `action=OPEN_POST, postId=...`
- `android/app/src/main/kotlin/.../MainActivity.kt` — **update:** `onNewIntent()` → call `MethodChannel("meep/widget")`
- `lib/core/router/app_router.dart` — **update:** nhận MethodChannel call → `GoRouter.go('/feed?highlight=$postId')`
- `lib/features/widget/application/widget_data_service.dart` — full impl

## Acceptance criteria — Deep link
- [ ] Tap widget → `PendingIntent` với `Intent.putExtra("action", "OPEN_POST").putExtra("postId", postId)`
- [ ] `MainActivity.onNewIntent()` override: xử lý foreground + background
- [ ] `MethodChannel("meep/widget")` Flutter nhận `postId` → `GoRouter.go('/feed?highlight=$postId')`
- [ ] Post đã xóa → navigate Home + toast "Khoảnh khắc này không còn tồn tại"
- [ ] Tap placeholder → mở app tại Home

## Acceptance criteria — WidgetDataService
- [ ] `updateWidgetData({latestPostId, latestImageUrl, authorName})` → 3 keys vào SharedPreferences + MethodChannel `invokeMethod("updateWidget")`
- [ ] `clearWidgetData()` khi logout → xóa tất cả widget keys → widget hiện placeholder
- [ ] `shared_preferences` package đã có (1 lần, dùng bởi Profile notification toggle)
- [ ] Gọi `updateWidgetData()` từ `FeedController` sau mỗi lần fetch feed mới

## Cross-module imports
- `FeedController` từ **home-camera-feed** (gọi updateWidgetData)

## Definition of Done
- [ ] Manual: post ảnh → widget update ≤15min; tap → đúng post; logout → placeholder
- [ ] PR merged
'@
        },
        @{
            title = "[Widget] T6 — Kotlin unit tests + smoke test checklist"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-widget-android.md` — Task T6
> **Estimate:** S (~4h) | **Branch:** `test/<DevName>/widget-tests`
> **Bị block bởi:** {sub0} — T1+2+3 done

## Files cần tạo
- `android/app/src/test/kotlin/.../WidgetSyncWorkerTest.kt` — JUnit

## Acceptance criteria — Kotlin tests
- [ ] `WidgetSyncWorker` không có token → return `Result.success()`, không crash, không throw
- [ ] `WidgetSyncWorker` có token → mock Firestore → `MeepWidget.updateWidget()` được gọi với đúng data

## Manual smoke test checklist
- [ ] Widget thêm được vào home screen từ Android widget picker
- [ ] Widget hiện ảnh mới nhất sau khi đăng ảnh từ app (≤15 phút)
- [ ] Tap widget → app mở đúng post
- [ ] Logout → widget hiện placeholder "Mở Meep để bắt đầu"

## Definition of Done
- [ ] Kotlin tests PASS
- [ ] Smoke test checklist hoàn thành trên device thực
- [ ] PR merged
'@
        }
    )

    New-Module "📱 [Widget Android]" $parentBody $ThienPDM 3 $subs
}
