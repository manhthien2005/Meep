# scripts/modules/friend.ps1
# Module: Friend | Owner: KhoaLND | M2

function Create-FriendModule {
    $parentBody = @'
> **Tier:** T0 | **Milestone:** M2 | **Assignee:** KhoaLND
> **Spec:** `docs/specs/2026-05-22-friend.md`
> **Plan:** `docs/plans/2026-05-23-friend.md`
> **Todo:** `tasks/todo-friend.md`
> **Phụ thuộc vào:** Auth (UserProfile, currentUidProvider)
> **Được phụ thuộc bởi:** Settings, Chat, Feed, Notification, Profile, Space, Widget

## Mục tiêu
Cho phép user tìm bạn theo username, gửi/chấp nhận/từ chối lời mời kết bạn, xem danh sách bạn bè, xóa bạn, chia sẻ invite link, lọc feed theo từng người. Tối đa 20 bạn/user.

## Data model
**`/friendships/{pairId}`** — `pairId = min(uid1,uid2) + "_" + max(uid1,uid2)` (sorted deterministic)
```
uid1, uid2, members: List<String>, createdAt
```
**`/friend_requests/{requestId}`**
```
senderId, receiverId, status: pending|accepted|declined|cancelled, createdAt, updatedAt
```

## Màn hình & Figma
| Màn hình | Figma ID |
|---|---|
| Friend sheet (default) | `501:2054` |
| Friend sheet + Yêu cầu kết bạn | `710:3999` |
| Tìm kiếm — có kết quả | `710:2522` |
| FriendsButton dropdown (feed) | `472:2142` |

## Contract artifacts (ThienPDM đã merge qua LX2)
- `lib/features/friend/data/friendship.dart` — Friendship @freezed
- `lib/features/friend/data/friend_request.dart` — FriendRequest @freezed, `FriendRequestStatus` enum
- `lib/features/friend/data/friend_repository.dart` — abstract
- `lib/features/friend/data/friend_request_repository.dart` — abstract
- `lib/features/friend/application/friend_controller.dart` — stub
- `lib/features/friend/presentation/friend_sheet.dart` — stub
- `lib/features/friend/presentation/friend_filter_dropdown.dart` — stub
- `lib/core/utils/pair_id.dart` — `pairIdOf()` (đã có từ LX0)
- Route `/invite/:uid` + `isFriend()` rule helper + CF stubs

## Worst cases
- `acceptFriendRequest` fail → toast, friendship + conversation không được tạo (atomic batch)
- `acceptFriendRequest` fail vì đã đạt max 20 bạn → toast, card không biến mất
- Unfriend khi đang offline → optimistic, revert nếu fail
'@

    $subs = @(
        @{
            title = "[Friend] T1 — FirebaseFriendRepository + FirebaseFriendRequestRepository"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-friend.md` — Task T1
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/friend-data-layer`
> **Bị block bởi:** LX2 contracts đã merge

## Files cần tạo
- `lib/features/friend/data/firebase_friend_repository.dart` — impl `FriendRepository`
- `lib/features/friend/data/firebase_friend_request_repository.dart` — impl `FriendRequestRepository`
- `test/features/friend/data/firebase_friend_repository_test.dart`

## Acceptance criteria
- [ ] `searchUser(username)` lowercase → query `/users.where('username', isEqualTo, query.toLowerCase()).limit(1)` — **KHÔNG** qua `/usernames` collection
- [ ] `searchUser` tự filter kết quả là chính mình (`result.uid == currentUid` → skip)
- [ ] `getFriendUids(uid)` dùng `where('members', arrayContains, uid)` — không full-scan
- [ ] `sendFriendRequest` với `receiverId == currentUid` → throw `AppError` trước khi write
- [ ] `pairIdOf(a, b) == pairIdOf(b, a)` — unit test pass (cả 2 chiều)
- [ ] `flutter test test/features/friend/data/` — 0 failures

## Definition of Done
- [ ] Tests PASS (fake_cloud_firestore)
- [ ] `flutter analyze` clean
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Friend] T2 — FriendController"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-friend.md` — Task T2
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/friend-controller`
> **Bị block bởi:** {sub0} — T1 phải done

## Files cần tạo
- `lib/features/friend/application/friend_controller.dart` — `FriendState` + full impl 8 methods
- `test/features/friend/application/friend_controller_test.dart`

## `FriendState` schema
```dart
@freezed class FriendState {
  List<UserProfile> friends
  List<FriendRequest> pendingRequests  // in + out
  UserProfile? searchResult
  String searchQuery
  bool isLoading
  String? errorMessage
}
```

## Acceptance criteria
- [ ] `searchUser` debounce 500ms — không query khi đang typing
- [ ] `acceptFriendRequest` gọi CF callable, **KHÔNG** write Firestore trực tiếp
- [ ] Error CF "max 20 friends" → `errorMessage = "Bạn đã có 20 bạn bè..."`, card không biến mất
- [ ] `unfriend` optimistic-remove bạn trước khi server confirm
- [ ] `sendFriendRequest` success → search result đổi sang state "Đã gửi"
- [ ] `flutter test test/features/friend/application/` — 0 failures

## Definition of Done
- [ ] Tests PASS (mocktail)
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Friend] T3+4 — FriendSheet UI + FriendFilterDropdown + invite link"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-friend.md` — Task T3, T4
> **Estimate:** L (2 ngày) | **Branch:** `feat/<DevName>/friend-ui`
> **Bị block bởi:** {sub1} — T2 phải done
> **Figma:** FriendSheet `501:2054`, Search result `710:2522`, Dropdown `472:2142`

## Files cần tạo
- `lib/features/friend/presentation/friend_sheet.dart` — 3 sections: search + pending + friend list
- `lib/features/friend/presentation/widgets/friend_search_result_card.dart` — 2 states: chưa bạn (nút "Gửi kết bạn") / đã bạn (nút "Trang cá nhân" → FriendProfileScreen)
- `lib/features/friend/presentation/widgets/pending_request_card.dart` — "Chấp nhận" + ✕ (Figma `710:3999`)
- `lib/features/friend/presentation/widgets/friend_list_item.dart` — avatar + displayName + ✕
- `lib/features/friend/presentation/friend_filter_dropdown.dart`
- `lib/features/friend/presentation/widgets/invite_section.dart` — copy link + Messenger + Instagram
- `lib/core/router/app_router.dart` — **update:** handle `/invite/:uid` + `pendingInviteUid` ephemeral state

## Acceptance criteria
- [ ] Tap search bar → ẩn sections (Bạn bè + Chia sẻ + Yêu cầu), chỉ hiện search
- [ ] Section "Yêu cầu kết bạn" ẩn khi `pendingRequests.isEmpty`
- [ ] Confirm unfriend: title "Xóa {displayName} khỏi Meep của bạn?" (Figma `564:7178`)
- [ ] Copy link → toast "Đã sao chép liên kết", icon link → check (Figma `710:4189`)
- [ ] `/invite/:uid` khi chưa login → lưu `pendingInviteUid` → redirect `/intro` → sau auth navigate profile
- [ ] `FriendFilterDropdown`: chọn friend → title đổi `[avatar] [tên] ∧`

## Cross-module imports
- `FriendProfileScreen` từ **profile** (navigate khi tap "Trang cá nhân")
- `FeedFilter` từ **home-camera-feed** (FriendFilterDropdown update filter)

## Definition of Done
- [ ] Manual: search → send → accept → list cập nhật; unfriend confirm; invite copy
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Friend] T5+6 — CF acceptFriendRequest + onFriendshipDeleted"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-friend.md` — Task T5, T6
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/friend-cloud-functions`
> **Bị block bởi:** {sub0} — T1 phải done; LX4 Chat contracts (conversation schema)

## Files cần tạo
- `firebase/functions/src/friend/acceptFriendRequest.ts` — HTTPS Callable
- `firebase/functions/src/friend/onFriendshipDeleted.ts` — Firestore onDelete `/friendships/{pairId}`
- `firebase/functions/test/friend/acceptFriendRequest.test.ts`
- `firebase/functions/test/friend/onFriendshipDeleted.test.ts`

## Acceptance criteria — `acceptFriendRequest`
- [ ] Check `sender.friendCount < 20` **VÀ** `receiver.friendCount < 20` — cả 2 phải < 20
- [ ] Firestore batch: create `/friendships/{pairId}` + create `/conversations/{pairId}` (type=direct) + set `friend_requests.status = accepted` + increment `friendCount` cả 2 (FieldValue.increment(1))
- [ ] `conversationId == pairId` (sorted uid1_uid2)
- [ ] A→B và B→A gửi đồng thời → idempotent, 1 friendship duy nhất
- [ ] Return `{ success: true, pairId: string }`

## Acceptance criteria — `onFriendshipDeleted`
- [ ] Decrement `friendCount` cả 2 bằng transaction (idempotent)
- [ ] Update `/conversations/{pairId}.status = 'unfriended'` nếu tồn tại
- [ ] Batch delete: `/users/{uid1}/feed/` WHERE `authorId == uid2 AND spaceId == null` và ngược lại
- [ ] Space posts (`spaceId != null`) **KHÔNG** bị xóa khỏi feed
- [ ] `npm test` PASS

## Definition of Done
- [ ] `npm test` + `npm run lint` PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Friend] T7 — Firestore rules tests /friendships + /friend_requests"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-friend.md` — Task T7
> **Estimate:** S (~4h) | **Branch:** `test/<DevName>/friend-rules`
> **Bị block bởi:** {sub0} — T1 phải done (cần schema)

## File cần tạo
- `firebase/functions/test/rules/friend.rules.test.ts`

## Acceptance criteria (11 test cases)
- [ ] `/friendships/{id}`: uid1 read ✓, uid2 read ✓, stranger read ✗, unauthenticated ✗
- [ ] `/friendships/{id}`: client create → ✗ (CF Admin SDK only)
- [ ] `/friendships/{id}`: uid1 delete ✓, stranger delete ✗
- [ ] `/friend_requests/{id}`: sender create với `senderId != receiverId` ✓; self-request ✗
- [ ] `/friend_requests/{id}`: receiver update pending→accepted ✓; receiver update pending→cancelled ✗
- [ ] `/friend_requests/{id}`: sender update pending→cancelled ✓; sender update pending→accepted ✗
- [ ] `firebase emulators:exec --only firestore "npm run test:rules"` — PASS

## Definition of Done
- [ ] Rules tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        }
    )

    New-Module "👥 [Friend]" $parentBody $KhoaLND 2 $subs
}
