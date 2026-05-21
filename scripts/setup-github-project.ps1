<#
.SYNOPSIS
  Setup GitHub Projects v2 board cho Meep capstone.

.DESCRIPTION
  Auto setup theo spec ADR-0003:
  - Check Status field (rename Todo→Backlog + add Review phải manual UI — GitHub API không support update options)
  - Add 4 custom fields: Sprint, Type, Lane, Effort
  - Tạo 15 labels (milestone/lane/tier/effort)
  - Tạo 12 epic issues từ docs/roadmap/milestones.md (Tier 0 + 0+)
  - Add issues vào project với field values (Sprint/Lane/Effort)

  ⚠️ DEPRECATED PARTIAL (2026-05-21) — sau ADR-0004 (solo-dev module ownership):
  - Lane field + lane:* labels không còn dùng. Mọi `Lane` trong script này là LEGACY.
  - Khi tạo issue mới: dùng template `task.md` với field "Module" thay vì Lane.
  - Đã chạy 1 lần rồi → labels tồn tại trên GitHub. Không cần re-run.
  - Để giữ board sạch: vào GitHub Projects → Settings → đổi field "Lane" thành "Module" (hoặc thêm field "Module" mới và archive Lane).

.NOTES
  Idempotent: safe re-run. Skip resource đã tồn tại.
  Requires: gh CLI ≥2.40, authenticated với scopes repo + project.

.EXAMPLE
  pwsh ./scripts/setup-github-project.ps1
#>

$ErrorActionPreference = 'Stop'

# Refresh PATH (Windows: gh có thể không load trong session mới)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Refresh GH_TOKEN từ User env var (Windsurf IDE cache env cũ, force inject classic PAT)
$userToken = [System.Environment]::GetEnvironmentVariable("GH_TOKEN", "User")
if ($userToken) {
    $env:GH_TOKEN = $userToken
}

# ============================================================
# CONFIG
# ============================================================

$OWNER = "manhthien2005"
$REPO = "manhthien2005/Meep"
$PROJECT_NUMBER = 2
$PROJECT_ID = "PVT_kwHOA-drWs4BWVYx"

# ============================================================
# HELPERS
# ============================================================

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

function Write-Step { param([string]$Message) Write-Host "  -> $Message" -ForegroundColor Gray }
function Write-Success { param([string]$Message) Write-Host "  [OK] $Message" -ForegroundColor Green }
function Write-WarnMsg { param([string]$Message) Write-Host "  [!] $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "  [FAIL] $Message" -ForegroundColor Red }

# ============================================================
# SECTION 1: Check Status field (manual UI only for updates)
# ============================================================

Write-Section "1. CHECK STATUS FIELD"

$allFields = gh project field-list $PROJECT_NUMBER --owner $OWNER --format json | ConvertFrom-Json
$statusField = $allFields.fields | Where-Object { $_.name -eq "Status" -and $_.type -eq "ProjectV2SingleSelectField" }

if ($statusField) {
    $statusOptionNames = ($statusField.options | ForEach-Object { $_.name }) -join ", "
    Write-Step "Current Status options: $statusOptionNames"

    $hasBacklog = $statusField.options | Where-Object { $_.name -eq "Backlog" }
    $hasReview = $statusField.options | Where-Object { $_.name -eq "Review" }

    if ($hasBacklog -and $hasReview) {
        Write-Success "Status field already matches ADR-0003 spec"
    } else {
        Write-WarnMsg "Status field CHƯA match ADR-0003 spec (Backlog/In Progress/Review/Done)"
        Write-WarnMsg "GitHub API không support update single-select options via CLI/GraphQL"
        Write-WarnMsg "Manual UI edit bắt buộc:"
        Write-WarnMsg "  1. Mở: https://github.com/users/$OWNER/projects/$PROJECT_NUMBER/settings"
        Write-WarnMsg "  2. Click field 'Status' -> edit"
        Write-WarnMsg "  3. Rename 'Todo' -> 'Backlog'"
        Write-WarnMsg "  4. Add option 'Review' (giữa 'In Progress' và 'Done')"
        Write-WarnMsg "  5. Save"
    }
} else {
    Write-Fail "Không tìm thấy Status field"
}

# ============================================================
# SECTION 2: Add 4 custom fields
# ============================================================

Write-Section "2. ADD 4 CUSTOM FIELDS"

function Add-SingleSelectField {
    param(
        [string]$Name,
        [string[]]$OptionNames
    )

    # Check exists (idempotent)
    $existingFields = gh project field-list $PROJECT_NUMBER --owner $OWNER --format json | ConvertFrom-Json
    $existing = $existingFields.fields | Where-Object { $_.name -eq $Name }
    if ($existing) {
        Write-WarnMsg "Field '$Name' exists (id: $($existing.id)). Skip."
        return $existing.id
    }

    $optionsCsv = $OptionNames -join ","
    Write-Step "Creating '$Name' with options: $optionsCsv"

    try {
        $result = gh project field-create $PROJECT_NUMBER --owner $OWNER --name $Name --data-type "SINGLE_SELECT" --single-select-options $optionsCsv --format json 2>&1 | Out-String
        $json = $result | ConvertFrom-Json -ErrorAction Stop
        if ($json.id) {
            Write-Success "Created '$Name' (id: $($json.id))"
            return $json.id
        } else {
            Write-Fail "Unexpected output: $result"
            return $null
        }
    } catch {
        Write-Fail "Create '$Name' fail: $_"
        return $null
    }
}

Add-SingleSelectField -Name "Sprint" -OptionNames @("1", "2", "3") | Out-Null
Add-SingleSelectField -Name "Type" -OptionNames @("feature", "fix", "chore", "refactor", "docs", "test") | Out-Null
Add-SingleSelectField -Name "Lane" -OptionNames @("Specialty-BE-Native", "Specialty-UI-Design", "Open") | Out-Null
Add-SingleSelectField -Name "Effort" -OptionNames @("XS", "S", "M", "L") | Out-Null

# Re-fetch all fields to build option ID lookup (needed for item-edit later)
Write-Step "Building field + option ID lookup"
$allFieldsAfter = gh project field-list $PROJECT_NUMBER --owner $OWNER --format json | ConvertFrom-Json

$fieldLookup = @{}
foreach ($fname in @("Sprint", "Type", "Lane", "Effort")) {
    $f = $allFieldsAfter.fields | Where-Object { $_.name -eq $fname }
    if ($f) {
        $optMap = @{}
        foreach ($opt in $f.options) {
            $optMap[$opt.name] = $opt.id
        }
        $fieldLookup[$fname] = @{
            Id = $f.id
            Options = $optMap
        }
        Write-Success "Mapped '$fname' (id: $($f.id), $($f.options.Count) options)"
    } else {
        Write-Fail "Field '$fname' not found after creation"
    }
}

# ============================================================
# SECTION 3: Create 15 labels
# ============================================================

Write-Section "3. CREATE 15 LABELS"

function Add-Label {
    param(
        [string]$Name,
        [string]$Color,   # hex without #
        [string]$Description
    )

    # Check exists
    $existing = gh label list --repo $REPO --search $Name --json name 2>$null | ConvertFrom-Json
    if ($existing | Where-Object { $_.name -eq $Name }) {
        Write-WarnMsg "Label '$Name' exists. Skip."
        return
    }

    try {
        gh label create $Name --repo $REPO --color $Color --description $Description 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Created '$Name'"
        } else {
            Write-Fail "Create '$Name' fail"
        }
    } catch {
        Write-Fail "Create '$Name' exception: $_"
    }
}

# Milestones (red shades)
Add-Label -Name "milestone:M1" -Color "FF6B6B" -Description "Milestone 1: Setup + Auth (1-13/5)"
Add-Label -Name "milestone:M2" -Color "EE5A6F" -Description "Milestone 2: Social Core (14-27/5)"
Add-Label -Name "milestone:M3" -Color "C41E3A" -Description "Milestone 3: Differentiator + Demo (28/5-9/6)"

# Lanes
Add-Label -Name "lane:specialty-be-native" -Color "FF8C42" -Description "Specialty: Backend + Native"
Add-Label -Name "lane:specialty-ui-design" -Color "E91E63" -Description "Specialty: UI + Design"
Add-Label -Name "lane:open" -Color "9E9E9E" -Description "Open: Moi dev pick up"

# Tiers
Add-Label -Name "tier:0" -Color "0366D6" -Description "Tier 0: Locket parity (must ship)"
Add-Label -Name "tier:0-plus" -Color "1E90FF" -Description "Tier 0+: Meep differentiator (must ship)"
Add-Label -Name "tier:1" -Color "5DADE2" -Description "Tier 1: Stretch goal"
Add-Label -Name "tier:2" -Color "AED6F1" -Description "Tier 2: Deferred post-capstone"

# Effort
Add-Label -Name "effort:xs" -Color "C6F6D5" -Description "<2h"
Add-Label -Name "effort:s" -Color "68D391" -Description "2-4h"
Add-Label -Name "effort:m" -Color "38A169" -Description "1-2 ngay"
Add-Label -Name "effort:l" -Color "22543D" -Description "3-5 ngay (can split)"

# Priority
Add-Label -Name "priority:critical" -Color "B60205" -Description "Block progress"

# ============================================================
# SECTION 4: Create 12 epic issues + add to project
# ============================================================

Write-Section "4. CREATE 12 EPIC ISSUES + ADD TO PROJECT"

function New-EpicIssue {
    param(
        [string]$Title,
        [string]$Body,
        [string[]]$Labels,
        [string]$Sprint,
        [string]$Lane,
        [string]$Effort
    )

    Write-Step "Processing: $Title"

    # Check duplicate — existing issues still proceed to project add
    $existing = gh issue list --repo $REPO --search "`"$Title`" in:title" --json number,title,url --state all 2>$null | ConvertFrom-Json
    $match = $existing | Where-Object { $_.title -eq $Title }

    if ($match) {
        Write-WarnMsg "Issue #$($match.number) exists. Skip create, process project add."
        $issueNumber = $match.number
        $url = $match.url
    } else {
        # Create issue
        $labelArg = ($Labels -join ",")
        $tmpBody = New-TemporaryFile
        Set-Content -Path $tmpBody -Value $Body -Encoding UTF8

        try {
            $output = gh issue create --repo $REPO --title $Title --body-file $tmpBody --label $labelArg 2>&1
            Remove-Item $tmpBody -Force -ErrorAction SilentlyContinue

            $url = ($output | Select-Object -Last 1).ToString().Trim()
            if ($url -notmatch "github.com/.+/issues/(\d+)$") {
                Write-Fail "Unexpected output: $output"
                return
            }
            $issueNumber = $Matches[1]
            Write-Success "Created issue #$issueNumber"
        } catch {
            Write-Fail "Create '$Title' exception: $_"
            if (Test-Path $tmpBody) { Remove-Item $tmpBody -Force -ErrorAction SilentlyContinue }
            return
        }
    }

    # Graceful skip if field lookup empty (Section 2 failed — PAT permission issue)
    if ($fieldLookup.Keys.Count -eq 0) {
        Write-WarnMsg "  Skip project add (field lookup empty — check Section 2 output)"
        return
    }

    # Check if already in project (idempotent)
    $existingItems = gh project item-list $PROJECT_NUMBER --owner $OWNER --format json --limit 200 2>$null | ConvertFrom-Json
    $existingItem = $existingItems.items | Where-Object { $_.content.number -eq [int]$issueNumber }
    if ($existingItem) {
        Write-WarnMsg "  Already in project (item: $($existingItem.id))"
        $itemId = $existingItem.id
    } else {
        $addResult = gh project item-add $PROJECT_NUMBER --owner $OWNER --url $url --format json 2>&1 | Out-String
        try {
            $itemJson = $addResult | ConvertFrom-Json -ErrorAction Stop
            if (-not $itemJson.id) {
                Write-Fail "  Add to project fail: $addResult"
                return
            }
            $itemId = $itemJson.id
            Write-Success "  Added to project (item: $itemId)"
        } catch {
            Write-Fail "  Add to project parse fail: $addResult"
            return
        }
    }

    # Set Sprint
    if ($Sprint -and $fieldLookup.Sprint) {
        $optId = $fieldLookup.Sprint.Options[$Sprint]
        if ($optId) {
            gh project item-edit --id $itemId --project-id $PROJECT_ID --field-id $fieldLookup.Sprint.Id --single-select-option-id $optId 2>&1 | Out-Null
            Write-Step "  Sprint=$Sprint"
        }
    }
    # Set Lane
    if ($Lane -and $fieldLookup.Lane) {
        $optId = $fieldLookup.Lane.Options[$Lane]
        if ($optId) {
            gh project item-edit --id $itemId --project-id $PROJECT_ID --field-id $fieldLookup.Lane.Id --single-select-option-id $optId 2>&1 | Out-Null
            Write-Step "  Lane=$Lane"
        }
    }
    # Set Effort
    if ($Effort -and $fieldLookup.Effort) {
        $optId = $fieldLookup.Effort.Options[$Effort]
        if ($optId) {
            gh project item-edit --id $itemId --project-id $PROJECT_ID --field-id $fieldLookup.Effort.Id --single-select-option-id $optId 2>&1 | Out-Null
            Write-Step "  Effort=$Effort"
        }
    }
}

function Get-EpicBody {
    param(
        [string]$Tier,
        [string]$FeatureName,
        [string]$Scope,
        [string]$AC,
        [string]$Dependencies,
        [string]$DocsRef
    )
    $slug = $FeatureName.ToLower() -replace ' ', '-'
    return @"
## Mô tả

**Tier:** $Tier
**Feature:** $FeatureName

## Scope

$Scope

## Acceptance Criteria

$AC

## Dependencies

$Dependencies

## Tài liệu tham khảo

$DocsRef

## Checklist

- [ ] Viết spec chi tiết qua ``/spec`` workflow -> ``docs/specs/YYYY-MM-DD-$slug.md``
- [ ] Viết plan chia task qua ``/plan`` workflow -> ``docs/plans/$slug.md``
- [ ] Break down thành sub-tasks (1 PR <= 200 lines)
- [ ] Implement theo TDD (test trước code)
- [ ] Verify chạy thật trước claim done
- [ ] Self-review qua ``/review`` trước PR
- [ ] PR vào ``develop``, >=1 reviewer approve

---

> Epic link: ``docs/roadmap/milestones.md`` + ``docs/product/features.md``
"@
}

# ------------------------------------------------------------
# TIER 0 (8 issues)
# ------------------------------------------------------------

New-EpicIssue `
    -Title "[T0] Auth - Signup 5-screen + Login + Auto-login" `
    -Body (Get-EpicBody `
        -Tier "0 (Locket parity, must ship M1)" `
        -FeatureName "Auth" `
        -Scope "- Signup flow 5 screens: email -> password -> hoten -> username -> skip contacts`n- Login: email + password`n- Logout`n- Auto-login (Firebase Auth persistence)`n- Signup qua Google (OAuth)`n- Username unique validation real-time" `
        -AC "- User moi signup trong <60s`n- User login back voi email/password OK`n- Auto-login: reopen app khong can re-login`n- Username unique check real-time (debounce 300ms)`n- Google signup OK tren Android" `
        -Dependencies "- Firebase Auth SDK`n- Cloud Function validate username`n- Firestore collection ``users``" `
        -DocsRef "- Figma: ``docs/specs/figma_design/Dang ky_*.png``, ``Dang nhap_*.png```n- User stories: ``docs/product/user-stories.md``") `
    -Labels @("milestone:M1", "tier:0", "lane:specialty-be-native", "effort:l") `
    -Sprint "1" -Lane "Specialty-BE-Native" -Effort "L"

New-EpicIssue `
    -Title "[T0] Friends - Invite + Accept + Friend list" `
    -Body (Get-EpicBody `
        -Tier "0 (must ship M2)" `
        -FeatureName "Friends" `
        -Scope "- Invite qua username search`n- Invite qua share-link (deep link meep://invite/{uid})`n- Friend request accept/decline`n- Friend list view`n- Bidirectional friendship (sortedPair doc)" `
        -AC "- User invite qua username -> friend request sent`n- Deep link mo app -> pre-friend request auto-sent`n- Accept friend -> bidirectional relationship`n- Friend list load tu Firestore, sorted by displayName`n- Decline friend -> request deleted" `
        -Dependencies "- Auth feature`n- Firestore ``friendships`` + ``friend_requests```n- Cloud Function ``sendFriendRequest`` + ``acceptFriendRequest```n- Deep link config Android" `
        -DocsRef "- Data model: ``docs/architecture/data-model.md``") `
    -Labels @("milestone:M2", "tier:0", "lane:specialty-be-native", "effort:l") `
    -Sprint "2" -Lane "Specialty-BE-Native" -Effort "L"

New-EpicIssue `
    -Title "[T0] Camera basic - Back + Flip + Capture + Caption" `
    -Body (Get-EpicBody `
        -Tier "0 (must ship M2)" `
        -FeatureName "Camera basic" `
        -Scope "- Camera viewfinder (back camera default)`n- Flip front camera button`n- Capture button`n- Preview screen sau capture`n- Caption input (<=200 chars)`n- Album picker tu gallery" `
        -AC "- Camera mo <1.5s`n- Capture -> preview <500ms`n- Flip camera smooth, khong crash`n- Caption support Unicode (tieng Viet + emoji)`n- Album picker load <2s" `
        -Dependencies "- Package ``camera`` + ``image_picker```n- Permission CAMERA + READ_MEDIA_IMAGES" `
        -DocsRef "- Figma: ``docs/specs/figma_design/Trang chu.png``, ``Xem truoc anh chup.png``") `
    -Labels @("milestone:M2", "tier:0", "lane:specialty-be-native", "effort:m") `
    -Sprint "2" -Lane "Specialty-BE-Native" -Effort "M"

New-EpicIssue `
    -Title "[T0] Share photo - Upload + Metadata + Push trigger" `
    -Body (Get-EpicBody `
        -Tier "0 (must ship M2)" `
        -FeatureName "Share photo" `
        -Scope "- Upload anh -> Storage posts/{uid}/{postId}/{filename}.jpg`n- Create Firestore post doc (authorId, caption, recipients, type)`n- Cloud Function ``onPostCreated`` resize + EXIF strip`n- Fan-out -> ``feeds/{recipientUid}/posts/{postId}```n- Push notification cho recipients" `
        -AC "- Upload 5MB anh <5s tren 4G`n- EXIF location stripped server-side`n- Fan-out den recipients <10s`n- Push notification <10s tu trigger`n- Retry logic neu network fail" `
        -Dependencies "- Camera + caption feature`n- Cloud Function ``onPostCreated``, ``fanoutPost```n- FCM setup`n- Storage rules" `
        -DocsRef "- API: ``docs/architecture/api-catalog.md``") `
    -Labels @("milestone:M2", "tier:0", "lane:specialty-be-native", "effort:m") `
    -Sprint "2" -Lane "Specialty-BE-Native" -Effort "M"

New-EpicIssue `
    -Title "[T0] Feed - Vertical list + Cache + Pagination" `
    -Body (Get-EpicBody `
        -Tier "0 (must ship M2)" `
        -FeatureName "Feed" `
        -Scope "- Vertical scroll feed, 1 post/card full-width`n- Pull-to-refresh`n- Pagination (infinite scroll, 20 posts/page)`n- Cache anh (``cached_network_image``)`n- Offline support (cached posts)`n- Filter theo recipient (Moi nguoi / Space)" `
        -AC "- Initial load <3s tren 4G`n- Scroll >=55fps`n- Cached images render <100ms`n- Empty state khi chua co post`n- Pull-to-refresh re-fetch latest" `
        -Dependencies "- Firestore ``feeds/{uid}/posts```n- ``cached_network_image``" `
        -DocsRef "- Figma: ``docs/specs/figma_design/Dang anh*.png``") `
    -Labels @("milestone:M2", "tier:0", "lane:specialty-ui-design", "effort:m") `
    -Sprint "2" -Lane "Specialty-UI-Design" -Effort "M"

New-EpicIssue `
    -Title "[T0] Push notification - FCM Android + 5 events" `
    -Body (Get-EpicBody `
        -Tier "0 (must ship M3)" `
        -FeatureName "Push notification" `
        -Scope "- FCM Android setup (google-services.json + FirebaseMessagingService)`n- Device token registration`n- 5 event types: new post, friend request, friend accepted, reaction, RollCall weekly`n- Deep link: tap notif -> screen dung`n- Silent data message cho widget update" `
        -AC "- Delivered <10s tu trigger`n- Tap notif -> deep link dung screen`n- Background app nhan notif OK`n- Token refresh auto sync Firestore" `
        -Dependencies "- Cloud Functions triggers`n- ``firebase_messaging```n- Android manifest permissions" `
        -DocsRef "- API: ``docs/architecture/api-catalog.md``") `
    -Labels @("milestone:M3", "tier:0", "lane:specialty-be-native", "effort:m") `
    -Sprint "3" -Lane "Specialty-BE-Native" -Effort "M"

New-EpicIssue `
    -Title "[T0] Reaction - Single emoji react" `
    -Body (Get-EpicBody `
        -Tier "0 (must ship M3)" `
        -FeatureName "Reaction" `
        -Scope "- Emoji picker bottom of photo (5 preset: heart, laugh, fire, wow, cry)`n- Optimistic UI update`n- Firestore ``posts/{postId}/reactions/{uid}```n- Denormalize count (``reactionCounts``)`n- Cloud Function ``onReactionCreated`` increment + push notif" `
        -AC "- Tap emoji -> UI <100ms`n- Sync Firestore <500ms`n- Author nhan push notif`n- Double-tap same emoji -> toggle off`n- Counter accurate voi multiple users" `
        -Dependencies "- Post data model`n- FCM push`n- Cloud Function trigger" `
        -DocsRef "- Data model: ``docs/architecture/data-model.md``") `
    -Labels @("milestone:M3", "tier:0", "lane:specialty-ui-design", "effort:s") `
    -Sprint "3" -Lane "Specialty-UI-Design" -Effort "S"

New-EpicIssue `
    -Title "[T0] Widget Android - Latest image + Tap deep link" `
    -Body (Get-EpicBody `
        -Tier "0 (HEADLINE differentiator, must ship M3)" `
        -FeatureName "Widget Android" `
        -Scope "- Native Kotlin AppWidget`n- Render latest image tu feed user`n- Size 4x4 (medium) + 4x2 (small)`n- Tap widget -> deep link ``meep://post/{postId}```n- FCM data message silent push -> widget refresh`n- Placeholder khi chua co anh / app chua login" `
        -AC "- Widget add to home screen OK`n- Latest image render <500ms`n- Update sau FCM data message <30s`n- Tap -> deep link dung post`n- Unlogin: show 'Dang nhap de xem anh'" `
        -Dependencies "- Android native (Kotlin) via ``home_widget```n- FCM data message`n- Cloud Function trigger on new post" `
        -DocsRef "- Project context: ``.windsurf/rules/10-project-context.md``") `
    -Labels @("milestone:M3", "tier:0", "lane:specialty-be-native", "effort:l", "priority:critical") `
    -Sprint "3" -Lane "Specialty-BE-Native" -Effort "L"

# ------------------------------------------------------------
# TIER 0+ (4 issues)
# ------------------------------------------------------------

New-EpicIssue `
    -Title "[T0+] Diary basic - Text entry + 1-3 images attach" `
    -Body (Get-EpicBody `
        -Tier "0+ (Meep differentiator, must ship M3)" `
        -FeatureName "Diary basic" `
        -Scope "- Diary entry: title + body text (<=5000 chars) + 1-3 anh attach`n- Grid list view 2 cot`n- Detail view (body + anh swipe)`n- Privacy toggle: private (owner only) / public (Profile)`n- NO canvas editor, NO drawing, NO sticker (Tier 2)" `
        -AC "- Tao entry voi title + body + 2 anh OK`n- Grid view render thumbnail + title + date`n- Privacy toggle work (private -> owner only fetch)`n- Public entries hien tren Profile tab Memory`n- Edit + delete own entries" `
        -Dependencies "- Auth feature`n- Firestore ``diaries/{uid}/entries```n- Storage ``diaries/{uid}/{entryId}/{filename}.jpg```n- ``image_picker``" `
        -DocsRef "- Figma: ``docs/specs/figma_design/Nhat ky*.png``") `
    -Labels @("milestone:M3", "tier:0-plus", "lane:specialty-ui-design", "effort:m") `
    -Sprint "3" -Lane "Specialty-UI-Design" -Effort "M"

New-EpicIssue `
    -Title "[T0+] Space basic - Groups + Send photo to space" `
    -Body (Get-EpicBody `
        -Tier "0+ (must ship M3)" `
        -FeatureName "Space basic" `
        -Scope "- Tao Space voi name + iconKey (preset 6-8 icons)`n- Invite friends vao Space`n- Accept/decline Space invite`n- Send photo vao Space (recipient picker)`n- Feed filter theo Space`n- NO theme switch per Space (Tier 2), NO group chat (Tier 2)" `
        -AC "- Tao Space + invite 1-5 members OK`n- Members nhan push notif invite`n- Photo send to Space -> chi members nhan`n- Feed dropdown filter by Space work`n- Leave Space remove user khoi members list" `
        -Dependencies "- Friends feature`n- Firestore ``spaces/{spaceId}`` + ``spaces/{spaceId}/members```n- Cloud Function ``inviteToSpace``, ``acceptSpaceInvite```n- Recipient picker UI" `
        -DocsRef "- Data model: ``docs/architecture/data-model.md``") `
    -Labels @("milestone:M3", "tier:0-plus", "lane:specialty-be-native", "effort:m") `
    -Sprint "3" -Lane "Specialty-BE-Native" -Effort "M"

New-EpicIssue `
    -Title "[T0+] RollCall - Weekly notif + Multi-emoji react" `
    -Body (Get-EpicBody `
        -Tier "0+ (must ship M3)" `
        -FeatureName "RollCall" `
        -Scope "- Cloud Function cron Sunday 8pm: send RollCall notif toi all users`n- Special post screen: album picker filter anh 7 ngay gan nhat`n- NO caption, NO edit tren RollCall post`n- Post tag type='rollcall'`n- Multi-emoji react (1 user co the react nhieu emoji tren 1 post)`n- NO 168h archive (Tier 2), NO feed gating (Tier 2)" `
        -AC "- Cron trigger dung Sunday 8pm Asia/Ho_Chi_Minh`n- Push notif delivered toi all users`n- Album picker filter dung 7 ngay`n- Multi-react: 1 user react fire + heart + love tren 1 post`n- Counter accurate per emoji" `
        -Dependencies "- Push notification feature`n- Reaction feature (base)`n- Cloud Scheduler Firebase`n- Album picker voi date filter" `
        -DocsRef "- API: ``docs/architecture/api-catalog.md``") `
    -Labels @("milestone:M3", "tier:0-plus", "lane:specialty-be-native", "effort:m") `
    -Sprint "3" -Lane "Specialty-BE-Native" -Effort "M"

New-EpicIssue `
    -Title "[T0+] Profile screen - Avatar + Username + Bio + Grid posts" `
    -Body (Get-EpicBody `
        -Tier "0+ (must ship M2)" `
        -FeatureName "Profile screen" `
        -Scope "- Profile view own + friend`n- Avatar + displayName + username + bio`n- Stats: total posts + friends count + spaces count`n- Grid posts 3 cot (filtered theo recipient)`n- Tab Memory (public Diary entries)`n- Edit own profile (avatar + bio)" `
        -AC "- Profile own view load <1s`n- Friend profile chi show info public`n- Grid posts pagination 20/page`n- Edit avatar upload Storage OK`n- Bio <=200 chars validation" `
        -Dependencies "- Auth + Friends + Diary features`n- Firestore ``users/{uid}```n- Storage ``avatars/{uid}/{filename}.jpg``" `
        -DocsRef "- Figma: ``docs/specs/figma_design/Trang Profile.png``") `
    -Labels @("milestone:M2", "tier:0-plus", "lane:specialty-ui-design", "effort:s") `
    -Sprint "2" -Lane "Specialty-UI-Design" -Effort "S"

# ============================================================
# SUMMARY
# ============================================================

Write-Section "DONE"

Write-Host "Project URL: https://github.com/users/$OWNER/projects/$PROJECT_NUMBER" -ForegroundColor Cyan
Write-Host ""
Write-Host "Manual UI steps con lai (Phase D+E):" -ForegroundColor Yellow
Write-Host "  1. (Neu Section 1 warn) Edit Status field: rename Todo->Backlog + add Review"
Write-Host "     -> Settings -> Custom fields -> Status"
Write-Host ""
Write-Host "  2. Tao custom views:"
Write-Host "     -> + New view"
Write-Host "     -> View 'Sprint Board': Board layout, group by Status, filter Sprint=1"
Write-Host "     -> View 'By Lane': Board layout, group by Lane"
Write-Host "     -> View 'By Assignee': Table layout, group by Assignee"
Write-Host "     -> View 'Backlog': Table layout, sort by Effort"
Write-Host ""
Write-Host "  3. Workflow automation:"
Write-Host "     -> Settings -> Workflows"
Write-Host "     -> Enable: Auto-add issues from repo Meep"
Write-Host "     -> Enable: Item closed -> Status=Done"
Write-Host "     -> Enable: Pull request merged -> Status=Done"
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
