# scripts/modules/feed.ps1
# Module: Home / Camera / Feed | Owner: KhoaLND | M2

function Create-FeedModule {
    $parentBody = @'
> **Tier:** T0 | **Milestone:** M2 | **Assignee:** KhoaLND
> **Spec:** `docs/specs/2026-05-22-home-camera-feed.md`
> **Plan:** `docs/plans/2026-05-23-home-camera-feed.md`
> **Todo:** `tasks/todo-home-camera-feed.md`
> **Phụ thuộc vào:** Friend (isFriend() rule, FriendRepository audience avatars), Settings (BlockRepository feed filter)
> **Được phụ thuộc bởi:** Notification (onPostCreated CF), Reaction (Post model), Profile (PhotoGrid), Space (FeedScreen + Post.spaceId), Widget (feed subcollection)

## Mục tiêu
Camera 400×400 + chụp ảnh + caption cycle 7 loại + đăng bài + feed fan-out + GridView. Đây là core feature của Meep.

## Data model — `/posts/{postId}`
```
postId, authorId, authorName, authorAvatarUrl?, imageUrl,
caption?, captionType? (text/location/weather/music/star/time/streak),
audienceType (all/select), audienceUids List<String>,
spaceId String?,  ← Space module dùng, phải reserve
createdAt
```
Feed: `/users/{uid}/feed/{postId}` — fan-out subcollection, query ORDER BY createdAt DESC.

## Contract artifacts (ThienPDM đã merge qua LX5)
- `lib/features/feed/data/post.dart`, `post_repository.dart`, `storage_repository.dart`
- `lib/features/feed/application/caption_service.dart`, `feed_controller.dart`, `app_camera_controller.dart`, `post_controller.dart`
- `lib/shared/widgets/` — `app_camera_button`, `app_note_pill`, `app_act_text_bar` (M2 disabled stub), `post_card`, `share_modal`
- `lib/features/feed/presentation/home_screen.dart` — stub
- `lib/features/home/presentation/photo_action_sheet.dart` — stub (owned by Feed, dùng bởi Settings)
- CF stubs: `onPostCreated`, `onPostDeleted`

## Figma refs
- HomeScreen: `440:1767` (camera topbar), `580:2883` (GridView), `580:2813` (ShareModal)
- CapturePreview: `442:2319`, CaptionPresetModal: `269:1747`
- PhotoActionSheet: `605:1769`
'@

    $subs = @(
        @{
            title = "[Feed] T1 — FirebasePostRepository + FirebaseStorageRepository"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-home-camera-feed.md` — Task T1
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/feed-data-layer`
> **Bị block bởi:** LX5 contracts đã merge

## Files cần tạo
- `lib/features/feed/data/firebase_post_repository.dart`
- `lib/features/feed/data/firebase_storage_repository.dart`
- `test/features/feed/data/firebase_post_repository_test.dart`

## Acceptance criteria
- [ ] `watchFeed` query `/users/{uid}/feed` ORDER BY `createdAt DESC` — **KHÔNG** query `/posts` trực tiếp (fan-out architecture)
- [ ] `FeedFilter.person(specificUid)` → thêm `.where('authorId', isEqualTo, uid)` vào feed query
- [ ] `createPost` với `audienceType == 'select'` và `audienceUids.isEmpty` → throw `AppError`
- [ ] `uploadImage` chỉ validate size ≤5MB rồi upload — compress là trách nhiệm `PostController`, không phải repository
- [ ] Upload file >5MB → throw `AppError` trước khi gọi Firebase Storage
- [ ] `deletePost` **KHÔNG** cascade xóa Storage (CF `onPostDeleted` làm)
- [ ] `flutter test test/features/feed/data/` — 0 failures

## Definition of Done
- [ ] Tests PASS (fake_cloud_firestore)
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Feed] T2+3 — CaptionService + AppCameraController + CameraSection UI"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-home-camera-feed.md` — Task T2, T3
> **Estimate:** L (2 ngày) | **Branch:** `feat/<DevName>/feed-camera`
> **Bị block bởi:** LX5 contracts đã merge (song song với T1)
> **Figma:** Camera section `440:1767`

## Files cần tạo
- `lib/features/feed/application/caption_service_impl.dart` — impl 7 CaptionType
- `lib/features/feed/application/weather_code_mapper.dart` — WMO code → emoji + text
- `lib/features/feed/application/app_camera_controller.dart` — full impl
- `lib/features/feed/presentation/widgets/camera_section.dart` — viewfinder 400×400 + controls
- `test/features/feed/application/caption_service_test.dart`

## Acceptance criteria — CaptionService
- [ ] `CaptionType.location`: GPS → Nominatim `GET /reverse?lat&lon&format=json&accept-language=vi` → "Quận X, TP.HCM"
- [ ] `CaptionType.weather`: GPS → Open-Meteo `GET /v1/forecast?...&current_weather=true` → WMO + temp → "☀️ Nắng 32°C"
- [ ] `CaptionType.time`: `DateFormat('HH:mm').format(DateTime.now())`
- [ ] GPS denied → fallback sang `CaptionType.text`, không crash
- [ ] Nominatim/Open-Meteo timeout >5s → fallback text, không block

## Acceptance criteria — AppCameraController
- [ ] Class tên là `AppCameraController` (**KHÔNG** phải `CameraController` — tránh conflict với camera package)
- [ ] Tap capture → disable button ngay lập tức đến khi navigate xong (tránh double submission)
- [ ] Swipe TRÁI trên viewfinder → Dual Camera mode
- [ ] Camera stop preview khi scroll xuống feed (`ScrollController` listener)
- [ ] Camera permission denied → `CameraPermissionScreen`, không crash

## Definition of Done
- [ ] Caption tests PASS (mock HTTP)
- [ ] Manual: camera preview đúng trên emulator
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Feed] T4 — CapturePreviewScreen"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-home-camera-feed.md` — Task T4
> **Estimate:** L (2 ngày) | **Branch:** `feat/<DevName>/feed-capture-preview`
> **Bị block bởi:** {sub1} — T2+3 done; {sub3} — T5+6 phải done (cần PostController)
> **Figma:** `442:2319` (preview), `269:1747` (CaptionPresetModal)

## Files cần tạo
- `lib/features/feed/presentation/capture_preview_screen.dart`
- `lib/features/feed/presentation/caption_preset_modal.dart` — grid 7 caption types

## Acceptance criteria
- [ ] Swipe trái/phải trên Note pill → cycle qua 7 caption types
- [ ] Tap `sparkles+` → `CaptionPresetModal` bottom sheet (Figma `269:1747`)
- [ ] "Tất cả" button selected by default; avatar circles từng friend toggle select/deselect
- [ ] `audienceType == 'select'` với 0 friend chọn → nút "Đăng" disabled
- [ ] Tap download → icon đổi in-place (download → ✔), ảnh lưu gallery, ở lại preview (Figma `579:1575`)
- [ ] Tap X → về Camera, không upload

## Cross-module imports
- `FriendRepository.getFriendUids()` từ **friend** (audience avatars)

## Definition of Done
- [ ] Manual: chụp → preview → cycle caption → đăng → feed hiện
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Feed] T5+6 — PostController.createPost + FeedController"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-home-camera-feed.md` — Task T5, T6
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/feed-controllers`
> **Bị block bởi:** {sub0} — T1 phải done

## Files cần tạo
- `lib/features/feed/application/post_controller.dart` — impl `createPost(File photo, PostDraft draft)`
- `lib/features/feed/application/feed_controller.dart` — `FeedState`, `loadFeed`, `loadNextPage`, `onItemVisible`
- `test/features/feed/application/post_controller_test.dart`
- `test/features/feed/application/feed_controller_test.dart`

## Acceptance criteria — PostController
- [ ] Compress ảnh ≤1MB, maxWidth 1080px bằng `flutter_image_compress` trước khi upload
- [ ] Upload fail → toast "Tải ảnh thất bại — thử lại", **KHÔNG** tạo Firestore doc
- [ ] Compress fail (OOM) → toast, về Camera
- [ ] `audienceType == 'all'` → `audienceUids = []` (không lưu empty với all)
- [ ] Post tạo xong → navigate về Camera (chờ CF fan-out feed)

## Acceptance criteria — FeedController
- [ ] Query `/users/{uid}/feed` ORDER BY `createdAt DESC` LIMIT 10, cursor-based
- [ ] Prefetch: `onItemVisible(index)` khi `index == currentItems.length - 4` → `loadNextPage()`
- [ ] `FeedFilter.all` / `FeedFilter.person(uid)` hoạt động đúng
- [ ] Feed load fail → hiện cached posts + error banner
- [ ] `flutter test test/features/feed/application/` — 0 failures

## Cross-module imports
- `BlockRepository` từ **settings** (filter blocked user posts)

## Definition of Done
- [ ] Tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Feed] T7+8 — FeedSection UI + GridViewScreen + PhotoActionSheet"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-home-camera-feed.md` — Task T7, T8
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/feed-ui`
> **Bị block bởi:** {sub3} — T5+6 phải done
> **Figma:** FeedSection PostCards, GridView `580:2883`, PhotoActionSheet `605:1769`

## Files cần tạo
- `lib/features/feed/presentation/widgets/feed_section.dart` — SliverList
- `lib/features/feed/presentation/widgets/friend_post_card.dart` — ảnh + caption + label + ActTextBar M2 disabled
- `lib/features/feed/presentation/widgets/own_post_card.dart` — ảnh + "Bạn [ngày]" + "✨ Chưa có HĐ nào!" pill
- `lib/features/feed/presentation/grid_view_screen.dart` — 3-column (Figma `580:2883`)
- `lib/shared/widgets/share_modal.dart` — full impl
- `lib/features/home/presentation/photo_action_sheet.dart` — full impl (Figma `605:1769`)

## Acceptance criteria
- [ ] `FriendPostCard`: ảnh 400×400, Note overlay, `ActTextBar` M2 disabled (no-op)
- [ ] `OwnPostCard`: ảnh 400×400, pill "✨ Chưa có HĐ nào!" (M2)
- [ ] Tap post người unfriend → `permission-denied` → ẩn card, không crash
- [ ] `ShareModal`: [Xóa] chỉ hiện khi `post.authorId == currentUid`
- [ ] `PhotoActionSheet` → [Báo cáo] toast "Tính năng sắp có"; [Chặn] → `BlockConfirmDialog` từ **settings**

## Cross-module imports
- `BlockConfirmDialog` từ **settings**

## Definition of Done
- [ ] Manual: feed load, OwnPost delete, GridView, Share, PhotoActionSheet
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Feed] T9+10 — CF onPostCreated + onPostDeleted"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-home-camera-feed.md` — Task T9, T10
> **Estimate:** L (2 ngày) | **Branch:** `feat/<DevName>/feed-cloud-functions`
> **Bị block bởi:** LX5 contracts (song song với T1-T8)

## Files cần tạo
- `firebase/functions/src/feed/onPostCreated.ts` — Firestore onCreate `/posts/{postId}`
- `firebase/functions/src/feed/onPostDeleted.ts` — Firestore onDelete
- Tests tương ứng

## Acceptance criteria — `onPostCreated`
- [ ] `audienceType == 'all'`: fan-out `/users/{friendUid}/feed/{postId}` cho tất cả friends — **chỉ khi `spaceId == null`**
- [ ] `audienceType == 'select'`: fan-out chỉ cho `audienceUids` — **chỉ khi `spaceId == null`**
- [ ] **Guard Space posts:** `spaceId != null` → skip friend fan-out (Space module `onSpacePostCreated` owns)
- [ ] Feed doc phải có `spaceId` field (Space filter dùng)
- [ ] Increment `postCount` trên `/users/{authorId}` — cho cả all-friends VÀ Space posts
- [ ] FCM fan-out cho friends có token — **chỉ khi `spaceId == null`**
- [ ] **1 function duy nhất** — Notification module không tạo CF riêng cho new_post

## Acceptance criteria — `onPostDeleted`
- [ ] Batch delete tất cả `/users/{uid}/feed/{postId}` docs
- [ ] Decrement `postCount` trên `/users/{authorId}`
- [ ] Xóa Storage file: parse path từ `post.imageUrl`
- [ ] Xóa reactions subcollection `/posts/{postId}/reactions/*`
- [ ] `npm test` PASS

## Definition of Done
- [ ] `npm test` + `npm run lint` PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Feed] T11 — Firestore + Storage rules tests"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-home-camera-feed.md` — Task T11
> **Estimate:** S (~4h) | **Branch:** `test/<DevName>/feed-rules`
> **Bị block bởi:** {sub0} — T1 done; {sub5} — T9+10 done

## File cần tạo
- `firebase/functions/test/rules/feed.rules.test.ts`

## Acceptance criteria
- [ ] `/posts/{id}`: author read ✓, recipient (có feed doc) read ✓, user không trong feed ✗
- [ ] `/posts/{id}`: create với `caption > 200 chars` ✗; update → ✗ (posts bất biến)
- [ ] `/users/{uid}/feed/{postId}`: owner read ✓, stranger read ✗, client write → ✗ (CF only)
- [ ] Storage `/posts/{uid}/...`: owner write ✓, >5MB ✗, non-image ✗, stranger read ✗

## Definition of Done
- [ ] Rules tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        }
    )

    New-Module "📸 [Home / Camera / Feed]" $parentBody $KhoaLND 2 $subs
}
