# TODO: Chat

> Plan: `docs/plans/2026-05-23-chat.md`
> Spec: `docs/specs/2026-05-23-chat.md`
> Tier: T1 Stretch (1-1) + T0+ exception (Group Chat ship cùng Space M3)
> Blocked by: Friend (CF acceptFriendRequest tạo conversation), Settings (BlockRepository)

---

## Phase 1 — Data layer

- [ ] **T1** — `FirebaseConversationRepository` (watchConversations filter blocked + getOrCreateConversation idempotent + sendMessage + watchMessages)

## Checkpoint: Data layer ✓
- [ ] `flutter test test/features/chat/` — 0 failures

---

## Phase 2 — Application layer

- [ ] **T2** — `ChatController` (loadMessages + sendMessage no-optimistic + sendMessageFromFeed)

## Checkpoint: App layer ✓
- [ ] `flutter test test/features/chat/` — 0 failures

---

## Phase 3 — UI

- [ ] **T3** — `InboxScreen` (list conversations sorted lastMessageAt DESC + empty state)
- [ ] **T4** — `ChatScreen` 1-1 (QuotedPhotoBlock + MessageBubble trái/phải + ChatInputBar + unfriended/blocked banner)
- [ ] **T5** — `GroupChatScreen` + `SpaceMembersSheet` — **T0+ ship cùng Space M3**
- [ ] **T6** — Block/unfriend từ chat ⋯ menu (BlockConfirmDialog từ Settings + FriendController.unfriend)

---

## Phase 4 — Rules

- [ ] **T7** — Firestore rules tests `/conversations` + `/messages` (status=blocked → cannot create message)

## Checkpoint: Chat complete ✓
- [ ] `flutter test test/features/chat/` — 0 failures
- [ ] `flutter analyze` clean
- [ ] Manual: reply ảnh từ Feed → inline text → gửi → Inbox cập nhật; block từ chat → conversation ẩn; unfriend → readonly banner
