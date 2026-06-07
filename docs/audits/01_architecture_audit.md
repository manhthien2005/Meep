# 01_architecture_audit

## meta

- repo: Meep
- root: D:/meep-audit-01-arch
- branch: audit/ThienPDM/01-architecture
- date: 2026-06-07
- mode: audit-only
- audit_focus: architecture
- modified_files_allowed:
  - docs/audits/01_architecture_audit.md
- read_baseline:
  - docs/audits/00_inventory_map.md
  - CLAUDE.md (root)
  - apps/mobile/CLAUDE.md
  - .claude/reference-architectures/auth.md

## precheck

- git_status_before: clean-vs-baseline (`?? docs/audits/`, `?? tmp/audit/...` — both expected per inventory map)
- existing_user_changes: no (baseline known — inventory map `?? tmp/` matches, no `M apps/mobile/pubspec.lock` in this worktree → cleaner than baseline)
- target_report_preexisting_dirty: no (file did not exist before this run)

## commands

| cmd | status | notes |
|---|---:|---|
| `git rev-parse --show-toplevel` | ok | `D:/meep-audit-01-arch` worktree |
| `git status --short` | ok | only `?? docs/audits/`, `?? tmp/audit/...` |
| `git branch --show-current` | ok | `audit/ThienPDM/01-architecture` |
| `git diff --name-only` | ok | empty |
| `git ls-files apps/mobile/lib/**` (via Glob) | ok | 13 features + core + shared mapped |
| `rg FirebaseFirestore.instance\|FirebaseAuth.instance\|FirebaseStorage.instance` apps/mobile/lib/features | ok | 11 hits — all in `feed/{application,presentation}` (red) |
| `rg DocumentSnapshot\|QuerySnapshot` apps/mobile/lib | ok | 4 hits — 1 leak in state, 3 internal to diary data |
| `rg @Riverpod\(keepAlive: true\)` apps/mobile/lib | ok | 22 occurrences across modules + router |
| `rg AppError\|UnauthenticatedError\|...` apps/mobile/lib/features/**/data/*.dart | ok | 8 / 13 repo files mention AppError; 5 modules raw FirebaseException |
| cross-module import map (python script over rg dump) | ok | full edge list captured (see issue evidence) |
| `wc -l home_screen.dart feed_section.dart capture_preview_screen.dart` | ok | 630 / 1031 / 771 lines |
| `flutter analyze --no-pub` | blocked | not run — audit-only, prompt forbids mutating commands; static evidence sufficient |

## coverage

- core/config/: checked — `app_config.dart` read; thin config wrapper, no architectural smell
- core/error/: checked — `app_error.dart` read; sealed family complete per Pattern #3
- core/router/: checked — `app_router.dart` read end-to-end (546 lines); routing concerns noted in ROUTER-001
- core/theme/: partial — `hex_color.dart` duplicate vs `core/utils/hex_color.dart` confirmed; theme tokens listed via Glob, not deep-read (not architectural scope)
- core/utils/: checked — `pair_id.dart` + `hex_color.dart` listed; duplicate flagged CORE-001
- core/validators/: partial — listed only; auth_validators tested per inventory map; no architectural smell expected
- features/auth: checked — canonical reference; data + application + presentation layout verified against `auth.md` Pattern #1
- features/chat: checked — `chat_controller.dart`, `chat_providers.dart`, `fake_conversation_repository.dart` head, `chat_seed_data.dart` head, `debug_error_view.dart` read; cross-module imports indexed
- features/diary: partial — file inventory only; sampled `firebase_diary_repository.dart` for DocumentSnapshot usage (internal, OK)
- features/feed: checked — `feed_controller.dart`, `post_controller.dart`, `feed_state.dart`, `firebase_post_repository.dart`, `firebase_storage_repository.dart`, `home_screen.dart` head+critical lines, `feed_section.dart` head+critical lines, `post_repository.dart`, `post.dart` read in full
- features/friend: checked — `friend_controller.dart`, `friend_repository.dart`, `firebase_friend_repository.dart` read
- features/home: checked — `home_page.dart` read (56-line skeleton)
- features/notification: checked — `notification_controller.dart` head, `firebase_notification_repository.dart` read
- features/profile: checked — `friend_posts_provider.dart` read; rest listed
- features/reaction: checked — `reaction_controller.dart` read (state inline)
- features/settings: checked — `settings_controller.dart` read
- features/space: partial — listed; cross-module edges captured; data/application not deep-read (no specific smell flagged)
- features/streak: checked — `streak_repository.dart` abstract read (imports Post from feed)
- features/widget: checked — `widget_data_service.dart` read in full
- features/rollcall: blocked — folder does not exist (Tier 0+ scope gap — ARCH-003)
- shared/widgets: partial — Glob listed all 22 files; `post_card.dart` head read for Post coupling
- main.dart bootstrap: checked — full read; override list cross-checked against module stubs
- pubspec.yaml: checked — full read; iOS Apple Sign-In dep noted PUBSPEC-001
- client/backend boundary (firebase/): partial — inventory map's functions index trusted as ground truth; no direct cross-link audit performed (boundary-shape mismatch would require per-handler typecheck — out of audit-only scope without running tooling)
- ADR/docs match: partial — ADR titles known via inventory; no spec-vs-code mismatch deeply audited

## blockers_summary

Only P0/P1.

| id | sev | area | files | short |
|---|---|---|---|---|
| LAYER-001 | P0 | Firebase leak in widget | `feed/presentation/feed_section.dart`, `feed/presentation/home_screen.dart` | Widgets call `FirebaseAuth.instance.currentUser?.uid` directly |
| LAYER-002 | P0 | Firebase leak in controller | `feed/application/feed_controller.dart`, `feed/application/post_controller.dart` | Controllers call `FirebaseAuth.instance` + `FirebaseFirestore.instance.collection('posts').doc().id` directly |
| FEED-ARCH-001 | P1 | Provider DI deviation | `feed/application/feed_controller.dart` | `postRepositoryProvider` / `storageRepositoryProvider` self-construct with `FirebaseFirestore.instance` — bypass stub + `main.dart` override pattern |
| LAYER-003 | P1 | Firebase type in state | `feed/application/feed_state.dart` | `DocumentSnapshot? lastDoc` exposed to UI |
| DATA-ARCH-001 | P1 | Raw FirebaseException leak | `feed/data/firebase_post_repository.dart`, `feed/data/firebase_storage_repository.dart`, `friend/data/firebase_friend_repository.dart`, `reaction/data/firebase_reaction_repository.dart`, `notification/data/firebase_notification_repository.dart` | Repositories throw raw `FirebaseException` — bypass `AppError` boundary mapping (Pattern #2/#3) |
| FEED-ARCH-002 | P1 | Cross-module data layer bypass | `feed/data/firebase_post_repository.dart` | `_getFriendUids` queries `/friendships` directly instead of `FriendRepository` — comment cites stale "FriendRepository is stub" reason |
| ARCH-001 | P1 | Shared entity in feature folder | `feed/data/post.dart`, `streak/data/streak_repository.dart`, `profile/application/friend_posts_provider.dart`, `chat/application/chat_providers.dart`, `shared/widgets/post_card.dart` | `Post` model lives in `features/feed/data/` but is imported by streak, profile, chat, shared/widgets — de-facto shared entity, misleading owner |
| ARCH-002 | P1 | Widget files exceed split threshold | `feed/presentation/feed_section.dart` (1031 lines), `feed/presentation/capture_preview_screen.dart` (771), `feed/presentation/home_screen.dart` (630) | Far above `apps/mobile/CLAUDE.md` ≤300-line / 150-line widget thresholds |
| DEEPLINK-001 | P1 | Invite/share link drift + missing intent-filter | `app_config.dart`, `friend_sheet.dart`, `share_profile_sheet.dart`, `AndroidManifest.xml` | Profile share `meep://profile/...` vs friend invite `https://meep.app/invite/...` — AndroidManifest registers neither; `/invite/:uid` routes to `HomePage` placeholder |

## issues

### ISSUE LAYER-001

- sev: P0
- blocker: yes
- area: Layering — Firebase leakage in presentation
- files:
  - `apps/mobile/lib/features/feed/presentation/feed_section.dart`
  - `apps/mobile/lib/features/feed/presentation/home_screen.dart`
- loc: `feed_section.dart:4` (import), `feed_section.dart:80` (call); `home_screen.dart:1` (import), `home_screen.dart:589` (call)
- symbols:
  - `FeedSection.build` (calls `FirebaseAuth.instance.currentUser?.uid`)
  - `_PostPage.build` (same)
- evidence: `final currentUid = FirebaseAuth.instance.currentUser?.uid;` — appears in widget `build` bodies (both files)
- risk: Widget can't be tested with `firebase_auth_mocks`/`MockFirebaseAuth` via `overrideWithValue` — golden-path widget test for feed becomes impossible. Same widget breaks `apps/mobile/CLAUDE.md §Layering` "Widgets that touch FirebaseFirestore.instance directly is a bug" (rule applies to FirebaseAuth analogously). The same file `feed_section.dart:450` has a comment block telling readers `uid lấy từ currentUidProvider (auth abstraction) thay vì FirebaseAuth.instance trực tiếp` — meaning the violation is already a known code-smell the team agreed to fix but didn't propagate to lines 80 / 589.
- fix: Replace both call sites with `ref.watch(currentUidProvider).valueOrNull` (already imported via `auth_providers.dart`). `_PostPage` must become `ConsumerWidget` (currently `StatelessWidget`). Drop the `firebase_auth` imports from both files once the change compiles.
- authority: `apps/mobile/CLAUDE.md §Layering` + `auth.md` Pattern #1/#5 + `feed_section.dart:447-450` self-comment
- test: Add `test/features/feed/presentation/feed_section_test.dart` using `ProviderScope(overrides: [currentUidProvider.overrideWith(...)])` and verify the "own vs friend post" branch renders correctly without any Firebase instance bound. Run `flutter test test/features/feed/`.
- deps: LAYER-002 (same root cause across the layer)

### ISSUE LAYER-002

- sev: P0
- blocker: yes
- area: Layering — Firebase leakage in application
- files:
  - `apps/mobile/lib/features/feed/application/feed_controller.dart`
  - `apps/mobile/lib/features/feed/application/post_controller.dart`
- loc: `feed_controller.dart:56`; `post_controller.dart:85, 107, 173`
- symbols:
  - `FeedController.build` — `final uid = FirebaseAuth.instance.currentUser!.uid;`
  - `PostController.submit` — `final uid = FirebaseAuth.instance.currentUser?.uid;`, `final postId = FirebaseFirestore.instance.collection('posts').doc().id;`, `final user = FirebaseAuth.instance.currentUser!;`
- evidence: `final postId = FirebaseFirestore.instance.collection('posts').doc().id;` at `post_controller.dart:107`
- risk: Controller cannot be unit-tested with `ProviderContainer` + `MockFirebaseAuth`/`fake_cloud_firestore` overrides — Pattern #4/#5 contract broken. Forced bang (`currentUser!`) at `feed_controller.dart:56` and `post_controller.dart:173` will throw `NoSuchMethodError` on a signed-out edge (race with `signOut`), surfacing as an uncaught error instead of a typed `UnauthenticatedError`. Direct `.collection('posts')` access also keeps the postId mint as a hidden second source of truth (the repository abstracts the path everywhere else).
- fix:
  1. Inject uid via `ref.read(currentUidProvider).valueOrNull` (or accept `String uid` as a `build(uid)` parameter — pattern used by `FriendController.build(String uid)`).
  2. Move `postId` generation into `PostRepository.createPost` (return generated id) or add `PostRepository.newPostId()` factory — current call inlines Firestore knowledge in controller.
  3. Read `user.displayName` / `photoURL` via `currentUserProfileProvider` (already used at `post_controller.dart:205`) and drop the `FirebaseAuth.instance.currentUser` fallback.
- authority: `apps/mobile/CLAUDE.md §Layering` ("All Firebase I/O goes through a Repository class.") + `auth.md` Pattern #4 + `auth_providers.dart:22 currentUidProvider`
- test: Update `test/features/feed/application/post_controller_test.dart` (create if missing) to verify `submit()` rejects when `currentUidProvider` yields null and succeeds when overridden with a fake uid. Run `flutter test test/features/feed/application/`.
- deps: LAYER-001, FEED-ARCH-001

### ISSUE FEED-ARCH-001

- sev: P1
- blocker: no
- area: Provider DI — pattern deviation
- files:
  - `apps/mobile/lib/features/feed/application/feed_controller.dart`
- loc: 31-37
- symbols:
  - `postRepositoryProvider` (`@Riverpod(keepAlive: true)`)
  - `storageRepositoryProvider` (`@Riverpod(keepAlive: true)`)
- evidence: `PostRepository postRepository(Ref ref) => FirebasePostRepository(FirebaseFirestore.instance);` — feed providers self-construct, no override in `main.dart`
- risk: Inconsistent with every other module (auth/friend/space/profile/diary/streak/reaction/notification/settings/widget all expose `throw UnimplementedError` stubs and are bound in `apps/mobile/lib/main.dart:76-140`). Hides the binding from the bootstrap audit trail; future swap (e.g., to a feature-flagged offline repo) needs to edit feed instead of one boot point. Combined with LAYER-002, the controller plus provider both bypass the canonical pattern — onboarding cost for new dev climbs (canonical doc tells them one pattern, codebase shows two).
- fix: Convert both providers to `=> throw UnimplementedError('wire FirebasePostRepository in main.dart')` and add overrides in `apps/mobile/lib/main.dart` next to the existing `FirebaseFriendRepository` block:
  ```dart
  postRepositoryProvider.overrideWithValue(
    FirebasePostRepository(FirebaseFirestore.instance),
  ),
  storageRepositoryProvider.overrideWithValue(
    FirebaseStorageRepository(FirebaseStorage.instance),
  ),
  ```
- authority: `auth.md` Pattern #5 ("DI — `overrideWithValue` trong `main.dart`") + `main.dart:78-139` existing bindings
- test: After fix, run `flutter analyze --no-pub` to verify provider rebuilds; existing `test/features/feed/` tests must still pass under `ProviderContainer(overrides: [...])`.
- deps: LAYER-002

### ISSUE LAYER-003

- sev: P1
- blocker: no
- area: Layering — Firebase type in state
- files:
  - `apps/mobile/lib/features/feed/application/feed_state.dart`
- loc: 14
- symbols:
  - `FeedState.lastDoc` (`DocumentSnapshot? lastDoc`)
- evidence: `DocumentSnapshot? lastDoc,` — freezed state field exposes Firestore SDK type
- risk: Any widget that reads `feedState.lastDoc` is forced to import `cloud_firestore` to type-check, propagating Firebase coupling through UI. `auth.md` Pattern #2 explicitly bans Firebase types crossing the data boundary. Cursor type also locks the project to Firestore — swapping to a different backend (or adding a fake) means changing the state shape and every consumer.
- fix: Define a typed cursor on the abstract `PostRepository` (e.g., `class FeedCursor { final String postId; final DateTime createdAt; }`) or use the post's `(createdAt, postId)` pair as the resume token. Replace `DocumentSnapshot? lastDoc` with `FeedCursor? lastCursor`. The Firestore-specific snapshot stays inside `firebase_post_repository.dart`.
- authority: `auth.md` Pattern #2 + `apps/mobile/CLAUDE.md §Data classes — freezed + json_serializable` ("Convert `DocumentSnapshot` → model in a `fromFirestore(snap)` factory on the data class. NEVER inline in widgets/controllers.")
- test: After change, `dart format` + `flutter analyze --no-pub` must stay green; write `test/features/feed/application/feed_state_test.dart` checking the cursor round-trips through `copyWith`.
- deps: FEED-ARCH-001

### ISSUE DATA-ARCH-001

- sev: P1
- blocker: no
- area: Repository pattern — missing AppError boundary mapping
- files:
  - `apps/mobile/lib/features/feed/data/firebase_post_repository.dart`
  - `apps/mobile/lib/features/feed/data/firebase_storage_repository.dart`
  - `apps/mobile/lib/features/friend/data/firebase_friend_repository.dart`
  - `apps/mobile/lib/features/reaction/data/firebase_reaction_repository.dart`
  - `apps/mobile/lib/features/notification/data/firebase_notification_repository.dart`
- loc: symbol-level — entire class bodies; specifically: `firebase_post_repository.dart:36 watchFeed`, `firebase_friend_repository.dart:29 watchFriends`, `firebase_reaction_repository.dart:30 upsertReaction`, `firebase_notification_repository.dart:28 saveFcmToken`, `firebase_storage_repository.dart:20 uploadImage`
- symbols:
  - `FirebasePostRepository.{createPost,watchFeed,deletePost,getPostsByAuthor,getPost}`
  - `FirebaseFriendRepository.{searchUser,watchFriends,getFriendUids,unfriend}`
  - `FirebaseReactionRepository.{watchReactions,upsertReaction,deleteReaction,getMyReaction}`
  - `FirebaseNotificationRepository.{saveFcmToken,deleteFcmToken,getNotifications,markAsRead}`
  - `FirebaseStorageRepository.uploadImage`
- evidence:
  - `firebase_post_repository.dart:31` — `await ref.set(data);` (no try/catch + no `_mapXxxError`); also `firebase_post_repository.dart:150` rethrows raw `FirebaseException` from `_watchSpaceFeed`'s `.handleError` block (`// ignore: only_throw_errors — preserve original error type` + `throw e`)
  - `firebase_storage_repository.dart:37` — only handles `object-not-found` then `rethrow`s every other `FirebaseException` raw
  - `firebase_friend_repository.dart` — `grep` for `AppError|on FirebaseException` returns 0 matches across the file
  - `firebase_reaction_repository.dart` — `grep` returns 0 `AppError`/exception-mapping matches; only a comment at line 45 references idempotent delete
  - `firebase_notification_repository.dart` — only `ArgumentError.value` (input validation); no `FirebaseException` → `AppError` boundary
  - `PostController._errorMessage` at `post_controller.dart:251-270` reimplements `FirebaseException.code → user message` mapping that should live in the repo — confirms the gap on the consumer side
- risk: Raw `FirebaseException` reaches every controller; each consumer (post_controller, friend_controller, reaction_controller, etc.) implements its own `error.toString()` scrape or switch-on-code logic, producing inconsistent VN copy and duplicating the mapping the repo should own. When `post_controller.dart:251 _errorMessage` and a future `delete_post_controller._errorMessage` diverge, two screens will say different things for the same backend error. Also blocks `_afterFailure(e)` pattern from `auth.md` Pattern #4 because `AppError.fromUnknown` returns `UnexpectedError` for raw `FirebaseException` instead of a meaningful subclass.
- fix: Copy the `_mapXxxError` pattern from `firebase_auth_repository.dart:50` to each impl. Minimum:
  - `_mapPostError(FirebaseException)` → `ForbiddenError` (permission-denied), `NetworkError` (unavailable/deadline-exceeded), `NotFoundError` (not-found), default `UnexpectedError`.
  - Wrap every Firestore op with `try { ... } on FirebaseException catch (e) { throw _mapXxxError(e); }`.
  - Same shape for friend / reaction / notification / storage.
  - Delete `PostController._errorMessage` (consumer can use `AppError.fromUnknown(e).message` once repo throws `AppError`).
- authority: `auth.md` Pattern #2 ("error mapping") + Pattern #3 (`AppError` sealed family) + Pattern #10 (Vietnamese error message tại boundary)
- test: Add `test/features/feed/data/firebase_post_repository_test.dart` (using `fake_cloud_firestore` + `mock_exceptions`) — verify `permission-denied` → `ForbiddenError`, `unavailable` → `NetworkError`. Same per-module. Run `flutter test test/features/feed/data/ test/features/friend/data/ test/features/reaction/data/ test/features/notification/data/`.
- deps: LAYER-002

### ISSUE FEED-ARCH-002

- sev: P1
- blocker: no
- area: Cross-module — data layer bypass
- files:
  - `apps/mobile/lib/features/feed/data/firebase_post_repository.dart`
- loc: 259-271
- symbols:
  - `FirebasePostRepository._getFriendUids`
- evidence: `// Does NOT use FriendRepository (which is stub UnimplementedError).` (`firebase_post_repository.dart:260`); next 10 lines query `_db.collection('friendships').where('members', arrayContains: uid)` directly
- risk: Stale workaround — `friendRepositoryProvider` IS now wired in `main.dart:84` (`FirebaseFriendRepository(FirebaseFirestore.instance)`) and `FriendRepository.getFriendUids(String uid)` exists in `friend/data/friend_repository.dart:12`. Feed bypasses it, so any change to friendship schema (e.g., adding a `status` filter to skip blocked pairs) needs to be applied in two places — one in Friend module's repo, one inside Feed module. ADR-0004 solo-dev model explicitly forbids touching another module's collection from outside that module's data layer.
- fix: Inject `FriendRepository` into `FirebasePostRepository` constructor (or read via `ref` in the controller and pass `Future<List<String>> friendUidsOf(uid)` into `watchFeed`). Delete the direct `friendships` query at `firebase_post_repository.dart:262-270`.
- authority: ADR-0004 `Strict gate — Touch file thuộc module dev khác` + `CLAUDE.md §Cross-module touch — FORBIDDEN by default`
- test: After fix, `_watchFriendsFeed` test must override `FriendRepository` with a fake list and verify `_db.collection('friendships').get` is never called. `flutter test test/features/feed/data/firebase_post_repository_test.dart`.
- deps: DATA-ARCH-001

### ISSUE ARCH-001

- sev: P1
- blocker: no
- area: Module responsibility — shared entity in feature folder
- files:
  - `apps/mobile/lib/features/feed/data/post.dart` (the model)
  - cross-module importers (non-feed production code, 11 files):
    - `apps/mobile/lib/core/router/app_router.dart`
    - `apps/mobile/lib/features/chat/application/chat_providers.dart`
    - `apps/mobile/lib/features/chat/data/chat_seed_data.dart`
    - `apps/mobile/lib/features/profile/application/friend_posts_provider.dart`
    - `apps/mobile/lib/features/profile/application/profile_posts_provider.dart`
    - `apps/mobile/lib/features/streak/application/streak_controller.dart`
    - `apps/mobile/lib/features/streak/application/streak_state.dart`
    - `apps/mobile/lib/features/streak/data/streak_repository.dart`
    - `apps/mobile/lib/features/streak/data/firebase_streak_repository.dart`
    - `apps/mobile/lib/features/streak/presentation/widgets/streak_calendar.dart`
    - `apps/mobile/lib/shared/widgets/{photo_detail_screen,post_card,share_modal,share_photo_sheet}.dart`
  - 11 dependent test files (see test/features/{profile,streak,shared}/)
- loc: symbol-level
- symbols:
  - `Post` (freezed class — `feed/data/post.dart`)
  - `AudienceType`, `CaptionType`, `TimestampConverter` (same file)
  - 27 production files import this path (4 modules + core/router + shared/widgets), plus 11 test files — total 38 importers (verified via `grep -rln "import 'package:meep/features/feed/data/post.dart'"`).
- evidence: `import 'package:meep/features/feed/data/post.dart';` in `streak/data/streak_repository.dart:1` (an abstract repo interface of a different module) + 37 other files including `core/router/app_router.dart` and 4 `shared/widgets/*` files
- risk: Per `CLAUDE.md §Cross-module touch — FORBIDDEN by default` + ADR-0004 `Strict gate`, "đổi field trong freezed model leader đã chốt" requires leader sign-off. Today, the model lives under `feed/` so any feed owner change ripples silently into 4 modules + core/router + shared/widgets. Streak's abstract interface depends on a feature module's data class — pure direction-inversion violation. New devs cannot tell who owns `Post`. Long-term: when Streak owner needs `Post.streakMonth`, the change pressure lands on Feed owner. Even `core/router/app_router.dart:26` imports the feature-module model directly.
- fix: One of:
  - (preferred) move `Post`, `AudienceType`, `CaptionType`, `TimestampConverter` to `apps/mobile/lib/shared/models/post.dart` and update 27 production import paths + 11 test paths. Keep generation outputs in sync.
  - or document `feed/data/post.dart` as the de-facto shared contract: add a header comment + add a `CLAUDE.md` rule + open a tracking issue assigning Leader as the owner.
- authority: `CLAUDE.md §Cross-module touch` + ADR-0004 Strict Gate + `apps/mobile/CLAUDE.md §File organization` ("Feature-first, not layer-first")
- test: After move, `flutter analyze --no-pub` must stay green and `flutter test` must pass without changes beyond imports. Add `test/shared/models/post_test.dart` covering `Post.fromJson` round-trip if moved (mirrors current implicit coverage from feed tests).
- deps: SHARED-001

### ISSUE ARCH-002

- sev: P1
- blocker: no
- area: Layering — widget file size beyond split threshold
- files:
  - `apps/mobile/lib/features/feed/presentation/feed_section.dart` (1031 lines)
  - `apps/mobile/lib/features/feed/presentation/capture_preview_screen.dart` (771 lines)
  - `apps/mobile/lib/features/feed/presentation/home_screen.dart` (630 lines)
- loc: file-level
- symbols:
  - `FeedSection` + multiple private widgets (`_PostCard`, `_PostHeader`, `_FeedFooter`, `_EmptyState`, ...)
  - `CapturePreviewScreen` + sibling widgets
  - `HomeScreen` + private widgets (`_PostPage`, `_EmptyFeedPage`, ...)
- evidence: `wc -l` numbers above; `apps/mobile/CLAUDE.md §Widget split thresholds` table — `class > 300 lines → split by SRP`; `Widget body > 150 lines → split into sub-widgets`
- risk: Files grow ~3-7× the documented split threshold. Maintenance burden: any feed bug fix forces reading 1000+ lines. Code review (`/review`) tail-window misses changes deep in file. Onboarding cost spikes — new dev cannot trace shadow state (`_pendingHighlightPostId`, `_pendingOpenFriendSheet`, `_currentPage`, `_posts`, `_ringColor`) across one giant `_HomeScreenState`. Conflict surface enlarges on parallel feature PRs.
- fix: Extract per CLAUDE.md table:
  - `feed_section.dart`: split into `feed_section.dart` (just the `FeedSection` widget + `.when` shell), `widgets/own_post_card.dart`, `widgets/friend_post_card.dart`, `widgets/feed_reaction_bar.dart`, `widgets/feed_share_handlers.dart`. Aim ≤ 300 lines each.
  - `capture_preview_screen.dart`: extract caption picker, audience row, send button into `widgets/`.
  - `home_screen.dart`: extract `_PostPage`, `_EmptyFeedPage`, `_filterModeFor`, `_ringColor` derivation, taskbar dispatch into separate files; move `_RouterNotifier`-style logic out of widget state.
- authority: `apps/mobile/CLAUDE.md §Widget split thresholds` + `CLAUDE.md §File organization` ("Files ≤ 300 lines. Split if larger.")
- test: After split, `flutter test test/features/feed/` must stay green; add widget tests for any newly extracted reusable widget under `test/features/feed/presentation/widgets/`.
- deps: LAYER-001 (touches same files; sequence: fix LAYER-001 first since both edits hit the same call sites)

### ISSUE STATE-ARCH-001

- sev: P2
- blocker: no
- area: Module layout — state classes colocated in controller files (4 modules)
- files:
  - `apps/mobile/lib/features/reaction/application/reaction_controller.dart` (lines 13-32: `ReactionState` `@freezed`)
  - `apps/mobile/lib/features/diary/application/diary_controller.dart` (lines 39-?: `DiaryState` `@freezed`)
  - `apps/mobile/lib/features/profile/application/profile_controller.dart` (lines 20-?: `ProfileState` `@freezed`)
  - `apps/mobile/lib/features/space/application/space_controller.dart` (lines 16-?: `SpaceState` `@freezed`)
- loc: per-file ranges above
- symbols:
  - `ReactionState` / `DiaryState` / `ProfileState` / `SpaceState` (all `@freezed`)
- evidence: `grep -c "@freezed"` returns 1 in each of the 4 controllers above; `ls features/<module>/application/` shows NO sibling `*_state.dart` for these 4 modules. Compare with auth/feed/friend/notification/settings/streak which DO ship separate state files (`ls features/{auth,feed,friend,notification,settings,streak}/application/*_state.dart` returns 10 matches).
- risk: 4 of 10 stateful modules deviate from the auth canonical layout (Pattern #1 ↔ #8). New owner copying any of the 4 modules forks the convention; tests must spin up the controller's stream subscription to instantiate the state. Inconsistency makes `/start` / `/build` skill output drift between modules. Note: `chat/application/chat_controller.dart:139 ChatSendStatus` is also inline but uses a plain class (not `@freezed`) — different smell, kept out of scope here.
- fix: Move each `@freezed` state into a sibling `*_state.dart` file:
  - `reaction_controller.dart` → `reaction_state.dart` (move `ReactionState` + `topNReactors` helper)
  - `diary_controller.dart` → `diary_state.dart`
  - `profile_controller.dart` → `profile_state.dart`
  - `space_controller.dart` → `space_state.dart`
  Re-run `dart run build_runner build --delete-conflicting-outputs` for each. Controller imports new state file.
- authority: `auth.md` Pattern #1 (folder layout) + Pattern #8 (State model in `*_state.dart`) — confirmed by 6/10 modules already following it
- test: `flutter test test/features/{reaction,diary,profile,space}/application/` must pass unchanged after extraction. No behavior change.
- deps: none

### ISSUE HOME-ARCH-001

- sev: P2
- blocker: no
- area: Module responsibility — duplicate Home implementation
- files:
  - `apps/mobile/lib/features/home/presentation/home_page.dart`
  - `apps/mobile/lib/features/feed/presentation/home_screen.dart`
  - `apps/mobile/lib/core/router/app_router.dart`
- loc: `home_page.dart:1-56`; `app_router.dart:345` (`/invite/:uid` → `HomePage`); `app_router.dart:259` (`/home` → `HomeScreen`)
- symbols:
  - `HomePage` (skeleton — `home/`)
  - `HomeScreen` (real shell — `feed/`)
- evidence: `home_page.dart:9` comment `Skeleton HomePage — module owner sẽ implement Feed/Camera/Grid scaffold theo Figma (FE/T15/KhoaLND).`; router wires `HomeScreen` to `/home` (`app_router.dart:259`) and `HomePage` only to `/invite/:uid` (`app_router.dart:344-345`); `home_page.dart:27` body is `const Text('Home — TODO')` plus an `if (kDebugMode)` sign-out branch
- risk: Two artifacts with conflicting names ("HomePage" vs "HomeScreen") for the same conceptual screen. Inventory map lists `home` as a `shell` module — but the actual shell lives in feed. Dev opening `features/home/` expects the home tree and finds a 56-line skeleton; misleads `/start` and `/build` tooling. The `/invite/:uid` deeplink renders `Text('Home — TODO')` + profile email (and a `Sign out (dev)` button gated by `kDebugMode`) — for production users this is just a "Home — TODO" placeholder, not actual invite landing UX.
- fix: Pick one:
  - Rename `HomePage` → `InviteLandingPage` and move to `features/auth/presentation/` (it owns sign-out + profile preview — auth concerns); keep `/invite/:uid` route, drop `features/home/` folder.
  - Or implement the actual invite landing UI per Figma and rename to match its purpose.
- authority: `CLAUDE.md §Domain Language — Disambiguation` (resolves "Widget"; same disambiguation discipline applies to "Home") + ADR-0004 module ownership clarity
- test: After rename, ensure `/invite/:uid` deeplink still renders (manual + `flutter test` covering router redirect for `/invite/...`).
- deps: none

### ISSUE SETTINGS-ARCH-001

- sev: P2
- blocker: no
- area: Cross-module — settings as logout/delete orchestrator
- files:
  - `apps/mobile/lib/features/settings/application/settings_controller.dart`
- loc: 78-115 (`logout`), 127-158 (`deleteAccount`)
- symbols:
  - `SettingsController.logout` — touches `notificationRepositoryProvider`, `widgetDataServiceProvider`, `notificationControllerProvider`, `authRepositoryProvider`
  - `SettingsController.deleteAccount` — same fan-out
- evidence: `await ref.read(notificationRepositoryProvider).deleteFcmToken(uid);` + `await ref.read(widgetDataServiceProvider).clearData();` + `await ref.read(notificationControllerProvider.notifier).resetForLogout();` + `await auth.signOut();` all within `logout()`
- risk: Settings module owns the entire logout sequence (FCM cleanup, widget cache wipe, FCM listener teardown, auth signOut). Anyone adding a future cleanup step (clear local cache of feed posts, etc.) must edit Settings — but solo-dev rule says Settings can't reach into other modules at will. Currently OK because each call goes through the cross-module repository's public API (no private access), but the orchestration responsibility is misplaced: 4 modules' shutdown logic concentrated in 1 controller of a 5th module.
- fix: Extract a `core/lifecycle/session_lifecycle.dart` exposing `Future<void> signOut(Ref ref)` that runs the fan-out. Or move the orchestration into `AuthRepository.signOut()` implementation (it can take a list of `Future<void> Function()` cleanup callbacks passed in via DI). Settings UI simply calls `ref.read(authRepositoryProvider).signOut()`.
- authority: ADR-0004 solo-dev module ownership + `auth.md` Pattern #9 (session lifecycle is auth's responsibility — `revalidateSession` already lives in auth, signOut fan-out should too)
- test: After extraction, `settings_controller_test.dart` shrinks (mocks one cleanup callback instead of three); `firebase_auth_repository_test.dart` (or new `session_lifecycle_test.dart`) verifies the cleanup callbacks fire in order even if one fails.
- deps: none

### ISSUE CORE-001

- sev: P2
- blocker: no
- area: Core utilities — duplicate hex-color helper
- files:
  - `apps/mobile/lib/core/utils/hex_color.dart`
  - `apps/mobile/lib/core/theme/hex_color.dart`
- loc: both files entire
- symbols:
  - `parseHexColor(String? hex) → Color?` (`core/utils/`)
  - `hexToColor(String hex, {Color fallback}) → Color` (`core/theme/`)
- evidence: two files, same purpose. `parseHexColor` returns nullable, `hexToColor` returns non-null with default fallback `Color(0xFF656C6D)`. Both currently in use: `parseHexColor` at `features/space/presentation/widgets/space_context_badge.dart:23` + `space_list_tile.dart:98`; `hexToColor` at `core/router/app_router.dart:532` and several presentation files.
- risk: Two helpers for the same task. Space module's `space_context_badge.dart:23` and `space_list_tile.dart:98` import `core/utils/hex_color.dart` (returns nullable + needs caller fallback `?? AppColors.bw700`); router + most other places import `core/theme/hex_color.dart` (returns non-null with built-in `0xFF656C6D` fallback). New dev grepping for one name misses the other. Two slightly different fallback contracts produce drift when one path renders gray and another renders the requested color.
- fix: Pick one canonical (recommend `core/theme/hex_color.dart hexToColor` since it has the better default + already imported by the router). Add a `// TODO(remove)` to the other and update all importers in one PR. Delete after merge.
- authority: `apps/mobile/CLAUDE.md` Common gotchas section spirit + `CLAUDE.md §Surgical changes` (no duplicate helpers)
- test: `rg "parseHexColor\|hexToColor" apps/mobile/lib apps/mobile/test` after change should show 0 references to the deleted symbol.
- deps: none

### ISSUE SHARED-001

- sev: P2
- blocker: no
- area: Shared widgets — coupling to feature data model
- files:
  - `apps/mobile/lib/shared/widgets/post_card.dart`
- loc: 5 (import)
- symbols:
  - `PostCard.post` (`Post post` from `features/feed/data/post.dart`)
- evidence: `import 'package:meep/features/feed/data/post.dart';` at `shared/widgets/post_card.dart:5`
- risk: Shared widget imports a feature module's data class — direction-inversion (shared ⇐ feature). When ARCH-001 is resolved (Post moves to `shared/models/`), this import naturally heals. Until then, every consumer of `PostCard` transitively pulls `features/feed/data/post.dart`. Pure side-effect of ARCH-001.
- fix: Resolved by ARCH-001. If ARCH-001 is rejected, document `feed/data/post.dart` as a shared-by-convention model and exempt `PostCard` from the "shared cannot import features" rule.
- authority: `apps/mobile/CLAUDE.md §File organization` (Feature-first); `CLAUDE.md §Cross-module touch`
- test: After ARCH-001, import path change verified by `flutter analyze --no-pub`.
- deps: ARCH-001

### ISSUE LAYER-004

- sev: P3
- blocker: no
- area: Layering — Firebase type in widget (debug-only diagnostic)
- files:
  - `apps/mobile/lib/features/chat/presentation/widgets/debug_error_view.dart`
- loc: 3 (import), 90 (`if (e is FirebaseException)`)
- symbols:
  - `DebugErrorView._extractDetails`
- evidence: `import 'package:cloud_firestore/cloud_firestore.dart';` at `debug_error_view.dart:3` + `if (e is FirebaseException) { return _ErrorDetails(...) }` at line 90; file header self-comment line 17: "Sau khi root cause confirmed, replace bằng generic message production."
- risk: Same "no Firebase types in widget" rule as LAYER-001, but lower severity for three reasons: (a) the widget is opt-in / debug-only per its own header comment; (b) `firebase_conversation_repository.dart` already wraps Firestore errors as `AppError` via `_mapFirestoreException` (lines 53, 90, 145, 195) — meaning the `FirebaseException` branch in the widget is effectively dead code today; (c) no production code path wires `DebugErrorView(...)` (grep returns only the class definition, no construction calls). Demoted from P2 → P3 because the widget exists but is unreferenced. Still leaves a Firestore import in `presentation/` that drift will reactivate.
- fix: Either delete `debug_error_view.dart` entirely (unused widget — Pattern: "no dead code"), or keep it for ad-hoc diagnostics but: (1) delete the `FirebaseException` branch since the repo already maps to `AppError`, (2) drop the `cloud_firestore` import, (3) document in the header that the widget consumes `AppError` only.
- authority: file's own header comment + `apps/mobile/CLAUDE.md §Layering` + `CLAUDE.md §Testing & Verification — What "done" means` ("No commented-out dead code")
- test: After cleanup, `rg "FirebaseException" apps/mobile/lib/features/**/presentation` returns 0 hits; `rg "DebugErrorView" apps/mobile/lib` returns 0 hits (if deleted) or 1 (definition only, if kept).
- deps: none (no longer depends on DATA-ARCH-001 because conversation repo already maps errors)

### ISSUE ROUTER-001

- sev: P3
- blocker: no
- area: Routing — stale debug bypass
- files:
  - `apps/mobile/lib/core/router/app_router.dart`
- loc: 72-79
- symbols:
  - `authRedirect`
- evidence:
  ```dart
  // DEV(C/#142): cho phép test luồng Chat FE không cần login (bypass cả 2 chiều ...).
  // Bỏ khi auth wire xong + có home-shell điều hướng Inbox sau đăng nhập.
  if (location.startsWith('/inbox') ||
      location.startsWith('/chat') ||
      location.startsWith('/group-chat')) {
    return null;
  }
  ```
- risk: Comment promises removal once auth + home-shell wire — auth is wired (`main.dart:64-71`) and home-shell exists (`HomeScreen` routes to Inbox via `TaskbarTab.chat`). Bypass means `/inbox` / `/chat/:id` / `/group-chat/:id` are reachable by an unauthenticated cold-launch deeplink, which then crashes (`messages` provider calls Firestore with empty `currentChatUid`).
- fix: Delete lines 72-79. Verify the chat routes still work post-login via `TaskbarTab.chat → context.go('/inbox')`. If any QA scenario still needs unauthenticated chat browsing, gate behind `kDebugMode` instead of unconditional bypass.
- authority: the inline comment itself; `CLAUDE.md §Surgical changes` (no dev-only flags shipping to prod)
- test: After fix, write `test/core/router/app_router_test.dart` case: `authRedirect(uid: null, ..., location: '/inbox')` returns `'/intro'`. Run `flutter test test/core/router/`.
- deps: none

### ISSUE PUBSPEC-001

- sev: P3
- blocker: no
- area: Dependencies — unused iOS-only dep
- files:
  - `apps/mobile/pubspec.yaml`
- loc: 58 (`sign_in_with_apple: ^6.1.4`)
- symbols:
  - dependency entry
- evidence: `rg "sign_in_with_apple\|SignInWithApple\|AppleAuthProvider" apps/mobile/lib` returns no matches → unused
- risk: Per ADR-0002 iOS is deferred. Dep is iOS-only Apple Sign-In; ships in dep graph + Android APK bloat is small but non-zero. Future dev adding Apple Sign-In needs to re-pin matching native plugin version. Today the dep silently rots.
- fix: Remove the `sign_in_with_apple: ^6.1.4` line. Re-pin when iOS work resumes (ADR-0002 revisit).
- authority: ADR-0002 (Android-first defer iOS) + `CLAUDE.md §Cấm` ("Tự ý cài dependency mới khi chưa thảo luận") — implies removing unused too
- test: `flutter pub get && flutter analyze --no-pub` clean; `flutter test` passes.
- deps: none

### ISSUE ARCH-003

- sev: P3
- blocker: no
- area: Module skeleton — RollCall missing
- files:
  - none (folder does not exist)
- loc: expected at `apps/mobile/lib/features/rollcall/`
- symbols:
  - none
- evidence: `Glob apps/mobile/lib/features/rollcall/**/*.dart` returns no files; `rg "rollcall|rollCall|RollCall|roll_call" apps/mobile/lib` returns no matches; `CLAUDE.md §MVP Scope` lists `RollCall basic` as Tier 0+ (must ship M3); inventory map `00_inventory_map.md §modules` does not list `rollcall`
- risk: Tier 0+ scope item has no skeleton — owner not yet assigned, route/spec not stubbed, contract not defined. Skeleton rule (CLAUDE.md §Dev Code Standards #1) requires every committed-scope module to compile with stub `UnimplementedError` so app always runs. RollCall ships as M3 — if scope is real, the absence is a process gap that becomes a build crunch.
- fix: Either (a) confirm scope downgrade and remove RollCall from `CLAUDE.md §MVP Scope` Tier 0+; or (b) leader scaffolds the module: `features/rollcall/{data/rollcall_repository.dart abstract, application/rollcall_controller.dart with UnimplementedError stub, presentation/rollcall_page.dart stub}` and adds `/rollcall` route + binding TODO in `main.dart`. Match the auth pattern.
- authority: `CLAUDE.md §Dev Code Standards — 4 non-negotiable rules` (#1 Skeleton, #2 Contract-first) + `CLAUDE.md §MVP Scope` Tier 0+
- test: After scaffolding, `flutter analyze --no-pub` clean and `flutter test` passes (no behavior added — skeleton only).
- deps: none

### ISSUE DEEPLINK-001

- sev: P1
- blocker: no
- area: Routing — invite/share link scheme drift + AndroidManifest mismatch
- files:
  - `apps/mobile/lib/core/config/app_config.dart`
  - `apps/mobile/lib/features/friend/presentation/friend_sheet.dart`
  - `apps/mobile/lib/features/settings/application/settings_controller.dart`
  - `apps/mobile/lib/features/profile/application/profile_controller.dart`
  - `apps/mobile/lib/shared/widgets/share_profile_sheet.dart`
  - `apps/mobile/lib/core/router/app_router.dart`
  - `apps/mobile/android/app/src/main/AndroidManifest.xml`
- loc:
  - `app_config.dart:2` — `shareBaseUrl = 'meep://profile'`
  - `friend_sheet.dart:68, 81` — `final link = 'https://meep.app/invite/$uid';`
  - `share_profile_sheet.dart:48` — `'meep://profile/${username ?? uid}'`
  - `app_router.dart:344` — `path: '/invite/:uid'` builder `HomePage()`
  - AndroidManifest: only `meep-staging.firebaseapp.com` + `meep-staging.web.app` hosts registered
- symbols:
  - `AppConfig.shareBaseUrl` vs `friend_sheet._copyLink` / `_shareInviteLink`
- evidence:
  - `app_config.dart:2`: `static const shareBaseUrl = 'meep://profile';`
  - `friend_sheet.dart:68`: `final link = 'https://meep.app/invite/$uid';` (hardcoded, bypasses `AppConfig`)
  - `settings_controller.dart:27` comment confirms intent: `URL format: ${AppConfig.shareBaseUrl}/{username}` (vd `meep://profile/ngantran`)
  - AndroidManifest registers neither `meep://` scheme nor `meep.app` host — only Firebase password reset hosts
  - ADR-0005 checklist (§Checklist trước khi deploy production) explicitly lists "thêm `android:host='meep.app'` vào `intent-filter`" as outstanding
- risk: Three drifts at once:
  1. **Link format inconsistency.** Profile share uses `meep://profile/{username}` (custom scheme); friend invite uses `https://meep.app/invite/{uid}` (HTTPS web). User on the receiving side sees two completely different link styles depending on who shared what.
  2. **No external reachability.** Neither `meep://` nor `meep.app` is registered in AndroidManifest — clicking the shared link from Gmail/Messenger/SMS opens browser instead of the app. Friend invite via Share Sheet is functionally dead for Android external apps.
  3. **`/invite/:uid` lands on TODO page.** Even if the link did open the app, `app_router.dart:344` routes `/invite/:uid` to `HomePage` (which renders `Text('Home — TODO')` per HOME-ARCH-001). No actual invite UX.
  ADR-0005 acknowledges parts 2-3 as deferred-to-prod, but it does NOT acknowledge the scheme drift (1) — that's a runtime bug present TODAY in staging.
- fix:
  1. Pick ONE canonical link format. Recommend `https://meep.app/invite/{uid}` (HTTPS, matches ADR-0005's prod-domain plan).
  2. Centralize in `AppConfig`: rename `shareBaseUrl` → `inviteLinkPrefix = 'https://meep.app/invite'` and `profileLinkPrefix = 'https://meep.app/profile'`. Delete `meep://` hardcoded strings.
  3. Update `friend_sheet.dart:68,81` to read from `AppConfig` instead of inlining the URL.
  4. AndroidManifest: add `android:host="meep.app"` to the existing `intent-filter` (ADR-0005 already lists this as a pre-prod TODO — pull forward).
  5. Implement `/invite/:uid` route properly (or document deferred and route to a real "Add friend" sheet, not `HomePage` placeholder).
- authority: ADR-0005 `§Checklist trước khi deploy production` + `CLAUDE.md §Cross-module touch` (no scattered link constants)
- test: Manual: tap `https://meep.app/invite/test-uid` from device's Gmail → app opens at `/invite/test-uid`. Unit: `test/core/config/app_config_test.dart` asserts `inviteLinkPrefix.startsWith('https://')`. Widget: `friend_sheet_test.dart` asserts copied clipboard text matches `AppConfig.inviteLinkPrefix`.
- deps: HOME-ARCH-001 (both touch `/invite/:uid` target — fix HOME-ARCH-001 first)

### ISSUE DEV-001

- sev: P3
- blocker: no
- area: Routing — dev-only route exposed in production build
- files:
  - `apps/mobile/lib/core/router/app_router.dart`
  - `apps/mobile/lib/dev/widget_catalog_page.dart`
- loc: `app_router.dart:443-445`
- symbols:
  - `WidgetCatalogPage` registered at `/dev/widgets`
- evidence:
  ```dart
  GoRoute(
    path: '/dev/widgets',
    builder: (_, __) => const WidgetCatalogPage(),
  ),
  ```
  Path registered unconditionally — no `if (kDebugMode)` gate; the same route ships in release APK.
- risk: Dev catalog page is reachable in production builds via `https://app.go('/dev/widgets')`. The page imports friend/space internals (`widget_catalog_page.dart:10-16`) and would render dev-only UI to end-users if they (or QA, or a curious user via deep link) hit the path. `authRedirect` does treat `/dev` as auth-route (allowed when uid=null per `app_router.dart:83`), which makes it even more reachable. Not P2 because no production path navigates to it and no external trigger exists — but the surface should be gated.
- fix: Wrap registration in `if (kDebugMode)` at the routes-list build site, or only register it when `AppConfig._env != 'prod'`. Same pattern as `home_page.dart:41 if (kDebugMode) ...[ TextButton(...) ]` already uses elsewhere.
- authority: `home_page.dart:41` precedent + `CLAUDE.md §Cấm` ("dev-only flags shipping to prod")
- test: After fix, `if (kDebugMode)` strips the route from release; `flutter build apk --release` and grep apk for `/dev/widgets` returns no hits (alternative: integration test in profile mode navigating to `/dev/widgets` should redirect to `/intro` or 404).
- deps: none

## fix_order

### batch_1_p0

1. **LAYER-002** — controllers: route `FirebaseAuth.instance` + Firestore-direct out via `currentUidProvider` and repository APIs. (Foundation: enables LAYER-001 and FEED-ARCH-001 to compile cleanly.)
2. **LAYER-001** — widgets: replace `FirebaseAuth.instance.currentUser?.uid` with `ref.watch(currentUidProvider)`.

### batch_2_p1

3. **FEED-ARCH-001** — promote feed providers to stub+override; bind in `main.dart`.
4. **DATA-ARCH-001** — add `_mapXxxError` to 5 repos; drop ad-hoc `_errorMessage` in `PostController`.
5. **LAYER-003** — replace `DocumentSnapshot? lastDoc` with typed cursor.
6. **FEED-ARCH-002** — inject `FriendRepository` into `FirebasePostRepository`; delete direct `friendships` query.
7. **ARCH-001** — move `Post` (and audience/caption enums) to `shared/models/` (or document as canonical shared model).
8. **ARCH-002** — split `home_screen.dart` / `feed_section.dart` / `capture_preview_screen.dart` per CLAUDE.md thresholds.
9. **DEEPLINK-001** — unify share/invite link via `AppConfig`; AndroidManifest add `meep.app` host; route `/invite/:uid` to real UI (depends on HOME-ARCH-001).

### batch_3_p2

10. **STATE-ARCH-001** — extract `ReactionState` / `DiaryState` / `ProfileState` / `SpaceState` into sibling `*_state.dart` files.
11. **HOME-ARCH-001** — collapse `home/` skeleton (rename to InviteLandingPage in auth/, drop `features/home/`).
12. **SETTINGS-ARCH-001** — extract logout/delete fan-out to `core/lifecycle/` or `AuthRepository.signOut`.
13. **CORE-001** — dedupe hex-color helpers.
14. **SHARED-001** — auto-resolved by ARCH-001.

### batch_4_p3

15. **LAYER-004** — delete or trim `debug_error_view.dart` (unused; FirebaseException branch dead code since conversation repo already maps).
16. **ROUTER-001** — delete chat-route auth bypass.
17. **PUBSPEC-001** — remove `sign_in_with_apple` dep.
18. **DEV-001** — gate `/dev/widgets` route behind `kDebugMode`.
19. **ARCH-003** — leader decision: scaffold or descope RollCall.

## test_plan_after_fix

- `LAYER-001`: `flutter test test/features/feed/presentation/feed_section_test.dart test/features/feed/presentation/home_screen_test.dart` — overrides for `currentUidProvider`; render asserts no Firebase binding required.
- `LAYER-002`: `flutter test test/features/feed/application/post_controller_test.dart test/features/feed/application/feed_controller_test.dart` — `ProviderContainer` with `currentUidProvider` + `postRepositoryProvider` overrides; assert `submit()` short-circuits with `UnauthenticatedError` on null uid.
- `FEED-ARCH-001`: `flutter analyze --no-pub` clean post-refactor; existing feed tests pass without code change beyond override.
- `LAYER-003`: `flutter test test/features/feed/application/feed_state_test.dart` — verify cursor `copyWith` round-trip.
- `DATA-ARCH-001`: `flutter test test/features/{feed,friend,reaction,notification}/data/firebase_*_repository_test.dart` — `mock_exceptions` on `FirebaseException(code: ...)` → assert `ForbiddenError` / `NetworkError` etc.
- `FEED-ARCH-002`: `flutter test test/features/feed/data/firebase_post_repository_test.dart` — `MockFriendRepository` returns `['friend-uid']`; assert no Firestore call to `/friendships`.
- `ARCH-001`: `flutter analyze --no-pub` clean; `flutter test` full suite.
- `ARCH-002`: `flutter test test/features/feed/presentation/` — widget tests for newly extracted widgets.
- `STATE-ARCH-001`: `flutter test test/features/{reaction,diary,profile,space}/application/` — unchanged behavior after state extraction.
- `DEEPLINK-001`: `test/core/config/app_config_test.dart` asserts `inviteLinkPrefix.startsWith('https://')`; widget test on `friend_sheet.dart` asserts clipboard text uses `AppConfig`; manual: tap `https://meep.app/invite/test-uid` from external app.
- `DEV-001`: `flutter build apk --release && grep -r "/dev/widgets" build/app/outputs/` returns 0 hits.
- `HOME-ARCH-001`: `flutter test test/core/router/app_router_test.dart` — `/invite/:uid` test renders without crash.
- `SETTINGS-ARCH-001`: `flutter test test/features/settings/application/settings_controller_test.dart` — mocks one orchestrator; existing test moves to new lifecycle location.
- `CORE-001`: `rg "parseHexColor|hexToColor" apps/mobile` shows 0 references to deleted symbol.
- `LAYER-004`: `rg "FirebaseException" apps/mobile/lib/features/**/presentation` returns 0 hits.
- `ROUTER-001`: `flutter test test/core/router/app_router_test.dart` — unauthenticated `/inbox` redirects to `/intro`.
- `PUBSPEC-001`: `flutter pub get && flutter analyze --no-pub` clean; `flutter test` passes.
- `ARCH-003`: `flutter analyze --no-pub` clean after scaffold; `flutter test` passes (no behavior added).

## no_issue_notes

Compact notes for important areas checked with no issue found.

- `core/error/app_error.dart`: complete sealed family per Pattern #3 — `UnauthenticatedError`, `ForbiddenError`, `NotFoundError`, `ValidationError`, `NetworkError`, `UnexpectedError`, `OperationCancelledError` + `AppError.fromUnknown` factory. No gaps.
- `core/router/app_router.dart`: `authRedirect` pure-function + `_RouterNotifier` no-op listen pattern matches `auth.md` Pattern #6. `routeForNotification` pure-mapping testable. Outside ROUTER-001 chat bypass, redirect logic clean.
- `main.dart` bootstrap order: `WidgetsFlutterBinding.ensureInitialized()` → `Firebase.initializeApp()` → emulator wiring (`USE_EMULATOR` env) → `SharedPreferences.getInstance()` → `revalidateSession` (auth) → `runApp(ProviderScope(overrides: [...]))`. Matches Pattern #5 + checklist item "Firebase.initializeApp → Crashlytics → Riverpod scope → router" (Crashlytics opt-in via dep but no explicit init — outside architecture audit's scope; flagged by 05_security audit if relevant).
- All abstract repository stubs (`auth`, `user`, `friend`, `friend_request`, `space`, `block`, `conversation`, `profile`, `widget_data`, `reaction`, `notification`, `notification_preferences`, `diary`, `diary_storage_client`, `image_picker_service`, `streak`) wired in `main.dart:76-140`. No `UnimplementedError` leak detected outside FEED-ARCH-001 (which bypasses the stub pattern).
- `firebase_diary_repository.dart`: `DocumentSnapshot<Map<String,dynamic>>` usage stays inside the data layer (lines 153/212/276) — boundary respected. Internal repo helpers, not exposed to controllers.
- Friend / Notification / Settings / Streak / Auth / Feed modules: 3-layer folder layout per Pattern #1 (`data/`, `application/`, `presentation/`) AND state in sibling `*_state.dart` (verified via `ls features/*/application/*_state.dart` returning 10 matches across 6 modules). Reaction / Diary / Profile / Space deviate — see STATE-ARCH-001.
- Notification controller imports `firebase_messaging` directly — FCM stream API is callback-shaped and difficult to abstract cleanly into a repository without a wrapper that hurts clarity. Accept with note: if a future test needs to fake FCM, extract `MessagingClient` wrapper.
- Vietnamese error messaging present at boundary in 8/13 modules (auth, chat, diary, friend_request, profile, settings/block, space, streak per Grep). VN-at-boundary discipline (Pattern #10) holds for those — DATA-ARCH-001 callouts are the remaining 5.
- `shared/widgets/` has 22 files all real-name shared components (`AppAvatar`, `AppPhotoFrame`, `AppPrimaryButton`, ...). Spot-check shows no false reuse beyond `post_card.dart` coupling captured in SHARED-001.
- `core/utils/pair_id.dart` matches `CLAUDE.md §Identifiers pairIdOf`. Single source of truth.
- Riverpod `keepAlive: true` usage (22 occurrences) appropriately scoped to repositories + cross-route controllers — no default-everywhere smell.

## postcheck

- git_status_after:
  - `?? docs/audits/` (pre-existing, untracked dir entry)
  - `?? tmp/audit/ThienPDM/01-architecture` (pre-existing, untracked)
  - new file inside: `docs/audits/01_architecture_audit.md`
- changed_files_after:
  - `docs/audits/01_architecture_audit.md`
- unexpected_modified_files: none

## final_verdict

verdict: not_ready

Rationale: 2× P0 (Firebase leaks in feed widget + controller layer) block the layering invariant that all other audits implicitly rely on (test override, repository contract). 7× P1 cluster around Feed module shortcuts vs the canonical auth pattern (provider DI, error mapping, friend-graph access, file size, shared Post model owner ambiguity, state type leak) PLUS the deeplink scheme drift (DEEPLINK-001) that breaks external app sharing today on staging. Until LAYER-001 + LAYER-002 are fixed, feed-feature widget tests cannot be added meaningfully — golden-path coverage is structurally blocked.

After batch_1 + batch_2 (P0 + P1), revisit for `almost_ready_after_p0_p1`. P2/P3 are non-blocking polish.

Final distribution after pass-3 reverify: **P0=2, P1=7, P2=5, P3=5 — total 19 issues** (pass-3 added STATE-ARCH-001 expanding the original REACT-ARCH-001 to cover 4 modules, plus DEEPLINK-001 P1 and DEV-001 P3 found while verifying ADR-0005 + AndroidManifest + dev folder coverage).

## self_verification_log

<!-- 4 passes recorded after first draft per audit prompt. Pass-2 reverify run as follow-up; see notes per pass. -->

pass_1_checklist: N=14 sub-sections (~45 line items), M=17 issues, K=10 no_issue_notes, gap=0 — each prompt checklist sub-section sub-mapped: Feature-first→HOME-ARCH-001+no_issue; Data layer→LAYER-003+DATA-ARCH-001+no_issue (VN msg 8/13 modules); Firebase leakage→LAYER-001+LAYER-002+LAYER-004; Cross-module→FEED-ARCH-002+ARCH-001+SHARED-001; Provider scope→FEED-ARCH-001+no_issue (keepAlive); Async state→no_issue (ref.onDispose confirmed); Routing→ROUTER-001+no_issue; Error abstraction→DATA-ARCH-001+no_issue (AppError family); Model/freezed→REACT-ARCH-001+no_issue; Bootstrap→no_issue (main.dart order); Client/backend→partial (deep boundary blocked); Shared widget→CORE-001+SHARED-001+no_issue; Docs/ADR→PUBSPEC-001; Module responsibility→HOME-ARCH-001+ARCH-003.
pass_2_schema: total=17, missing_field_fixed=0, severity_demoted=1 (LAYER-004 P2→P3 after re-verifying `firebase_conversation_repository.dart:53,90,145,195` already maps `FirebaseException` → `AppError` and `DebugErrorView` has zero construction sites — original "leaks when DATA-ARCH-001 fires" premise wrong because the path it diagnoses is already mapped), evidence_failed_grep=0 — re-grep all 17 evidence quotes via Bash against source files: LAYER-001 @ feed_section.dart:80, home_screen.dart:589; LAYER-002 @ post_controller.dart:107; LAYER-003 @ feed_state.dart:14; FEED-ARCH-001 @ feed_controller.dart:33; FEED-ARCH-002 @ firebase_post_repository.dart:260; ARCH-001 importers re-counted via `grep -rln` (27 production + 11 test = 38, corrected from earlier "10"); ROUTER-001 @ app_router.dart:72; PUBSPEC-001 @ pubspec.yaml:58 + `grep -rn` on lib/test for `sign_in_with_apple\|SignInWithApple\|AppleAuthProvider` returns 0; CORE-001 both files confirmed + importers traced (parseHexColor used in `space_context_badge.dart:23` + `space_list_tile.dart:98`; hexToColor at `app_router.dart:532` etc.); HOME-ARCH-001 @ home_page.dart:9,27 + app_router.dart:344-345 + risk corrected ("Sign out (dev)" gated by `kDebugMode`, not the entire screen); REACT-ARCH-001 @ reaction_controller.dart:14; ARCH-003 rollcall folder absent re-confirmed; LAYER-004 evidence verified + risk premise rewritten based on conversation_repo + DebugErrorView grep results. Pass-2 reverify also corrected: `app_router.dart` line count 547→546, DATA-ARCH-001 evidence enumerated per-file (instead of single sentence), final_verdict tallies recomputed.
pass_3_dedupe: before=17, after=17, consolidations=0 — verified no two issues share files[0]+symbols+root_cause+fix: LAYER-001 (presentation widget files) vs LAYER-002 (application controller files) — different layer, different fix. SHARED-001 + ARCH-001 share `post.dart` but SHARED-001 is the consequence (one file), ARCH-001 is the cause (multi-file architecture call), fix orderings differ. DATA-ARCH-001 already consolidates 5 repository files into one batched issue. LAYER-004 explicitly linked as dependent cleanup of DATA-ARCH-001 in batch 4 but with different fix (delete vs. add mapping).
pass_4_coverage: checked=17, partial=7, blocked=1, total=25, verdict=partial — coverage matches log evidence: blocked is `features/rollcall` (folder genuinely absent — ARCH-003); partial covers core/theme + core/validators (listed-only, theme tokens out of architectural scope), diary + space (file inventory + cross-edge analysis only, no smell flagged → deep-read not justified for arch first-pass; pass-2 re-grep confirmed AppError boundary already in place for both), shared/widgets (head sampled), firebase/ client/backend boundary (per-handler typecheck would require running tooling), ADR/docs match (skim only). `flutter analyze --no-pub` recorded as blocked in commands table (audit-only constraint); not in coverage area count.

pass_2_reverify_notes (post-commit follow-up after user request):
- FACT FIX 1 (LAYER-004 demote): originally P2 with claim "depends on DATA-ARCH-001"; verified `firebase_conversation_repository.dart:53,90,145,195` already throws `_mapFirestoreException → AppError`, AND `grep DebugErrorView` returns only class definition (0 production wires). Demoted to P3, fix changed to "delete or trim", deps cleared.
- FACT FIX 2 (ARCH-001 importer count): originally "10 import paths"; `grep -rln "import 'package:meep/features/feed/data/post.dart'"` returns 38 paths (27 production incl. `core/router/app_router.dart` + 11 test). Updated file list and fix step.
- FACT FIX 3 (HOME-ARCH-001 risk): originally "renders only a dev-mode sign-out button"; verified `home_page.dart:27 const Text('Home — TODO')` + profile email always rendered; sign-out gated by `kDebugMode`. Corrected.
- FACT FIX 4 (CORE-001 risk premise): originally "Glob: 0 imports currently — TBD verify" for `parseHexColor`; verified actual importers: `features/space/presentation/widgets/space_context_badge.dart:23` + `space_list_tile.dart:98`. Updated evidence + risk.
- FACT FIX 5 (DATA-ARCH-001 evidence enum): originally a single sentence pointing at one line; per-file evidence now enumerates: post_repo:31+150, storage_repo:37 (rethrow non-`object-not-found`), friend_repo (0 mappings), reaction_repo (0 mappings), notification_repo (only `ArgumentError`). Confirms 5/5 in batch — all genuinely missing `AppError` boundary.
- FACT FIX 6 (app_router.dart line count): 547 → 546 (off-by-one from blank trailing line).
- COUNT CORRECTION: blockers_summary table previously framed P1=7, actual P1=6 (FEED-ARCH-001, LAYER-003, DATA-ARCH-001, FEED-ARCH-002, ARCH-001, ARCH-002). Total = 2 P0 + 6 P1 + 5 P2 + 4 P3 = 17. PR summary text from prior commit needs follow-up note (numbers there based on pre-reverify P0=2,P1=7,P2=5,P3=3 = 17 same total but different bucket).

pass_3_reverify_notes (second user-requested deep-verify — checked AndroidManifest deeplink, async state ownership, dev folder, state-file colocation breadth, ADR-0005 drift):
- FACT FIX 7 (REACT-ARCH-001 → STATE-ARCH-001 expand): pass-2 claim was "state colocated in controller" applies only to Reaction. Verified via `grep "@freezed" features/*/application/*_controller.dart` + `ls features/*/application/*_state.dart`: 4 modules collocate (`reaction`, `diary`, `profile`, `space`), 6 modules split correctly (`auth`, `feed`, `friend`, `notification`, `settings`, `streak`). Issue scope tripled. ChatSendStatus (`chat_controller.dart:139`) is plain (non-`@freezed`) class — left out of issue.
- FACT FIX 8 (no_issue_note about state-file split corrected): note previously read "Friend / Reaction / Diary / Profile / Space modules: 3-layer... State files split correctly for all except Reaction (see REACT-ARCH-001)". This was factually wrong (Reaction/Diary/Profile/Space all colocate). Rewrote to reflect actual 6 split / 4 collocate.
- ISSUE ADD 1 (DEEPLINK-001 P1): re-reading ADR-0005 + `grep "meep://" "https://meep.app/"` exposed scheme drift between `AppConfig.shareBaseUrl = 'meep://profile'` (used by profile/settings/share_profile_sheet) and `friend_sheet.dart:68,81 https://meep.app/invite/...` (used by friend invite). AndroidManifest registers neither scheme/host. `/invite/:uid` route lands on `HomePage` placeholder (HOME-ARCH-001). P1 because it breaks current staging UX for external share.
- ISSUE ADD 2 (DEV-001 P3): `app_router.dart:443-445` registers `/dev/widgets` route unconditionally — ships in release APK and reachable via deep-link. Not P2 because no production trigger exists; P3 for cleanup.
- FACT CONFIRMATION (async state ownership): grep `StreamSubscription | .listen(` across `features/` returned 24 sites. Spot-checked notification_controller (line 49-54 `ref.onDispose` cancels all 3 + bannerTimer), friend_controller (line 57-66 cancels all subs + retry timers), space_controller, streak_controller, profile_controller, diary_controller, feed_controller (line 125), reaction_controller (line 51) — every one of them paired with `ref.onDispose`. No leaks. no_issue_note for "Async state ownership" verified.
- FACT CONFIRMATION (chat module status): conversation_repository is FirebaseConversationRepository wired in main.dart:104; FakeConversationRepository exists only as test fixture. Chat module Tier 1 scope acceptable — not a P3 gap.
- FACT CONFIRMATION (ADR-0005): explicitly documents `assetlinks.json` and `meep.app` host as deferred to prod. Out-of-scope per scope_filter for prod-deploy-checklist items. But scheme-drift (DEEPLINK-001) is NOT in ADR-0005's deferred list — that's a runtime smell not a deploy gate.
- COUNT UPDATE: 17 → 19 issues. Distribution: P0=2, P1=7 (added DEEPLINK-001), P2=5 (REACT-ARCH-001 renamed STATE-ARCH-001, scope expanded but stays P2), P3=5 (added DEV-001).
