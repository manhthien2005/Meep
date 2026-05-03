<#
.SYNOPSIS
  Update title + body cho 12 Epic issues theo format chuẩn mới.

.DESCRIPTION
  - Title: `[TIER] <Module> — <Mô tả tiếng Việt>`
  - Body: Template enhanced (Tóm tắt / Phạm vi / Tiêu chí / Phụ thuộc / Tests / Tài liệu / Workflow 4 phases)
  - Idempotent: re-run safe, always overrides to latest spec
  - Dùng `gh issue edit --title --body-file`

.NOTES
  Re-run sau mỗi lần đổi template. Issue # cố định 1-12 theo thứ tự tạo.

.EXAMPLE
  pwsh ./scripts/update-epic-issues.ps1
#>

$ErrorActionPreference = 'Stop'

# Refresh PATH + GH_TOKEN (Windsurf IDE cache bypass)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$userToken = [System.Environment]::GetEnvironmentVariable("GH_TOKEN", "User")
if ($userToken) { $env:GH_TOKEN = $userToken }

$REPO = "manhthien2005/Meep"

# ============================================================
# BODY RENDERER
# ============================================================

function Render-Body {
    param(
        [string]$Tier,            # "0" or "0 (Locket parity)" etc
        [string]$TierLabel,       # Human readable tier, e.g. "Tier 0 (Locket parity)"
        [string]$Milestone,       # "M1", "M2", "M3"
        [string]$Feature,         # Module folder name (auth, friend, camera, etc.)
        [string]$Summary,
        [string]$Scope,           # Pre-formatted bullet list
        [string]$Acceptance,      # Pre-formatted bullet list with `- [ ]`
        [string]$Dependencies,    # Pre-formatted bullet list
        [string]$Tests,           # Pre-formatted sub-sections with ### headers
        [string]$FigmaRefs        # Additional figma refs text (optional)
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
- [User stories](https://github.com/manhthien2005/Meep/blob/develop/docs/product/user-stories.md)
- [Features catalog](https://github.com/manhthien2005/Meep/blob/develop/docs/product/features.md)
- [Testing rules](https://github.com/manhthien2005/Meep/blob/develop/.windsurf/rules/30-testing-and-verification.md)

## 🚦 Workflow chi tiết (4 phases)

### 📐 Phase 1 — Design (leader)

- [ ] Chạy ``/spec $Feature`` → ``docs/specs/YYYY-MM-DD-$Feature.md`` (requirements + 2-3 design approaches)
- [ ] Approve spec với team (review meeting hoặc async comment trong PR spec)
- [ ] Chạy ``/plan $Feature`` → ``tasks/todo-$Feature.md`` (8-12 sub-tasks, mỗi task 1 PR ≤200 LOC)
- [ ] Tạo sub-issues từ plan (script ``scripts/breakdown-epic.ps1``)

### 🛠️ Phase 2 — Implementation (all devs, parallel)

- [ ] Assign sub-issue cho dev qua Project #2 (Assignees field)
- [ ] Dev checkout feature branch: ``feature/<DevName>/<desc>`` (vd ``feature/KhoaLND/$Feature-subtask``)
- [ ] Viết test TRƯỚC (TDD 🔴 RED)
- [ ] Implement minimal code cho test pass (TDD 🟢 GREEN)
- [ ] Refactor giữ test pass (TDD ♻️ REFACTOR)
- [ ] Chạy ``flutter test`` / ``npm test`` verify local
- [ ] Commit theo Conventional Commits tiếng Việt

### 🔍 Phase 3 — Review & Merge

- [ ] Dev self-review qua ``/review`` workflow (5-axis checklist)
- [ ] Open PR vào ``develop`` với template ``.github/pull_request_template.md``
- [ ] CI pass bắt buộc: commitlint + lint + flutter analyze + test + format
- [ ] ≥1 CODEOWNER approve (auto-assign từ ``.github/CODEOWNERS`` theo module)
- [ ] Squash merge (giữ history clean, không có merge commit)
- [ ] Auto: sub-issue closed → Epic progress bar update

### ✔️ Phase 4 — Verification

- [ ] Smoke test trên staging APK (Firebase App Distribution)
- [ ] Team test thực tế flow end-to-end
- [ ] Update memory Cascade nếu có decision mới
- [ ] Close Epic khi **all sub-issues done** + **acceptance criteria pass**

---

📍 [Milestones roadmap](https://github.com/manhthien2005/Meep/blob/develop/docs/roadmap/milestones.md) · [Features catalog](https://github.com/manhthien2005/Meep/blob/develop/docs/product/features.md) · [Team workflow](https://github.com/manhthien2005/Meep/blob/develop/docs/team-workflow.md)
"@
}

# ============================================================
# UPDATE HELPER
# ============================================================

function Update-Issue {
    param(
        [int]$Number,
        [string]$Title,
        [string]$Body
    )

    Write-Host ""
    Write-Host "-> Issue #$Number : $Title" -ForegroundColor Cyan

    $tmp = New-TemporaryFile
    try {
        [System.IO.File]::WriteAllText($tmp.FullName, $Body, [System.Text.UTF8Encoding]::new($false))
        gh issue edit $Number --repo $REPO --title $Title --body-file $tmp.FullName 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   [OK] Updated" -ForegroundColor Green
        } else {
            Write-Host "   [FAIL] gh exit $LASTEXITCODE" -ForegroundColor Red
        }
    } finally {
        Remove-Item $tmp.FullName -Force -ErrorAction SilentlyContinue
    }
}

# ============================================================
# ISSUE DATA — 12 Epic
# ============================================================

Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "UPDATE 12 EPIC ISSUES — title + body theo format enhanced" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan

# ---------- Issue #1: Auth ----------
Update-Issue -Number 1 -Title "[T0] Auth — Đăng ký + Đăng nhập + Auto-login" -Body (Render-Body `
    -Tier "0" -TierLabel "Tier 0 (Locket parity)" -Milestone "M1" -Feature "auth" `
    -Summary "Authentication foundation của Meep: đăng ký 5-step flow, đăng nhập email/Google, auto-login, logout.`nLà module nền để các feature khác chạy được (friend, camera, share, ...)." `
    -Scope @"
- Signup flow 5 bước: email → password → họ tên → username → skip contacts
- Đăng nhập: email + password
- Đăng nhập bằng Google (OAuth)
- Auto-login (Firebase Auth persistence)
- Username unique validation real-time (debounce 300ms)
- Logout
"@ `
    -Acceptance @"
- [ ] User signup hoàn tất < 60 giây
- [ ] Login lại bằng email/password OK
- [ ] Reopen app không cần login lại (auto-login)
- [ ] Username unique check real-time (debounce 300ms)
- [ ] Google signup OK trên Android
- [ ] Tất cả tests pass với coverage ≥80% controllers + repositories
"@ `
    -Dependencies @"
- Firebase Auth SDK (``firebase_auth`` Flutter package + FlutterFire)
- Cloud Function ``validateUsername`` (Node 20 + TypeScript)
- Firestore collection ``users`` + security rules
- Riverpod 2 + code-gen (state management)
- ``freezed`` + ``json_serializable`` (data classes)
"@ `
    -Tests @"
### Unit tests (Flutter)

- ``AuthController``: tất cả flows (sign up, sign in, sign out, auto-login)
- ``AuthRepository``: Firebase Auth mocks (``firebase_auth_mocks``)
- Validators: email, password strength, username format
- **Target:** ≥80% coverage

### Widget tests (Flutter)

- Form signup 5 màn: states (empty, filled, loading, error)
- Button disable/enable theo validation
- Username unique check loading indicator

### Integration test (Flutter)

- 1 full flow end-to-end: signup email → login → logout → auto-login next open

### Unit tests (Cloud Functions)

- ``validateUsername`` với fake Firestore stub
- Test cases: valid, already-taken, invalid-format, reserved-name

### Rules tests

- Firestore rules cho ``/users/{uid}``: owner read/write, friend read public, stranger deny
- Chạy qua ``firebase emulators:exec --only firestore "npm run test:rules"``
"@ `
    -FigmaRefs "[``Dang ky_*.png``, ``Dang nhap_*.png``](https://github.com/manhthien2005/Meep/tree/develop/docs/specs/figma_design)")

# ---------- Issue #2: Friends ----------
Update-Issue -Number 2 -Title "[T0] Friends — Mời bạn + Kết bạn + Danh sách bạn" -Body (Render-Body `
    -Tier "0" -TierLabel "Tier 0 (Locket parity)" -Milestone "M2" -Feature "friend" `
    -Summary "Friend graph cơ bản: tìm bạn qua username hoặc share link, gửi/nhận friend request, accept/decline, danh sách bạn bè." `
    -Scope @"
- Tìm bạn qua username (exact match)
- Invite qua share link (deeplink schema ``meep://friend/<uid>``)
- Gửi friend request
- Accept / decline friend request
- Danh sách bạn bè + search
- Unfriend (xoá bidirectional)
"@ `
    -Acceptance @"
- [ ] Tìm đúng username có hồi đáp, not found hiển thị ""Không tìm thấy""
- [ ] Invite link mở app → màn accept friend
- [ ] Accept → lưu vào friend graph (bidirectional, pair ID sorted)
- [ ] Danh sách bạn load trong < 2s với 50 bạn
- [ ] Unfriend xoá cả 2 chiều (friendships doc + listings)
- [ ] Tests pass với coverage ≥80% controllers + repositories
"@ `
    -Dependencies @"
- Cloud Functions: ``sendFriendRequest``, ``acceptFriendRequest``, ``declineFriendRequest``
- Firestore collections: ``friend_requests``, ``friendships``
- Deeplink plugin (``uni_links`` hoặc ``app_links``)
- ``share_plus`` cho invite link
"@ `
    -Tests @"
### Unit tests (Flutter)

- ``FriendController``: request, accept, decline, list, unfriend flows
- ``FriendRepository``: Firestore mocks (``fake_cloud_firestore``)
- Username search validator + debouncer

### Widget tests (Flutter)

- ``FriendList``: states (empty, loading, loaded, error)
- ``FriendRequestCard``: accept + decline buttons
- ``SearchBox``: debounce + clear

### Integration test (Flutter)

- Full invite → accept → visible trong friend list của cả 2 users

### Unit tests (Cloud Functions)

- ``sendFriendRequest``, ``acceptFriendRequest`` với fake Firestore
- Pair ID sort logic (smaller UID first)
- Edge cases: duplicate request, self-request, already-friends

### Rules tests

- ``friend_requests``: recipient read, sender read, stranger deny
- ``friendships``: both members read, stranger deny, no one write directly (Function-only)
"@)

# ---------- Issue #3: Camera ----------
Update-Issue -Number 3 -Title "[T0] Camera — Chụp ảnh (flip cam + caption)" -Body (Render-Body `
    -Tier "0" -TierLabel "Tier 0 (Locket parity)" -Milestone "M2" -Feature "camera" `
    -Summary "Camera cơ bản: chụp ảnh bằng back + flip front cam, thêm caption text, lưu tạm local trước khi upload." `
    -Scope @"
- Camera preview full-screen
- Nút chụp capture (shutter button)
- Flip front/back camera (animated)
- Caption text tối đa 200 ký tự
- Lưu ảnh tạm vào app cache trước upload
- Image compression < 500KB
"@ `
    -Acceptance @"
- [ ] Camera preview load < 1s sau permission grant
- [ ] Capture OK → photo lưu local tạm thành công
- [ ] Flip camera OK < 500ms (smooth animation)
- [ ] Caption max 200 chars, counter visible real-time
- [ ] Photo compress < 500KB trước pass qua Share feature
- [ ] Tests pass với coverage ≥70% (UI-heavy module)
"@ `
    -Dependencies @"
- ``camera`` Flutter plugin
- ``path_provider`` cho tmp storage
- ``image`` plugin cho compression
- ``permission_handler`` (runtime camera permission)
"@ `
    -Tests @"
### Unit tests (Flutter)

- ``CameraController``: init, capture, flip, dispose
- Image compression logic: input → output size + quality
- Caption validator: max length, trim

### Widget tests (Flutter)

- ``CaptureButton`` states (idle, capturing, error)
- ``FlipButton`` toggle animation
- ``CaptionField`` với counter + max length

### Integration test (Flutter)

- Capture → preview → caption → save flow end-to-end
- Permission denied handling

### Mocking strategy

- Camera plugin dùng mocktail cho platform channel
- Image files dùng test assets fixed-size
"@)

# ---------- Issue #4: Share photo ----------
Update-Issue -Number 4 -Title "[T0] Share photo — Upload ảnh + Push notify bạn bè" -Body (Render-Body `
    -Tier "0" -TierLabel "Tier 0 (Locket parity)" -Milestone "M2" -Feature "post" `
    -Summary "Upload photo lên Firebase Storage, lưu metadata Firestore, trigger Cloud Function fan-out FCM push notify friends." `
    -Scope @"
- Upload ảnh (compressed) lên Firebase Storage path ``posts/{uid}/{postId}/{filename}.jpg``
- Lưu metadata Firestore collection ``posts``: authorId, caption, createdAt, storagePath
- Trigger Cloud Function ``onPostCreated`` → fan-out FCM notification cho friends
- Retry 3 lần nếu upload fail
- Progress indicator (percentage)
"@ `
    -Acceptance @"
- [ ] Upload ảnh < 500KB trong < 3s (4G connection)
- [ ] Metadata lưu Firestore đúng schema ``Post`` model
- [ ] Bạn bè nhận push notify trong < 10s sau post
- [ ] Retry 3 lần nếu fail, sau đó show error UI
- [ ] Progress bar hiển thị % upload real-time
- [ ] EXIF metadata stripped (privacy — no location leak)
"@ `
    -Dependencies @"
- Firebase Storage + ``firebase_storage`` Flutter plugin
- ``cloud_firestore`` Flutter plugin
- Cloud Function ``onPostCreated`` (fan-out FCM)
- FCM (``firebase_messaging``)
- Post model trong ``lib/features/post/data/post.dart``
"@ `
    -Tests @"
### Unit tests (Flutter)

- ``PostRepository``: upload, save metadata, retry logic
- ``PostController``: state machine (idle, uploading, success, error)
- Metadata builder: Post model serialization

### Widget tests (Flutter)

- ``UploadProgressBar`` với % updates
- ``RetryButton`` trong error state
- ``PostButton`` disable during upload

### Integration test (Flutter)

- Camera → upload → verify Firestore doc + Storage file tồn tại
- Network fail simulation → retry → eventual success

### Unit tests (Cloud Functions)

- ``onPostCreated`` với fake Firestore + FCM mock
- Fan-out: iterate friends, send notification per device token
- EXIF stripping verification

### Rules tests

- ``posts/{postId}``: author create, friend read, stranger deny
- Storage ``posts/{uid}/**``: owner write, friend read, 10MB size cap
"@)

# ---------- Issue #5: Feed ----------
Update-Issue -Number 5 -Title "[T0] Feed — List bài viết + Cache + Pagination" -Body (Render-Body `
    -Tier "0" -TierLabel "Tier 0 (Locket parity)" -Milestone "M2" -Feature "feed" `
    -Summary "Vertical list feed bài viết từ friends với skeleton loader, cache offline 20 items mới nhất, infinite scroll pagination." `
    -Scope @"
- Vertical list (timeline) bài viết friends
- Skeleton loader while loading
- Cache 20 bài mới nhất offline (shared_preferences hoặc hive)
- Infinite scroll pagination (20 items/page)
- Pull to refresh
- Empty state (chưa có bạn / chưa có bài)
"@ `
    -Acceptance @"
- [ ] Feed load 20 items trong < 2s (cache hit) / < 4s (cold)
- [ ] Cache hiển thị offline khi không có network
- [ ] Pagination trigger khi scroll đến 80% list
- [ ] Pull refresh work không duplicate items
- [ ] Empty state với icon + CTA ""Mời bạn"" friendly
- [ ] Tests pass với coverage ≥70%
"@ `
    -Dependencies @"
- ``cached_network_image`` cho image caching
- Firestore pagination với ``startAfter`` cursor
- ``shared_preferences`` hoặc ``hive`` cho local cache
- Post model từ Share photo feature
"@ `
    -Tests @"
### Unit tests (Flutter)

- ``FeedController``: load, refresh, paginate, cache states
- ``FeedRepository``: Firestore pagination logic
- ``PaginationState``: cursor tracking, hasMore detection

### Widget tests (Flutter)

- ``FeedList`` với states (loading, loaded, empty, error)
- ``PostCard`` render với placeholder image
- ``SkeletonLoader`` animation
- ``EmptyState`` với CTA button
- Pull-to-refresh gesture

### Integration test (Flutter)

- Load → scroll → pagination end-to-end
- Offline mode → cache hit → content visible
- Online resume → refresh → new items prepend

### Rules tests

- ``posts`` collection: read by friend (via ``friendships`` check)
"@)

# ---------- Issue #6: Push notification ----------
Update-Issue -Number 6 -Title "[T0] Push notification — FCM Android (5 events)" -Body (Render-Body `
    -Tier "0" -TierLabel "Tier 0 (Locket parity)" -Milestone "M3" -Feature "notification" `
    -Summary "Firebase Cloud Messaging push notification trên Android với 5 event types + deeplink routing khi tap notification." `
    -Scope @"
- FCM token registration + save Firestore sau signup
- 5 notify events:
  1. Friend request received
  2. Friend request accepted
  3. New post from friend
  4. Reaction on your post
  5. Weekly RollCall reminder
- Deeplink khi tap → mở đúng màn trong app
- Handle 3 states: foreground / background / terminated
- Notification channels (Android 8+)
"@ `
    -Acceptance @"
- [ ] FCM token register thành công khi signup
- [ ] 5 events trigger notify với title + body tiếng Việt
- [ ] Tap notify → mở đúng screen (feed / friend list / post detail / v.v.)
- [ ] Foreground: in-app banner
- [ ] Background: system notification tray
- [ ] Terminated: tap launches app với correct route
- [ ] Notification settings system respect (user opt-out)
"@ `
    -Dependencies @"
- ``firebase_messaging`` Flutter plugin
- Cloud Functions trigger từ Firestore events (onCreate per event type)
- FCM Admin SDK (Node 20)
- Deeplink schema ``meep://<route>``
- Android notification channels
"@ `
    -Tests @"
### Unit tests (Flutter)

- ``NotificationController``: token register, foreground handler
- ``DeepLinkHandler``: parse route, validate path
- ``NotificationBuilder``: per event type → title/body tiếng Việt

### Widget tests (Flutter)

- In-app banner rendering
- Deeplink navigation trigger

### Integration test (Flutter)

- Tap notify (mocked) → navigate correct screen
- Terminated state launch (instrumented)

### Unit tests (Cloud Functions)

- Fan-out logic per event type (send to all device tokens of recipient)
- FCM payload validation
- Error handling: token invalid → cleanup

### Manual test

- Staging APK test 5 events thực tế trên device
"@)

# ---------- Issue #7: Reaction ----------
Update-Issue -Number 7 -Title "[T0] Reaction — Thả emoji vào bài viết" -Body (Render-Body `
    -Tier "0" -TierLabel "Tier 0 (Locket parity)" -Milestone "M3" -Feature "reaction" `
    -Summary "Simple 1 emoji react per bài viết (heart, laugh, wow, sad, angry). Override nếu user đổi emoji. Count aggregate + push notify author." `
    -Scope @"
- 5 emoji options: ❤️ 😂 😮 😢 😡
- 1 user chỉ 1 react / 1 post (override nếu chọn emoji khác)
- Animation khi react (scale + fade)
- Count aggregate hiển thị trên feed (totals per emoji)
- Trigger Cloud Function notify author
"@ `
    -Acceptance @"
- [ ] 5 emoji work đúng UI + logic
- [ ] User chọn emoji → feed update real-time (< 1s)
- [ ] Override react cũ OK (1 react per user per post)
- [ ] Count hiển thị chính xác aggregated (sum emoji occurrences)
- [ ] Author nhận push notify trong < 10s
- [ ] Tests pass với coverage ≥75%
"@ `
    -Dependencies @"
- Firestore subcollection ``reactions/{postId}/{userId}``
- Cloud Function ``onReactionAdded`` → notify author
- Flutter ``ScaleTransition`` + ``FadeTransition`` cho animation
- Aggregation logic (client-side hoặc counter shards)
"@ `
    -Tests @"
### Unit tests (Flutter)

- ``ReactionController``: add, update, remove reaction
- ``ReactionRepository``: subcollection write + read
- Aggregator logic: count per emoji

### Widget tests (Flutter)

- ``EmojiPicker`` với 5 options
- ``ReactionButton`` với scale animation
- Count badge render đúng totals

### Integration test (Flutter)

- Tap emoji → Firestore update → feed refresh → count increment
- Change emoji → old removed, new added

### Unit tests (Cloud Functions)

- ``onReactionAdded``: notify author với correct emoji + message
- Skip notify nếu author == reactor

### Rules tests

- ``reactions/{postId}/{userId}``: owner read/write own, friend read, stranger deny
"@)

# ---------- Issue #8: Widget Android ----------
Update-Issue -Number 8 -Title "[T0] Widget Android — Ảnh mới nhất + Tap deep link" -Body (Render-Body `
    -Tier "0" -TierLabel "Tier 0 (Locket parity, Meep differentiator)" -Milestone "M3" -Feature "widget" `
    -Summary "Android home-screen widget hiển thị ảnh mới nhất từ friends. Tap widget → mở app vào feed. Native Kotlin AppWidget + WorkManager periodic update." `
    -Scope @"
- Home-screen widget 2x2 (default size)
- Hiển thị ảnh mới nhất từ feed (1 ảnh lớn)
- Update periodic every 15-30 min (WorkManager)
- Tap widget → deeplink ``meep://feed``
- Loading state (chưa có ảnh từ bạn bè)
- Cache image local (Glide / Coil)
"@ `
    -Acceptance @"
- [ ] Widget hiển thị ảnh mới nhất trong < 5s sau add home
- [ ] Update every 15-30 min (WorkManager), respect battery saver
- [ ] Tap → mở app → feed screen đúng
- [ ] No-network: show cached last image (no error)
- [ ] Low battery: reduced update frequency (battery-aware)
- [ ] Works on Android 7+ (API 24+)
"@ `
    -Dependencies @"
- Android AppWidget framework (Kotlin)
- WorkManager cho periodic update
- ``home_widget`` Flutter plugin để Flutter ↔ Kotlin communication
- Glide hoặc Coil cho image caching
- SharedPreferences cho cache metadata
"@ `
    -Tests @"
### Unit tests (Kotlin)

- ``WidgetProvider`` lifecycle: onUpdate, onEnabled, onDisabled
- ``ImageLoader``: URL → bitmap với caching
- ``UpdateWorker``: fetch latest post, update widget view

### Instrumentation tests (Android)

- Widget render test với espresso
- Tap action launch correct intent
- Cache hit offline scenario

### Manual test

- 3 devs add widget thực tế lên launcher
- Verify update periodic thực tế sau post mới
"@)

# ---------- Issue #9: Diary ----------
Update-Issue -Number 9 -Title "[T0+] Diary — Nhật ký text + 1-3 ảnh đính kèm" -Body (Render-Body `
    -Tier "0+" -TierLabel "Tier 0+ (Meep differentiator)" -Milestone "M3" -Feature "diary" `
    -Summary "Diary basic — viết text entry + đính kèm 1-3 ảnh từ gallery hoặc camera. KHÔNG có canvas editor (defer post-capstone)." `
    -Scope @"
- Text entry tối đa 1000 ký tự
- Attach 1-3 ảnh (gallery hoặc camera)
- Grid hiển thị diary entries (own only, chronological)
- Delete entry own (confirmation dialog)
- **Out of scope:** canvas editor, drawing, stickers (defer)
"@ `
    -Acceptance @"
- [ ] Viết text + attach 1-3 ảnh OK
- [ ] Lưu Firestore ``diary_entries/{uid}/{entryId}`` với ``images[]`` array
- [ ] Grid hiển thị entries với thumbnail ảnh đầu tiên
- [ ] Delete own entry OK với confirmation dialog
- [ ] Max 3 ảnh validation UI (button disabled khi đạt max)
- [ ] Tests pass với coverage ≥70%
"@ `
    -Dependencies @"
- ``image_picker`` plugin (gallery + camera)
- Firestore ``diary_entries`` subcollection (per user)
- Cloud Storage cho diary images (``diary/{uid}/{entryId}/{filename}``)
- Camera feature (cho capture option)
"@ `
    -Tests @"
### Unit tests (Flutter)

- ``DiaryController``: create, list, delete flows
- ``DiaryRepository``: Firestore + Storage operations
- Validator: text length max 1000, images max 3

### Widget tests (Flutter)

- ``DiaryForm``: text field với counter, image picker với 3 max
- ``EntryGrid``: thumbnails, empty state, date display
- ``DeleteConfirmationDialog``

### Integration test (Flutter)

- Create entry → verify Firestore + Storage
- List entries với pagination
- Delete entry → Firestore + Storage cleanup

### Rules tests

- ``diary_entries/{uid}/**``: owner-only read/write (private collection)
- Storage ``diary/{uid}/**``: owner-only
"@)

# ---------- Issue #10: Space ----------
Update-Issue -Number 10 -Title "[T0+] Space — Nhóm bạn + Chia sẻ ảnh theo space" -Body (Render-Body `
    -Tier "0+" -TierLabel "Tier 0+ (Meep differentiator)" -Milestone "M3" -Feature "space" `
    -Summary "Space = nhóm bạn bè close circle. Share ảnh chỉ trong space (không public). KHÔNG có theme switch, KHÔNG có group chat (defer)." `
    -Scope @"
- Tạo space với name + invite bạn từ friend list
- Space max 10 members
- Share photo chọn destination: ""public feed"" hoặc ""space X""
- Space members list với avatar + username
- Leave space (xoá self từ members)
- **Out of scope:** theme switch per space, group chat (defer)
"@ `
    -Acceptance @"
- [ ] Tạo space với 2-10 members OK
- [ ] Share photo → chọn space → chỉ members trong space nhận
- [ ] Members list hiển thị avatar + username
- [ ] Leave space OK (self removed, others vẫn thấy space)
- [ ] Non-member KHÔNG thấy post trong space (rules enforce)
- [ ] Tests pass với coverage ≥75%
"@ `
    -Dependencies @"
- Firestore collections: ``spaces`` + ``space_members`` subcollection
- Cloud Function ``fanoutToSpace`` (thay thế ``fanoutToFriends`` nếu post gắn space)
- Friend feature (invite từ friend list)
"@ `
    -Tests @"
### Unit tests (Flutter)

- ``SpaceController``: create, invite, leave flows
- ``SpaceRepository``: Firestore operations
- Member validation: max 10, friend-only invite

### Widget tests (Flutter)

- ``SpaceList`` với user's spaces
- ``MemberList`` trong space detail
- ``InviteForm`` với friend selector
- ``ShareDestinationSelector`` (public vs space)

### Integration test (Flutter)

- Create space → invite friend → share photo → verify access
- Leave space → removed từ members list

### Unit tests (Cloud Functions)

- ``fanoutToSpace``: iterate space members, send FCM per device token
- Skip non-members
- Handle space deleted edge case

### Rules tests

- ``spaces/{spaceId}``: member-only read, creator write
- ``space_members``: member read, creator write
"@)

# ---------- Issue #11: RollCall ----------
Update-Issue -Number 11 -Title "[T0+] RollCall — Thông báo tuần + Multi-emoji react" -Body (Render-Body `
    -Tier "0+" -TierLabel "Tier 0+ (Meep differentiator)" -Milestone "M3" -Feature "rollcall" `
    -Summary "Weekly RollCall: push notify thứ 6 8h sáng → user post ảnh ""bạn đang làm gì?"" với multi-emoji react đặc biệt. KHÔNG có 168h archive (defer)." `
    -Scope @"
- Cron Cloud Function weekly (Friday 8h GMT+7)
- FCM notify tất cả active users
- Post special tagged ``rollcall: true``
- Multi-emoji react (5 emojis đồng thời vs 1 emoji thường)
- RollCall posts priority top trong 24h feed
- **Out of scope:** 168h archive, RollCall feed gating (defer)
"@ `
    -Acceptance @"
- [ ] Cron trigger đúng 8h Friday GMT+7 weekly
- [ ] Push notify tất cả active users (có post trong 7 ngày qua)
- [ ] RollCall post tagged ``rollcall: true`` trong Firestore
- [ ] Multi-emoji react (5 emojis đồng thời) OK
- [ ] Feed hiển thị RollCall posts priority top trong 24h sau trigger
- [ ] Tests pass với coverage ≥70%
"@ `
    -Dependencies @"
- Cloud Scheduler + Cloud Function cron (``scheduleRollCall``)
- FCM fan-out tới active users
- Firestore ``posts`` collection với field ``rollcall: boolean``
- Reaction feature (multi-emoji logic extension)
"@ `
    -Tests @"
### Unit tests (Flutter)

- ``RollCallController``: banner state, post flow
- ``MultiReactionLogic``: 5 simultaneous reactions
- Feed sorting: RollCall first trong 24h

### Widget tests (Flutter)

- ``RollCallBanner`` notification
- ``MultiEmojiPicker`` (5 emojis selectable)

### Integration test (Flutter)

- Post RollCall → verify tag + feed priority
- Multi-react → verify aggregation

### Unit tests (Cloud Functions)

- ``scheduleRollCall`` cron trigger (invoke directly via test)
- Active user filter logic
- Fan-out FCM

### Manual test

- Wait weekly trigger hoặc force trigger trên staging
"@)

# ---------- Issue #12: Profile ----------
Update-Issue -Number 12 -Title "[T0+] Profile — Avatar + Username + Bio + Grid ảnh" -Body (Render-Body `
    -Tier "0+" -TierLabel "Tier 0+ (Meep differentiator)" -Milestone "M2" -Feature "profile" `
    -Summary "Profile screen: avatar, username, bio (max 100 chars), grid ảnh posts. View own profile (editable) + others' profile (read-only public fields)." `
    -Scope @"
- Avatar upload + crop 1:1 aspect ratio (hoặc default placeholder)
- Username display + edit (own only, unique check)
- Bio text max 100 chars + edit
- Grid ảnh posts của user (infinite scroll)
- View other user's profile (hide private fields)
"@ `
    -Acceptance @"
- [ ] Avatar upload + crop 1:1 OK, lưu Storage ``avatars/{uid}.jpg``
- [ ] Username edit với unique check real-time
- [ ] Bio edit với counter 100 chars
- [ ] Grid ảnh paginate 20 items
- [ ] Other's profile hide private fields (email, phone, friends count)
- [ ] Tests pass với coverage ≥70% (UI-heavy)
"@ `
    -Dependencies @"
- ``image_cropper`` plugin cho avatar crop
- Firestore ``users`` collection (Auth feature ownership)
- Firestore ``posts`` collection (Share photo feature)
- Cloud Storage ``avatars/{uid}.jpg``
- Cloud Function ``validateUsername`` (reuse từ Auth)
"@ `
    -Tests @"
### Unit tests (Flutter)

- ``ProfileController``: load, edit avatar, edit bio, edit username flows
- ``ProfileRepository``: Firestore + Storage operations
- ``AvatarUploader``: upload + crop pipeline

### Widget tests (Flutter)

- ``AvatarPicker`` với crop preview
- ``BioField`` với counter
- ``PostGrid`` với pagination
- ``EditButton`` visible chỉ own profile
- Private fields hidden cho non-owner view

### Integration test (Flutter)

- Edit avatar → save → verify Storage + Firestore
- Edit username → unique check → save
- View other's profile → private fields hidden

### Rules tests

- ``users/{uid}``: public fields read by all authed, private fields owner-only
- ``users/{uid}/private/**``: owner-only read/write
"@)

# ============================================================
# DONE
# ============================================================

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "DONE — 12 Epic issues updated" -ForegroundColor Green
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""
Write-Host "Verify:" -ForegroundColor Yellow
Write-Host "  Project board: https://github.com/users/manhthien2005/projects/2"
Write-Host "  Issues list: https://github.com/$REPO/issues"
Write-Host ""
