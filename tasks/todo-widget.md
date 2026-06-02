# TODO — Widget Android (T1+T2+T3) · Issue #139

> **Branch:** `feature/KhoaLND/t1+t2+t3-layout-widget`
> **Scope nhánh này:** T1 (layout + deps) · T2 (MeepWidget + WidgetDataStore) · T3 (WidgetSyncWorker)
> **Ngoài scope:** T4 (deep link), T5 (Flutter WidgetDataService), T6 (unit test) — issue/branch riêng
> **Spec:** `docs/specs/2026-05-23-widget-android.md` (LOCKED) · **Plan:** `docs/plans/2026-05-23-widget-android.md`
> **Milestone:** M3 — demo 2026-06-09 (còn ~8 ngày)

Kiến trúc (theo spec, KHÔNG re-litigate): **native-pull**. Kotlin WorkManager tự query Firebase
(Auth + Firestore) + Glide tải ảnh + RemoteViews render. Flutter chỉ ghi display-data + lastViewedAt
vào SharedPreferences (T5, ngoài scope).

---

## 0 · Quyết định cần chốt TRƯỚC khi code

- [ ] **Data bridge: `shared_preferences` hay `home_widget`?**
  - Spec LOCKED (§Dependencies, §Technical approach) chốt **`shared_preferences`** → Flutter ghi key bị
    prefix `flutter.` → Kotlin đọc `getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)` với
    key `flutter.widget_image_url`.
  - Nhưng `pubspec.yaml` đã có sẵn `home_widget: ^0.7.0` (API native sạch, key không prefix, kèm deep-link
    helper cho T4).
  - **Default = theo spec (`shared_preferences`).** Đổi sang `home_widget` = sửa contract T5 (`WidgetDataService`)
    + cập nhật spec → **cần ThienPDM duyệt** (strict gate). Trong scope T1-T3 chỉ khác mỗi cách đọc trong
    `WidgetDataStore.kt`, đổi sau rẻ.
- [ ] **Firebase native deps — KHÔNG pin `firebase-firestore-ktx:24.4.0` cứng.**
  App đã dùng FlutterFire (`cloud_firestore`) kéo Firebase BoM ~33.x (Firestore 25.x). Pin artifact `-ktx`
  cũ 24.4.0 vừa lệch version vừa dùng artifact đã deprecate (KTX merged vào artifact chính từ BoM 32.5.0+).
  → Dùng **Firebase BoM khớp FlutterFire** + `firebase-firestore` + `firebase-auth` (không version, không `-ktx`).
  Verify version resolved ≥ 24.4.0 để có `Query.count()` (25.x có sẵn). Đây là deviation khỏi chữ trong plan
  → ghi rõ trong PR cho ThienPDM.

---

## T1 · Layout + AppWidget metadata + build.gradle deps — S (~4h)

Layout zones (spec §Widget UI Content, source of truth Figma `693:2617`):

```
┌──────────────────────────┐
│                     [9+] │  widget_count — top-right, badge tròn #00C9E3, text trắng
│                          │
│   widget_photo (full)    │  fullscreen centerCrop, bo góc widget
│                          │
│  (avt)  caption pill     │  bottom-left: widget_avatar tròn 40dp + widget_caption pill
└──────────────────────────┘
   ↕ widget_placeholder (đè cả frame khi no-data): logo Meep + "Mở Meep để bắt đầu"
```

**Files:**

- [ ] `apps/mobile/android/app/src/main/res/layout/meep_widget.xml` — viết lại đủ 5 view:
  - [ ] `ImageView#widget_photo` — fullscreen, `scaleType=centerCrop`
  - [ ] `ImageView#widget_avatar` — 40×40dp, tròn (background drawable oval), bottom-left
  - [ ] `TextView#widget_caption` — pill: bg `#39404166`, radius 30dp, **Nunito SemiBold 14sp**, text trắng,
        padding h12/v6, bottom-left cạnh avatar. Ẩn (GONE) khi caption null.
  - [ ] `TextView#widget_count` — badge tròn: bg `#00C9E3` (Turquoise/600), text trắng Bold 12sp, top-right.
        Ẩn khi count = 0.
  - [ ] `widget_placeholder` container — Meep logo + "Mở Meep để bắt đầu". Hiện khi normal-container GONE.
- [ ] `apps/mobile/android/app/src/main/res/font/nunito.ttf` — copy từ `apps/mobile/assets/fonts/Nunito.ttf`
      (file 1-weight → **verify có nét SemiBold/600 không**; nếu không, fallback `sans-serif-medium`).
- [ ] `apps/mobile/android/app/src/main/res/drawable/` — tạo: `bg_caption_pill.xml` (shape rounded-rect
      #39404166 r30), `bg_count_badge.xml` (shape oval #00C9E3), `ic_avatar_default.xml` (oval + icon người dùng),
      logo placeholder.
- [ ] `apps/mobile/android/app/src/main/res/xml/meep_widget_info.xml` — **đã đúng** (250dp, updatePeriodMillis
      900000). Chỉ verify, không sửa.
- [ ] `apps/mobile/android/app/build.gradle.kts` — thêm deps:
  - [ ] `com.github.bumptech.glide:glide:4.16.0`
  - [ ] Firebase BoM + `firebase-firestore` + `firebase-auth` (xem §0 — KHÔNG pin 24.4.0)

**Gotcha RemoteViews:**
- RemoteViews KHÔNG set runtime cornerRadius/background-color tuỳ ý → pill + badge phải là **drawable shape XML**.
- `<Group>` (ẩn/hiện theo nhóm) chỉ chạy trong ConstraintLayout RemoteViews **API 31+**. An toàn cho minSdk 21:
  dùng 2 container (FrameLayout/LinearLayout) `normal` + `placeholder`, toggle bằng `setViewVisibility`.
- Custom `res/font` trong RemoteViews chỉ chắc apply **API 26+**. Verify trên thiết bị test < 26.

**Acceptance (#139 / plan T1):**
- [ ] `appwidget-provider` minWidth/minHeight = 250dp
- [ ] `meep_widget.xml` đủ 5 view: photo, avatar, caption, count, placeholder
- [ ] Placeholder hiện khi normal-container GONE
- [ ] Glide + firebase-firestore + firebase-auth đã add
- [ ] `flutter build apk --debug` → Kotlin compile clean

---

## T2 · MeepWidget.kt + WidgetDataStore.kt — M (~6h)

**Files:**

- [ ] `apps/mobile/android/app/src/main/kotlin/dev/meep/meep/WidgetDataStore.kt` — helper đọc 6 key
      SharedPreferences (theo §0: prefix `flutter.` nếu shared_preferences):
  - `widget_post_id` `String` · `widget_image_url` `String` · `widget_author_avatar_url` `String`
  - `widget_caption` `String?` · `widget_caption_type` `String?` · `widget_last_viewed_at` `Long`
  - Map ra data class `WidgetData`. Null/empty post_id → coi như "no data" → placeholder.
- [ ] `apps/mobile/android/app/src/main/kotlin/dev/meep/meep/MeepWidget.kt` — full `AppWidgetProvider`:
  - [ ] `onUpdate()` đọc `WidgetDataStore` → có data → normal state; không có → placeholder.
  - [ ] `updateWidget(context, data, unreadCount)` (static/companion):
    - Glide load `imageUrl` → Bitmap → `setImageViewBitmap(widget_photo, ...)`
    - Glide load `authorAvatarUrl` + `CircleCrop` → `setImageViewBitmap(widget_avatar, ...)`;
      `authorAvatarUrl == null` → default avatar drawable, **không crash**
    - `setTextViewText(widget_caption, caption)` + visibility theo `caption == null`
    - `setTextViewText(widget_count, formatCount(unreadCount))` + visibility theo `unreadCount == 0`
    - `formatCount`: 1–9 → số thực; ≥10 → "9+"
  - [ ] `AppWidgetManager.updateAppWidget(appWidgetIds, views)` — update mọi instance.

**Note caption/emoji:** caption từ Flutter là **chuỗi đã resolved, emoji đã nhúng sẵn** (xem
`caption_service_impl.dart`: location→`📍 ...`, weather→emoji, music→`♪ ...`, star→`⭐ ...`, streak→`🔥 ...`).
→ RemoteViews **render thẳng** `widget_caption`, KHÔNG cần tự map icon theo captionType. (`captionType` đọc vào
nhưng chưa cần dùng để render — chỉ giữ cho parity. Lưu ý lệch nhỏ: `time` resolve ra `HH:mm` không kèm 🕐;
nếu muốn đúng spec §Caption style thì prefix natively cho riêng `time` — follow-up nhỏ, không block.)

**Acceptance (#139 / plan T2):**
- [ ] `WidgetDataStore` đọc đúng 6 key
- [ ] `onUpdate()` rẽ nhánh normal / placeholder đúng
- [ ] Glide load photo + avatar (CircleCrop), avatar null → default, không crash
- [ ] Caption + count visibility + `formatCount` đúng
- [ ] `updateAppWidget` cập nhật tất cả instance

---

## T3 · WidgetSyncWorker.kt — L (~10h)

**File:** `apps/mobile/android/app/src/main/kotlin/dev/meep/meep/WidgetSyncWorker.kt` — đổi `Worker` → **`CoroutineWorker`**.

**Logic `doWork()`:**
- [ ] **[H7]** Token KHÔNG lưu SharedPreferences — `FirebaseAuth.getInstance().currentUser?.getIdToken(false)?.await()`
      mỗi lần. `currentUser == null` → update placeholder + `Result.success()`.
- [ ] Query `/users/{uid}/feed` ORDER BY `createdAt DESC` LIMIT 1 → fetch `/posts/{postId}` → lấy
      `imageUrl`, `authorAvatarUrl`, `caption`, `captionType` (fan-out subcollection, KHÔNG `whereIn`).
- [ ] Đọc `widget_last_viewed_at` → `count()` query `/users/{uid}/feed WHERE createdAt > lastViewedAt` → `unreadCount`.
      Offline/fail → `unreadCount = 0`, không crash (count() là server-only).
- [ ] Glide download imageUrl + authorAvatarUrl (CircleCrop) → cache internal storage.
- [ ] Gọi `MeepWidget.updateWidget(context, data, unreadCount)`.
- [ ] Network fail → giữ ảnh Glide cache cũ, không clear widget, không crash.
- [ ] Schedule: `WorkManager.enqueueUniquePeriodicWork("widget_sync", KEEP, PeriodicWorkRequest(15 phút))` —
      đăng ký ở đâu? (gợi ý: trong `MeepWidget.onEnabled()` hoặc khi app khởi động). Không duplicate worker.

**Prerequisite & verify (quan trọng cho native Firebase):**
- [ ] `google-services.json` có ở `apps/mobile/android/app/` (gitignored — checkout sạch sẽ thiếu). Worker
      dùng `FirebaseAuth/Firestore.getInstance()` → Firebase auto-init qua `FirebaseInitProvider`, độc lập Flutter engine.
- [ ] Verify `currentUser` non-null trong Worker trên device đã login (FlutterFire + native FirebaseAuth dùng
      chung session persisted) — đây là giả định cốt lõi của H7, test sớm.

**Acceptance (#139 / plan T3):** như checklist trên (token, query, count fallback, Glide cache, schedule unique).

---

## Worst-path coverage (spec §Worst path) — map vào task scope nhánh

Mỗi case PHẢI có nhánh xử lý + không crash. Đây là checklist verify cho T2/T3:

| Scenario | Expected | Task |
|---|---|---|
| Prefs chưa có data (lần đầu / sau `clearData`) | placeholder Meep logo + "Mở Meep để bắt đầu" | T2 `onUpdate` |
| `authorAvatarUrl == null` (chưa set avatar) | default avatar tròn (icon người dùng), không crash | T2 + T3 |
| Nhiều widget instance trên home screen | tất cả cùng update — `updateAppWidget(ids, views)` | T2 |
| `caption == null` | ẩn hẳn pill (GONE) | T2 |
| `currentUser == null` (chưa login / logout) | skip query → placeholder + `Result.success()` | T3 |
| Auth token hết hạn trong Worker | `getIdToken(false)` tự refresh; vẫn fail → placeholder | T3 |
| Feed rỗng (chưa có post) | query empty → placeholder, không crash | T3 |
| Network fail trong Worker | giữ ảnh Glide cache cũ, KHÔNG update timestamp, KHÔNG clear widget | T3 |
| Image download fail (Glide) | giữ cache cũ (nếu có) hoặc placeholder; KHÔNG show broken image | T3 |
| `count()` query fail (offline/permission) | `unreadCount = 0` → ẩn badge, ảnh + caption vẫn hiện | T3 |
| OS defer Worker (Doze mode) | ảnh cũ stale — known limitation, **document trong README** | T3 + README |
| Post đã xóa khi tap | Home + toast "Khoảnh khắc này không còn tồn tại" | **T4 (ngoài scope)** |

> Mitigation Doze (spec §Risks): trigger thêm 1 `enqueueUniqueWork` one-time khi app vào foreground (thuộc T5)
> — ghi nhận, không làm ở nhánh này.

---

## Verify nhánh

- [ ] `cd apps/mobile && flutter build apk --debug` — **cách duy nhất** compile Kotlin thật (không có gradlew
      wrapper trong android/; `flutter analyze` chỉ check Dart). Lần đầu tải Glide/Firebase deps → lâu vài phút.
- [ ] Manual smoke (cần device, sau khi có T5 hoặc seed prefs bằng `adb`):
  - [ ] Add widget từ picker → placeholder hiện
  - [ ] Device đã login + có post → worker pull → ảnh + avatar + caption + badge
  - [ ] Logout → placeholder

## Test (T6 — task riêng, nhưng cân nhắc gộp vào nhánh này)

`WidgetSyncWorker` có logic thật cần test theo CLAUDE.md (≥80% business logic): token null → success;
avatar null → default không crash; count() fail → unreadCount 0. Issue #139 DoD chỉ yêu cầu "Kotlin build
clean + manual smoke", unit test nằm ở T6. → **Confirm ThienPDM**: gộp T6 vào PR này hay tách.

## Thứ tự commit (1 nhánh, stage rõ)

`feat(widget): T1 …` → `feat(widget): T2 …` → `feat(widget): T3 …` → (`/review` sạch) → push → PR vào `develop`.
