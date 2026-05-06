#!/usr/bin/env pwsh
# Fix duplicate/corrupted "Files phải đọc trước" sections in auth sub-issues.
# Removes ALL existing "Files ph*" sections, then re-inserts the correct one.

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:GH_TOKEN = [System.Environment]::GetEnvironmentVariable("GH_TOKEN", "User")
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$repo = "manhthien2005/Meep"
$insertBeforePattern = "## Acceptance criteria"

$ctx20 = @'
## Files phải đọc trước (context)

- `apps/mobile/lib/features/auth/data/auth_repository.dart` — abstract interface cần implement: method signatures, return types
- `apps/mobile/lib/core/error/app_error.dart` — AppError hierarchy cho error mapping Firebase → tiếng Việt

'@

$ctx21 = @'
## Files phải đọc trước (context)

- `apps/mobile/lib/features/auth/data/auth_repository.dart` — interface + pattern cho UserRepository
- `apps/mobile/lib/features/auth/data/user_profile.dart` — UserProfile model (T2 đã tạo)
- `apps/mobile/lib/features/auth/data/firebase_auth_repository.dart` — impl pattern tham khảo (T2)
- `firebase/firestore.rules` — existing rules base cần extend cho /users/{uid} + /usernames/{username}

'@

$ctx22 = @'
## Files phải đọc trước (context)

- `apps/mobile/lib/features/auth/data/auth_repository.dart` — available methods cho controller gọi
- `apps/mobile/lib/features/auth/data/user_profile.dart` — UserProfile model (dùng làm typed mock)
- `apps/mobile/lib/features/auth/data/firebase_auth_repository.dart` — real impl (T2) controller sẽ gọi
- `apps/mobile/lib/features/auth/application/auth_controller.dart` — existing stub pattern cần follow
- `apps/mobile/lib/core/error/app_error.dart` — error types cần propagate đúng

'@

$ctx23 = @'
## Files phải đọc trước (context)

- `apps/mobile/lib/features/auth/data/auth_repository.dart` — signInWithEmail + signInWithGoogle interface
- `apps/mobile/lib/features/auth/data/firebase_auth_repository.dart` — extend thêm signInWithGoogle impl
- `apps/mobile/lib/features/auth/application/auth_controller.dart` — SignUpController pattern để follow cho LoginController
- `apps/mobile/lib/core/error/app_error.dart` — error types

'@

$ctx24 = @'
## Files phải đọc trước (context)

- `apps/mobile/lib/features/auth/application/auth_controller.dart` — SignUpController provider, state machine
- `apps/mobile/lib/features/auth/data/user_profile.dart` — UserProfile model cho typed mock
- `apps/mobile/lib/core/router/app_router.dart` — route names + navigation context (/intro, /signup/*)
- `apps/mobile/lib/core/theme/app_theme.dart` — design tokens (colors, text styles)

'@

$ctx25 = @'
## Files phải đọc trước (context)

- `apps/mobile/lib/features/auth/application/auth_controller.dart` — SignUpController.createAccount() method + username availability state
- `apps/mobile/lib/features/auth/data/user_profile.dart` — UserProfile model cho typed mock
- `apps/mobile/lib/core/router/app_router.dart` — route sau khi signup thành công

'@

$ctx26 = @'
## Files phải đọc trước (context)

- `apps/mobile/lib/features/auth/application/auth_controller.dart` — LoginController.signIn() + forgotPassword()
- `apps/mobile/lib/core/router/app_router.dart` — route sau login thành công (/home)
- `apps/mobile/lib/core/theme/app_theme.dart` — shared design tokens (shared layout với signup screens)

'@

$issueMap = @{
    20 = $ctx20; 21 = $ctx21; 22 = $ctx22; 23 = $ctx23
    24 = $ctx24; 25 = $ctx25; 26 = $ctx26
}

foreach ($num in ($issueMap.Keys | Sort-Object)) {
    Write-Host "`n=== Issue #$num ===" -ForegroundColor Cyan

    $bodyJson = gh issue view $num --repo $repo --json body 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Host "  ✗ Fetch failed" -ForegroundColor Red; continue }

    $body = ($bodyJson | ConvertFrom-Json).body

    # Step 1: Remove ALL existing "Files ph*" sections (corrupted + correct duplicates)
    # Pattern: from "## Files ph" (any chars) up to but NOT including "## Acceptance criteria"
    $cleaned = [regex]::Replace($body, '(?s)## Files ph.+?(?=## Acceptance criteria)', '')

    # Step 2: Verify insertion point still exists
    if ($cleaned -notmatch [regex]::Escape($insertBeforePattern)) {
        Write-Host "  ✗ Insertion point not found after cleanup — skipping" -ForegroundColor Red
        continue
    }

    # Step 3: Insert correct section
    $newBody = $cleaned -replace [regex]::Escape($insertBeforePattern), ($issueMap[$num] + $insertBeforePattern)

    # Step 4: Write to temp file (UTF-8 no BOM) and update
    $tempFile = [System.IO.Path]::GetTempFileName() + ".md"
    [System.IO.File]::WriteAllText($tempFile, $newBody, [System.Text.UTF8Encoding]::new($false))

    gh issue edit $num --repo $repo --body-file $tempFile 2>&1 | Out-Null
    Remove-Item $tempFile -ErrorAction SilentlyContinue

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Fixed #$num" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Update failed #$num" -ForegroundColor Red
    }
}

Write-Host "`nDone." -ForegroundColor Green
