# scripts/modules/contracts.ps1
# Module: Contracts & Shared Components | Owner: ThienPDM | M1

function Create-ContractsModule {
    $parentBody = @'
> **Owner:** ThienPDM | **Tier:** Foundation
> **Plan:** `docs/plans/2026-05-23-leader.md`
> **Rule:** commit thẳng `develop` sau mỗi LX; app phải compile sau mỗi commit

## Mục tiêu
Tạo toàn bộ contracts (freezed models, abstract repos, Riverpod stubs, widget stubs, CF stubs) và shared infrastructure cho 12 modules. Phải done trước khi giao module cho dev.

## Thứ tự bàn giao
- **M1:** LX0 (core) → LX1 (auth)
- **M2:** LX2 (friend) → LX3 (settings) → LX5 (feed) → LX8 (diary) → LX9 (profile)
- **M3:** LX4 (chat) → LX6 (notif) → LX7 (reaction) → LX10 (space) → LX11 (widget) → LX12 (streak) → LX-RULES

## Checklist trước khi giao dev
- [ ] `flutter analyze` clean
- [ ] App launch không crash
- [ ] Providers throw `UnimplementedError` với hint
- [ ] TODO markers: `// TODO(<prefix>/T<N>/TBD): ...`
'@

    $subs = @(
        @{
            title = "[Contracts] LX0 — Core infrastructure"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-leader.md` — LX0
> **Estimate:** S (~4h) | **Branch:** `chore/ThienPDM/core-infrastructure`
> **Bị block bởi:** Không có — task đầu tiên

## Files cần tạo
- `lib/core/error/app_error.dart` — sealed class: `UnauthenticatedError`, `UnexpectedError`, `ValidationError`, `PermissionDeniedError`
- `lib/core/theme/app_colors.dart` — Turquoise 300/500/800, BW 100-900, semantic success700/error700
- `lib/core/utils/pair_id.dart` — `String pairIdOf(String a, String b)` sorted deterministic (Friend + Chat dùng)
- `lib/core/config/app_config.dart` — `static const shareBaseUrl = 'meep://profile'`
- `lib/main.dart` — `Firebase.initializeApp` + `ProviderScope` skeleton

## Acceptance criteria
- [ ] `pairIdOf(a, b) == pairIdOf(b, a)` — unit test pass (cả 2 chiều)
- [ ] App launch không crash, hiện `/intro` placeholder
- [ ] `flutter analyze` clean

## Definition of Done
- [ ] Commit trực tiếp vào `develop`
'@
        },
        @{
            title = "[Contracts] LX1 — Auth contracts (M1)"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-leader.md` — LX1; `docs/plans/2026-05-04-auth.md` §PART 1
> **Estimate:** M (~8h) | **Branch:** `chore/ThienPDM/auth-contracts`
> **Bị block bởi:** {sub0} — LX0 phải done

## Files cần tạo
- `lib/features/auth/data/user_profile.dart` — @freezed, full schema incl. bio/dateOfBirth/phoneNumber/gender/postCount/friendCount/spaceCount, `TimestampConverter`
- `lib/features/auth/data/auth_repository.dart` — abstract 9 methods (signUp, signIn, signInGoogle, signOut, sendPasswordReset, deleteCurrentUser, reauthenticate, updateEmail, currentUid stream)
- `lib/features/auth/data/user_repository.dart` — abstract (createProfile, getProfile, isUsernameAvailable)
- `lib/features/auth/application/auth_controller.dart` — `currentUidProvider`, `currentUserProfileProvider`, `isSignedInProvider` — stubs throw `UnimplementedError`
- `lib/features/auth/application/sign_up_controller.dart` — stub + `SignUpState` + `SignUpStep` enum
- `lib/features/auth/application/login_controller.dart` — stub + `LoginState`
- `lib/core/router/app_router.dart` — GoRouter redirect guard + auth routes + stub `/home`
- Shared auth widget stubs (4): `app_primary_button`, `app_back_button`, `app_google_button`, `app_text_input`
- 10 screen stubs: `intro_page`, signup 4 pages, login 2 pages, `home_page`

## Acceptance criteria
- [ ] `flutter analyze` clean
- [ ] `authRepositoryProvider` throw `UnimplementedError('wire FirebaseAuthRepository in main.dart')`
- [ ] Router redirect: unauthenticated → `/intro`, authenticated → `/home`
- [ ] TODO markers: `// TODO(A/T<N>/TBD): ...`

## Definition of Done
- [ ] PR merged vào `develop`
- [ ] Auth dev nhận "go"
'@
        },
        @{
            title = "[Contracts] LX2/3/5/8/9 + PUBSPEC — M2 contracts"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-leader.md` — LX2, LX3, LX5, LX8, LX9
> **Estimate:** L (2 ngày) | Mỗi LX = 1 commit riêng vào `develop`
> **Bị block bởi:** {sub1} — LX1 phải done

## LX tasks (theo thứ tự dependency)
- **LX2** — Friend: `Friendship`, `FriendRequest`, `FriendRepository`, `FriendRequestRepository`, controller stub, `FriendSheet`/`FriendFilterDropdown` stubs, route `/invite/:uid`, `isFriend()` rule helper, CF stubs
- **LX3** — Settings: `Block` (blockId = `{blocker}_{target}` NOT sorted), `BlockRepository` (**canonical** — Chat + Feed import từ đây), controller stub, screen stubs (5), `isBlocked()` helper, `ShareProfileSheet` shared widget, CF stubs
- **LX5** — Feed: `Post` (incl. `spaceId String?`), `PostRepository`, `StorageRepository`, `CaptionService` abstract + `CaptionType` enum, controller/widget stubs (6), `HomeScreen` replace placeholder, CF stubs
- **LX8** — Diary: `DiaryEntry`, `DiaryContentBlock`, `DiaryRepository` (**bắt buộc có `getPublicEntries(authorUid)`** — Profile dùng), `DiaryCanvasMode` enum, screen stubs (6)
- **LX9** — Profile: `ProfileRepository`, controller stub, screen stubs (5), routes
- **LX-PUBSPEC M2** — `share_plus`, `camera`, `flutter_image_compress`, `gal`, `geolocator`, `cached_network_image`, `http`, `intl`, `image_picker`

## Acceptance criteria
- [ ] `flutter analyze` clean sau mỗi LX commit
- [ ] `Post.spaceId String?` đã reserve (Space dùng sau)
- [ ] `BlockRepository` đúng path `lib/features/settings/data/block_repository.dart`
- [ ] `getPublicEntries(String authorUid)` có trong `DiaryRepository` interface (kiểu `Future<List<DiaryEntry>>`, không phải Stream)
- [ ] App navigate được tới `/home` stub
- [ ] `flutter pub get` không conflict

## Definition of Done
- [ ] 5+ PRs merged vào `develop`
- [ ] Module Owners M2 nhận "go"
'@
        },
        @{
            title = "[Contracts] LX4/6/7/10/11/12 + PUBSPEC — M3 contracts"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-leader.md` — LX4, LX6, LX7, LX10, LX11, LX12
> **Estimate:** L (2-3 ngày) | Mỗi LX = 1 commit riêng
> **Bị block bởi:** {sub2} — LX2/3/5/8/9 batch phải done

## LX tasks
- **LX4** — Chat: `Conversation` (conversationId, type enum, participantIds, spaceId?, quotedPostId?, lastMessage, status enum), `Message`, `ConversationRepository`, screen stubs (4), routes `/inbox`, `/chat/:id`. **Chat KHÔNG define `BlockRepository` riêng** — import từ settings
- **LX6** — Notification: `AppNotification`, `NotificationRepository`, controller stub, FCM init comment trong `main.dart`, deep link slots. `NotificationType`: friend_request/friend_accepted/reaction — **KHÔNG có new_post** (không lưu doc)
- **LX7** — Reaction: `Reaction`, `ReactionRepository` (**phải có `getMyReaction(postId, uid)` — [H2-FIX]**), controller stub, sheet stubs. Update `ActTextBar` stub: thêm optional `ReactionController?` param
- **LX10** — Space: `Space`, `SpaceMember`, `SpaceRepository`, controller stub, widget stubs (4). **Gate changes**: verify `Post.spaceId` đã có + update `FeedScreen` nhận `spaceId` param + `FeedFilter.space` case, CF stubs (8)
- **LX11** — Widget: Kotlin stubs (3 files), `AndroidManifest` update, `WidgetDataService` Flutter stub, route intent handler
- **LX12** — Streak: stubs only, reuse `Post` + `PostRepository` từ Feed (không tạo model mới)
- **LX-PUBSPEC M3** — `firebase_messaging`, `flutter_local_notifications`, `emoji_picker_flutter` (1 lần — Reaction + Space đều dùng), `flutter_svg`, `shared_preferences` (1 lần — Profile + Widget), Android WorkManager, Glide

## Acceptance criteria
- [ ] `flutter analyze` clean + Android build clean
- [ ] `getMyReaction` có trong `ReactionRepository` abstract
- [ ] `FeedFilter.space(spaceId)` case compile
- [ ] `emoji_picker_flutter` và `shared_preferences` mỗi cái chỉ thêm 1 lần
- [ ] `flutter pub get` không conflict

## Definition of Done
- [ ] PRs merged vào `develop`
- [ ] Module Owners M3 nhận "go"
'@
        },
        @{
            title = "[Contracts] LX-RULES — Firestore + Storage rules hoàn chỉnh"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-leader.md` — LX-RULES
> **Estimate:** M (~8h) | **Branch:** `chore/ThienPDM/firestore-rules`
> **Bị block bởi:** Tất cả LX1–LX12 phải done (cần tất cả helper functions)

## Files
- `firebase/firestore.rules` — merge theo thứ tự:
  1. Helper functions: `isAuthed()`, `isOwner(uid)`, `isFriend(uid)` (LX2), `isBlocked(uid)` (LX3), `isMember(spaceId)`, `isCreator(spaceId)` (LX10), `isParticipant(conversationId)` (LX4)
  2. Match blocks từng collection (spec §Security của từng module)
  3. `/posts/{id}` là **1 block duy nhất** (feed + space + reaction — 3 specs contribute)
- `firebase/storage.rules` — `avatars/{uid}/`, `posts/{uid}/`, `diary/{uid}/`

## Acceptance criteria
- [ ] `firebase emulators:exec --only firestore "npm run test:rules"` — 0 failures
- [ ] Không có `allow read, write: if true` bất kỳ đâu
- [ ] `/posts/{postId}` rule là 1 block duy nhất
- [ ] Storage: `size < 10MB`, `contentType.matches('image/.*')`

## Definition of Done
- [ ] Rules tests PASS
- [ ] PR merged vào `develop`
'@
        }
    )

    New-Module "🏗️ [Contracts & Shared Components]" $parentBody $ThienPDM 1 $subs
}
