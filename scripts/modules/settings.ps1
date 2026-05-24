# scripts/modules/settings.ps1
# Module: Settings | Owner: NganTNK | M2

function Create-SettingsModule {
    $parentBody = @'
> **Tier:** T0 | **Milestone:** M2 (CF slip to M3) | **Assignee:** NganTNK
> **Spec:** `docs/specs/2026-05-23-settings.md`
> **Plan:** `docs/plans/2026-05-23-settings.md`
> **Todo:** `tasks/todo-settings.md`
> **Phụ thuộc vào:** Auth (signOut, reauthenticate), Friend (unfriend), Notification (deleteFcmToken khi logout)
> **Được phụ thuộc bởi:** Chat (import BlockRepository), Home/Camera/Feed (import BlockRepository cho feed filter)

## Mục tiêu
Hub cài đặt: quản lý block, logout, xóa tài khoản, chia sẻ profile, widget setup.

## Data model — `/blocks/{blockId}`
`blockId = {blockerUid}_{blockedUid}` — **KHÔNG** sorted (khác với pairId)
```
blockId, blockerUid, blockedUid, createdAt
```

## Contract artifacts (ThienPDM đã merge qua LX3)
- `lib/features/settings/data/block.dart` — @freezed
- `lib/features/settings/data/block_repository.dart` — **canonical owner** (Chat + Feed import từ đây)
- Controller stub, screen stubs (5 screens), `ShareProfileSheet` shared widget (leader own)
- `isBlocked(uid)` rule helper (check cả 2 chiều)
- CF stubs: `blockUser`, `deleteAccount`

## Figma refs
- SettingsSheet: `572:4183`, BlockedAccountsPage: `572:4490`/`572:4839`
- BlockConfirmDialog: `605:1991`, WidgetConfirmSheet: `662:3341`
- DeleteAccountDialog: `572:4605`
'@

    $subs = @(
        @{
            title = "[Settings] T1 — FirebaseBlockRepository"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-settings.md` — Task T1
> **Estimate:** S (~4h) | **Branch:** `feat/<DevName>/settings-block-repository`
> **Bị block bởi:** LX3 contracts đã merge

## Files cần tạo
- `lib/features/settings/data/firebase_block_repository.dart`
- `test/features/settings/data/firebase_block_repository_test.dart`

## Acceptance criteria
- [ ] `blockUser(targetUid)` gọi CF callable `blockUser` — **KHÔNG** write Firestore trực tiếp (CF Admin SDK bypass rules)
- [ ] `unblockUser(targetUid)` xóa `/blocks/{currentUid}_{targetUid}` client-side (OK vì blocker delete)
- [ ] `isBlocked(uid)` check cả 2 chiều: tồn tại `/blocks/{me}_{uid}` OR `/blocks/{uid}_{me}` → true
- [ ] `watchBlockedUsers()` query `where('blockerUid', isEqualTo, currentUid)` — chỉ list người mình block
- [ ] `flutter test test/features/settings/data/` — 0 failures

## Definition of Done
- [ ] Tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Settings] T2 — SettingsSheet layout + static pages"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-settings.md` — Task T2
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/settings-sheet-ui`
> **Bị block bởi:** LX3 contracts (song song T1)
> **Figma:** SettingsSheet `572:4183`

## Files cần tạo
- `lib/features/settings/presentation/settings_sheet.dart`
- `lib/features/settings/presentation/widgets/settings_header.dart` — avatar + username + copy link
- `lib/features/settings/presentation/widgets/space_quick_row.dart` — mock pre-M3
- `lib/features/settings/presentation/terms_page.dart` — static text
- `lib/features/settings/presentation/privacy_policy_page.dart` — static text

## Acceptance criteria
- [ ] Trigger: tap avatar góc phải topbar → SettingsSheet slide up
- [ ] Tap "👥 N người bạn" → đóng SettingsSheet → mở FriendSheet
- [ ] Tap "↗ Chia sẻ" → `ShareProfileSheet` với URL `meep://profile/{username}`
- [ ] SpaceQuickRow pre-M3: mock + tap "Tạo" → toast "Tính năng đang phát triển"
- [ ] Tap "Thêm tiện ích" → mở `WidgetConfirmSheet`
- [ ] Copy link → clipboard + toast "Đã sao chép liên kết", dùng `AppConfig.shareBaseUrl`

## Cross-module imports
- `FriendSheet` từ **friend**

## Definition of Done
- [ ] Manual: mở SettingsSheet → layout đúng Figma
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Settings] T3+4 — SettingsController + BlockedAccountsPage + dialogs"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-settings.md` — Task T3, T4
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/settings-controller-ui`
> **Bị block bởi:** {sub0} — T1 done; {sub1} — T2 done

## Files cần tạo
- `lib/features/settings/application/settings_controller.dart` — `SettingsState` + impl: `logout`, `copyProfileLink`, `shareProfile`
- `lib/features/settings/presentation/blocked_accounts_page.dart` (Figma `572:4490`)
- `lib/features/settings/presentation/block_confirm_dialog.dart` (Figma `605:1991`) — **shared với Feed** (PhotoActionSheet gọi widget này)
- `lib/features/settings/presentation/widget_confirm_sheet.dart` (Figma `662:3341`)
- `lib/features/settings/presentation/logout_confirm_dialog.dart`

## Acceptance criteria — SettingsController
- [ ] `logout()`: gọi `deleteFcmToken()` (Notification) → `AuthRepository.signOut()` → clear SharedPreferences → `GoRouter.go('/intro')`
- [ ] `logout()` offline vẫn hoạt động (Firebase clears local session locally)
- [ ] `copyProfileLink(username)` → clipboard = `meep://profile/{username}`

## Acceptance criteria — BlockedAccountsPage
- [ ] Load stream `watchBlockedUsers()`, list avatar + username + "Bỏ chặn" button
- [ ] Tap "Bỏ chặn" → confirm "Bỏ chặn {username}?" → [Xác nhận] → `unblockUser()` → removed

## Acceptance criteria — BlockConfirmDialog (shared)
- [ ] Block success → button đổi "[Đã chặn!]" state (Figma `624:1906`)
- [ ] `WidgetConfirmSheet`: tap [Thêm] → `requestPinAppWidget()` Android API
- [ ] `flutter test test/features/settings/application/` — 0 failures

## Cross-module imports
- `AuthRepository` từ **auth**
- `NotificationRepository.deleteFcmToken()` từ **notification**

## Definition of Done
- [ ] Tests PASS
- [ ] Manual: logout → IntroPage; block từ PhotoActionSheet → BlockedAccountsPage
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Settings] T5+6+7 — CF blockUser + deleteAccount + DeleteAccountDialog"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-settings.md` — Task T5, T6, T7
> **Estimate:** L (2-3 ngày) | **Branch:** `feat/<DevName>/settings-cloud-functions`
> **Bị block bởi:** {sub2} — T3 phải done (cần SettingsController.deleteAccount); LX3 contracts cho CF stubs

## Files cần tạo
- `firebase/functions/src/settings/blockUser.ts` — HTTPS Callable
- `firebase/functions/src/settings/deleteAccount.ts` — HTTPS Callable
- `lib/features/settings/presentation/delete_account_dialog.dart` (Figma `572:4605`)
- Tests tương ứng

## Acceptance criteria — `blockUser`
- [ ] Guard: `blockerUid != targetUid` (no self-block) → throw `INVALID_ARGUMENT`
- [ ] Batch: create `/blocks/{blockerUid}_{targetUid}` + delete `/friendships/{pairId}` nếu tồn tại + update `/conversations/{pairId}.status = 'blocked'` nếu tồn tại
- [ ] Idempotent: block doc đã tồn tại → không throw, return success
- [ ] Return `{ success: true }`

## Acceptance criteria — `deleteAccount`
- [ ] Thứ tự: Storage buckets → Firestore subcollections → Firestore documents → `admin.auth().deleteUser(uid)` **(Auth xóa CUỐI CÙNG)**
- [ ] Idempotent: check existence trước mỗi bước, skip nếu đã xóa
- [ ] CF fail giữa chừng → Auth account vẫn còn → user có thể retry

## Acceptance criteria — DeleteAccountDialog
- [ ] Step 1: confirm → Step 2
- [ ] Step 2 email user: hiện password field inline
- [ ] Step 2 Google user: trigger `reauthenticateWithCredential(GoogleAuthProvider)`
- [ ] `requires-recent-login` → hiện error inline, **KHÔNG** auto-dismiss dialog
- [ ] `npm test` PASS

## Definition of Done
- [ ] `npm test` + `npm run lint` PASS
- [ ] Manual staging: delete account cascade đúng
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Settings] T8 — Firestore rules tests /blocks + CF tests"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-settings.md` — Task T8
> **Estimate:** S (~4h) | **Branch:** `test/<DevName>/settings-rules`
> **Bị block bởi:** {sub0} — T1 done; {sub3} — T5+6+7 done

## File cần tạo
- `firebase/functions/test/rules/settings.rules.test.ts`

## Acceptance criteria
- [ ] `/blocks/{id}`: blocker read ✓, blocked read ✓, stranger read ✗
- [ ] `/blocks/{id}`: client create → ✗ (CF only); update → ✗; blocker delete ✓
- [ ] CF `blockUser`: self-block guard ✗, success ✓, already blocked idempotent ✓
- [ ] CF `deleteAccount`: no re-auth → reject; cascade order đúng ✓; idempotent ✓

## Definition of Done
- [ ] Rules tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        }
    )

    New-Module "⚙️ [Settings]" $parentBody $NganTNK 2 $subs
}
