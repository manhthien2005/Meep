<#
.SYNOPSIS
  Setup branch protection rules cho Meep repo.

.DESCRIPTION
  Auto setup theo ADR-0003:
  - Protect `develop` branch: require 1 approval + CODEOWNERS + resolve conversations
  - Create `deploy` branch nếu chưa có (from develop HEAD)
  - Protect `deploy` branch: stricter, same + linear history
  - Admin bypass ALLOWED (leader pre-team pragmatic)
  - Required status checks: KHÔNG set (chờ first PR để verify context names)

.NOTES
  Idempotent: safe re-run.
  Requires: gh CLI ≥2.40 với scopes `repo` + `admin:repo_hook` (classic PAT).
  Note: enforce_admins = false nghĩa là admin CÓ THỂ bypass (self-merge).
  Khi team join đầy đủ → update enforce_admins = true để strict workflow.

.EXAMPLE
  pwsh ./scripts/setup-branch-protection.ps1
#>

$ErrorActionPreference = 'Stop'

# Refresh PATH + GH_TOKEN (Windsurf IDE cache bypass)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$userToken = [System.Environment]::GetEnvironmentVariable("GH_TOKEN", "User")
if ($userToken) { $env:GH_TOKEN = $userToken }

$OWNER = "manhthien2005"
$REPO = "manhthien2005/Meep"

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

function Set-BranchProtection {
    param(
        [string]$Branch,
        [hashtable]$Payload
    )

    Write-Host "  -> Applying protection to '$Branch'" -ForegroundColor Gray
    $tmp = New-TemporaryFile
    try {
        $Payload | ConvertTo-Json -Depth 10 | Set-Content -Path $tmp -Encoding UTF8
        $result = gh api -X PUT "/repos/$REPO/branches/$Branch/protection" --input $tmp 2>&1 | Out-String
        $json = $result | ConvertFrom-Json -ErrorAction Stop
        if ($json.url) {
            Write-Host "  [OK] Protection applied to '$Branch'" -ForegroundColor Green
            Write-Host "       Required approvals: $($json.required_pull_request_reviews.required_approving_review_count)" -ForegroundColor Gray
            Write-Host "       CODEOWNERS review: $($json.required_pull_request_reviews.require_code_owner_reviews)" -ForegroundColor Gray
            Write-Host "       Admin enforce: $($json.enforce_admins.enabled)" -ForegroundColor Gray
            Write-Host "       Force push: $($json.allow_force_pushes.enabled)" -ForegroundColor Gray
            Write-Host "       Linear history: $($json.required_linear_history.enabled)" -ForegroundColor Gray
        } else {
            Write-Host "  [FAIL] Unexpected response: $result" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Exception: $_" -ForegroundColor Red
        Write-Host "         Raw: $result" -ForegroundColor DarkGray
    } finally {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
}

# ============================================================
# 1. DEVELOP branch
# ============================================================

Write-Section "1. PROTECT 'develop' BRANCH"

$developPayload = @{
    required_status_checks = $null   # Set later khi xác nhận CI context names
    enforce_admins = $false           # Admin bypass ALLOWED (anh chọn)
    required_pull_request_reviews = @{
        required_approving_review_count = 1
        dismiss_stale_reviews = $true
        require_code_owner_reviews = $true
        require_last_push_approval = $false
    }
    restrictions = $null              # No push restrictions (public contribution)
    required_linear_history = $false  # Allow merge commits on develop
    allow_force_pushes = $false
    allow_deletions = $false
    required_conversation_resolution = $true
    lock_branch = $false
    allow_fork_syncing = $true
}
Set-BranchProtection -Branch "develop" -Payload $developPayload

# ============================================================
# 2. CREATE 'deploy' branch if missing
# ============================================================

Write-Section "2. CHECK/CREATE 'deploy' BRANCH"

$branches = gh api "/repos/$REPO/branches" --jq '.[].name' 2>&1
$deployExists = $branches -contains "deploy"

if ($deployExists) {
    Write-Host "  [!] 'deploy' branch exists. Skip create." -ForegroundColor Yellow
} else {
    Write-Host "  -> Creating 'deploy' from develop HEAD" -ForegroundColor Gray
    # Get develop SHA
    $developSha = gh api "/repos/$REPO/branches/develop" --jq '.commit.sha' 2>&1
    if ($developSha -match "^[a-f0-9]{40}$") {
        $body = @{
            ref = "refs/heads/deploy"
            sha = $developSha.Trim()
        } | ConvertTo-Json
        $tmp = New-TemporaryFile
        $body | Set-Content -Path $tmp -Encoding UTF8
        try {
            gh api -X POST "/repos/$REPO/git/refs" --input $tmp 2>&1 | Out-Null
            Write-Host "  [OK] Created 'deploy' branch at $($developSha.Substring(0,7))" -ForegroundColor Green
        } catch {
            Write-Host "  [FAIL] Create deploy: $_" -ForegroundColor Red
        } finally {
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "  [FAIL] Can't get develop SHA: $developSha" -ForegroundColor Red
        exit 1
    }
}

# ============================================================
# 3. DEPLOY branch protection (stricter)
# ============================================================

Write-Section "3. PROTECT 'deploy' BRANCH"

$deployPayload = @{
    required_status_checks = $null
    enforce_admins = $false           # Admin bypass ALLOWED
    required_pull_request_reviews = @{
        required_approving_review_count = 1
        dismiss_stale_reviews = $true
        require_code_owner_reviews = $true
        require_last_push_approval = $true   # Stricter: last push must be re-approved
    }
    restrictions = $null
    required_linear_history = $true   # Stricter: no merge commits, clean history
    allow_force_pushes = $false
    allow_deletions = $false
    required_conversation_resolution = $true
    lock_branch = $false
    allow_fork_syncing = $true
}
Set-BranchProtection -Branch "deploy" -Payload $deployPayload

# ============================================================
# SUMMARY
# ============================================================

Write-Section "DONE"

Write-Host "Branches: https://github.com/$REPO/branches" -ForegroundColor Cyan
Write-Host "Settings > Branches: https://github.com/$REPO/settings/branches" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Sau khi first PR merged + CI chạy -> note actual context names"
Write-Host "     (tab Actions trong PR)"
Write-Host "  2. Update protection với required_status_checks qua gh api:"
Write-Host "     gh api -X PUT /repos/$REPO/branches/develop/protection/required_status_checks \\"
Write-Host "       -f strict=true \\"
Write-Host "       -f contexts[]='Branch name format' \\"
Write-Host "       -f contexts[]='Commit message format' \\"
Write-Host "       -f contexts[]='Flutter (mobile app)' \\"
Write-Host "       -f contexts[]='Cloud Functions (TypeScript)'"
Write-Host ""
Write-Host "  3. Khi team 4 dev fully onboard -> consider enforce_admins = true"
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
