# scripts/modules/space.ps1
# Module: Space | Owner: ThienPDM | M3

function Create-SpaceModule {
    $parentBody = @'
> **Tier:** T0+ | **Milestone:** M3 | **Assignee:** ThienPDM
> **Spec:** `docs/specs/2026-05-23-space.md`
> **Plan:** `docs/plans/2026-05-23-space.md`
> **Todo:** `tasks/todo-space.md`
> **Phụ thuộc vào:** Friend (FriendRepository invite), Feed (Post.spaceId + FeedScreen gate), Chat (Conversation schema — CF createSpace)
> ⚠️ **Gate changes trước khi start:** Leader verify `Post.spaceId` đã có + update `FeedScreen` nhận `spaceId` param

## Mục tiêu
Nhóm chia sẻ ảnh: tạo Space với emoji icon + color, invite friends (≤9), camera context switch (viền = colorHex), feed riêng per Space, group chat.

## Data model
**`/spaces/{spaceId}`**: `spaceId, name (≤30), iconEmoji, colorHex (7 chars), creatorId, memberCount, memberIds List<String> (≤10), createdAt, deletedAt?`
**`/space_members/{spaceId}/members/{uid}`**: `uid, role (creator/member), joinedAt`
Soft delete pattern: `deleteSpace` → set `deletedAt = serverTimestamp()` (không hard delete)

## Contract artifacts (ThienPDM đã merge qua LX10)
- `lib/features/space/data/space.dart`, `space_member.dart` — @freezed
- `lib/features/space/data/space_repository.dart` — abstract
- Controller stub, widget stubs (4 widgets), routes `/space/create`, `/space/:spaceId`
- **Gate changes**: `Post.spaceId` đã reserve (LX5) + `FeedScreen(spaceId)` + `FeedFilter.space(spaceId)` case (LX10)
- CF stubs: createSpace, leaveSpace, kickMember, transferOwnership, onSpaceMemberAdded/Removed, onSpacePostCreated, onSpaceDeleted
- `emoji_picker_flutter` đã add (LX-PUBSPEC M3)
'@

    $subs = @(
        @{
            title = "[Space] T1+2 — FirebaseSpaceRepository + SpaceController"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-space.md` — Task T1, T2
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/space-data-controller`
> **Bị block bởi:** LX10 contracts + gate changes đã merge

## Files cần tạo
- `lib/features/space/data/firebase_space_repository.dart`
- `lib/features/space/application/space_controller.dart` — `SpaceState` + full impl
- Tests tương ứng

## Acceptance criteria — FirebaseSpaceRepository
- [ ] `watchMySpaces(uid)` query `/spaces.where('memberIds', arrayContains, uid)` filter `deletedAt == null`
- [ ] `deleteSpace(spaceId)` soft delete: update `deletedAt = serverTimestamp()` — **KHÔNG** hard delete
- [ ] Client **KHÔNG** create `/spaces` trực tiếp (rule `create: if false`)

## Acceptance criteria — SpaceController
- [ ] `createSpace(name, emoji, color, friendUids)`: validate `name.isNotEmpty`, `friendUids.length ≤ 9` → gọi CF `createSpace`
- [ ] `leaveSpace(spaceId)`: creator → throw `AppError("Chọn người quản trị mới trước")`
- [ ] `deleteSpace(spaceId)`: chỉ creator → soft delete → `onSpaceDeleted` CF tự trigger; non-creator → throw
- [ ] `flutter test test/features/space/` — 0 failures

## Definition of Done
- [ ] Tests PASS
- [ ] PR merged
'@
        },
        @{
            title = "[Space] T3 — SpaceCreateSheet (3-step flow)"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-space.md` — Task T3
> **Estimate:** L (2 ngày) | **Branch:** `feat/<DevName>/space-create-sheet`
> **Bị block bởi:** {sub0} — T1+2 phải done
> **Figma:** FriendSelectStep `269:1193`, SpaceConfigStep `269:1257`, IconBuilderStep `269:1334`/`596:1601`

## Files cần tạo
- `lib/features/space/presentation/space_create_sheet.dart` — 3-step bottom sheet
- `lib/features/space/presentation/widgets/friend_select_step.dart`
- `lib/features/space/presentation/widgets/space_config_step.dart`
- `lib/features/space/presentation/widgets/icon_builder_step.dart` — `emoji_picker_flutter` + color preset

## Acceptance criteria
- [ ] Step 1: search + checkbox select, "Tiếp tục" disabled khi 0 chọn, max 9 friends
- [ ] Step 2: preset 8 emoji + "+" button, "Hoàn tất" disabled khi name rỗng, loading spinner khi tạo
- [ ] Step 3 (từ "+"): `emoji_picker_flutter` tab + color preset grid — **KHÔNG** custom hex; "Xong" → về Step 2
- [ ] Back Step 2 → Step 1 giữ friends đã chọn; Back Step 3 → Step 2 bỏ thay đổi icon
- [ ] Create success → đóng sheet, navigate Feed per Space mới

## Cross-module imports
- `FriendRepository.watchFriends()` từ **friend**

## Definition of Done
- [ ] Manual: create Space 3-step → Space appear in list
- [ ] PR merged
'@
        },
        @{
            title = "[Space] T4+5 — Camera context switch + SpaceContextBadge + Feed per Space"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-space.md` — Task T4, T5
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/space-camera-feed`
> **Bị block bởi:** {sub1} — T3 done; Feed T5+6 FeedController done

## Files cần tạo/sửa
- `lib/features/space/presentation/space_context_bottom_sheet.dart`
- `lib/features/space/presentation/widgets/space_context_badge.dart`
- `lib/features/feed/presentation/widgets/camera_section.dart` — **update:** long-press FriendsButton → SpaceContextBottomSheet; viền + nút đổi màu theo `colorHex`
- `lib/features/feed/application/feed_controller.dart` — **update:** `FeedFilter.space(spaceId)` WHERE `spaceId == spaceId`
- `lib/features/feed/presentation/home_screen.dart` — **update:** optional `spaceId` param (leader gate từ LX10)

## Acceptance criteria
- [ ] Long-press FriendsButton camera → `SpaceContextBottomSheet` (khác tap = FriendSheet)
- [ ] Chọn Space → camera viền = `colorHex`, nút chụp = `colorHex`, badge "Đang gửi: [SpaceName]" hiện
- [ ] Chọn "All friends" → reset Camera về mặc định, badge ẩn
- [ ] `FeedFilter.space(spaceId)` query `/users/{uid}/feed WHERE spaceId == spaceId`
- [ ] Feed docs phải có `spaceId` field (CF `onPostCreated` đã set)
- [ ] **Leader gate change** — file thuộc Feed module, Space dev KHÔNG tự sửa mà qua leader

## Cross-module imports
- `AppCameraController` từ **home-camera-feed**
- `FeedController` từ **home-camera-feed**

## Definition of Done
- [ ] Manual: chọn Space → camera viền đổi → chụp → Space feed
- [ ] PR merged
'@
        },
        @{
            title = "[Space] T6-10 — Cloud Functions (8 functions)"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-space.md` — Task T6, T7, T8, T9, T10
> **Estimate:** L (2-3 ngày) | **Branch:** `feat/<DevName>/space-cloud-functions`
> **Bị block bởi:** {sub0} — T1+2 done; LX4 Chat contracts (conversation schema)

## Files cần tạo
- `firebase/functions/src/space/createSpace.ts` — HTTPS Callable
- `firebase/functions/src/space/leaveSpace.ts`, `kickMember.ts`, `transferOwnership.ts`
- `firebase/functions/src/space/onSpaceMemberAdded.ts`, `onSpaceMemberRemoved.ts`
- `firebase/functions/src/space/onSpacePostCreated.ts` — Firestore onCreate `/posts/{postId}` WHERE `spaceId != null`
- `firebase/functions/src/space/onSpaceDeleted.ts` — Firestore onUpdate `/spaces/{spaceId}` WHERE `deletedAt != null`
- Tests tương ứng

## Acceptance criteria — `createSpace`
- [ ] Batch atomic: `/spaces/{id}` + `/space_members/{id}/members/{uid}` cho tất cả + `/conversations/{id}` (type=space)
- [ ] `memberCount = friendUids.length + 1` (creator included)
- [ ] `memberIds` array và `space_members` subcollection sync trong cùng batch

## Acceptance criteria — `onSpacePostCreated`
- [ ] Guard: chỉ fire khi `post.spaceId != null`
- [ ] Đọc Space members → fan-out `/users/{uid}/feed/{postId}` cho tất cả members (kể cả author)
- [ ] FCM fan-out cho members có token — **KHÔNG** gửi cho author
- [ ] **Đây là nguồn duy nhất fan-out Space posts** (Feed `onPostCreated` skip khi `spaceId != null`)

## Acceptance criteria — `onSpaceDeleted`
- [ ] Trigger khi `deletedAt` từ null → timestamp
- [ ] Xóa `/space_members/{id}/members/*`
- [ ] Update `/conversations/{id}.status = 'deleted'` (giữ lịch sử)
- [ ] `npm test` PASS tất cả 8 functions

## Definition of Done
- [ ] `npm test` + `npm run lint` PASS
- [ ] PR merged
'@
        },
        @{
            title = "[Space] T10b+11 — SpaceManagementSheet + Firestore rules"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-space.md` — Task T10b, T11
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/space-management-rules`
> **Bị block bởi:** {sub3} — T6-10 CF done; {sub2} — T4+5 done (FeedScreen Space context)

## Files cần tạo
- `lib/features/space/presentation/space_management_sheet.dart`
- `lib/features/space/presentation/widgets/leave_space_dialog.dart`
- `lib/features/space/presentation/widgets/kick_member_dialog.dart`
- `lib/features/space/presentation/widgets/delete_space_dialog.dart`
- `firebase/functions/test/rules/space.rules.test.ts`

## Acceptance criteria — SpaceManagementSheet
- [ ] `...` icon hiện trên FeedScreen khi `spaceId != null`
- [ ] Creator: [Rời khỏi Space] + [Xóa Space] + [Kick thành viên]
- [ ] Member thường: chỉ [Rời khỏi Space]
- [ ] Creator leave: phải chọn creator mới trước → `transferOwnership()` → `leaveSpace()`
- [ ] Kick member: list members (trừ bản thân) → confirm → CF `kickMember`

## Acceptance criteria — Rules
- [ ] `/spaces/{id}`: member read ✓, non-member ✗, client create ✗ (CF only)
- [ ] `/space_members/{id}/members/{uid}`: member read ✓, client create/delete ✗ (CF only)

## Definition of Done
- [ ] Manual: kick; transfer; delete Space
- [ ] Rules tests PASS
- [ ] PR merged
'@
        }
    )

    New-Module "🌌 [Space]" $parentBody $ThienPDM 3 $subs
}
