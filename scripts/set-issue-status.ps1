#!/usr/bin/env pwsh
# Set the Status field of a GitHub Project v2 item linked to an issue.
# Usage: pwsh -File scripts/set-issue-status.ps1 -IssueNum 22 -Status "In Progress"
# Valid statuses: Backlog | In Progress | Review | Done

param(
    [Parameter(Mandatory)][int]$IssueNum,
    [Parameter(Mandatory)][ValidateSet("Backlog","In Progress","Review","Done")][string]$Status
)

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
$env:GH_TOKEN = [System.Environment]::GetEnvironmentVariable("GH_TOKEN","User")
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$repo        = "manhthien2005/Meep"
$projectNum  = 2
$owner       = "manhthien2005"
$projectId   = "PVT_kwHOA-drWs4BWVYx"
$statusField = "PVTSSF_lAHOA-drWs4BWVYxzhRqkZA"

$optionIds = @{
    "Backlog"     = "f75ad846"
    "In Progress" = "47fc9ee4"
    "Review"      = "89e02f53"
    "Done"        = "98236657"
}

# Find project item ID for this issue
$items = gh project item-list $projectNum --owner $owner --format json 2>&1 | ConvertFrom-Json
$item  = $items.items | Where-Object { $_.content.number -eq $IssueNum }

if (-not $item) {
    Write-Host "✗ Issue #$IssueNum not found in project board" -ForegroundColor Red
    exit 1
}

$itemId = $item.id
Write-Host "Issue #$IssueNum → item $itemId → setting '$Status'..." -ForegroundColor Cyan

gh project item-edit `
    --project-id $projectId `
    --id $itemId `
    --field-id $statusField `
    --single-select-option-id $optionIds[$Status] 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ #$IssueNum status → $Status" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to update status" -ForegroundColor Red
    exit 1
}
