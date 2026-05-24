# scripts/modules/chat.ps1
# Module: Chat | Owner: NganTNK | M3

function Create-ChatModule {
    $parentBody = @'
> **Tier:** T1 Stretch (1-1) + T0+ exception (Group Chat ship cùng Space M3) | **Assignee:** NganTNK
> **Spec:** `docs/specs/2026-05-23-chat.md`
> **Plan:** `docs/plans/2026-05-23-chat.md`
> **Todo:** `tasks/todo-chat.md`
> **Phụ thuộc vào:** Friend (CF acceptFriendRequest tạo conversation, FriendController.unfriend), Settings (BlockRepository — canonical owner)
> **Được phụ thuộc bởi:** Space (GroupChatScreen)

## Mục tiêu
Inbox + Chat 1-1 (T1 stretch) + Group Chat per Space (T0+, ship cùng Space M3).

## Data model
**`/conversations/{conversationId}`**: `conversationId, type (direct/space), participantIds, spaceId?, quotedPostId?, lastMessage, lastMessageAt, lastSenderId, status (active/blocked/unfriended), createdAt`
**`/conversations/{id}/messages/{msgId}`**: `messageId, senderId, text (≤500), createdAt`

`conversationId` của 1-1 = `pairId` (sorted uid1_uid2) — consistent với `/friendships/{pairId}`

## Contract artifacts (ThienPDM đã merge qua LX4)
- `lib/features/chat/data/conversation.dart`, `message.dart` — @freezed
- `lib/features/chat/data/conversation_repository.dart` — abstract
- Controller stub, screen stubs (4), routes `/inbox`, `/chat/:conversationId`
- `BlockRepository` **KHÔNG** define trong chat — import từ settings

## Figma refs
- InboxScreen: `269:942`, ChatScreen 1-1: `564:6934`, GroupChatScreen: `564:8603`
- SpaceMembersSheet: `564:8896`, ChatMenu: `564:6965`
'@

    $subs = @(
        @{
            title = "[Chat] T1+2 — FirebaseConversationRepository + ChatController"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-chat.md` — Task T1, T2
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/chat-repository-controller`
> **Bị block bởi:** LX4 contracts đã merge; Friend T5+6 CF done (conversation tạo khi accept)

## Files cần tạo
- `lib/features/chat/data/firebase_conversation_repository.dart`
- `lib/features/chat/application/chat_controller.dart` — `ChatState` + full impl
- Tests tương ứng

## Acceptance criteria — Repository
- [ ] `watchConversations()` filter `status != 'blocked'` — blocked conversations ẩn khỏi Inbox
- [ ] `getOrCreateConversation(peerUid)` idempotent — tạo mới nếu không tồn tại, trả existing nếu đã có
- [ ] `sendMessage` với `text.length > 500` → throw `AppError` trước khi write
- [ ] `sendMessage` với `text.isEmpty` → throw `AppError`
- [ ] `watchMessages` sort `createdAt ASC` (chronological)
- [ ] `getOrCreateConversation` chỉ là fallback — 1-1 conversation bình thường đã tạo bởi CF `acceptFriendRequest`

## Acceptance criteria — Controller
- [ ] `sendMessage` **KHÔNG** optimistic — chỉ append sau Firestore confirm
- [ ] `sendMessageFromFeed(postId, authorId, text)` gọi `getOrCreateConversation(authorId)` trước
- [ ] `getConversations()` sort `lastMessageAt DESC`
- [ ] Error network → `errorMessage = "Gửi thất bại — thử lại"`, message không xuất hiện
- [ ] `flutter test test/features/chat/` — 0 failures

## Cross-module imports
- `BlockRepository` từ **settings** (`lib/features/settings/data/block_repository.dart`)

## Definition of Done
- [ ] Tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Chat] T3+4 — InboxScreen + ChatScreen 1-1"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-chat.md` — Task T3, T4
> **Estimate:** L (2 ngày) | **Branch:** `feat/<DevName>/chat-inbox-screen`
> **Bị block bởi:** {sub0} — T1+2 phải done
> **Figma:** InboxScreen `269:942`, ChatScreen `564:6934`

## Files cần tạo
- `lib/features/chat/presentation/inbox_screen.dart`
- `lib/features/chat/presentation/widgets/conversation_tile.dart`
- `lib/features/chat/presentation/chat_screen.dart`
- `lib/features/chat/presentation/widgets/quoted_photo_block.dart` — thumbnail 301×301 + Note pill + timestamp
- `lib/features/chat/presentation/widgets/message_bubble.dart` — trái/phải
- `lib/features/chat/presentation/widgets/chat_input_bar.dart`

## Acceptance criteria — InboxScreen
- [ ] Sort by `lastMessageAt DESC`
- [ ] Empty state: "Chưa có tin nhắn nào — reply một ảnh để bắt đầu"
- [ ] Skeleton loading khi fetch
- [ ] Conversations `status == 'blocked'` **KHÔNG** hiện (filter bởi `watchConversations`)

## Acceptance criteria — ChatScreen 1-1
- [ ] Bubble trái = đối phương: `[avatar] [text bubble]`; bubble phải = mình: `[text bubble]` (Figma `564:6934`)
- [ ] Quoted photo block đầu thread: thumbnail + caption pill + `"DD thg M HH:mm"`
- [ ] Send button disabled khi input rỗng
- [ ] `status == 'unfriended'`: input bar ẩn, banner "Hãy thêm bạn lại để nhắn tin"
- [ ] `status == 'blocked'`: input bar ẩn, Firestore rule enforce không gửi được
- [ ] `limit(50)` messages + load-more khi scroll lên

## Cross-module imports
- `Post` từ **home-camera-feed** (fetch quoted post thumbnail)

## Definition of Done
- [ ] Manual: reply ảnh Feed → Inbox cập nhật; unfriend → banner hiện
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Chat] T5+6 — GroupChatScreen + SpaceMembersSheet + block/unfriend từ chat"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-chat.md` — Task T5, T6
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/chat-group`
> **Bị block bởi:** {sub1} — T3+4 done; Space T3 (SpaceCreateSheet) done; Settings T1 (BlockRepository) done
> **Figma:** GroupChatScreen `564:8603`, SpaceMembersSheet `564:8896`, ChatMenu `564:6965`

## Files cần tạo
- `lib/features/chat/presentation/group_chat_screen.dart`
- `lib/features/chat/presentation/widgets/group_message_bubble.dart` — avatar + displayName above bubble
- `lib/features/chat/presentation/widgets/space_members_sheet.dart`
- `lib/features/chat/presentation/widgets/chat_menu_dropdown.dart` — [Xóa bạn] / [Chặn]

## Acceptance criteria — GroupChatScreen
- [ ] Topbar: `[←] [Space icon + Space name] [⋯ menu]`
- [ ] ⋯ menu: Chỉnh sửa theme / Xem thành viên → SpaceMembersSheet / Rời khỏi Space → dialog
- [ ] Rời Space từ chat → `SpaceController.leaveSpace()` (Space module)
- [ ] Non-member → Firestore rule deny → navigate back + toast

## Acceptance criteria — SpaceMembersSheet
- [ ] Header "Mọi người (N)", list `[avatar] [displayName] [creator badge nếu creator]`

## Acceptance criteria — block/unfriend (ChatMenu)
- [ ] [Chặn] → `BlockConfirmDialog` (Settings) → confirm → `BlockRepository.blockUser()` → về Inbox
- [ ] [Xóa bạn] → unfriend popup → confirm → `FriendController.unfriend()` → về Inbox
- [ ] Sau block/unfriend: conversation lịch sử giữ, input ẩn

## Cross-module imports
- `BlockRepository` từ **settings**
- `BlockConfirmDialog` từ **settings**
- `FriendController.unfriend()` từ **friend**
- `SpaceController.leaveSpace()` từ **space**

## Definition of Done
- [ ] Manual: group chat từ Space → members sheet; block từ chat
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Chat] T7 — Firestore rules tests /conversations + /messages"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-chat.md` — Task T7
> **Estimate:** S (~4h) | **Branch:** `test/<DevName>/chat-rules`
> **Bị block bởi:** {sub0} — T1+2 phải done (cần schema)

## File cần tạo
- `firebase/functions/test/rules/chat.rules.test.ts`

## Acceptance criteria
- [ ] `/conversations/{id}`: participant read ✓, non-participant read ✗, unauthenticated ✗
- [ ] `/conversations/{id}/messages/{id}`: participant create với `text ≤ 500` ✓
- [ ] `/conversations/{id}/messages/{id}`: create với `text > 500` ✗
- [ ] Message khi `conversation.status == 'blocked'` → ✗ (rule check `status == 'active'`)
- [ ] Edit message → ✗; delete message → ✗

## Definition of Done
- [ ] Rules tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        }
    )

    New-Module "💬 [Chat]" $parentBody $NganTNK 3 $subs
}
