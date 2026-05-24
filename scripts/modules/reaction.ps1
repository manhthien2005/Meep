function Create-ReactionModule {
    $parentBody = @'
> **Tier:** T0 | **Milestone:** M3 | **Assignee:** NganTNK
> **Spec:** `docs/specs/2026-05-23-reaction.md`
> **Plan:** `docs/plans/2026-05-23-reaction.md`
> **Todo:** `tasks/todo-reaction.md`
> **Phụ thuộc vào:** Feed module — Post model, ActTextBar M2 stub, PostRepository (feed read check)
> **Được phụ thuộc bởi:** Notification module — CF `onReactionCreated` trigger

## Mục tiêu
Cho phép user react một emoji vào post của bạn bè. Mỗi user chỉ react được 1 emoji/post. React emoji khác = thay thế cũ. Un-react bằng cách tap lại emoji đang active.

## Phạm vi (M3)
- React emoji: 3 quick preset (light-blue-heart / 🤣 / 🥰, Figma `472:2252`) + full picker (nút smile-plus)
- Un-react: tap lại emoji đang active → xóa reaction
- Change react: tap emoji khác → overwrite (1 user = 1 reaction/post)
- Reaction count display trên ActTextBar
- ReactionListSheet: tap count → bottom sheet list ai react gì, sort newest first

**Ngoài phạm vi:** Notification (thuộc Notification module), Reaction trên Diary/Space (post-MVP)

## Data model
Collection: `/posts/{postId}/reactions/{reactorUid}`
```
reactorUid:  string    // documentId = reactorUid → enforce 1/user/post
reactorName: string    // denormalized displayName
emoji:       string    // single emoji char, vd "😂"
createdAt:   Timestamp // serverTimestamp()
```
Document ID = `reactorUid` → tự enforce 1 reaction/user/post. Dùng `set()` (upsert), **KHÔNG** `add()`.

## Architecture
```
Presentation              Application              Data
ActTextBar                ReactionController       ReactionRepository (abstract)
EmojiPickerSheet          - ReactionState          FirebaseReactionRepository
ReactionListSheet         - toggleReact()          - watchReactions(postId)
                          - watchReactions()       - upsertReaction()
                          - loadReactors()         - deleteReaction()
                                                   - getMyReaction(postId, uid)
```

## toggleReact logic (bắt buộc implement đúng)
```dart
final existing = await repo.getMyReaction(postId, currentUid);
if (existing == null)              → upsertReaction  // react lần đầu
else if (existing.emoji == emoji)  → deleteReaction  // un-react
else                               → upsertReaction  // change emoji
```

## Contract artifacts (ThienPDM đã merge vào develop qua LX7)
- `lib/features/reaction/data/reaction.dart` — Reaction freezed model
- `lib/features/reaction/data/reaction_repository.dart` — abstract ReactionRepository
- `lib/features/reaction/application/reaction_controller.dart` — stub (throw UnimplementedError)
- `lib/shared/widgets/app_act_text_bar.dart` — M2 stub (update → M3 trong T3)
- `lib/features/reaction/presentation/emoji_picker_sheet.dart` — stub
- `lib/features/reaction/presentation/reaction_list_sheet.dart` — stub

## Package
`emoji_picker_flutter` — cũng dùng bởi Space module, thêm vào pubspec 1 lần (ThienPDM đã thêm qua LX-PUBSPEC M3)

## Worst cases
| Tình huống | Hành vi mong đợi |
|---|---|
| `upsertReaction` fail (network) | Rollback optimistic + toast "Thả cảm xúc thất bại — thử lại" |
| Double-tap nhanh | In-flight lock: bỏ qua tap thứ 2 cho đến khi request đầu resolve |
| Reaction count âm (optimistic glitch) | Clamp `max(0, count)` — không hiện số âm |
| React trên post `permission-denied` (đã unfriend) | Toast lỗi, post card ẩn xử lý ở Feed |
'@

    $subs = @(
        @{
            title = "[Reaction] T1 — FirebaseReactionRepository"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-reaction.md` — Task T1
> **Estimate:** S (~4h) | **Branch:** `feat/<DevName>/reaction-repository`
> **Bị block bởi:** LX7 contracts (ReactionRepository abstract + Reaction model đã có trong `develop`)

## Files cần tạo
- `lib/features/reaction/data/firebase_reaction_repository.dart` — implement `ReactionRepository`
- `test/features/reaction/data/firebase_reaction_repository_test.dart`

## Acceptance criteria
- [ ] `upsertReaction(postId, uid, emoji)` dùng `Firestore.set(docId: uid)` — **KHÔNG** `add()`, đảm bảo 1 reaction/user/post
- [ ] Gọi `upsertReaction` lần 2 với emoji khác → field `emoji` + `createdAt` được cập nhật (overwrite)
- [ ] `getMyReaction(postId, uid)` → `null` khi chưa react; trả `Reaction` khi đã react
- [ ] `watchReactions(postId)` → realtime stream toàn subcollection
- [ ] `deleteReaction(postId, uid)` → xóa doc, không throw khi doc không tồn tại
- [ ] `flutter test test/features/reaction/data/` — 0 failures

## Definition of Done
- [ ] Tests PASS (dùng `fake_cloud_firestore`)
- [ ] `flutter analyze` clean
- [ ] PR merged vào `develop` (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Reaction] T2 — ReactionController (toggleReact + optimistic + lock)"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-reaction.md` — Task T2
> **Estimate:** S (~4h) | **Branch:** `feat/<DevName>/reaction-controller`
> **Bị block bởi:** {sub0} — T1 phải done trước

## Files cần tạo
- `lib/features/reaction/application/reaction_controller.dart` — `ReactionState` + `ReactionController`
- `test/features/reaction/application/reaction_controller_test.dart`

## ReactionState schema
```dart
@freezed class ReactionState {
  List<Reaction> reactions   // danh sách tất cả reactions của post
  Reaction? myReaction       // reaction của current user (null nếu chưa react)
  bool isLoading
}
```

## toggleReact logic (bắt buộc implement đúng — xem spec)
```dart
final existing = await repo.getMyReaction(postId, currentUid);
if (existing == null)              → upsertReaction  // react lần đầu
else if (existing.emoji == emoji)  → deleteReaction  // un-react
else                               → upsertReaction  // change
```

## Acceptance criteria
- [ ] `existing == null` → `upsertReaction` → count tăng +1 (optimistic)
- [ ] `existing.emoji == emoji` → `deleteReaction` → count giảm -1 (optimistic)
- [ ] `existing.emoji != emoji` → `upsertReaction` overwrite → count giữ nguyên
- [ ] Optimistic update: count + highlight thay đổi ngay, rollback khi Firestore fail
- [ ] In-flight lock: tap thứ 2 bị ignore khi request thứ 1 chưa resolve
- [ ] Upsert fail → rollback + toast "Thả cảm xúc thất bại — thử lại"
- [ ] Reaction count: `max(0, count)` — không hiện số âm
- [ ] `flutter test test/features/reaction/application/` — 0 failures (min 5 test cases)

## Definition of Done
- [ ] Tests PASS (mocktail mock `ReactionRepository`)
- [ ] `flutter analyze` clean
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Reaction] T3+4 — ActTextBar M3 + EmojiPickerSheet + ReactionListSheet"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-reaction.md` — Task T3 + T4
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/reaction-ui`
> **Bị block bởi:** {sub1} — T2 phải done trước
> **Figma:** Feed card ActTextBar M3 `472:2241`; 3 quick emoji `472:2252` (nodes 501:1008/1009/1010)

## Files cần sửa / tạo
- `lib/shared/widgets/app_act_text_bar.dart` — **UPDATE** M2 stub → M3: inject optional `ReactionController`
- `lib/features/reaction/presentation/widgets/emoji_button.dart` — active/inactive states
- `lib/features/reaction/presentation/emoji_picker_sheet.dart` — dùng `emoji_picker_flutter`
- `lib/features/reaction/presentation/reaction_list_sheet.dart` — list reactions sort DESC
- `test/features/reaction/presentation/act_text_bar_test.dart` — widget tests

## Acceptance criteria — ActTextBar
- [ ] 3 quick emoji: light-blue-heart / 🤣 / 🥰 theo Figma nodes 501:1008/1009/1010
- [ ] Tap emoji → highlight active + count tăng (optimistic) → `ReactionController.toggleReact()`
- [ ] Tap active emoji → un-highlight + count giảm (optimistic)
- [ ] Tap smile-plus → `EmojiPickerSheet` bottom sheet
- [ ] **M2 fallback:** nếu `ReactionController` là null → ActTextBar là no-op (không crash, không show count)
- [ ] Widget test: tap emoji → active state; tap active → inactive; count display đúng

## Acceptance criteria — EmojiPickerSheet
- [ ] Dùng `emoji_picker_flutter` (MIT), grid scroll, **không có search** (MVP)
- [ ] Tap emoji → `toggleReact()` + sheet tự động đóng

## Acceptance criteria — ReactionListSheet
- [ ] Trigger khi tap vùng count trên ActTextBar
- [ ] Hiển thị: `[avatar] [displayName] [emoji]`, sort `createdAt DESC`
- [ ] Tap avatar → navigate `FriendProfileScreen` (Profile module) nếu là bạn bè
- [ ] Empty state khi chưa có reaction nào

## Cross-module imports
- `FriendProfileScreen` từ Profile module (khi tap avatar trong ReactionListSheet)
- `ActTextBar` là shared widget, được dùng bởi `FriendPostCard` của Feed module

## Definition of Done
- [ ] Widget tests PASS
- [ ] `flutter analyze` clean
- [ ] Manual: tap → active; tap lại → un-react; tap khác → change; picker mở; list hiển thị đúng
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Reaction] T5 — Firestore rules tests /reactions"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-reaction.md` — Task T5
> **Estimate:** S (~4h) | **Branch:** `test/<DevName>/reaction-rules`
> **Bị block bởi:** {sub0} — T1 phải done trước (cần biết schema để viết rules)

## File cần tạo
- `firebase/functions/test/rules/reaction.rules.test.ts`

## Rules cần implement (trong `firestore.rules`)
```javascript
match /posts/{postId}/reactions/{reactorUid} {
  allow read: if isAuthed() && (
    request.auth.uid == get(/databases/$(database)/documents/posts/$(postId)).data.authorId
    || exists(/databases/$(database)/documents/users/$(request.auth.uid)/feed/$(postId))
  );
  allow create: if isAuthed()
    && request.auth.uid == reactorUid
    && request.auth.uid == request.resource.data.reactorUid;
  allow update: if isAuthed() && request.auth.uid == reactorUid
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['emoji', 'createdAt']);
  allow delete: if isAuthed() && request.auth.uid == reactorUid;
}
```

## Acceptance criteria (7 test cases)
- [ ] Create by owner (là author hoặc có feed doc): ALLOW
- [ ] Create by stranger (uid mismatch): DENY
- [ ] Create với `reactorUid != auth.uid`: DENY
- [ ] Update field `emoji` + `createdAt` by owner: ALLOW
- [ ] Update field `reactorUid`: DENY (không được đổi owner)
- [ ] Delete by owner: ALLOW
- [ ] Delete by stranger: DENY
- [ ] Read by user không có feed doc (non-audience): DENY
- [ ] `firebase emulators:exec --only firestore "npm run test:rules"` — PASS

## Definition of Done
- [ ] Rules tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        }
    )

    New-Module "⚛️ [Reaction]" $parentBody $NganTNK 3 $subs
}

# ==============================================================
# DIARY - HanDHG - M3
# ==============================================================
