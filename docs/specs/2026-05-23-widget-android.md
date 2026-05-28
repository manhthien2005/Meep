# Spec: Widget Android Module

**Date:** 2026-05-23
**Status:** Locked
**Owner:** ThienPDM (leader assign trước khi giao)
**Epic:** [T0] Widget Android — Ảnh mới nhất + Tap deep link · Milestone M3
**Platform:** Android only (iOS WidgetKit deferred per ADR-0002)

---

## Goal

Hiển thị ảnh mới nhất từ bạn bè trên home screen Android dưới dạng AppWidget 2×2 bo góc. Widget gồm: ảnh full-frame, avatar tác giả + caption (style Note pill, dùng chung `app_note_pill` từ homefeed — KhoaLND), và badge đếm số ảnh mới chưa xem. Tap vào widget → mở Meep app tại post đó. Widget tự cập nhật khi có post mới.

---

## User stories

- Là user, tôi muốn thêm Meep Widget vào home screen Android để thấy ảnh mới nhất của bạn bè.
- Là user, tôi muốn tap vào ảnh trong widget để mở app xem đầy đủ.
- Là user, tôi muốn widget tự cập nhật khi bạn bè đăng ảnh mới (không cần mở app).

---

## Scope

### In-scope (M3)

1. **AppWidget 2×2** — hiện ảnh mới nhất từ feed bạn bè, fullscreen bo góc. Overlay: avatar tác giả + caption (bottom-left), unread count badge (top-right)
2. **Tap deep link** — tap widget → mở Meep → navigate đến post đó
3. **Auto-update** — WorkManager job chạy background, fetch ảnh mới, update widget
4. **Widget setup flow** — trigger từ Settings → "Thêm tiện ích" → Android widget picker
5. **Placeholder state** — khi chưa có ảnh hoặc chưa login: hiện logo Meep + text "Mở Meep để bắt đầu"

### Out-of-scope

- Widget 4×2 hoặc size khác — post-MVP
- Multiple photos / carousel widget — post-MVP
- iOS WidgetKit — defer per ADR-0002
- Widget hiện danh sách avatar nhiều bạn bè (friend group overview) — widget chỉ hiện avatar của 1 tác giả bài viết mới nhất
- Glance API (Android 12+) — post-MVP

---

## Widget UI Content

> Source of truth: screenshot Android thực tế từ Figma frame `693:2617`.

### Layout

```
┌──────────────────────────┐
│                     [9+] │  ← unread count badge (top-right)
│                          │     • 1–9 : hiện số thực
│   [ảnh bạn bè full]      │     • ≥10 : hiện "9+"
│                          │     màu Turquoise/600 (#00C9E3), text trắng
│  [avt]  caption text     │  ← bottom-left: avatar tròn + caption
└──────────────────────────┘
```

### Elements

| Element | Source data | Hiển thị |
|---|---|---|
| Ảnh background | `post.imageUrl` | Fullscreen, scaleType centerCrop |
| Unread count badge | `count(feed where createdAt > lastViewedAt)` | Top-right, màu Turquoise/600 (`#00C9E3`) theo app theme, text trắng, "1"–"9" hoặc "9+" |
| Avatar tác giả | `post.authorAvatarUrl` | Tròn, bottom-left |
| Caption | `post.caption` + `post.captionType` | Note pill style — **dùng chung style `app_note_pill` từ homefeed (KhoaLND)**. Ẩn hoàn toàn khi `caption == null` |
| Placeholder state | — | Meep logo + "Mở Meep để bắt đầu", hiện khi chưa login hoặc chưa có post |

### Unread count logic

- `lastViewedAt` = timestamp lúc user **mở app** từ bất kỳ đâu (AppLifecycleState.resumed → Flutter ghi vào SharedPreferences). Badge phản ánh số bài mới kể từ lần cuối dùng app.
- WorkManager đọc `lastViewedAt` → query `/users/{uid}/feed` where `createdAt > lastViewedAt` → đếm số docs
- Khi user tap widget → app navigate đến post đó (deep link). `lastViewedAt` sẽ được reset tự nhiên khi app resumed sau đó.
- Badge ẩn khi `unreadCount == 0`

### Caption style (RemoteViews replication)

Style `app_note_pill.dart` (homefeed — KhoaLND) cần replicate trong RemoteViews:
- Background: `#39404166` (semi-transparent dark), cornerRadius 30dp
- Text: white, Nunito SemiBold 14sp
- Padding: horizontal 12dp, vertical 6dp
- Icon prefix theo `captionType` (emoji hoặc vector drawable): `text`→none, `location`→📍, `weather`→emoji thời tiết, `music`→♪, `star`→⭐, `time`→🕐, `streak`→🔥

---

## Màn hình & Figma IDs

| Màn hình | Figma ID | Ghi chú |
|---|---|---|
| Widget confirm sheet (trong Settings) | `662:3341` | Bottom sheet "Thêm vào màn hình chờ?" |
| Widget confirm variant | `678:2321` | Variant state |
| Sau khi thêm widget | `693:2617` | Screenshot Android home screen thực tế với widget đang hiển thị — source of truth cho widget UI |
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
             → Không có callback thành công → hiện màn hình 693:2617 (screenshot home screen + widget) như hướng dẫn
        [Huỷ]  → đóng sheet
```

### Widget hiển thị ảnh

```
WorkManager PeriodicWorkRequest (interval: 15 phút — Android đảm bảo chạy trong ~15–30 phút tuỳ Doze mode)
    → WidgetSyncWorker.doWork():
        (1) [H7-FIX] Lấy token: FirebaseAuth.getInstance().currentUser?.getIdToken(false)?.await()
            Nếu currentUser == null → update widget với placeholder, return Result.success()
        (2) Lấy currentUid từ FirebaseAuth.currentUser.uid
        (3) Query Firestore (dùng fan-out subcollection, không dùng whereIn):
            /users/{currentUid}/feed ORDER BY createdAt DESC LIMIT 1
            Sau đó fetch /posts/{feedDoc.postId} để lấy imageUrl, authorAvatarUrl, caption, captionType
        (4) Đọc widget_last_viewed_at từ SharedPreferences
            Query /users/{currentUid}/feed WHERE createdAt > lastViewedAt → count() → unreadCount
            ⚠️ count() là server-only, không có offline cache — nếu offline → fallback unreadCount = 0, không crash
        (5) Download imageUrl + authorAvatarUrl → cache (Glide)
            authorAvatarUrl → transform thành circular Bitmap
        (6) AppWidgetManager.updateAppWidget() với RemoteViews:
            - setImageViewBitmap(widget_photo, photoBitmap)
            - setImageViewBitmap(widget_avatar, circularAvatarBitmap)
            - setTextViewText(widget_caption, caption) + setViewVisibility(VISIBLE/GONE)
            - setTextViewText(widget_count, formatCount(unreadCount)) + setViewVisibility(VISIBLE/GONE)
            formatCount: 1–9 → số thực, ≥10 → "9+"
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

- **Widget UI:** Android `AppWidgetProvider` (Kotlin) + `RemoteViews` — native Android, nằm trong `apps/mobile/android/`
- **Background sync:** `WorkManager` (AndroidX) — `PeriodicWorkRequest` 15 phút
- **Data sharing Flutter ↔ Widget:** `SharedPreferences` (Android native) — Flutter plugin lưu **latest post display data** vào `shared_prefs` mà Kotlin đọc được. **KHÔNG lưu auth token** (xem H7 bên dưới).

  Keys:
  ```
  widget_post_id            String  — postId, dùng cho deep link
  widget_image_url          String  — URL ảnh background
  widget_author_avatar_url  String  — URL avatar tác giả (tròn, bottom-left)
  widget_caption            String? — caption text đã resolved (nullable — ẩn pill khi null)
  widget_caption_type       String? — "text"|"location"|"weather"|"music"|"star"|"time"|"streak"
  widget_last_viewed_at     Long    — millis timestamp lần cuối mở app (cho unread count)
  ```
  `authorName` **không lưu** — widget không hiện tên, avatar là visual identifier.
- **[H7-FIX] Auth token trong Worker:** Firebase ID token hết hạn sau 1h — không thể lưu vào SharedPreferences rồi đọc lại. Worker phải gọi `FirebaseAuth.getInstance().currentUser?.getIdToken(false)?.await()` để lấy token mới mỗi lần chạy (Firebase SDK tự refresh internally). Nếu `currentUser == null` → skip query, hiện placeholder.
- **Image caching:** Glide (Kotlin side) — download + cache ảnh vào internal storage
- **Deep link:** `MethodChannel` Flutter ↔ Android để truyền `postId` khi tap widget

### File structure

```
apps/mobile/android/app/src/main/
├─ kotlin/.../
│   ├─ MainActivity.kt          ← xử lý widget tap intent
│   ├─ MeepWidget.kt            ← AppWidgetProvider
│   ├─ WidgetDataStore.kt       ← helper đọc SharedPreferences
│   └─ WidgetSyncWorker.kt      ← WorkManager worker
└─ res/
    ├─ layout/meep_widget.xml   ← RemoteViews layout
    └─ xml/meep_widget_info.xml ← AppWidget metadata (size, update interval)
```

### Flutter side

```dart
// Lưu data cho widget sau mỗi lần fetch feed
abstract class WidgetDataService {
  /// Gọi từ FeedController (KhoaLND) sau mỗi lần fetch feed mới.
  /// caption + captionType: lấy từ post.caption / post.captionType (đã resolved string).
  Future<void> updateWidgetData({
    required String postId,
    required String imageUrl,
    required String authorAvatarUrl,
    String? caption,       // null → pill ẩn trong widget
    String? captionType,   // "text"|"location"|"weather"|"music"|"star"|"time"|"streak"
  });

  /// Gọi khi app vào foreground (AppLifecycleState.resumed).
  /// Ghi widget_last_viewed_at = DateTime.now().millisecondsSinceEpoch.
  Future<void> recordLastViewedAt();

  /// Gọi khi logout → xóa tất cả widget_* keys → widget hiện placeholder.
  Future<void> clearData();
}
```

**Cross-module:** `updateWidgetData()` được gọi từ `FeedController` (homefeed module — KhoaLND). Caption style (`app_note_pill`) do KhoaLND implement trong homefeed; Widget module replicate style trong RemoteViews XML.

---

## Dependencies

### Flutter (pubspec.yaml)

| Package | Lý do | Có sẵn? |
|---|---|---|
| `shared_preferences` | Share data Flutter ↔ Android widget | ✅ đã có (`^2.3.3`) |

### Android (build.gradle)

| Dependency | Lý do | Có sẵn? |
|---|---|---|
| `androidx.work:work-runtime-ktx:2.9.1` | WorkManager background sync | ✅ đã có |
| `com.github.bumptech.glide:glide` | Image download + cache + CircleCrop cho avatar | ❌ cần thêm |
| `com.google.firebase:firebase-firestore-ktx:24.4.0+` | Query latest post + unread `count()` từ Kotlin — **min 24.4.0** (phiên bản đầu tiên có `Query.count()`) | ❌ cần thêm |
| `com.google.firebase:firebase-auth-ktx` | Đọc auth token trong worker | ❌ cần thêm |

> ⚠️ `count()` là server-side only — **không hoạt động offline**, không hỗ trợ realtime listener. Nếu query fail (offline/network) → badge fallback = 0, không crash (xem Worst path).

---

## Security

- Widget chỉ đọc post data của user đang login — dùng Firebase Auth SDK trực tiếp trong WorkManager worker
- **[H7] Auth token KHÔNG lưu SharedPreferences** — Worker gọi `FirebaseAuth.getInstance().currentUser?.getIdToken(false)?.await()` mỗi lần chạy. Firebase SDK tự refresh token nếu cần.
- SharedPreferences chỉ lưu display data (postId, imageUrl, authorAvatarUrl, caption, captionType, lastViewedAt) — không lưu credentials
- Nếu `currentUser == null` (chưa login / logout) → worker skip update, widget hiện placeholder
- Không lưu password hay sensitive credentials trong SharedPreferences

---

## Testing strategy

### Unit tests (Kotlin)

| Test | Target |
|---|---|
| `WidgetSyncWorker` không có token → return `Result.success()` (skip gracefully) | `WidgetSyncWorker` |
| `WidgetSyncWorker` có token → fetch post + update widget | `WidgetSyncWorker` (mock Firestore) |
| `WidgetSyncWorker` có token, `authorAvatarUrl == null` → Glide load null → không crash, hiện default avatar | `WidgetSyncWorker` |
| `WidgetSyncWorker` có token, `count()` query fail (offline/permission) → badge = 0, widget vẫn update bình thường | `WidgetSyncWorker` |
| `MeepWidget.onUpdate()` với valid RemoteViews → không crash | `MeepWidget` |
| `authorAvatarUrl == null` → Glide fallback, không crash, widget vẫn render | `WidgetSyncWorker` |
| `count()` query fail (offline/network) → unreadCount = 0, badge ẩn, widget update tiếp tục | `WidgetSyncWorker` |

### Manual smoke tests (device required)

- [ ] Widget thêm được vào home screen từ Android widget picker
- [ ] Widget hiện ảnh mới nhất sau khi đăng ảnh từ app
- [ ] Tap widget → app mở đúng post
- [ ] Widget hiện placeholder khi logout
- [ ] Widget tự update sau ≤ 15 phút khi bạn đăng ảnh mới (có thể trễ hơn do Doze mode)

---

## Contract bàn giao

| Artifact | File | Status |
|---|---|---|
| `MeepWidget.kt` (AppWidgetProvider) | `android/app/src/main/kotlin/.../MeepWidget.kt` | ⏳ stub |
| `WidgetDataStore.kt` (SharedPreferences helper) | `android/app/src/main/kotlin/.../WidgetDataStore.kt` | ❌ chưa có |
| `WidgetSyncWorker.kt` (WorkManager) | `android/app/src/main/kotlin/.../WidgetSyncWorker.kt` | ⏳ stub |
| `meep_widget.xml` (RemoteViews layout) | `android/app/src/main/res/layout/meep_widget.xml` | ⏳ stub — cần thêm widget_avatar, widget_caption pill, widget_count badge |
| `meep_widget_info.xml` (AppWidget metadata) | `android/app/src/main/res/xml/meep_widget_info.xml` | ✅ |
| `AndroidManifest.xml` — khai báo widget | `android/app/src/main/AndroidManifest.xml` | ✅ |
| `WidgetDataService` (Flutter abstract) | `lib/features/widget/application/widget_data_service.dart` | ⏳ stub — cần update interface (avatar, caption, recordLastViewedAt) |
| `MethodChannel` handler trong `MainActivity.kt` | `android/app/src/main/kotlin/.../MainActivity.kt` | ❌ update |

> Mọi stub phải có TODO marker theo format `// TODO(W/T<n>/<DevName>): <mô tả>`

---

## Open questions

| # | Câu hỏi | Status |
|---|---|---|
| OQ1 | Widget 2×2 hiện ảnh hay avatars? | **✅ Resolved 2026-05-27:** ảnh fullscreen + avatar tác giả overlay bottom-left + caption pill + unread count badge top-right |
| OQ2 | Update interval: 15 phút hay khác? | **✅ Resolved:** 15 phút (schedule interval). Android thực tế có thể delay thêm do Doze mode — known limitation |
| OQ3 | Dùng `workmanager` Flutter plugin hay native WorkManager? | **✅ Resolved:** native WorkManager (Kotlin) |
| OQ4 | Widget hiện authorName hay không? | **✅ Resolved 2026-05-27:** không — avatar là visual identifier, không lưu authorName |
| OQ5 | Caption có trong widget không? | **✅ Resolved 2026-05-27:** có. Style Note pill (reuse `app_note_pill` từ homefeed — KhoaLND). Ẩn khi `caption == null` |
| OQ6 | Unread count format? | **✅ Resolved 2026-05-27:** 1–9 hiện số thực, ≥10 hiện "9+". Badge ẩn khi count = 0 |
| OQ7 | `lastViewedAt` reset khi nào? | **✅ Resolved 2026-05-27:** AppLifecycleState.resumed. App tự navigate đến post mới nhất khi mở |

---

## Worst path

| Scenario | Expected behavior |
|---|---|
| Auth token hết hạn trong Worker | Worker skip update (`Result.success()`), widget hiện placeholder "Mở Meep để đăng nhập lại" |
| Network fail trong Worker | Giữ ảnh Glide đã cache trước đó; không update timestamp; không crash |
| OS defer Worker (Doze mode) | Widget hiện ảnh cũ (stale) — known limitation. Worker schedule 15 phút nhưng Android có thể defer; document trong README |
| Deep link tap: post đã bị xóa | App mở, navigate đến Feed Home (fallback); toast "Khoảnh khắc này không còn tồn tại" |
| SharedPreferences chưa có data (lần đầu / sau xóa cache) | Widget hiện placeholder Meep logo + "Mở Meep để bắt đầu" |
| User logout khi widget đang cài | Flutter ghi `null` vào SharedPreferences → Worker next run detect no token → widget hiện placeholder ngay |
| Feed rỗng (chưa có post nào) | Worker query trả empty → widget hiện placeholder, không crash |
| Image download fail (Glide) | Widget giữ ảnh cached cũ (nếu có) hoặc hiện placeholder; không show broken image |
| `authorAvatarUrl == null` (user chưa set avatar) | Glide load null → hiện default avatar placeholder (circle với icon người dùng); không crash |
| Unread count query fail (network/permission) | Ẩn badge (fallback về 0), không block widget update; ảnh + caption vẫn hiện bình thường |
| User thêm widget trước khi đăng nhập | Placeholder state, tự update khi app được mở và đăng nhập |
| Nhiều widget instance trên home screen | Tất cả cùng hiện ảnh mới nhất — `AppWidgetManager.updateAppWidget(ids, views)` update all |

---

---

## Risks

- **WorkManager Doze mode delay:** Schedule 15 phút nhưng Android có thể defer khi device tiết kiệm pin. Mitigation: trigger sync bổ sung khi user mở app (`WorkManager.enqueueUniqueWork` one-time khi foreground) + document known limitation trong README.
- **Glide circular bitmap:** Download 2 ảnh (photo + avatar) trong cùng Worker run. Glide cache giảm overhead. Avatar cần `CircleCrop` transform.
- **Unread count stale:** Count tính tại thời điểm Worker chạy, không realtime. Acceptable — widget vốn không realtime.
- **`app_note_pill` cross-module:** Style reference từ homefeed (KhoaLND). Nếu KhoaLND update style, Widget RemoteViews cần update tương ứng (manual sync — không có code share giữa Flutter và RemoteViews XML).

---

## Changelog

| Ngày | Thay đổi | Tác giả |
|---|---|---|
| 2026-05-23 | Tạo spec ban đầu | ThienPDM |
| 2026-05-27 | Cập nhật widget content dựa trên Figma thực tế (frame `693:2617`): thêm avatar tác giả (bottom-left), caption pill (style `app_note_pill` — KhoaLND), unread count badge (top-right, màu Turquoise/600, format 1–9/9+). Xác nhận không hiện authorName. Thêm `lastViewedAt` logic — reset mỗi lần mở app (Option A), navigate khi tap widget. WorkManager interval giữ 15 phút. Note Firebase Firestore `count()` min version 24.4.0 + offline limitation. Thêm `WidgetDataStore.kt` vào contract + file structure. Thêm 2 unit test case (avatarUrl null, count fail). Resolve OQ1–OQ7. | ThienPDM |
