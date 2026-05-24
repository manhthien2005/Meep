# scripts/modules/profile.ps1
# Module: Profile | Owner: HanDHG | M2

function Create-ProfileModule {
    $parentBody = @'
> **Tier:** T0+ | **Milestone:** M2 (T8+9 slip to M3) | **Assignee:** HanDHG
> **Spec:** `docs/specs/2026-05-22-profile.md`
> **Plan:** `docs/plans/2026-05-23-profile.md`
> **Todo:** `tasks/todo-profile.md`
> **Phụ thuộc vào:** Auth (UserProfile model — source of truth, reauthenticate), Friend (FriendRepository, FriendSheet), Diary (DiaryRepository.getPublicEntries — M3)
> **Được phụ thuộc bởi:** Chat (FriendProfileScreen), Reaction (tap avatar → FriendProfileScreen)

## Mục tiêu
Màn hình profile cá nhân: xem ảnh, chỉnh sửa thông tin, đổi avatar, chia sẻ profile. Màn hình profile bạn bè: view-only.

## Contract artifacts (ThienPDM đã merge qua LX9)
- `lib/features/auth/data/user_profile.dart` — **verify** đủ fields mới: bio, dateOfBirth, phoneNumber, gender, postCount, friendCount, spaceCount
- `lib/features/profile/data/profile_repository.dart` — abstract
- `lib/features/profile/application/profile_controller.dart` — stub
- Screen stubs: profile_screen, edit_profile_screen, photo_detail_screen, avatar_picker_sheet
- `lib/shared/widgets/share_profile_sheet.dart` — shared (leader own)
- Routes: `/profile`, `/profile/edit`, `/profile/photo/:postId`, `/friend-profile/:uid`
- Storage rules `avatars/{uid}/` stub

## Figma refs
- ProfileScreen: `269:1941`, EditProfile: `573:2968`, AvatarPicker: `573:3561`
- PhotoDetail: `660:1940`

## Notes
- `isUsernameAvailable` KHÔNG có trong `ProfileRepository` — ProfileController inject `UserRepository` từ auth
- `ShareProfileSheet` đã tạo ở LX3 — không tạo lại
'@

    $subs = @(
        @{
            title = "[Profile] T1 — FirebaseProfileRepository"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-profile.md` — Task T1
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/profile-repository`
> **Bị block bởi:** LX9 contracts đã merge (UserProfile model đã update đủ fields)

## Files cần tạo
- `lib/features/profile/data/firebase_profile_repository.dart`
- `test/features/profile/data/firebase_profile_repository_test.dart`

## Acceptance criteria
- [ ] `updateProfile(uid, fields)` chỉ cho phép update: `displayName, username, avatarUrl, bio, dateOfBirth, phoneNumber, gender, updatedAt` — field khác → throw `AppError`
- [ ] `updateAvatar(uid, file)`: compress → upload `avatars/{uid}/avatar.jpg` (overwrite) → update `avatarUrl`
- [ ] `removeAvatar(uid)`: update `avatarUrl = null` (không xóa Storage file ngay)
- [ ] Avatar upload >5MB → throw `AppError` trước khi upload
- [ ] `watchUserProfile(uid)` — realtime stream, không one-time get
- [ ] `flutter test test/features/profile/data/` — 0 failures

## Cross-module imports
- `UserProfile` từ **auth** (`lib/features/auth/data/user_profile.dart`)

## Definition of Done
- [ ] Tests PASS (fake_cloud_firestore)
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Profile] T2 — ProfileController"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-profile.md` — Task T2
> **Estimate:** S (~4h) | **Branch:** `feat/<DevName>/profile-controller`
> **Bị block bởi:** {sub0} — T1 phải done

## Files cần tạo
- `lib/features/profile/application/profile_controller.dart` — `ProfileState` + full impl
- `test/features/profile/application/profile_controller_test.dart`

## Acceptance criteria
- [ ] `isUsernameAvailable` delegate sang `UserRepository.isUsernameAvailable()` — **KHÔNG** call Firestore trực tiếp trong ProfileController
- [ ] Avatar upload fail → rollback `ProfileState.profile.avatarUrl` về giá trị cũ
- [ ] `shareProfile(username)` → `AppConfig.shareBaseUrl/username` (không hardcode)
- [ ] `updateField('bio', value)` validate `value.length <= 150` trước khi gọi repo
- [ ] `flutter test test/features/profile/application/` — 0 failures

## Cross-module imports
- `UserRepository` từ **auth** (isUsernameAvailable)

## Definition of Done
- [ ] Tests PASS (mocktail)
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Profile] T3+4 — ProfileScreen + PhotoGrid + PhotoDetailScreen"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-profile.md` — Task T3, T4
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/profile-screens`
> **Bị block bởi:** {sub1} — T2 phải done
> **Figma:** ProfileScreen `269:1941`, PhotoDetail `660:1940`

## Files cần tạo
- `lib/features/profile/presentation/profile_screen.dart`
- `lib/features/profile/presentation/widgets/profile_header.dart` — avatar + username + bio
- `lib/features/profile/presentation/widgets/profile_stats.dart` — [N Khoảnh khắc] [N Bạn bè] [N Space]
- `lib/features/profile/presentation/widgets/photo_grid.dart` — 3-column, lazy load, cursor-paginated 9/batch
- `lib/features/profile/presentation/photo_detail_screen.dart` (Figma `660:1940`)

## Acceptance criteria
- [ ] Stats: Khoảnh khắc = `postCount`, Bạn bè = `friendCount`, Space = `spaceCount` (hiện `0` M2)
- [ ] Tap "N Bạn bè" → mở `FriendSheet`
- [ ] Avatar null → initials placeholder
- [ ] Photos tab: 3-column, 9/batch cursor-paginated, `PostRepository.getPostsByAuthor(currentUid)`
- [ ] Diary tab M2: empty state "Tính năng sắp ra mắt"
- [ ] PhotoDetail: swipe trái = ảnh cũ hơn; swipe phải = ảnh mới hơn; thumbnail strip (current = enlarged + outline turquoise `#00DEEE`)

## Cross-module imports
- `FriendSheet` từ **friend**
- `PostRepository` từ **home-camera-feed**
- `ShareModal` từ **home-camera-feed** (PhotoDetail topbar share icon)

## Definition of Done
- [ ] Manual: profile load → stats đúng; grid scroll; tap ảnh → detail swipe
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Profile] T5+6 — EditProfileScreen + AvatarPickerSheet"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-profile.md` — Task T5, T6
> **Estimate:** L (2 ngày) | **Branch:** `feat/<DevName>/profile-edit`
> **Bị block bởi:** {sub1} — T2 phải done
> **Figma:** EditProfile `573:2968`, AvatarPicker `573:3561`

## Files cần tạo
- `lib/features/profile/presentation/edit_profile_screen.dart`
- `lib/features/profile/presentation/widgets/date_picker_sheet.dart` — DD/MM/YYYY
- `lib/features/profile/presentation/widgets/gender_picker_sheet.dart` — Nam/Nữ/Khác
- `lib/features/profile/presentation/widgets/bio_input_sheet.dart` — max 150 chars
- `lib/features/profile/presentation/widgets/email_update_dialog.dart` — re-auth inline
- `lib/features/profile/presentation/widgets/notification_toggle.dart` — SharedPreferences
- `lib/features/profile/presentation/avatar_picker_sheet.dart`

## Acceptance criteria
- [ ] `displayName`: validate không rỗng, min 2 ký tự
- [ ] `username`: `isUsernameAvailable()` check → inline error nếu taken
- [ ] `bio`: max 150 chars, optional, hint "Tiểu sử hiển thị với bạn bè của bạn."
- [ ] Email update: `reauthenticateWithCredential()` required; Google user → `GoogleAuthProvider` (không hiện password field)
- [ ] `requires-recent-login` → re-auth dialog inline, **KHÔNG** show generic error
- [ ] Notification toggle: lưu vào `SharedPreferences` key `notification_enabled` — **KHÔNG** lưu Firestore, **KHÔNG** unsubscribe FCM
- [ ] AvatarPickerSheet: "Chọn từ thư viện" / "Chụp ảnh" / "Gỡ ảnh hiện tại" (ẩn khi `avatarUrl == null`)

## Cross-module imports
- `AuthRepository.reauthenticateWithCredential()`, `updateEmail()` từ **auth**

## Definition of Done
- [ ] Manual: edit name → save → update; avatar change; email re-auth
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Profile] T7 — FriendProfileScreen + ShareProfileSheet"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-profile.md` — Task T7
> **Estimate:** S (~4h) | **Branch:** `feat/<DevName>/profile-friend-screen`
> **Bị block bởi:** {sub2} — T3+4 phải done

## Files cần tạo
- `lib/features/profile/presentation/friend_profile_screen.dart`

## Acceptance criteria
- [ ] Chỉ accessible khi đã là bạn bè (`isFriend` check ở routing hoặc controller)
- [ ] Hiển thị: avatar + stats (postCount + friendCount; **KHÔNG** hiện Space) + bio + grid ảnh
- [ ] **KHÔNG** có nút Edit/Chia sẻ — chỉ có nút "Xóa bạn" (mở FriendSheet)
- [ ] Grid: `PostRepository.getPostsByAuthor(friendUid)` — chỉ posts có trong feed của mình
- [ ] Non-friend → error / redirect

## Cross-module imports
- `FriendSheet` từ **friend**
- `PostRepository` từ **home-camera-feed**

## Definition of Done
- [ ] Manual: tap friend avatar → FriendProfileScreen đúng
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Profile] T8+9 — Diary tab M3 + Firestore/Storage rules"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-profile.md` — Task T8, T9
> **Estimate:** S (~4h) | **Branch:** `feat/<DevName>/profile-diary-rules`
> **Bị block bởi:** {sub2} — T3+4 done; Diary T1 phải done (`getPublicEntries`)

## Files cần tạo
- `lib/features/profile/presentation/widgets/diary_tab_content.dart` — M2: empty state; M3: DiaryMoodCard grid
- `firebase/functions/test/rules/profile.rules.test.ts`

## Acceptance criteria — Diary tab M3
- [ ] M3: `DiaryRepository.getPublicEntries(uid)` → `DiaryMoodCard` grid chỉ public entries
- [ ] Tap card → `DiaryCanvasScreen(mode: read)` (view-only, không edit)
- [ ] Viewer không phải bạn bè → ẩn diary section

## Acceptance criteria — Rules
- [ ] `/users/{uid}` read by any authed ✓ (CANONICAL — cần cho username search)
- [ ] `/users/{uid}` update: chỉ allowed fields ✓; đổi `uid` hoặc `email` ✗
- [ ] Storage `avatars/{uid}/`: owner write ✓, >5MB ✗, non-image ✗; read by authed ✓

## Cross-module imports
- `DiaryRepository.getPublicEntries()` từ **diary**
- `DiaryMoodCard` từ **diary**

## Definition of Done
- [ ] Rules tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        }
    )

    New-Module "👤 [Profile]" $parentBody $HanDHG 2 $subs
}
