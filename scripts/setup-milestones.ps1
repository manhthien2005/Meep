<#
.SYNOPSIS
  Tạo 3 GitHub Milestones (M1/M2/M3) + assign 12 Epic issues.

.DESCRIPTION
  - M1: Foundation + Auth, due 2026-05-13
  - M2: Social Core, due 2026-05-27
  - M3: Differentiator + Demo, due 2026-06-09
  - Idempotent: check milestone tồn tại trước khi tạo
  - Assign issues theo mapping trong docs/roadmap/milestones.md

.NOTES
  Due dates theo timeline trong docs/roadmap/milestones.md (30/4 → 9/6/2026).
  Label `milestone:M1/M2/M3` đã gán rồi, script này thêm GitHub native Milestone object.

.EXAMPLE
  pwsh ./scripts/setup-milestones.ps1
#>

$ErrorActionPreference = 'Stop'

# Refresh PATH + GH_TOKEN (Windsurf IDE cache bypass)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$userToken = [System.Environment]::GetEnvironmentVariable("GH_TOKEN", "User")
if ($userToken) { $env:GH_TOKEN = $userToken }

$OWNER = "manhthien2005"
$REPO = "manhthien2005/Meep"

# ============================================================
# MILESTONE DATA
# ============================================================

$milestones = @(
    @{
        Title = "M1 — Foundation + Auth"
        Description = "Setup CI/CD + Firebase + Auth feature. End of M1: 4 dev signup/login được, CI pipeline work. Source: docs/roadmap/milestones.md §M1."
        DueOn = "2026-05-13T17:00:00Z"   # 13/5 23:59 GMT+7 → 16:59 UTC (safe 17:00)
    },
    @{
        Title = "M2 — Social Core"
        Description = "Friends + Camera + Share photo + Feed + Profile. Team test được social flow end-to-end. Source: docs/roadmap/milestones.md §M2."
        DueOn = "2026-05-27T17:00:00Z"
    },
    @{
        Title = "M3 — Differentiator + Demo"
        Description = "Push + Reaction + Widget Android + Diary + Space + RollCall. Demo day 9/6. Source: docs/roadmap/milestones.md §M3."
        DueOn = "2026-06-09T17:00:00Z"
    }
)

# Mapping: issue number → milestone title
$issueMilestone = @{
    1  = "M1 — Foundation + Auth"          # Auth
    2  = "M2 — Social Core"                # Friends
    3  = "M2 — Social Core"                # Camera
    4  = "M2 — Social Core"                # Share photo
    5  = "M2 — Social Core"                # Feed
    12 = "M2 — Social Core"                # Profile (partial M1, final M2)
    6  = "M3 — Differentiator + Demo"      # Push notification
    7  = "M3 — Differentiator + Demo"      # Reaction
    8  = "M3 — Differentiator + Demo"      # Widget Android
    9  = "M3 — Differentiator + Demo"      # Diary
    10 = "M3 — Differentiator + Demo"      # Space
    11 = "M3 — Differentiator + Demo"      # RollCall
}

# ============================================================
# HELPERS
# ============================================================

function Get-ExistingMilestones {
    $result = gh api "/repos/$REPO/milestones?state=all" 2>&1 | Out-String
    try {
        return $result | ConvertFrom-Json
    } catch {
        Write-Host "  [FAIL] Parse milestones list: $result" -ForegroundColor Red
        return @()
    }
}

function Create-OrUpdateMilestone {
    param(
        [string]$Title,
        [string]$Description,
        [string]$DueOn,
        [array]$Existing
    )

    $match = $Existing | Where-Object { $_.title -eq $Title }

    if ($match) {
        Write-Host "  [!] '$Title' exists (number=$($match.number)). Update description + due_on." -ForegroundColor Yellow
        $tmp = New-TemporaryFile
        $payload = @{
            title = $Title
            description = $Description
            due_on = $DueOn
            state = "open"
        } | ConvertTo-Json -Depth 3
        [System.IO.File]::WriteAllText($tmp.FullName, $payload, [System.Text.UTF8Encoding]::new($false))
        try {
            gh api -X PATCH "/repos/$REPO/milestones/$($match.number)" --input $tmp.FullName 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "      [OK] Updated" -ForegroundColor Green
            }
        } finally {
            Remove-Item $tmp.FullName -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "  -> Creating '$Title'" -ForegroundColor Gray
        $tmp = New-TemporaryFile
        $payload = @{
            title = $Title
            description = $Description
            due_on = $DueOn
            state = "open"
        } | ConvertTo-Json -Depth 3
        [System.IO.File]::WriteAllText($tmp.FullName, $payload, [System.Text.UTF8Encoding]::new($false))
        try {
            $result = gh api -X POST "/repos/$REPO/milestones" --input $tmp.FullName 2>&1 | Out-String
            $json = $result | ConvertFrom-Json -ErrorAction Stop
            if ($json.number) {
                Write-Host "      [OK] Created (number=$($json.number))" -ForegroundColor Green
            } else {
                Write-Host "      [FAIL] Unexpected response: $result" -ForegroundColor Red
            }
        } catch {
            Write-Host "      [FAIL] Exception: $_" -ForegroundColor Red
        } finally {
            Remove-Item $tmp.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

function Assign-IssueMilestone {
    param(
        [int]$IssueNumber,
        [string]$MilestoneTitle
    )

    Write-Host "   -> Issue #$IssueNumber → $MilestoneTitle" -ForegroundColor Gray
    $result = gh issue edit $IssueNumber --repo $REPO --milestone $MilestoneTitle 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      [OK]" -ForegroundColor Green
    } else {
        Write-Host "      [FAIL] $result" -ForegroundColor Red
    }
}

# ============================================================
# MAIN
# ============================================================

Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "SETUP 3 MILESTONES + ASSIGN 12 ISSUES" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan

# Phase 2.1: Create/Update milestones
Write-Host ""
Write-Host "2.1. Create/Update milestones" -ForegroundColor Cyan

$existing = Get-ExistingMilestones
foreach ($ms in $milestones) {
    Create-OrUpdateMilestone -Title $ms.Title -Description $ms.Description -DueOn $ms.DueOn -Existing $existing
}

# Phase 2.2: Assign issues
Write-Host ""
Write-Host "2.2. Assign 12 issues" -ForegroundColor Cyan

foreach ($issue in $issueMilestone.GetEnumerator() | Sort-Object Key) {
    Assign-IssueMilestone -IssueNumber $issue.Key -MilestoneTitle $issue.Value
}

# ============================================================
# DONE
# ============================================================

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "DONE" -ForegroundColor Green
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""
Write-Host "Verify:" -ForegroundColor Yellow
Write-Host "  Milestones: https://github.com/$REPO/milestones"
Write-Host "  Each milestone has progress bar + due date + linked issues"
Write-Host ""
