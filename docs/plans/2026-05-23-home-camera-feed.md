# Plan: Home / Camera / Feed / Post Module

> **Phụ thuộc vào:** Friend — `isFriend()` rule helper, `FriendRepository`; Settings — `BlockRepository` (feed filter loại bỏ blocked users)
> **Được phụ thuộc bởi:** Notification (Post model, `onPostCreated` CF), Reaction (Post model, reactions subcollection), Profile (PhotoGrid), Space (FeedScreen + Post model + spaceId field), Streak (PostRepository), Widget (feed subcollection)
> **Spec:** `docs/specs/2026-05-22-home-camera-feed.md`
> **Tier:** T0 — Milestone M2

---

## PART 1 — Contract artifacts (ThienPDM merge vào `develop` TRƯỚC khi giao dev)

| File path | Type | Key contents |
|-----------|------|-------------|
| `lib/features/feed/data/post.dart` | freezed model | `postId String`, `authorId String`, `authorName String`, `authorAvatarUrl String?`, `imageUrl String`, `caption String?` (≤200), `captionType CaptionType?` enum, `audienceType AudienceType` (all/select), `audienceUids List<String>`, `spaceId String?`, `createdAt DateTime` |
| `lib/features/feed/data/post_repository.dart` | abstract class | `Future<void> createPost(Post post)`, `Stream<List<Post>> watchFeed(FeedFilter filter)`, `Future<void> deletePost(String postId)`, `Future<List<Post>> getPostsByAuthor(String uid, {DocumentSnapshot? cursor})` |
| `lib/features/feed/data/storage_repository.dart` | abstract class | `Future<String> uploadImage(String uid, String postId, File file)`, `Future<void> deleteImage(String imageUrl)` |
| `lib/features/feed/application/caption_service.dart` | abstract class | `Future<String> resolve(CaptionType type)` |
| `lib/features/feed/application/feed_controller.dart` | Riverpod stub | `FeedState` (posts, filter, isLoading, isLoadingMore, cursor), `FeedFilter` enum (all/person/space) |
| `lib/features/feed/application/app_camera_controller.dart` | Riverpod stub | `CameraState` (isInitialized, isCapturing, flashMode, zoomLevel) |
| `lib/features/feed/application/post_controller.dart` | Riverpod stub | `PostState` (isUploading, progress, error?) |
| `lib/shared/widgets/app_camera_button.dart` | shared widget | 82×82, inner white 70×70, outer Turquoise/500 ring |
| `lib/shared/widgets/app_note_pill.dart` | shared widget | `cornerRadius 30`, bg `#39404166`, editable |
| `lib/shared/widgets/app_act_text_bar.dart` | shared widget | M2: render disabled. M3: inject `ReactionController` |
| `lib/shared/widgets/post_card.dart` | shared widget | 400×400, cornerRadius 50, Note overlay |
| `lib/shared/widgets/share_modal.dart` | shared widget | Bottom sheet: share targets + actions |
| `lib/features/feed/presentation/home_screen.dart` | widget stub | `CustomScrollView` với Camera + Feed sections |
| `lib/features/home/presentation/photo_action_sheet.dart` | **shared widget** — owned by Feed, used by Settings | "Chia sẻ đến..." overlay: Row 1 (Chia sẻ/Messenger/Instagram/Tin nhắn-disabled) + Row 2 (Báo cáo-stub/Chặn/Lưu/Xoá-if-author). Xoá chỉ hiện khi `isAuthor`. [Báo cáo] → toast "Tính năng sắp có". [Chặn] → `BlockConfirmDialog` từ Settings |
| `firebase/functions/src/index.ts` | CF stubs | `onPostCreated`, `onPostDeleted` |

> `FeedFilter.space(spaceId)` được thêm khi Space module implement — field đã reserve trong enum.

---

## PART 2 — Tasks

---
**T1 · feat(feed): data layer — FirebasePostRepository + FirebaseStorageRepository**

| | |
|---|---|
| Assignee | TBD |
| Estimate | M (~8h) |
| Branch | `feat/TBD/feed-data-layer` |
| Blocked by | contracts Part 1 |

Files:
- `lib/features/feed/data/firebase_post_repository.dart` — impl `PostRepository`: `createPost` (Firestore set), `watchFeed` (query `/users/{uid}/feed` subcollection, fetch `/posts/{postId}`), `deletePost`, `getPostsByAuthor` (cursor pagination)
- `lib/features/feed/data/firebase_storage_repository.dart` — impl `StorageRepository`
- `test/features/feed/firebase_post_repository_test.dart` — test: createPost doc tạo đúng fields, watchFeed trả đúng filter, deletePost xóa doc, upload >5MB → reject

Acceptance criteria:
- [ ] `watchFeed` query `/users/{uid}/feed` ORDER BY `createdAt DESC` — không query `/posts` trực tiếp (fan-out architecture)
- [ ] `FeedFilter.person(specificUid)` → thêm `.where('authorId', isEqualTo, specificUid)` vào feed query
- [ ] `createPost` với `audienceType == 'select'` và `audienceUids.isEmpty` → throw `AppError`
- [ ] `uploadImage` nhận file đã compressed (compress là trách nhiệm của `PostController`, không phải repository) — repository chỉ validate size ≤5MB rồi upload
- [ ] Upload file > 5MB → throw `AppError` trước khi gọi Firebase Storage
- [ ] `deletePost` không cascade xóa Storage (CF `onPostDeleted` làm việc này)

Cross-module imports: None

---
**T2 · feat(feed): CaptionService — Text + Location + Weather + Time + Mock**

| | |
|---|---|
| Assignee | TBD |
| Estimate | M (~8h) |
| Branch | `feat/TBD/feed-caption-service` |
| Blocked by | contracts Part 1 |

Files:
- `lib/features/feed/application/caption_service_impl.dart` — impl 7 types
- `lib/features/feed/application/weather_code_mapper.dart` — WMO → emoji + text mapping
- `test/features/feed/caption_service_test.dart` — test: Text passthrough, Time format HH:mm, Location Nominatim mock, Weather OpenMeteo mock + WMO mapping, GPS denied → fallback

Acceptance criteria:
- [ ] `CaptionType.text`: passthrough `TextEditingController.text`
- [ ] `CaptionType.location`: GPS → Nominatim `GET /reverse?lat&lon&format=json&accept-language=vi` → trim thành "Quận X, TP.HCM"
- [ ] `CaptionType.weather`: GPS → Open-Meteo `GET /v1/forecast?latitude&longitude&current_weather=true` → WMO code + temp → "☀️ Nắng 32°C"
- [ ] `CaptionType.time`: `DateTime.now()` local timezone → `DateFormat('HH:mm').format(now)`
- [ ] GPS `permission-denied` → tự động fallback sang `CaptionType.text`, không crash
- [ ] Nominatim/Open-Meteo timeout >5s → hiện fallback text `"📍 ..."` / `"🌤️ ..."`, không block

Cross-module imports: None

---
**T3 · feat(feed): AppCameraController + CameraSection UI**

| | |
|---|---|
| Assignee | TBD |
| Estimate | L (2 ngày) |
| Branch | `feat/TBD/feed-camera-section` |
| Blocked by | contracts Part 1 |

Files:
- `lib/features/feed/application/app_camera_controller.dart` — full impl: initialize, capture, flip, flash, zoom, dispose
- `lib/features/feed/presentation/widgets/camera_section.dart` — viewfinder 400×400 + controls (Figma `440:1767`)
- `lib/features/feed/presentation/home_screen.dart` — `CustomScrollView`: `SliverToBoxAdapter` (CameraSection) + `SliverList` (FeedSection)
- `test/features/feed/app_camera_controller_test.dart` — test: double-tap capture → disabled until navigate, GPS fallback

Acceptance criteria:
- [ ] `AppCameraController` (không phải `CameraController` — tránh conflict với `camera` package)
- [ ] Tap capture → disable button ngay lập tức cho đến khi navigate xong (tránh double submission)
- [ ] Swipe TRÁI trên viewfinder → Dual Camera mode
- [ ] Camera stop preview khi scroll xuống feed (`ScrollController` listener)
- [ ] Camera không khởi động được (quyền) → `CameraPermissionScreen`, không crash
- [ ] Tap "Lịch sử" → `scrollController.animateTo(cameraHeight)` xuống feed

Cross-module imports: None (camera section không import từ Friend module trực tiếp; friend data được FeedController inject qua FriendRepository ở T4/T6)

---
**T4 · feat(feed): CapturePreviewScreen — caption cycle + audience selector + send + save local**

| | |
|---|---|
| Assignee | TBD |
| Estimate | L (2 ngày) |
| Branch | `feat/TBD/feed-capture-preview` |
| Blocked by | T2, T3 |

Files:
- `lib/features/feed/presentation/capture_preview_screen.dart` — full impl (Figma `442:2319`)
- `lib/features/feed/presentation/caption_preset_modal.dart` — 7 caption types grid (Figma `269:1747`)
- `test/features/feed/capture_preview_screen_test.dart` — widget tests: swipe caption → cycle 7 types, audience "Tất cả" default, tap download → icon changes in-place

Acceptance criteria:
- [ ] Swipe trái/phải trên Note pill → cycle qua 7 caption types theo thứ tự
- [ ] Tap `sparkles+` → `CaptionPresetModal` bottom sheet hiện 7 types (Figma `269:1747`)
- [ ] "Tất cả" button selected by default, avatar circles từng friend có thể toggle select/deselect
- [ ] `audienceType == 'select'` và 0 friend chọn → nút "Đăng" disabled
- [ ] Tap download → icon đổi in-place (download → ✔), ảnh lưu gallery, ở lại preview (Figma `579:1575`)
- [ ] Tap X → về Camera, không upload gì

Cross-module imports: `FriendRepository.getFriendUids()` từ **friend** (hiển thị audience avatars)

---
**T5 · feat(feed): PostController.createPost — compress + upload Storage + Firestore**

| | |
|---|---|
| Assignee | TBD |
| Estimate | M (~8h) |
| Branch | `feat/TBD/feed-post-controller` |
| Blocked by | T1, T4 |

Files:
- `lib/features/feed/application/post_controller.dart` — full impl: `createPost(File photo, PostDraft draft)`
- `test/features/feed/post_controller_test.dart` — test: compress → upload → Firestore, Storage fail → không tạo Firestore doc, OOM compress → toast error

Acceptance criteria:
- [ ] Compress ảnh ≤ 1MB, maxWidth 1080px bằng `flutter_image_compress` trước khi upload
- [ ] Upload fail → toast "Tải ảnh thất bại — thử lại", KHÔNG tạo Firestore doc
- [ ] Compress fail (OOM) → toast "Không thể xử lý ảnh", về Camera
- [ ] `audienceType == 'all'` → `audienceUids = []` (không lưu empty với all)
- [ ] Post tạo xong → navigate về Camera (không hiện post ngay lập tức — chờ CF fan-out feed)

Cross-module imports: None

---
**T6 · feat(feed): FeedController — fan-out query + cursor pagination + FeedFilter**

| | |
|---|---|
| Assignee | TBD |
| Estimate | M (~8h) |
| Branch | `feat/TBD/feed-controller` |
| Blocked by | T1 |

Files:
- `lib/features/feed/application/feed_controller.dart` — full impl: `loadFeed(FeedFilter)`, `loadNextPage()`, `onItemVisible(int index)` (prefetch tại index `length - 4`)
- `test/features/feed/feed_controller_test.dart` — test: loadFeed trả đúng 10 posts, loadNextPage append, filter person → đúng authorId, prefetch trigger đúng index

Acceptance criteria:
- [ ] Query `/users/{uid}/feed` ORDER BY `createdAt DESC` LIMIT 10, `startAfterDocument` cho cursor
- [ ] Prefetch: `onItemVisible(index)` khi `index == currentItems.length - 4` → `loadNextPage()`
- [ ] `FeedFilter.all` → không filter thêm; `FeedFilter.person(uid)` → `.where('authorId', isEqualTo, uid)`
- [ ] Feed load fail (offline) → hiện cached posts từ `cached_network_image`; error banner
- [ ] Hết list → "Đã hiển thị tất cả", không call thêm

Cross-module imports: `BlockRepository` từ **settings** (filter blocked user posts khỏi feed)

---
**T7 · feat(feed): FeedSection UI — PostCard (friend + own) + ActText bar M2**

| | |
|---|---|
| Assignee | TBD |
| Estimate | M (~8h) |
| Branch | `feat/TBD/feed-section-ui` |
| Blocked by | T6 |

Files:
- `lib/features/feed/presentation/widgets/feed_section.dart` — `SliverList` của PostCards
- `lib/features/feed/presentation/widgets/friend_post_card.dart` — ảnh + caption + `[Tên bạn] [time ago]` + `ActTextBar` (disabled M2)
- `lib/features/feed/presentation/widgets/own_post_card.dart` — ảnh + caption + `"Bạn [ngày]"` + "✨ Chưa có hoạt động nào!" pill
- `lib/shared/widgets/app_act_text_bar.dart` — M2: render "Gửi tin nhắn..." + 3 emoji + smile-plus, **disabled** no-op
- `test/features/feed/feed_section_test.dart` — widget tests: OwnPostCard "Chưa có HĐ" pill, FriendPostCard hiện đúng label, tap post của người unfriend → ẩn (permission-denied)

Acceptance criteria:
- [ ] `FriendPostCard`: ảnh 400×400, `Note` overlay, label `"[Tên bạn] [time ago]"`, ActText bar disabled
- [ ] `OwnPostCard`: ảnh 400×400, `"Bạn [ngày]"`, pill "✨ Chưa có hoạt động nào!" (M2)
- [ ] Tap post của người unfriend → Firestore `permission-denied` → ẩn card, không crash
- [ ] `ActTextBar` M2: render UI nhưng mọi interaction là no-op (disabled)
- [ ] `FriendsButton` dropdown kết hợp với `FeedController.setFilter()` → title đổi

Cross-module imports: None

---
**T8 · feat(feed): GridViewScreen + ShareModal**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/feed-grid-share` |
| Blocked by | T7 |

Files:
- `lib/features/feed/presentation/grid_view_screen.dart` — 3-column grid (Figma `580:2883`), tap → FriendPostCard full-screen
- `lib/shared/widgets/share_modal.dart` — basic share (Figma `580:2813`): Chia sẻ + Messenger + Instagram + Tin nhắn (disabled) + [Lưu] + [Xoá] (chỉ khi `isAuthor`)
- `lib/features/home/presentation/photo_action_sheet.dart` — full action sheet (Figma `605:1769`): share row + [Báo cáo(stub)] + [Chặn → BlockConfirmDialog] + [Lưu] + [Xoá if author]. Trigger: tap ↑ icon khi đang xem ảnh bạn
- `test/features/feed/grid_view_screen_test.dart` — widget tests: grid 3 columns, tap → detail view

Acceptance criteria:
- [ ] Grid: 3-column layout, `cached_network_image`, FriendsButton filter giữ nguyên
- [ ] Tap ảnh → Xem ảnh bạn bè full-screen (nếu filter = bản thân → TODO Profile module)
- [ ] ShareModal: [Xoá] chỉ hiện khi `post.authorId == currentUid`
- [ ] "Tin nhắn" trong ShareModal → disabled M2 (Chat module T1 stretch)
- [ ] `PhotoActionSheet` (tab ↑ trên ảnh bạn): [Báo cáo] → toast "Tính năng sắp có" (stub); [Chặn] → `BlockConfirmDialog` từ **Settings module** + gọi `BlockRepository.blockUser()`

Cross-module imports: `BlockConfirmDialog` từ **settings**

---
**T9 · feat(feed): CF `onPostCreated` — feed fan-out + postCount increment + FCM to friends**

| | |
|---|---|
| Assignee | TBD |
| Estimate | L (2 ngày) |
| Branch | `feat/TBD/feed-cf-post-created` |
| Blocked by | contracts Part 1 |

Files:
- `firebase/functions/src/feed/onPostCreated.ts` — Firestore onCreate trigger `/posts/{postId}`
- `firebase/functions/test/feed/onPostCreated.test.ts` — test: fan-out đúng recipients, audienceType all vs select, spaceId field preserved, postCount increment, FCM gọi đúng số tokens

Acceptance criteria:
- [ ] `audienceType == 'all'`: đọc `/friendships` arrayContains `authorId` → fan-out feed cho tất cả friends — **chỉ khi `post.spaceId == null`**
- [ ] `audienceType == 'select'`: fan-out chỉ cho `audienceUids` list — **chỉ khi `post.spaceId == null`**
- [ ] **Guard Space posts:** nếu `post.spaceId != null` → skip friend fan-out (Space module CF `onSpacePostCreated` owns fan-out cho Space posts); vẫn increment `postCount`
- [ ] Feed doc: `{ postId, authorId, spaceId?, createdAt }` — phải include `spaceId` field (Space filter dùng)
- [ ] Increment `postCount` trên `/users/{authorId}` (FieldValue.increment(1)) — cho CẢ all-friends VÀ Space posts
- [ ] FCM fan-out: gửi notification cho friends có FCM token — **chỉ khi `post.spaceId == null`** (Space FCM handled by `onSpacePostCreated`)
- [ ] **1 function duy nhất** — không tạo function riêng trong notification.md (xem [H10] trong spec)

Cross-module imports: None (Admin SDK, nhưng đọc `/users/{uid}/fcmTokens` schema từ Notification module)

---
**T10 · feat(feed): CF `onPostDeleted` — feed cleanup + Storage delete + postCount decrement**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `feat/TBD/feed-cf-post-deleted` |
| Blocked by | T9 |

Files:
- `firebase/functions/src/feed/onPostDeleted.ts` — Firestore onDelete trigger `/posts/{postId}`
- `firebase/functions/test/feed/onPostDeleted.test.ts` — test: feed docs xóa, Storage file xóa, postCount decrement

Acceptance criteria:
- [ ] Batch delete tất cả `/users/{uid}/feed/{postId}` docs (tất cả recipients)
- [ ] Decrement `postCount` trên `/users/{authorId}`
- [ ] Xóa Storage file: parse path từ `post.imageUrl` → `posts/{uid}/{postId}/photo.jpg`
- [ ] Xóa reactions subcollection `/posts/{postId}/reactions/*` (batch)

Cross-module imports: None

---
**T11 · test(feed): Firestore rules + Storage rules tests**

| | |
|---|---|
| Assignee | TBD |
| Estimate | S (~4h) |
| Branch | `test/TBD/feed-rules` |
| Blocked by | T1, T9 |

Files:
- `firebase/functions/test/rules/feed.rules.test.ts`

Acceptance criteria:
- [ ] `/posts/{id}`: author read ✓, recipient (có feed doc) read ✓, user không trong feed ✗
- [ ] `/posts/{id}`: create với `caption > 200 chars` ✗; create by author ✓
- [ ] `/posts/{id}`: update → ✗ (posts bất biến sau khi tạo)
- [ ] `/users/{uid}/feed/{postId}`: owner read ✓, stranger read ✗, client write → ✗ (CF only)
- [ ] Storage `/posts/{uid}/...`: owner write ✓, >5MB ✗, non-image ✗
- [ ] Storage `/posts/{uid}/...`: read bởi author ✓, read bởi user có feed doc ✓, stranger ✗

Cross-module imports: None

---

## PART 3 — Dependency graph

```
contracts Part 1 → T1 → T5 → (check T4 done) → navigate Post → Camera
contracts Part 1 → T2 → (parallel T3)
T1, T2, T3 → T4
T1 → T6 → T7 → T8
contracts Part 1 → T9 → T10 → T11
```

T2 (CaptionService) và T3 (Camera) có thể chạy song song sau contracts.
T9, T10 (Cloud Functions) có thể chạy song song với T1-T8 (Flutter).

---

## PART 4 — Open questions

Tất cả đã resolved trong spec. 

> **Note cross-module:** `onFriendshipDeleted` CF (cross-feed cleanup) được implement tại **Friend module T6** — Feed module KHÔNG tạo CF riêng.
> **Note Space:** Khi Space module bắt đầu, cần leader gate thêm `spaceId` param vào `FeedScreen` và `FeedFilter.space(spaceId)` — xem Space spec §Cross-module contract.
