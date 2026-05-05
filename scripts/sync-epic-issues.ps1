<#
.SYNOPSIS
  Sync 13 Epic issues với modules.md đã LOCKED (2026-05-03).

.DESCRIPTION
  - Update title + body 12 issues cũ (#1-#12)
  - Tạo Epic #14 (Chat) nếu chưa tồn tại
  - Assign #14 vào milestone M2 + add vào Project #2
  - Idempotent: re-run safe

.EXAMPLE
  pwsh ./scripts/sync-epic-issues.ps1
#>

$ErrorActionPreference = 'Stop'

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$userToken = [System.Environment]::GetEnvironmentVariable("GH_TOKEN", "User")
if ($userToken) { $env:GH_TOKEN = $userToken }

$REPO = "manhthien2005/Meep"
$PROJECT_NUMBER = 2

# ============================================================
# HELPERS
# ============================================================

function Render-Body {
    param(
        [string]$TierLabel, [string]$Milestone, [string]$Feature,
        [string]$Summary, [string]$Scope, [string]$Acceptance,
        [string]$Dependencies, [string]$Tests, [string]$FigmaRefs
    )
    $figmaBlock = if ($FigmaRefs) { "`n- Figma: $FigmaRefs" } else { "" }
    return @"
> 📦 **Epic** · $TierLabel · Milestone $Milestone

## 📌 Tóm tắt

$Summary

## 🎯 Phạm vi

$Scope

## ✅ Tiêu chí nghiệm thu

$Acceptance

## 🔗 Phụ thuộc

$Dependencies

## 🧪 Tests bắt buộc viết

$Tests

## 📚 Tài liệu
$figmaBlock
- [Modules catalog](https://github.com/manhthien2005/Meep/blob/develop/docs/product/modules.md)
- [User stories](https://github.com/manhthien2005/Meep/blob/develop/docs/product/user-stories.md)

## 🚦 Workflow (4 phases)

1. **Design:** ``/spec $Feature`` → approve → ``/plan $Feature`` → sub-issues
2. **Implement:** TDD (RED→GREEN→REFACTOR), feature branch ``feature/<Dev>/<desc>``
3. **Review:** ``/review`` 5-axis, PR vào ``develop``, CI pass, ≥1 approve
4. **Verify:** Staging APK smoke test, close Epic khi all sub-issues done

---
📍 [Milestones](https://github.com/manhthien2005/Meep/blob/develop/docs/roadmap/milestones.md) · [Team workflow](https://github.com/manhthien2005/Meep/blob/develop/docs/team-workflow.md)
"@
}

function Update-Issue {
    param([int]$Number, [string]$Title, [string]$Body)
    Write-Host "`n-> Issue #$Number : $Title" -ForegroundColor Cyan
    $tmp = New-TemporaryFile
    try {
        [System.IO.File]::WriteAllText($tmp.FullName, $Body, [System.Text.UTF8Encoding]::new($false))
        gh issue edit $Number --repo $REPO --title $Title --body-file $tmp.FullName 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host "   [OK]" -ForegroundColor Green }
        else { Write-Host "   [FAIL] exit $LASTEXITCODE" -ForegroundColor Red }
    } finally { Remove-Item $tmp.FullName -Force -ErrorAction SilentlyContinue }
}

# ============================================================
# ISSUE DATA — 13 Epic (modules.md LOCKED 2026-05-03)
# ============================================================

Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "SYNC 13 EPIC ISSUES" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

# ---- #1 Auth ----
Update-Issue -Number 1 -Title "[T0] Auth — Đăng ký + Đăng nhập + Forgot + Email verify" -Body (Render-Body `
    -TierLabel "Tier 0 · M1" -Milestone "M1" -Feature "auth" `
    -Summary "Signup 5-step, login email/Google, auto-login, forgot password, email verification lazy+banner. Effort **L** (4-5d)." `
    -Scope @"
- **Signup 5 bước:** email+password → display name → username → skip pic → skip contacts → Feed
- **Login:** email+password, Google OAuth 1-tap Android
- **Auto-login:** Firebase Auth persistence
- **Forgot password:** Firebase hosted reset, link TTL 1h
- **Email verify:** lazy+banner, auto-send, escalation 24h→7d, TTL 72h, resend 1/min
- **Deeplink:** handle reset + verify links
- **Username:** unique, 3-20 ``[a-z0-9_]``, đổi 1/30d
- **Password:** min 8, ≥1 upper + ≥1 num + ≥1 special
- **Default avatar:** chữ cái đầu display name
- **Out of scope:** Apple Sign-In, Phone OTP, Account deletion, 2FA
"@ `
    -Acceptance @"
- [ ] Signup 5 bước < 60s
- [ ] Login email + Google OK
- [ ] Auto-login reopen app
- [ ] Forgot password flow hoàn tất
- [ ] Email verify banner + resend rate limit
- [ ] Username unique check realtime
- [ ] Password policy enforce
- [ ] Tests ≥80% coverage
"@ `
    -Dependencies "Firebase Auth, Cloud Function ``validateUsername``, Firestore ``users``, Riverpod 2" `
    -Tests "Unit: AuthController + Repository + Validators`nWidget: signup forms, verify banner`nIntegration: full flow signup→login→logout`nFunctions: validateUsername`nRules: ``/users/{uid}``" `
    -FigmaRefs "``Dang ky_*.png``, ``Dang nhap_*.png``")

# ---- #2 Friends ----
Update-Issue -Number 2 -Title "[T0] Friends — Mời bạn + Kết bạn + Danh sách bạn" -Body (Render-Body `
    -TierLabel "Tier 0 · M2" -Milestone "M2" -Feature "friend" `
    -Summary "Friend graph: username search, invite link ``meep://{username}``, request lifecycle (send/cancel/accept/decline), unfriend. Effort **M** (3d)." `
    -Scope @"
- Tìm bạn qua username (exact match MVP)
- Invite link ``meep://{username}`` (share_plus)
- Send / cancel / accept / decline friend request
- Request expiry 30 ngày (cron cleanup)
- Duplicate request (A→B + B→A) → auto-accept
- Friend list alphabetical display name + search
- Unfriend: dialog confirm, giữ chat history, không notify
- Pair ID: ``<min_uid>_<max_uid>``
- **Out of scope:** Friend suggestions, mutual friends count
"@ `
    -Acceptance @"
- [ ] Username search exact match
- [ ] Invite link mở app → accept screen
- [ ] Request lifecycle (send/cancel/accept/decline)
- [ ] Expiry 30d cleanup
- [ ] Duplicate → auto-accept
- [ ] Unfriend xoá bidirectional
- [ ] Tests ≥80%
"@ `
    -Dependencies "Cloud Functions: ``sendFriendRequest``, ``acceptFriendRequest``, ``declineFriendRequest``; Firestore: ``friend_requests``, ``friendships``; ``share_plus``, deeplink" `
    -Tests "Unit: FriendController + Repository`nWidget: FriendList, RequestCard, SearchBox`nIntegration: invite→accept→friend list`nFunctions: request lifecycle, pair ID`nRules: ``friend_requests``, ``friendships``")

# ---- #3 Camera ----
Update-Issue -Number 3 -Title "[T0] Camera — Photo + Dual cam + Short video + Caption" -Body (Render-Body `
    -TierLabel "Tier 0 · M2" -Milestone "M2" -Feature "camera" `
    -Summary "Camera đầy đủ: photo 1:1, dual sequential (BeReal), short video 5-10s, caption templates. Effort **XL** (7-9d)." `
    -Scope @"
- **Photo:** 1:1 square viewport, 720p, compress < 500KB JPEG ~80%
- **Dual sequential (BeReal):** back cam → switch ~0.5-1s → front cam → 2 files (main+selfie)
- **Short video:** 5-10s, H.264 720p, client compress (``video_compress``), Cloud Function thumbnail
- **Flip camera:** front/back toggle
- **Flash:** Auto / On / Off
- **Caption templates:** 3-5 preset styles (font+color+bg), 200 chars, overlay preview
- **Gallery pick:** ``image_picker``, cùng compression pipeline
- **Preview trước gửi:** capture → preview + caption → confirm
- **Front camera:** un-mirror (preview mirror, save un-mirror)
- **Permission denied:** dialog giải thích + mở Settings
- **Out of scope:** True multi-camera API đồng thời, filters/AR, stickers, video > 10s
"@ `
    -Acceptance @"
- [ ] Photo 1:1 capture OK, < 500KB
- [ ] Dual sequential: back→front < 1.5s total
- [ ] Video 5-10s record + compress OK
- [ ] Caption templates 3-5 styles render
- [ ] Gallery pick + compression pipeline
- [ ] Preview before send
- [ ] Permission handling graceful
- [ ] Tests ≥70%
"@ `
    -Dependencies "``camera``, ``video_compress``, ``image_picker``, ``path_provider``, ``image``, ``permission_handler``; Cloud Function ``onVideoUploaded``" `
    -Tests "Unit: CameraController, compression, caption validator`nWidget: CaptureButton, FlipButton, CaptionField, PreviewScreen`nIntegration: capture→preview→caption→save`nFunctions: onVideoUploaded thumbnail" `
    -FigmaRefs "``Trang chu.png``")

# ---- #4 Share photo ----
Update-Issue -Number 4 -Title "[T0] Share photo — Upload ảnh/video + Fan-out + Delete" -Body (Render-Body `
    -TierLabel "Tier 0 · M2" -Milestone "M2" -Feature "post" `
    -Summary "Upload photo/video/dual → Storage → metadata Firestore → fan-out FCM. Delete post, offline queue. Effort **L** (4-5d)." `
    -Scope @"
- **Upload photo:** JPEG → ``posts/{uid}/{postId}/photo.jpg``, EXIF strip client-side
- **Upload video:** H.264 → ``posts/{uid}/{postId}/video.mp4``
- **Upload dual:** **2 file riêng** ``main.jpg`` + ``selfie.jpg`` (tap swap trong feed)
- **Resumable upload** + progress indicator + retry 3 lần
- **Post metadata:** authorId, type (``photo``/``video``/``dual``), caption, timestamp, thumbnailUrl
- **Cloud Function ``onPostCreated``:** fan-out FCM friends (≤500/batch)
- **Cloud Function ``onVideoUploaded``:** thumbnail frame 0
- **Delete post:** author delete, soft delete flag, Cloud Function cleanup Storage
- **Offline queue:** ``connectivity_plus``, auto-upload khi có mạng
- **Caption:** text metadata (không burn vào media)
- **Size limit:** photo < 500KB, video < 10MB
- **Destination:** MVP = all friends. Space extend (#10)
- **Out of scope:** Multi-image, edit after share, scheduled, draft
"@ `
    -Acceptance @"
- [ ] Upload photo < 3s (4G)
- [ ] Upload video < 10s
- [ ] Dual 2 files upload OK
- [ ] Fan-out FCM < 10s
- [ ] Delete post soft delete + Storage cleanup
- [ ] Offline queue auto-upload
- [ ] EXIF stripped
- [ ] Tests ≥80%
"@ `
    -Dependencies "Firebase Storage, ``cloud_firestore``, ``connectivity_plus``; Cloud Functions: ``onPostCreated``, ``onVideoUploaded``" `
    -Tests "Unit: PostRepository upload/retry, PostController states`nWidget: UploadProgress, RetryButton`nIntegration: capture→upload→Firestore+Storage verify`nFunctions: onPostCreated fan-out, onVideoUploaded thumbnail`nRules: ``posts``, Storage ``posts/{uid}/**``")

# ---- #5 Feed ----
Update-Issue -Number 5 -Title "[T0] Feed — Full-screen swipe + 3 post types + Space theme" -Body (Render-Body `
    -TierLabel "Tier 0 · M2" -Milestone "M2" -Feature "feed" `
    -Summary "Full-screen PageView (Locket style): photo/video/dual posts, Space theme color indicator, reply→chat. Effort **L** (5-6d)." `
    -Scope @"
- **Layout:** Full-screen PageView swipe up/down, 1 post/lần (Locket style)
- **3 post types:** photo (cached), video (auto-play muted, tap unmute), dual (main+PIP, tap swap)
- **Feed chung:** all friends + spaces chronological. Space post → viền/badge màu Space
- **Feed per Space:** vào Space → chỉ posts Space đó
- **Reply:** nút reply → inbox/chat (không comment MXH). 1-1 → author, Space → group chat
- **Menu "...":** lưu ảnh (photo/dual), delete (author only, soft delete)
- **Caption:** text metadata dưới post
- **Author info:** avatar + display name + timestamp → tap Profile
- **Reaction count** dưới post → tap Reaction flow
- **Cache offline:** 20 bài + images, video thumbnail only
- **Skeleton loader** + empty state
- **RollCall posts:** pin top 24h
- **Out of scope:** Algorithmic ranking, stories, comment thread MXH, seen indicator
"@ `
    -Acceptance @"
- [ ] Full-screen swipe 60fps
- [ ] Video auto-play muted, tap unmute
- [ ] Dual PIP tap swap animation
- [ ] Space posts show theme color
- [ ] Reply → opens chat
- [ ] Offline cache 20 bài
- [ ] Delete post author only
- [ ] Tests ≥70%
"@ `
    -Dependencies "``PageView``, ``cached_network_image``, ``video_player``, ``hive``; Firestore pagination ``startAfter``; Feed depends on Share (#4), Friends (#2), Chat (#14)" `
    -Tests "Unit: FeedController, PaginationState`nWidget: PostCard (3 types), SwipeGesture, EmptyState`nIntegration: load→swipe→pagination`nRules: ``posts`` read by friend" `
    -FigmaRefs "``Trang chu.png``")

# ---- #6 Push notification ----
Update-Issue -Number 6 -Title "[T0] Push notification — FCM Android (7 events + 3 channels)" -Body (Render-Body `
    -TierLabel "Tier 0 · M3" -Milestone "M3" -Feature "notification" `
    -Summary "FCM Android: 7 events (incl. chat), 3 channels (social/chat/rollcall), custom chat sound, deeplink. Effort **L** (4-5d)." `
    -Scope @"
- **FCM token** register + refresh
- **7 events:** friend request received, friend accepted, new post, reaction, RollCall reminder, chat message 1-1, chat message group
- **Deeplink:** tap → mở đúng screen
- **3 states:** foreground (in-app banner), background, terminated
- **3 Android channels:** ``social`` (friend/reaction/post), ``chat`` (custom sound riêng), ``rollcall``
- **Smart suppress:** không notify nếu đang trong đúng conversation
- **Badge count** (unread)
- **Out of scope:** iOS APNs, notification preferences UI, email notify, bundling, DND
"@ `
    -Acceptance @"
- [ ] 7 events trigger OK
- [ ] Deeplink routing chính xác
- [ ] 3 channels tách biệt
- [ ] Chat sound custom riêng
- [ ] In-chat suppress hoạt động
- [ ] Badge count chính xác
"@ `
    -Dependencies "``firebase_messaging``; Cloud Functions per event; Deeplink ``meep://<route>``" `
    -Tests "Unit: NotificationController, DeepLinkHandler`nWidget: in-app banner`nFunctions: fan-out per event, FCM payload`nManual: staging APK 7 events")

# ---- #7 Reaction ----
Update-Issue -Number 7 -Title "[T0] Reaction — Emoji react + Cumulative RollCall" -Body (Render-Body `
    -TierLabel "Tier 0 · M3" -Milestone "M3" -Feature "reaction" `
    -Summary "5 emoji react. Regular post: 1/user/post override. RollCall: cumulative cộng dồn. Double-tap ❤️. Effort **S** (1-2d)." `
    -Scope @"
- **5 emoji:** ❤️😂😮😢😡
- **Regular post:** 1 emoji/user/post, tap lại → override
- **RollCall post:** cumulative (mỗi thả = 1 record, cộng dồn, không giới hạn)
- **Double-tap post:** = ❤️ shortcut
- **Undo react:** tap emoji đang active → remove
- **Animation:** emoji float
- **Count display:** aggregated (emoji + số)
- **Notify author:** push event #4
- **React on video:** có
- **RollCall UI cố định:** button góc phải dưới, emoji góc trái dưới
- **Out of scope:** Custom emoji, reaction comments
"@ `
    -Acceptance @"
- [ ] 5 emoji work, override regular, cumulative RollCall
- [ ] Double-tap = ❤️
- [ ] Undo react
- [ ] Animation smooth
- [ ] Author notified < 10s
- [ ] Tests ≥75%
"@ `
    -Dependencies "Firestore ``posts/{postId}/reactions/{userId}``; Cloud Function ``onReactionAdded``" `
    -Tests "Unit: ReactionController add/update/remove`nWidget: EmojiPicker, ReactionButton, CountBadge`nIntegration: tap→Firestore→count`nFunctions: onReactionAdded notify`nRules: reactions subcollection")

# ---- #8 Widget Android ----
Update-Issue -Number 8 -Title "[T0] Widget Android — Ảnh mới nhất + Space viền + Tap deeplink" -Body (Render-Body `
    -TierLabel "Tier 0 · M3" -Milestone "M3" -Feature "widget" `
    -Summary "Android AppWidget 2x2: ảnh mới nhất, Space viền màu, WorkManager 30min, deeplink. Effort **L** (5d)." `
    -Scope @"
- **Size:** 2x2 MVP
- **Content:** ảnh mới nhất (photo/dual thumbnail, video thumbnail)
- **Space post:** viền màu Space để nhận biết
- **Update:** WorkManager 30 phút, battery saver → 60 phút
- **Tap:** ``meep://feed``
- **Cache:** Glide/Coil local
- **Offline:** cached ảnh cuối + ""Offline"" badge
- **Auth:** blank + ""Đăng nhập Meep"" nếu chưa login
- **Out of scope:** iOS WidgetKit, multiple sizes, per-Space widget, configurable
"@ `
    -Acceptance @"
- [ ] Widget hiển thị ảnh < 5s sau add
- [ ] Update 30min, battery saver 60min
- [ ] Tap → feed screen
- [ ] Offline cached image
- [ ] Auth blank state
- [ ] Space viền màu
"@ `
    -Dependencies "Android AppWidget (Kotlin), WorkManager, ``home_widget``, Glide/Coil" `
    -Tests "Kotlin unit: WidgetProvider, ImageLoader, UpdateWorker`nInstrumentation: render + tap intent`nManual: 3 devs add widget thực tế")

# ---- #9 Diary ----
Update-Issue -Number 9 -Title "[T0+] Diary — Nhật ký text + ảnh + Public/Private toggle" -Body (Render-Body `
    -TierLabel "Tier 0+ · M3" -Milestone "M3" -Feature "diary" `
    -Summary "Diary basic: text + 1-3 ảnh, edit, delete, public/private toggle. NO canvas editor. Effort **M** (3d)." `
    -Scope @"
- **Privacy:** default private, toggle ``isPublic`` (confirm dialog khi public)
- **Public entries:** hiện trên Profile Tab 2 cho bạn bè xem
- **Text:** 1000 chars, plain text
- **Attach ảnh:** 1-3 từ gallery/camera, cùng compression pipeline
- **Layout:** grid entries (thumbnail + date + preview)
- **Detail:** tap → full text + ảnh gallery
- **Edit:** cho edit text + thêm/xoá ảnh
- **Delete:** dialog confirm
- **Sort:** chronological DESC
- **Camera fallback:** chụp không chọn Space → option ""Lưu vào Nhật ký""
- **RollCall archive:** nhận posts 168h auto-archive từ RollCall (#11)
- **Out of scope:** Canvas editor, stickers, voice notes, search diary
"@ `
    -Acceptance @"
- [ ] Create entry text + 1-3 ảnh
- [ ] isPublic toggle + confirm dialog
- [ ] Public entries visible trên Profile bạn bè
- [ ] Edit/delete OK
- [ ] RollCall archive nhận
- [ ] Tests ≥70%
"@ `
    -Dependencies "Firestore ``diary_entries/{uid}/{entryId}``; Storage ``diary/{uid}/``; ``image_picker``" `
    -Tests "Unit: DiaryController CRUD, DiaryRepository`nWidget: DiaryForm, EntryGrid, DeleteDialog`nIntegration: create→edit→delete verify`nRules: owner-only + isPublic friend read" `
    -FigmaRefs "``Nhat ky.png``")

# ---- #10 Space ----
Update-Issue -Number 10 -Title "[T0+] Space — Context switch + Group chat + Broadcasting" -Body (Render-Body `
    -TierLabel "Tier 0+ · M3" -Milestone "M3" -Feature "space" `
    -Summary "Không gian & Kết nối: context switch Camera (theme per Space), auto-broadcast, group chat. Effort **L** (5-6d)." `
    -Scope @"
**Space management:**
- Tạo Space (name + icon preset + color HEX)
- Invite members từ friend list (max 10 MVP)
- Leave Space, Delete (creator only, soft delete), Kick member
- Only invited (không search/discover)

**Context Switch (Camera):**
- Long-press ""Tổng bạn bè"" → bottom sheet danh sách Space
- Chọn Space → Camera UI đổi theme (viền, nút chụp, text = color HEX + icon)

**Broadcasting:**
- Chụp trong Space → auto-broadcast tất cả members
- Post metadata có ``spaceId``

**Group Chat:**
- Reply ảnh Space → Group Chat Space (trong Inbox chung)
- Quote mechanism: thumbnail 200x200 + caption gốc
- Real-time sync members

**Business Rules:**
- BR1: Camera mặc định → chọn Space trước, hoặc → Diary
- BR2: Data isolation Space A ≠ Space B
- BR3: Thumbnail chat 200x200 nén

**Out of scope:** Public discovery, admin hierarchy, custom icon upload, custom hex input
"@ `
    -Acceptance @"
- [ ] Tạo Space với name + icon + color
- [ ] Camera context switch theme change
- [ ] Auto-broadcast members
- [ ] Group chat real-time
- [ ] Quote mechanism thumbnail
- [ ] Data isolation
- [ ] Tests ≥75%
"@ `
    -Dependencies "Firestore: ``spaces``, ``space_members``; Cloud Functions: ``fanoutToSpace``; Camera (#3) context switch; Chat (#14) group" `
    -Tests "Unit: SpaceController, SpaceRepository`nWidget: SpaceList, MemberList, ThemeSwitch`nIntegration: create→invite→share→group chat`nFunctions: fanoutToSpace`nRules: ``spaces`` member-only, ``space_members``")

# ---- #11 RollCall ----
Update-Issue -Number 11 -Title "[T0+] RollCall — Gallery picker + Feed gating + 168h archive" -Body (Render-Body `
    -TierLabel "Tier 0+ · M3" -Milestone "M3" -Feature "rollcall" `
    -Summary "Kết nối tập thể: gallery picker 7 ngày, feed gating (phải post mới xem), 168h archive→Diary, cumulative react. Effort **L** (6d)." `
    -Scope @"
**Trigger:**
- Schedule Friday 8h GMT+7 (MVP fixed)
- 2 entry: push notification deeplink HOẶC icon RollCall góc trên trái

**Content (FR1):**
- Gallery picker: lọc ảnh ``dateCreated`` 7 ngày gần nhất
- Không caption — chỉ ảnh
- Đăng nhanh: chọn → nhấn Đăng (không preview/edit)

**Feed Gating (FR2):**
- Phải post trước mới xem feed RollCall bạn bè
- Chưa post → blur/placeholder + nút kêu gọi

**Cumulative Reaction (FR3):**
- Mỗi thả emoji = 1 record riêng, cộng dồn
- UI cố định: button góc phải dưới, emoji góc trái dưới

**168h Archive (BR4):**
- Post tồn tại 168h trên feed
- Sau 168h → ẩn → tự động chuyển vào Diary (private)
- Cloud Function cron cleanup

**Out of scope:** Custom schedule, video RollCall, multi-photo, caption
"@ `
    -Acceptance @"
- [ ] Cron trigger Friday 8h OK
- [ ] Gallery picker filter 7 ngày
- [ ] Feed gating block/unlock
- [ ] Cumulative react cộng dồn
- [ ] 168h archive → Diary
- [ ] Tests ≥70%
"@ `
    -Dependencies "Cloud Functions: ``scheduleRollCall``, ``archiveRollCall``; ``photo_manager`` gallery; Firestore ``posts`` rollcall flag; Diary (#9) archive target; Reaction (#7) cumulative" `
    -Tests "Unit: RollCallController, gallery filter`nWidget: GatingScreen, GalleryPicker`nIntegration: post→unlock→view→archive`nFunctions: scheduleRollCall, archiveRollCall cron`nManual: wait/force trigger staging")

# ---- #12 Profile ----
Update-Issue -Number 12 -Title "[T0+] Profile — Stats + 2 tabs (Posts + Diary) + Share link" -Body (Render-Body `
    -TierLabel "Tier 0+ · M2" -Milestone "M2" -Feature "profile" `
    -Summary "Profile screen: avatar, stats (posts+friends+spaces), 2 tabs (grid posts + diary public), share link, edit. Effort **M** (3d)." `
    -Scope @"
**Header:**
- Avatar circle, upload + crop 1:1
- Stats row: Bài viết (count) | Người bạn (count) | Space (count)
- Username + Bio (plain text, 100 chars)
- Own: ""Chỉnh sửa"" (edit avatar/name/bio) + ""Chia sẻ trang cá nhân"" (copy ``meep://{username}``)
- Others: Add Friend / Pending / Unfriend button

**2 Tabs:**
- Tab 1 (Grid posts): 3 columns, rounded, tap → Feed fullscreen
- Tab 2 (Diary public): entries ``isPublic: true``, grid (thumbnail + date)

- Username edit: 1 lần/30 ngày
- **Out of scope:** Cover photo, verified badges, profile themes, follower count
"@ `
    -Acceptance @"
- [ ] Avatar upload crop 1:1
- [ ] Stats row 3 counts chính xác
- [ ] Edit avatar/name/bio
- [ ] Share profile link copy
- [ ] Tab 1 grid posts pagination
- [ ] Tab 2 diary public entries
- [ ] Add friend button on others
- [ ] Tests ≥70%
"@ `
    -Dependencies "``image_cropper``; Firestore ``users``, ``posts``, ``diary_entries``; Storage ``avatars/{uid}.jpg``; Auth (#1), Share (#4), Diary (#9), Friends (#2), Space (#10)" `
    -Tests "Unit: ProfileController, ProfileRepository`nWidget: AvatarPicker, BioField, PostGrid, DiaryGrid, StatsRow`nIntegration: edit→save→verify, view other profile`nRules: ``users/{uid}`` public vs private fields" `
    -FigmaRefs "``Trang Profile.png``")

# ============================================================
# ISSUE #14: Chat — CREATE IF NOT EXISTS, ELSE UPDATE
# ============================================================

Write-Host "`n" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "EPIC #14 — Chat (NEW)" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

$chatBody = Render-Body `
    -TierLabel "Tier 0 · M2-M3" -Milestone "M2" -Feature "chat" `
    -Summary "Inbox tin nhắn (Locket style): 1-1 photo-anchored + group chat Space. Reply post → chat. Effort **L** (5-6d)." `
    -Scope @"
**Inbox:**
- List conversations (1-1 + group Space), sort by last message time
- Avatar + name + date + preview text + chevron
- Group: icon Space + color thay avatar
- Unread badge per conversation + total bottom nav
- Pull-to-refresh

**1-1 Chat (photo-anchored):**
- Reply post Feed → thread với author
- Quote mechanism: thumbnail ảnh gốc + caption
- Text only MVP (max 500 chars)
- Real-time Firestore snapshots
- Tạo: chỉ qua reply post hoặc ""Nhắn tin"" trên profile

**Group Chat (Space):**
- Mỗi Space = 1 group chat thread
- Reply post Space → group chat
- Quote thumbnail 200x200 + caption
- All members tham gia

**Messages:**
- Text max 500 chars, timestamp
- Auto-scroll bottom, load older 30/page scroll up
- Offline cache: 20 conversations + 30 messages
- Delete conversation: ẩn (không xoá data), group không xoá

**Out of scope:** Typing indicator, read receipts, image/video in chat, edit/delete message, search, voice, reactions, block
"@ `
    -Acceptance @"
- [ ] Inbox list 1-1 + group
- [ ] Reply post → mở chat thread
- [ ] Quote mechanism thumbnail
- [ ] Real-time messages
- [ ] Unread badge
- [ ] Group chat Space
- [ ] Offline cache
- [ ] Tests ≥75%
"@ `
    -Dependencies "Firestore ``conversations/{convId}/messages/{msgId}``; Real-time snapshots; Feed (#5) reply; Space (#10) group; Push (#6) events #6,#7; Friends (#2)" `
    -Tests "Unit: ChatController, MessageRepository`nWidget: InboxList, ChatThread, QuoteBubble, MessageInput`nIntegration: reply→send→receive realtime`nRules: ``conversations`` member-only read/write" `
    -FigmaRefs "``Tin nhan.png``"

$chatTitle = "[T0] Chat — Inbox + 1-1 photo-anchored + Group Space"

# Chat = Issue #14 (not #13 which is a merged PR)
$CHAT_ISSUE_NUMBER = 14

$existingIssue = gh issue view $CHAT_ISSUE_NUMBER --repo $REPO --json number,title 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Issue #$CHAT_ISSUE_NUMBER already exists — updating..." -ForegroundColor Yellow
    Update-Issue -Number $CHAT_ISSUE_NUMBER -Title $chatTitle -Body $chatBody
} else {
    Write-Host "Issue #$CHAT_ISSUE_NUMBER does not exist — creating..." -ForegroundColor Yellow
    $tmp = New-TemporaryFile
    try {
        [System.IO.File]::WriteAllText($tmp.FullName, $chatBody, [System.Text.UTF8Encoding]::new($false))
        gh issue create --repo $REPO `
            --title $chatTitle `
            --body-file $tmp.FullName `
            --label "tier:0" --label "lane:open" --label "effort:l" `
            --milestone "M2 — Social Core"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   [OK] Created Chat issue" -ForegroundColor Green

            Write-Host "   Adding to Project #2..." -ForegroundColor Yellow
            $newNum = (gh issue list --repo $REPO --json number,title --limit 1 | ConvertFrom-Json)[0].number
            gh project item-add $PROJECT_NUMBER --owner manhthien2005 --url "https://github.com/$REPO/issues/$newNum" 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Host "   [OK] Added to project" -ForegroundColor Green }
            else { Write-Host "   [WARN] Failed to add to project — do it manually" -ForegroundColor Yellow }
        } else {
            Write-Host "   [FAIL] Could not create issue" -ForegroundColor Red
        }
    } finally {
        Remove-Item $tmp.FullName -Force -ErrorAction SilentlyContinue
    }
}

# ============================================================
# UPDATE PROJECT #2 FIELDS (Effort + Lane)
# ============================================================

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "UPDATE PROJECT FIELDS — Effort + Lane" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

$OWNER = "manhthien2005"

# Get project ID (node ID for GraphQL)
$projectJson = gh project list --owner $OWNER --format json | ConvertFrom-Json
$proj = $projectJson.projects | Where-Object { $_.number -eq $PROJECT_NUMBER }
if (-not $proj) {
    Write-Host "[FAIL] Project #$PROJECT_NUMBER not found" -ForegroundColor Red
    exit 1
}
$PROJECT_ID = $proj.id
Write-Host "Project ID: $PROJECT_ID"

# Build field + option lookup
$allFields = gh project field-list $PROJECT_NUMBER --owner $OWNER --format json | ConvertFrom-Json
$fieldLookup = @{}
foreach ($fname in @("Effort", "Lane")) {
    $f = $allFields.fields | Where-Object { $_.name -eq $fname }
    if ($f) {
        $optMap = @{}
        foreach ($opt in $f.options) { $optMap[$opt.name] = $opt.id }
        $fieldLookup[$fname] = @{ Id = $f.id; Options = $optMap }
        Write-Host "  Field '$fname': $($optMap.Keys -join ', ')" -ForegroundColor DarkGray
    } else {
        Write-Host "  [WARN] Field '$fname' not found" -ForegroundColor Yellow
    }
}

# Check if XL exists in Effort options
$hasXL = $fieldLookup.Effort -and $fieldLookup.Effort.Options.ContainsKey("XL")
if (-not $hasXL) {
    Write-Host "`n  [INFO] Effort 'XL' option does not exist. Camera #3 will be flagged." -ForegroundColor Yellow
    Write-Host "  -> Anh add 'XL' option manually in Project Settings > Effort field" -ForegroundColor Yellow
}

# Issue → Effort + Lane mapping (from locked modules.md)
$issueFields = @(
    @{ Number = 1;  Effort = "L"; Lane = "Specialty-BE-Native" }
    @{ Number = 2;  Effort = "M"; Lane = "Specialty-BE-Native" }
    @{ Number = 3;  Effort = "XL"; Lane = "Open" }  # XL may not exist yet
    @{ Number = 4;  Effort = "L"; Lane = "Specialty-BE-Native" }
    @{ Number = 5;  Effort = "L"; Lane = "Specialty-UI-Design" }
    @{ Number = 6;  Effort = "L"; Lane = "Specialty-BE-Native" }
    @{ Number = 7;  Effort = "S"; Lane = "Specialty-UI-Design" }
    @{ Number = 8;  Effort = "L"; Lane = "Specialty-BE-Native" }
    @{ Number = 9;  Effort = "M"; Lane = "Specialty-UI-Design" }
    @{ Number = 10; Effort = "L"; Lane = "Open" }
    @{ Number = 11; Effort = "L"; Lane = "Open" }
    @{ Number = 12; Effort = "M"; Lane = "Specialty-UI-Design" }
    @{ Number = 14; Effort = "L"; Lane = "Open" }  # Chat (was #13 conflict with PR)
)

# Get all project items to find item IDs per issue
$itemsJson = gh project item-list $PROJECT_NUMBER --owner $OWNER --format json --limit 100 | ConvertFrom-Json
$itemMap = @{}
foreach ($item in $itemsJson.items) {
    if ($item.content -and $item.content.number) {
        $itemMap[[int]$item.content.number] = $item.id
    }
}
Write-Host "  Items in project: $($itemMap.Count)" -ForegroundColor DarkGray

# Ensure #14 (Chat) is in project
if (-not $itemMap.ContainsKey([int]14)) {
    Write-Host "`n  Adding #14 to project..." -ForegroundColor Yellow
    gh project item-add $PROJECT_NUMBER --owner $OWNER --url "https://github.com/$REPO/issues/14" 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    # Re-fetch items
    $itemsJson = gh project item-list $PROJECT_NUMBER --owner $OWNER --format json --limit 100 | ConvertFrom-Json
    $itemMap = @{}
    foreach ($item in $itemsJson.items) {
        if ($item.content -and $item.content.number) {
            $itemMap[[int]$item.content.number] = $item.id
        }
    }
}

# Update each issue's project fields
$manualTodo = @()
foreach ($entry in $issueFields) {
    $num = $entry.Number
    $itemId = $itemMap[[int]$num]
    if (-not $itemId) {
        Write-Host "`n-> #$num : [SKIP] Not in project" -ForegroundColor Yellow
        continue
    }

    Write-Host "`n-> #$num : Effort=$($entry.Effort), Lane=$($entry.Lane)" -ForegroundColor Cyan

    # Set Effort
    if ($fieldLookup.Effort) {
        $optId = $fieldLookup.Effort.Options[$entry.Effort]
        if ($optId) {
            gh project item-edit --id $itemId --project-id $PROJECT_ID --field-id $fieldLookup.Effort.Id --single-select-option-id $optId 2>&1 | Out-Null
            Write-Host "   Effort=$($entry.Effort) [OK]" -ForegroundColor Green
        } else {
            Write-Host "   Effort=$($entry.Effort) [SKIP] option not found" -ForegroundColor Yellow
            $manualTodo += "#$num Effort=$($entry.Effort)"
        }
    }

    # Set Lane
    if ($fieldLookup.Lane) {
        $optId = $fieldLookup.Lane.Options[$entry.Lane]
        if ($optId) {
            gh project item-edit --id $itemId --project-id $PROJECT_ID --field-id $fieldLookup.Lane.Id --single-select-option-id $optId 2>&1 | Out-Null
            Write-Host "   Lane=$($entry.Lane) [OK]" -ForegroundColor Green
        } else {
            Write-Host "   Lane=$($entry.Lane) [SKIP] option not found" -ForegroundColor Yellow
            $manualTodo += "#$num Lane=$($entry.Lane)"
        }
    }
}

# ============================================================
# DONE
# ============================================================

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "DONE — 13 Epic issues synced + project fields updated" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""
Write-Host "Verify:" -ForegroundColor Yellow
Write-Host "  Issues: https://github.com/$REPO/issues"
Write-Host "  Project: https://github.com/users/manhthien2005/projects/$PROJECT_NUMBER"
Write-Host ""
if ($manualTodo.Count -gt 0) {
    Write-Host "Manual TODO (option not found in project):" -ForegroundColor Yellow
    foreach ($t in $manualTodo) { Write-Host "  - $t" }
    Write-Host ""
}
