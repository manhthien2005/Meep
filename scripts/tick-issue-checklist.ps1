#!/usr/bin/env pwsh
# Mark all acceptance criteria checkboxes as done (- [ ] → - [x]) in a GitHub issue.
# Safe: only replaces within the "## Acceptance criteria" section.
# Usage: pwsh -File scripts/tick-issue-checklist.ps1 -IssueNum 22

param([Parameter(Mandatory)][int]$IssueNum)

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
$env:GH_TOKEN = [System.Environment]::GetEnvironmentVariable("GH_TOKEN","User")
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$repo = "manhthien2005/Meep"

# Fetch body with proper UTF-8 decoding
$body = (gh issue view $IssueNum --repo $repo --json body 2>&1 | ConvertFrom-Json).body

if (-not $body) {
    Write-Host "✗ Could not fetch issue #$IssueNum body" -ForegroundColor Red
    exit 1
}

# Find the Acceptance criteria section and replace only within it
# Pattern: from "## Acceptance criteria" to the next "##" heading (or end of string)
$sectionHeader = "## Acceptance criteria"
$startIdx = $body.IndexOf($sectionHeader)

if ($startIdx -lt 0) {
    Write-Host "⚠  No '## Acceptance criteria' section found in #$IssueNum" -ForegroundColor Yellow
    exit 0
}

# Find next section heading after the criteria section
$afterSection = $body.IndexOf("`n## ", $startIdx + $sectionHeader.Length)

$before   = $body.Substring(0, $startIdx)
$section  = if ($afterSection -gt 0) { $body.Substring($startIdx, $afterSection - $startIdx) } else { $body.Substring($startIdx) }
$after    = if ($afterSection -gt 0) { $body.Substring($afterSection) } else { "" }

# Count unchecked items
$unchecked = ([regex]::Matches($section, '- \[ \]')).Count
if ($unchecked -eq 0) {
    Write-Host "✅ #$IssueNum — all criteria already checked" -ForegroundColor Green
    exit 0
}

# Replace - [ ] with - [x] only within this section
$updatedSection = $section -replace '- \[ \]', '- [x]'
$newBody = $before + $updatedSection + $after

# Write temp file (UTF-8 no BOM) and update issue
$tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString() + ".md")
[System.IO.File]::WriteAllText($tempFile, $newBody, [System.Text.UTF8Encoding]::new($false))

gh issue edit $IssueNum --repo $repo --body-file $tempFile 2>&1 | Out-Null
Remove-Item $tempFile -ErrorAction SilentlyContinue

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ #$IssueNum — $unchecked criteria marked done" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to update #$IssueNum" -ForegroundColor Red
    exit 1
}
