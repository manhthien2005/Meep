# Spec: Widget Android Module

**Date:** 2026-05-23
**Status:** Locked
**Owner:** ThienPDM (leader assign trước khi giao)
**Epic:** [T0] Widget Android — Ảnh mới nhất + Tap deep link · Milestone M3
**Platform:** Android only (iOS WidgetKit deferred per ADR-0002)

---

## Goal

Hiển thị ảnh mới nhất từ bạn bè trên home screen / lock screen Android dưới dạng AppWidget 2×2. Tap vào ảnh → mở Meep app tại post đó (deep link). Widget tự cập nhật khi có post mới.

---

## User stories

- Là user, tôi muốn thêm Meep Widget vào home screen Android để thấy ảnh mới nhất của bạn bè.
- Là user, tôi muốn tap vào ảnh trong widget để mở app xem đầy đủ.
- Là user, tôi muốn widget tự cập nhật khi bạn bè đăng ảnh mới (không cần mở app).

---

## Scope

### In-scope (M3)

1. **AppWidget 2×2** — hiện 1 ảnh mới nhất từ feed (bạn bè + bản thân)
2. **Tap deep link** — tap widget → mở Meep → navigate đến post đó
3. **Auto-update** — WorkManager job chạy background, fetch ảnh mới, update widget
4. **Widget setup flow** — trigger từ Settings → "Thêm tiện ích" → Android widget picker
5. **Placeholder state** — khi chưa có ảnh hoặc chưa login: hiện logo Meep + text "Mở Meep để bắt đầu"

### Out-of-scope

- Widget 4×2 hoặc size khác — post-MVP
- Multiple photos / carousel widget — post-MVP
- iOS WidgetKit — defer per ADR-0002
- Widget hiện avatar friends (Settings OQ4 resolved: hiện ảnh, không phải avatars)
- Glance API (Android 12+) — post-MVP

---

## Màn hình & Figma IDs

| Màn hình | Figma ID | Ghi chú |
|---|---|---|
| Widget confirm sheet (trong Settings) | `662:3341` | Bottom sheet "Thêm vào màn hình chờ?" |
| Widget confirm variant | `678:2321` | Variant state |
| Sau khi thêm widget | `693:2617` | Screenshot lock screen instructional UI |
| Widget on home screen | _(native Android — không có Figma)_ | Render bằng RemoteViews |

---

## Luồng đầy đủ

### Setup widget

```
Settings sheet → tap "Thêm tiện ích"
    → WidgetConfirmSheet (662:3341):
        Preview: [Meep Widget 2×2 — ảnh mới nhất]
        [Thêm] → requestPinAppWidget() (Android API)
             → Android system widget picker mở
             → User đặt widget lên home screen
             → Không có callback thành công → hiện instructional screen 693:2617
        [Huỷ]  → đóng sheet
```

### Widget hiển thị ảnh

```
WorkManager PeriodicWorkRequest (interval: 15 phút)
    → WidgetSyncWorker.doWork():
        (1) [H7-FIX] Lấy token: FirebaseAuth.getInstance().currentUser?.getIdToken(false)?.await()
            Nếu currentUser == null → update widget với placeholder, return Result.success()
        (2) Lấy currentUid từ FirebaseAuth.currentUser.uid
        (3) Query Firestore (dùng fan-out subcollection, không dùng whereIn):
            /users/{currentUid}/feed ORDER BY createdAt DESC LIMIT 1
            Sau đó fetch /posts/{feedDoc.postId} để lấy imageUrl
        (4) Download ảnh → cache vào app's files directory (Glide)
        (5) AppWidgetManager.updateAppWidget() với RemoteViews mới
```

### Tap widget

```
User tap ảnh trong widget
    → PendingIntent → MainActivity với extras:
        action: "OPEN_POST"
        postId: "{postId}"
    → App mở (hoặc resume từ background)
    → Flutter side nhận intent từ MethodChannel
    → GoRouter.go('/feed?highlight={postId}')
```

---

## Technical approach

### Stack

- **Widget UI:** Android `AppWidgetProvider` (Kotlin) + `RemoteViews` — native Android, nằm trong `apps/widget/` hoặc `apps/mobile/android/`
- **Background sync:** `WorkManager` (AndroidX) — `PeriodicWorkRequest` 15 phút
- **Data sharing Flutter ↔ Widget:** `SharedPreferences` (Android native) — Flutter plugin lưu **latest post display data** (`postId`, `imageUrl`, `authorName`) vào `shared_prefs` mà Kotlin đọc được. **KHÔNG lưu auth token** (xem H7 bên dưới).
- **[H7-FIX] Auth token trong Worker:** Firebase ID token hết hạn sau 1h — không thể lưu vào SharedPreferences rồi đọc lại. Worker phải gọi `FirebaseAuth.getInstance().currentUser?.getIdToken(false)?.await()` để lấy token mới mỗi lần chạy (Firebase SDK tự refresh internally). Nếu `currentUser == null` → skip query, hiện placeholder.
- **Image caching:** Glide (Kotlin side) — download + cache ảnh vào internal storage
- **Deep link:** `MethodChannel` Flutter ↔ Android để truyền `postId` khi tap widget

### File structure

```
apps/mobile/android/app/src/main/
├─ kotlin/.../
│   ├─ MainActivity.kt          ← xử lý widget tap intent
│   ├─ MeepWidget.kt            ← AppWidgetProvider
│   └─ WidgetSyncWorker.kt      ← WorkManager worker
└─ res/
    ├─ layout/meep_widget.xml   ← RemoteViews layout
    └─ xml/meep_widget_info.xml ← AppWidget metadata (size, update interval)
```

### Flutter side

```dart
// Lưu data cho widget sau mỗi lần fetch feed
class WidgetDataService {
  static Future<void> updateWidgetData({
    required String latestPostId,
    required String latestImageUrl,
    required String authorName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widget_post_id', latestPostId);
    await prefs.setString('widget_image_url', latestImageUrl);
    await prefs.setString('widget_author_name', authorName);
    // Trigger widget update via MethodChannel
    await _channel.invokeMethod('updateWidget');
  }
}
```

---

## Dependencies

### Flutter (pubspec.yaml)

| Package | Lý do | Có sẵn? |
|---|---|---|
| `shared_preferences` | Share data Flutter ↔ Android widget | ❌ cần thêm (cũng dùng Profile notification toggle) |
| `workmanager` | Trigger WorkManager từ Flutter (optional) | ❌ cần thêm hoặc dùng native only |

### Android (build.gradle)

| Dependency | Lý do |
|---|---|
| `androidx.work:work-runtime-ktx` | WorkManager background sync |
| `com.github.bumptech.glide:glide` | Image download + cache |
| `com.google.firebase:firebase-firestore-ktx` | Query latest post từ Kotlin |
| `com.google.firebase:firebase-auth-ktx` | Đọc auth token trong worker |

---

## Security

- Widget chỉ đọc post data của user đang login — dùng Firebase Auth SDK trực tiếp trong WorkManager worker
- **[H7] Auth token KHÔNG lưu SharedPreferences** — Worker gọi `FirebaseAuth.getInstance().currentUser?.getIdToken(false)?.await()` mỗi lần chạy. Firebase SDK tự refresh token nếu cần.
- SharedPreferences chỉ lưu display data (postId, imageUrl, authorName) — không lưu credentials
- Nếu `currentUser == null` (chưa login / logout) → worker skip update, widget hiện placeholder
- Không lưu password hay sensitive credentials trong SharedPreferences

---

## Testing strategy

### Unit tests (Kotlin)

| Test | Target |
|---|---|
| `WidgetSyncWorker` không có token → return `Result.success()` (skip gracefully) | `WidgetSyncWorker` |
| `WidgetSyncWorker` có token → fetch post + update widget | `WidgetSyncWorker` (mock Firestore) |
| `MeepWidget.onUpdate()` với valid RemoteViews → không crash | `MeepWidget` |

### Manual smoke tests (device required)

- [ ] Widget thêm được vào home screen từ Android widget picker
- [ ] Widget hiện ảnh mới nhất sau khi đăng ảnh từ app
- [ ] Tap widget → app mở đúng post
- [ ] Widget hiện placeholder khi logout
- [ ] Widget tự update sau ≤ 15 phút khi bạn đăng ảnh mới

---

## Contract bàn giao

| Artifact | File | Status |
|---|---|---|
| `MeepWidget.kt` (AppWidgetProvider) | `android/app/src/main/kotlin/.../MeepWidget.kt` | ❌ |
| `WidgetSyncWorker.kt` (WorkManager) | `android/app/src/main/kotlin/.../WidgetSyncWorker.kt` | ❌ |
| `meep_widget.xml` (RemoteViews layout) | `android/app/src/main/res/layout/meep_widget.xml` | ❌ |
| `meep_widget_info.xml` (AppWidget metadata) | `android/app/src/main/res/xml/meep_widget_info.xml` | ❌ |
| `AndroidManifest.xml` — khai báo widget + WorkManager | `android/app/src/main/AndroidManifest.xml` | ❌ update |
| `WidgetDataService` (Flutter) | `lib/features/widget/application/widget_data_service.dart` | ❌ |
| `MethodChannel` handler trong `MainActivity.kt` | `android/app/src/main/kotlin/.../MainActivity.kt` | ❌ update |
| TODO markers trên mọi stub | — | ⏳ |

---

## Open questions

| # | Câu hỏi | Status |
|---|---|---|
| OQ1 | Widget 2×2 hiện ảnh hay avatars? | **✅ Resolved:** hiện ảnh mới nhất (từ Settings spec OQ4) |
| OQ2 | Update interval: 15 phút hay khác? | **15 phút** — minimum WorkManager interval. Có thể trigger thêm khi mở app |
| OQ3 | Dùng `workmanager` Flutter plugin hay native WorkManager? | **Gợi ý: native WorkManager** — tránh thêm Flutter plugin, logic đơn giản đủ viết Kotlin |

---

## Worst path

| Scenario | Expected behavior |
|---|---|
| Auth token hết hạn trong Worker | Worker skip update (`Result.success()`), widget hiện placeholder "Mở Meep để đăng nhập lại" |
| Network fail trong Worker | Giữ ảnh Glide đã cache trước đó; không update timestamp; không crash |
| OS defer Worker (Doze mode) | Widget hiện ảnh cũ (stale tối đa 15+ phút) — known limitation, document trong README |
| Deep link tap: post đã bị xóa | App mở, navigate đến Feed Home (fallback); toast "Khoảnh khắc này không còn tồn tại" |
| SharedPreferences chưa có data (lần đầu / sau xóa cache) | Widget hiện placeholder Meep logo + "Mở Meep để bắt đầu" |
| User logout khi widget đang cài | Flutter ghi `null` vào SharedPreferences → Worker next run detect no token → widget hiện placeholder ngay |
| Feed rỗng (chưa có post nào) | Worker query trả empty → widget hiện placeholder, không crash |
| Image download fail (Glide) | Widget giữ ảnh cached cũ (nếu có) hoặc hiện placeholder; không show broken image |
| User thêm widget trước khi đăng nhập | Placeholder state, tự update khi app được mở và đăng nhập |
| Nhiều widget instance trên home screen | Tất cả cùng hiện ảnh mới nhất — `AppWidgetManager.updateAppWidget(ids, views)` update all |

## Risks

- **WorkManager 15 phút minimum:** Android không cho schedule dưới 15 phút. Widget có thể chậm tối đa 15 phút sau khi bạn đăng ảnh. Mitigation: trigger sync thêm khi user mở app (Flutter push FCM → update widget).
- **Doze mode / battery optimization:** Android có thể defer WorkManager trên device tiết kiệm pin. Mitigation: document known limitation trong README.
- **SharedPreferences race condition:** Flutter write + Kotlin read đồng thời → stale data. Mitigation: Kotlin luôn đọc fresh từ Firestore trong Worker, SharedPreferences chỉ là cache.
- **Glide vs Coil:** nếu project đã có Coil trong Android deps → dùng Coil thay Glide để avoid duplicate image library.
- **RemoteViews limitation:** không support tất cả Flutter widget — UI widget bị giới hạn bởi Android RemoteViews API. Design phải đơn giản (ImageView + TextView).
