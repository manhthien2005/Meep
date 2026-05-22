# Spec: HomePage + Camera + Feed + Post

**Date:** 2026-05-22  
**Status:** 🔒 LOCKED  
**Owner:** ThienPDM  
**Epic:** [T0] Camera + Share + Feed — Milestone M2

---

## Goal

Cho phép user chụp ảnh, thêm caption preset, chọn audience và gửi đến bạn bè. Feed hiển thị ảnh mới nhất của bạn bè (và bản thân) theo dạng full-screen card cuộn dọc. Reactions (M3) được thiết kế sẵn nhưng implement sau.

---

## User stories

- Là user, tôi muốn chụp ảnh bằng camera và gửi cho bạn bè ngay từ màn hình chính.
- Là user, tôi muốn chọn caption preset nhanh (hoặc tự gõ) để đính kèm ảnh.
- Là user, tôi muốn chọn gửi cho tất cả bạn bè hoặc chọn từng người.
- Là user, tôi muốn scroll xuống để xem ảnh mới nhất từ bạn bè.
- Là user, tôi muốn lọc feed theo từng người bạn để chỉ xem ảnh của họ.
- Là user, tôi muốn xem lại ảnh của mình cùng trạng thái hoạt động (reactions).

---

## Scope

### In-scope (M2)

1. **Camera screen** — viewfinder + flash + zoom 1x + flip + album picker + capture
2. **Photo preview** — 7 caption types (swipe), audience selector, send/cancel/save-local
3. **Caption type modal** (`sparkles+`) — hiển thị 7 loại caption, user chọn type
4. **Post creation** — upload ảnh lên Storage + tạo Firestore doc (không có notification)
5. **Feed** — scroll dọc dưới camera, mỗi card = 1 post full-width, newest first
6. **Feed filter** (`FriendsButton`) — lọc theo người cụ thể, title đổi thành tên + avatar
7. **View friend's photo** — full-screen card, caption, name + time, ActText (M3 placeholder)
8. **View own photo** — full-screen card, 3 states: no-activity / has-activity / share-mode
9. **Grid view** — 3-column grid ảnh đã post (từ grid icon trên Taskbar feed)
10. **Save to local** — tap download trên preview → lưu vào gallery thiết bị (không upload)

### Out-of-scope

- Reactions / gửi tin nhắn trả lời ảnh (M3 — `ActText` render nhưng không functional)
- Profile tap (avatar góc phải — thuộc Profile module)
- **Xem ảnh bản thân** (3 states) — thuộc **Profile module**, TODO khi Profile done
- Notification khi đăng ảnh (không cần)
- Music detection thực sự (mock only ở M2)
- Horoscope/ngôi sao thực sự (mock only ở M2)
- Streak caption thực sự (TODO — link Streak module)

---

## Luồng đầy đủ

### Luồng chính — Camera + Feed (một viewport)

```
HomeScreen (CustomScrollView)
│
├─ [Top / scroll UP] Camera Section
│   ├─ FriendsButton "15 người bạn" [audience selector cho post sắp gửi]
│   ├─ Avatar góc phải (Profile module — out of scope)
│   ├─ Viewfinder 400×400, cornerRadius 50
│   ├─ 2 pagination dots: [Single] [Dual]
│   ├─ Swipe TRÁI trên viewfinder → Dual Camera mode
│   ├─ Flash (zap), Zoom "1x" tag
│   ├─ [ Album | Capture | Flip ]
│   └─ "Lịch sử" combo → tap = scroll xuống feed (❓ còn chờ confirm)
│
└─ [Scroll DOWN] Feed Section (newest first)
    ├─ FriendsButton filter [filter feed — khác với FriendsButton trên camera]:
    │   ├─ Default: "Mọi người" → tất cả bạn bè + bản thân
    │   ├─ Tap → dropdown list friends + "Bản thân"
    │   └─ Chọn một người → filter feed + title = [avatar người đó] [tên] ▾
    │
    ├─ Post card: ảnh bạn bè
    │   ├─ Photo 400×400
    │   ├─ Caption overlay (Note pill)
    │   ├─ "[Tên bạn] [time ago]" label bên dưới ảnh
    │   └─ ActText bar: "Gửi tin nhắn..." + �🤣🥰 + smile-plus [M3 — disabled]
    │
    └─ Post card: ảnh bản thân
        ├─ Photo 400×400
        ├─ Caption overlay
        └─ "Bạn [ngày]" label
        └─ "\u2728 Chưa có hoạt động nào!" pill (M2 — reactions M3)
        └─ [TODO Profile module: Xem ảnh bản thân các states]
```

### Luồng chụp + gửi ảnh

```
[Tap Capture] hoặc [Swipe trái viewfinder → Dual Camera mode]
    → Xem trước ảnh chụp
        ├─ Photo preview 400×400
        ├─ Caption type overlay (Note pill, default = Text rỗng)
        │   ├─ Swipe trái/phải trên pill → cycle 7 caption types
        │   └─ Tap sparkles+ → Caption Type Modal (chọn type)
        │
        ├─ Audience selector (bottom):
        │   ├─ "Tất cả" button (Turquoise) — default selected
        │   └─ Avatar circles từng bạn → tap select/deselect
        │
        ├─ Tap Download (top-right):
        │   → Icon đổi từ download → ✔ tick (in-place, không navigate)
        │   → Ảnh lưu vào gallery, ở lại màn preview
        ├─ Tap X → huỷ, về Camera
        └─ Tap Send → [loading] → upload → post created → về Camera
```

### Luồng Grid View

```
[Tap layout-grid icon (góc trái Taskbar feed)] → Grid View
    ├─ 3-column grid tất cả ảnh đã post (của filter hiện tại)
    ├─ FriendsButton filter giữ nguyên
    └─ Tap 1 ảnh → Xem ảnh bạn bè (full-screen, thông tin người đăng)
         [nếu filter = bản thân → TODO Profile module]
```

### Luồng Share Modal

```
[Tap ↑ (share icon, ngoài pill Taskbar)] → Share Modal (bottom sheet)
    ├─ Title: "Chia sẻ đến..."
    ├─ Share targets (4 icon):
    │   ├─ "Chia sẻ" → native OS share sheet
    │   ├─ "Messenger" → deep link Messenger
    │   ├─ "Instagram" → deep link Instagram
    │   └─ "Tin nhắn" → TODO Tier 1 — Chat module (disabled M2)
    └─ Actions:
        ├─ [Lưu] → lưu ảnh xuống gallery
        └─ [Xoá] → xóa post (chỉ hiển khi là bản thân là author)
```

---

## Màn hình & Figma IDs

| Màn hình | Figma ID | Ghi chú |
|---|---|---|
| Trang chủ - Single Camera | `440:1767` | MVP |
| Xem trước ảnh chụp | `442:2319` | |
| Trang chủ - Dual Camera | `269:1402` | Swipe trái từ Single Camera |
| Lưu ảnh thành công | `579:1575` | In-place icon download→✔ |
| Chú thích ảnh (caption modal) | `269:1747` | Mở từ sparkles+ |
| Xem ảnh bạn bè | `472:2241` | Feed card + Grid detail |
| Xem ảnh dạng lưới | `580:2883` | Grid view |
| Share Modal (bottom sheet) | `580:2813` | Tap ↑ trên Taskbar feed |
| ~~Xem ảnh bản thân (3 states)~~ | ~~`472:1950`, `472:2041`, `579:2844`~~ | **Profile module** |

---

## Technical approach

### Architecture

```
Presentation                  Application                Data
──────────────────────        ──────────────────         ──────────────────────
HomeScreen                    CameraController            PostRepository (abstract)
 ├─ CameraSection              └─ CameraState             FirebasePostRepository
 └─ FeedSection               FeedController              StorageRepository (abstract)
     ├─ FeedFilterBar           ├─ FeedState               FirebaseStorageRepository
     └─ PostCard                └─ FeedFilter
         ├─ FriendPostCard      PostController
         └─ OwnPostCard          └─ PostState
CapturePreviewScreen
CaptionPresetModal
GridViewScreen
```

**Scroll architecture:** `CustomScrollView` với 2 sliver:
- `SliverToBoxAdapter` → `CameraSection` (fixed height)
- `SliverList` → `FeedSection` (danh sách `PostCard`)

`CameraSection` scroll OUT khi user kéo xuống. Tap "Lịch sử" = `scrollController.animateTo(cameraHeight)`.

### Data model

**Firestore `/posts/{postId}`:**
```
{
  authorId:         string,
  authorName:       string,        // denormalized từ UserProfile
  authorAvatarUrl:  string?,       // denormalized
  imageUrl:         string,        // Firebase Storage URL
  caption:          string?,       // ≤ 200 chars, null nếu không chọn
  captionType:      'text' | 'location' | 'weather' | 'music' | 'star' | 'time' | 'streak' | null,
  audienceType:     'all' | 'select',
  audienceUids:     string[],      // [] khi audienceType='all'
  createdAt:        Timestamp,     // serverTimestamp()
}
```

**Firestore `/posts/{postId}/reactions/{reactionId}`** — M3:
```
{ reactorId, reactorName, emoji, createdAt }
```

**Firebase Storage path:** `posts/{uid}/{postId}/photo.jpg`

### Feed query + pagination

**Giới hạn hệ thống:** tối đa 20 bạn bè/user → `whereIn` tối đa 21 UIDs (20 bạn + bản thân), an toàn với giới hạn 30 của Firestore.

**M2 (Friend module chưa có) — owner-only:**
```dart
Firestore.collection('posts')
  .where('authorId', isEqualTo: currentUid)
  .orderBy('createdAt', descending: true)
  .limit(10)
  .startAfterDocument(lastDoc)  // cursor pagination
```

**M2+ (sau khi Friend module done) — all friends + self:**
```dart
final friendUids = await friendRepository.getFriendUids(currentUid);
Firestore.collection('posts')
  .where('authorId', whereIn: [currentUid, ...friendUids])  // max 21 UIDs
  .orderBy('createdAt', descending: true)
  .limit(10)
  .startAfterDocument(lastDoc)
```

**Feed filter (FriendsButton):**
- `FeedFilter.all` → `whereIn [currentUid + friendUids]`
- `FeedFilter.person(uid)` → `where authorId == uid` (xem feed của 1 người)

**Pagination strategy — prefetch tại item thứ 6:**
```dart
// Trong FeedController — build từng PostCard:
bool _shouldPrefetch(int index) => index == currentItems.length - 4;
// 10 items loaded → prefetch khi render item index 6 (còn 4 item trước khi hết)

void onItemVisible(int index) {
  if (_shouldPrefetch(index) && !isLoadingMore) {
    loadNextPage(); // .limit(10).startAfterDocument(lastDoc)
  }
}
```

### Caption types (7 loại)

Swipe trái/phải trên preview = cycle qua 7 loại theo thứ tự. Tap `sparkles+` = modal hiển thị cả 7 để chọn nhanh. Tất cả resolve client-side (không cần Firestore).

| # | Type | Data source | M2 status |
|---|---|---|---|
| 1 | **Text** | `TextEditingController` — user tự gõ | ✅ Full |
| 2 | **Vị trí** | GPS (`geolocator`) → Nominatim reverse geocode | ✅ Full |
| 3 | **Thời tiết** | GPS → Open-Meteo API | ✅ Full |
| 4 | **Đang phát** | Hardcoded mock text `"♪ Đang phát nhạc"` | ⚙️ Mock |
| 5 | **Ngôi sao** | Hardcoded mock text `"⭐ Ngôi sao"` | ⚙️ Mock |
| 6 | **Giờ hiện tại** | `DateTime.now()` + `intl` timezone | ✅ Full |
| 7 | **Streak** | TODO — link Streak module | 🔗 TODO |

**API specs:**

```
// Vị trí — Nominatim (free, no key)
GET https://nominatim.openstreetmap.org/reverse
    ?lat={lat}&lon={lon}&format=json&accept-language=vi
Output: display_name → trim thành "Quận X, TP.HCM"

// Thời tiết — Open-Meteo (free, no key)
GET https://api.open-meteo.com/v1/forecast
    ?latitude={lat}&longitude={lon}&current_weather=true
Output: weathercode + temperature_2m → map sang emoji + text
        vd: "☀️ Nắng 32°C" / "🌧️ Mưa 25°C"

// Giờ hiện tại — device timezone
DateTime.now() → format "HH:mm" theo intl DateFormat
Output: "14:30" (không cần API)
```

**Weather code mapping (cần implement):**

| WMO code | Text | Emoji |
|---|---|---|
| 0 | Trời quang | ☀️ |
| 1-3 | Có mây | ⛅ |
| 45,48 | Sương mù | 🌫️ |
| 51-67 | Mưa nhỏ/vừa | 🌧️ |
| 71-77 | Tuyết | ❄️ |
| 80-82 | Mưa rào | 🌦️ |
| 95-99 | Dông | ⛈️ |

### Post creation flow

```dart
// PostController.createPost()
1. Compress ảnh (≤ 1MB, max 1080px) — dùng flutter_image_compress
2. Upload Storage: posts/{uid}/{postId}/photo.jpg
3. Lấy download URL
4. Firestore batch:
   - Set /posts/{postId} với imageUrl + metadata
// Không có notification khi đăng ảnh
```

### Dependencies

| Package | Lý do | Có sẵn? |
|---|---|---|
| `camera` | Camera capture, flash, zoom | ❌ cần thêm |
| `flutter_image_compress` | Compress ảnh trước upload | ❌ cần thêm |
| `gal` | Lưu ảnh vào gallery thiết bị | ❌ cần thêm |
| `geolocator` | GPS lat/lng cho caption Vị trí + Thời tiết | ❌ cần thêm |
| `cached_network_image` | Cache ảnh feed, tránh re-download | ❌ cần thêm |
| `http` | Gọi Nominatim + Open-Meteo API | ❌ cần thêm |
| `intl` | Format giờ hiện tại theo timezone | ❌ cần thêm |
| `cloud_firestore` | Post docs, feed query | ✅ |
| `firebase_storage` | Image upload | ✅ |
| `go_router` | Navigation | ✅ |
| `riverpod` | State | ✅ |

> **Leader phải approve** trước khi add package mới. Tổng: 7 package cần thêm.

---

## Security

### Firestore rules

```javascript
match /posts/{postId} {
  // M2: owner-only — chỉ tác giả đọc được post của mình
  // TODO(Friend module): mở rộng thêm || isFriend(authorId)
  // để bạn bè đọc được sau khi Friend rules được deploy
  allow read: if isAuthed() && request.auth.uid == resource.data.authorId;
  allow create: if isAuthed()
                && request.auth.uid == request.resource.data.authorId
                && (request.resource.data.caption == null
                    || request.resource.data.caption.size() <= 200);
  allow delete: if isAuthed() && request.auth.uid == resource.data.authorId;
  allow update: if false; // posts bất biến sau khi tạo
}
```

### Storage rules

```javascript
match /posts/{uid}/{postId}/{filename} {
  // M2: owner-only — chỉ tác giả đọc được ảnh của mình
  // TODO(Friend module): mở rộng thêm || isFriend(uid)
  allow read:  if isAuthed() && request.auth.uid == uid;
  allow write: if isAuthed()
               && request.auth.uid == uid
               && request.resource.size < 5 * 1024 * 1024
               && request.resource.contentType.matches('image/.*');
}
```

---

## Testing strategy

### Unit tests

| Test | Target |
|---|---|
| `createPost` success → doc tạo + Storage URL | `FirebasePostRepository` |
| `createPost` Storage fail → Firestore không tạo | `FirebasePostRepository` |
| `getFeed` trả đúng posts theo filter | `FirebasePostRepository` |
| `FeedController` pagination cursor | `FeedController` |
| `PostController` compress + upload flow | `PostController` |
| Caption preset cycle (7 presets) | `CaptionPresetService` |

### Widget tests

| Test | Screen |
|---|---|
| Camera screen render, tap capture → PreviewScreen | `HomeScreen` |
| Preview: swipe caption → cycles 7 presets | `CapturePreviewScreen` |
| Audience: "Tất cả" default selected, tap friend toggles | `CapturePreviewScreen` |
| Feed filter: chọn friend → FriendsButton title đổi | `FeedFilterBar` |
| Own photo "Chưa có HĐ" → đúng pill hiển thị | `OwnPostCard` |

### Firestore rules tests

- `/posts/{id}` Firestore: author read ✓, other user read ✗
- Storage `/posts/{uid}/...`: owner read ✓, other user read ✗
- `/posts/{id}` Firestore: author read ✓
- `/posts/{id}`: caption > 200 chars → create rejected ✗
- `/posts/{id}`: update → rejected ✗
- Storage: upload > 5MB → rejected ✗
- Storage: non-image MIME → rejected ✗

---

## Components (leader code trước)

| Widget | Spec |
|---|---|
| `app_camera_button.dart` | 82×82, inner white 70×70 `Ellipse`, outer Turquoise/500 ring. Tap animate scale 0.9→1. |
| `app_note_pill.dart` | `cornerRadius 30`, bg `#39404166`, Nunito Bold 14, white. `case-sensitive` icon bên trái. Editable via `TextEditingController`. |
| `app_act_text_bar.dart` | M3 placeholder — render "Gửi tin nhắn..." + 3 emoji + smile-plus. Disabled (no-op tap) ở M2. |
| `post_card.dart` | 400×400 image, cornerRadius 50, `Note` overlay, label bên dưới. |
| `caption_service.dart` | Abstract: `Future<String> resolve(CaptionType type)`. Impl: Text (passthrough), Location (Nominatim), Weather (Open-Meteo), Time (DateTime), Mock (Music/Star/Streak). |
| `share_modal.dart` | Bottom sheet: title "Chia sẻ đến...", 4 share targets (Chia sẻ/Messenger/Instagram/Tin nhắn-disabled), 2 actions (Lưu/Xoá). Xoá chỉ hiển khi `isAuthor == true`. |

---

## Boundaries

### Always do

- Compress ảnh xuống ≤ 1MB, maxWidth 1080px trước khi upload.
- `serverTimestamp()` cho `createdAt`.
- Không lưu local path vào Firestore — chỉ lưu Storage download URL.
- Paginate feed bằng `startAfterDocument` — không dùng `limit+offset`.

### Ask first

- Cache strategy cho feed (offline support): hỏi anh trước khi implement.
- Caption type 7 (Streak): hỏi anh khi Streak module bắt đầu implement.

### Never do

- Không upload ảnh > 5MB (enforce cả client + Storage rules).
- Không query feed không có filter uid (full collection scan).
- Không store `audienceUids` cho `audienceType='all'` (để mảng rỗng `[]`).

---

## Contract bàn giao (leader merge trước khi giao dev)

| Artifact | File | Status |
|---|---|---|
| `Post` freezed model | `lib/features/feed/data/post.dart` | ❌ cần tạo |
| `PostRepository` abstract | `lib/features/feed/data/post_repository.dart` | ❌ |
| `StorageRepository` abstract | `lib/features/feed/data/storage_repository.dart` | ❌ |
| `CaptionService` abstract | `lib/features/feed/application/caption_service.dart` | ❌ |
| `FeedController` stub | `lib/features/feed/application/feed_controller.dart` | ❌ |
| `CameraController` stub | `lib/features/feed/application/camera_controller.dart` | ❌ |
| `PostController` stub | `lib/features/feed/application/post_controller.dart` | ❌ |
| Routes: `/home`, `/capture-preview`, `/caption-modal`, `/grid-view` | `lib/core/router/app_router.dart` | ❌ |
| Shared widgets (6 items) | `lib/shared/widgets/` | ❌ |
| TODO markers trên mọi stub | — | ⏳ thêm khi commit |

---

## Open questions — đã chốt hết

| # | Kết luận |
|---|---|
| OQ1 | Icon ↑ = **Share button** → mở bottom sheet "Chia sẻ đến..." |
| OQ2 | "Lịch sử" tap = **chỉ scroll xuống feed** (Option A), không mở dropdown |

---

## Decisions đã chốt

| # | Quyết định |
|---|---|
| 1 | Caption = 7 types (Text/Vị trí/Thời tiết/Nhạc-mock/Sao-mock/Giờ/Streak-TODO) |
| 2 | Không có notification khi đăng ảnh |
| 3 | Feed M2: owner-only. M2+: whereIn max 21 UIDs (giới hạn 20 bạn/user) |
| 4 | Vị trí: Nominatim. Thời tiết: Open-Meteo. Cả 2 free, no API key |
| 5 | Firestore + Storage rules M2: owner-only read, TODO isFriend khi Friend module done |
| 6 | Dual camera: swipe trái trên viewfinder, không phải Tier 2 nữa |
| 7 | Xem ảnh bản thân (3 states) — thuộc Profile module, out of scope |
| 8 | Download tap = icon đổi in-place (download → ✔), không navigate |
| 9 | Camera stop khi scroll xuống feed |
| 10 | Grid tap ảnh → Xem ảnh bạn bè full-screen |
| 11 | Icon ↑ Taskbar feed = Share button → bottom sheet "Chia sẻ đến..." |
| 12 | "Lịch sử" tap = scroll xuống feed (không dropdown) |
| 13 | "Tin nhắn" trong Share Modal → disabled M2, TODO Chat module (Tier 1) |

---

## Risks

- **`camera` package cold start** trên Android low-end: preview lag khi khởi tạo. Mitigation: init camera trong `initState` với `loading` overlay.
- **Storage upload fail mid-way:** Retry logic cần thiết. Mitigation: `UploadTask` với resume support.
- **GPS permission cold start:** Lần đầu request permission → dialog → user deny → caption Vị trí + Thời tiết không hoạt động. Mitigation: graceful fallback về Text type, không crash.
- **Nominatim rate limit:** 1 req/giây. Mitigation: cache kết quả geocode trong session (không gọi lại nếu vị trí chưa đổi đáng kể).
- **Open-Meteo cold start:** API call mất 200-500ms. Mitigation: hiển thị loading spinner trong Note pill.
- **Feed empty state (M2):** Vì owner-only, khi user chưa post gì → feed rỗng. Cần empty state widget.
