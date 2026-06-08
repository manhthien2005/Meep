# 04_performance_audit

## meta

- repo: Meep
- root: D:/meep-audit-04-perf
- branch: docs/ThienPDM/04-performance-audit
- date: 2026-06-07
- mode: audit-only
- audit_focus: performance_runtime_firebase_cost
- modified_files_allowed:
  - docs/audits/04_performance_audit.md
- read_baseline:
  - docs/audits/00_inventory_map.md
  - docs/audits/A_PHASE_BASELINE_SUMMARY.md
  - docs/audits/01_architecture_audit.md
  - docs/audits/05_security_firebase_audit.md
  - CLAUDE.md (root)
  - apps/mobile/CLAUDE.md
  - .claude/reference-architectures/auth.md
  - firebase/firestore.indexes.json

## precheck

- git_status_before: `?? tmp/docs/ThienPDM/04-performance-audit` (audit staging, not part of repo)
- existing_user_changes: no (matches baseline `00_inventory_map.md §baseline_git_status` — `M apps/mobile/pubspec.lock` absent because fresh worktree clone; `?? tmp/` chỉ là audit staging)
- target_report_preexisting_dirty: no (file created in this pass)

## commands

| cmd | status | notes |
|---|---|---|
| `git rev-parse --show-toplevel` + `git status --short` + `git branch --show-current` | ok | precheck |
| `git ls-files apps/mobile/lib` | ok | 200+ files mapped |
| Read `apps/mobile/lib/main.dart` | ok | bootstrap + 13 provider overrides |
| Read `apps/mobile/lib/features/feed/data/firebase_post_repository.dart` | ok | per-author fan-out + space stream + `_mergeStreams` + `_getFriendUids` direct |
| Read `apps/mobile/lib/features/feed/data/firebase_storage_repository.dart` | ok | 5MB cap, single putData |
| Read `apps/mobile/lib/features/feed/application/feed_controller.dart` | ok | watchFeed + onItemVisible + widget update fire-and-forget |
| Read `apps/mobile/lib/features/feed/application/post_controller.dart` | ok | flutter_image_compress quality 85→60 fallback |
| Read `apps/mobile/lib/features/feed/presentation/{home_screen,feed_section,camera_section,capture_preview_screen,grid_view_screen,grid_photo_tile}.dart` | ok | rebuild + image-cache patterns |
| Read `apps/mobile/lib/features/friend/data/firebase_friend_repository.dart` | ok | watchFriends N+1 batch get + searchUser limit(1) |
| Read `apps/mobile/lib/features/friend/application/friend_controller.dart` | ok | 3 stream subs + self-healing retry + onDispose cancel |
| Read `apps/mobile/lib/features/notification/data/firebase_notification_repository.dart` | ok | getNotifications no limit |
| Read `apps/mobile/lib/features/notification/application/notification_controller.dart` | ok | initFcm idempotent + onDispose cancel 3 subs + timer |
| Read `apps/mobile/lib/features/space/{application/space_controller,data/firebase_space_repository}.dart` | ok | watchMySpaces + watchMembers + 5 callables |
| Read `apps/mobile/lib/features/chat/{application/{chat_controller,chat_providers},data/firebase_conversation_repository,presentation/{inbox_screen,chat_thread_view}}.dart` | ok | conversations + messages windowed limit 50 |
| Read `apps/mobile/lib/features/diary/{data/firebase_diary_repository,application/diary_controller,presentation/{diary_list_screen,diary_canvas_screen}}.dart` | ok | watchEntries no limit + getPublicEntries no limit + searchEntries client filter |
| Read `apps/mobile/lib/features/streak/data/firebase_streak_repository.dart` | ok | watchUserMonth scoped query OK + getUserAllDates full scan |
| Read `apps/mobile/lib/features/profile/{application/{friend_posts_provider,profile_posts_provider},data/firebase_profile_repository,presentation/{edit_profile_screen,widgets/photo_grid}}.dart` | ok | unbounded getPostsByAuthor + Image.network no cache |
| Read `apps/mobile/lib/features/reaction/application/reaction_controller.dart` | ok | watchReactions per postId + ref.onDispose |
| Read `apps/mobile/lib/features/settings/application/settings_controller.dart` | ok | logout/deleteAccount fan-out |
| Read `apps/mobile/lib/features/auth/application/auth_providers.dart` | ok | currentUidProvider + currentUserProfileProvider stream |
| Read `apps/mobile/lib/features/widget/application/widget_data_service.dart` | ok | SharedPreferences + MethodChannel poke |
| Read `apps/mobile/lib/shared/widgets/{app_avatar,post_card}.dart` | ok | CachedNetworkImage no memCacheWidth |
| Read `apps/mobile/android/app/src/main/kotlin/dev/meep/meep/{WidgetSyncWorker,WidgetDataStore,MeepWidget}.kt` | ok | 15min periodic + NetworkType.CONNECTED + Glide cache + ID token refresh |
| Read `firebase/functions/src/{index,feed/onPostCreated,space/{spacePostFanOut,createSpace,onSpaceMemberAdded},notification/{_fcm,onReactionCreated}}.ts` | ok | region asia-southeast1 + maxInstances=10 + timeout=60 + lazy-import messaging |
| Read `firebase/firestore.indexes.json` | ok | 10 composite indexes |
| `rg debugPrint apps/mobile/lib/features/feed` | ok | 53 hits across 8 feed files (debug logs in hot path) |
| `rg cacheWidth\|memCacheWidth apps/mobile/lib` | ok | 0 hits — no image cache sizing anywhere |
| `rg RepaintBoundary apps/mobile/lib` | ok | 0 hits |
| `rg AutomaticKeepAlive apps/mobile/lib` | ok | 0 hits |
| `rg ListView\(\|GridView\( apps/mobile/lib` | ok | 3 hits (chat_thread_view + space_quick_row + widget_catalog_page) |
| `flutter analyze --no-pub` | blocked | audit-only constraint per LAYER-B; static evidence sufficient |

## coverage

- UI rebuild patterns: checked (feed/home/streak/chat/inbox/diary/profile + 22 shared widgets sampled)
- Firestore queries (client): checked (feed/friend/notification/space/chat/diary/streak/profile/reaction repos all read end-to-end)
- Firestore queries (functions): checked (onPostCreated + spacePostFanOut + onReactionCreated + createSpace + onSpaceMemberAdded + _fcm)
- Streams/listeners lifecycle: checked (notification 3 subs + friend 3 subs + 3 retry timers + space 1 sub + 1 retry + diary 1 sub + feed 1 sub via completer + reaction 1 sub — all paired with `ref.onDispose`; `_mergeStreams` cancels on completer close)
- Image pipeline (compress/upload/cache): checked (post_controller compress 85→60 fallback, image_picker_service 85@1024, profile compress 85@512, AppAvatar/PostCard/GridPhotoTile CachedNetworkImage, PhotoGrid Image.network)
- Functions cost/cold-start: checked (globalOpts asia-southeast1 + maxInstances 10 + timeout 60; lazy-import `firebase-admin/messaging` in `_fcm.ts:51`; spacePostFanOut sequential per spaceId; idempotency markers via `.create()` for notification + space member)
- Widget native (Kotlin) refresh: checked (15min PeriodicWork floor + `NetworkType.CONNECTED` + Glide disk+memory cache + 720/128px override + 20s blocking timeout + AggregateSource.SERVER count())
- Indexes coverage: checked (10 composite indexes vs 9 distinct client query shapes — all client queries have a matching index; 1 dead index `posts(authorId, spaceId, createdAt)` noted in `no_issue_notes`)
- FCM token write frequency: checked (`saveFcmToken` read-then-batch-delete-then-set per onTokenRefresh; SHA-256 doc-id makes same-device re-login idempotent)
- App bootstrap: checked (`main.dart:53-74` ensureInitialized → Firebase.initializeApp → optional emulator + SharedPreferences + revalidateSession network call → runApp with 13 overrides)

## blockers_summary

Only P0/P1.

| id | sev | area | files | short |
|---|---|---|---|---|
| FEED-PERF-001 | P0 | Firestore listener fan-out | `apps/mobile/lib/features/feed/data/firebase_post_repository.dart` | `_watchFriendsFeed` spawns 1 listener per friend (+1 space) — 20 friends = 21 concurrent snapshots, ~21×20 reads/emit on home cold start |
| FRIEND-PERF-001 | P0 | Firestore N+1 reads | `apps/mobile/lib/features/friend/data/firebase_friend_repository.dart` | `watchFriends` re-fetches every friend's `/users/{fuid}` doc on EVERY `/friendships` snapshot emit → 20 docs/emit, fires whenever any friendship doc updates |
| FEED-REBUILD-001 | P1 | UI rebuild excess + perf cost | `apps/mobile/lib/features/feed/presentation/feed_section.dart` | `addPostFrameCallback` scheduled in `SliverChildBuilderDelegate.itemBuilder` on every visible item rebuild → `onItemVisible` fires N×scroll-frames |
| NOTIF-PERF-001 | P1 | Firestore over-fetch | `apps/mobile/lib/features/notification/data/firebase_notification_repository.dart` | `getNotifications` has no `.limit()` → loads entire `/users/{uid}/notifications` collection in one `get()` |
| IMG-PERF-001 | P1 | Image memory pressure | 13 sites (post_card×2, app_avatar, grid_photo_tile, photo_detail_screen×2, profile_screen, friend_profile_screen, edit_profile_screen, calendar_day_cell, message_quoted_post, quoted_photo_block, camera_section history thumb) | `CachedNetworkImage` codebase-wide without `memCacheWidth/memCacheHeight` — 1080px source decoded for 37×35px calendar cell + 60px thumb + 40px avatar |
| PROFILE-PERF-001 | P1 | Firestore over-fetch | `apps/mobile/lib/features/profile/application/{profile_posts_provider,friend_posts_provider}.dart`, `apps/mobile/lib/features/feed/data/firebase_post_repository.dart` | `getPostsByAuthor` returns the entire author history with no `.limit()` — profile screen + friend profile screen both call it |
| WIDGET-PERF-001 | P1 | Battery + user-data drain | `apps/mobile/android/app/src/main/kotlin/dev/meep/meep/WidgetSyncWorker.kt` | `WidgetSyncWorker` uses `NetworkType.CONNECTED` — image-heavy 15-min sync runs over mobile data (no UNMETERED gate, no battery-not-low constraint) |
| FUNC-PERF-003 | P1 | CF query schema drift — dead cleanup | `firebase/functions/src/friend/onFriendshipDeleted.ts` | Line 60-66 filters feed docs by `where('spaceId', '==', null)` but feed/post docs use `spaceIds` (plural array) — query NEVER matches → unfriend leaves stale feed entries forever |

## issues

### ISSUE FEED-PERF-001

- sev: P0
- blocker: yes
- area: Firestore listener fan-out + read cost
- files:
  - `apps/mobile/lib/features/feed/data/firebase_post_repository.dart`
- loc: 172-221 (`_watchFriendsFeed`), 224-257 (`_mergeStreams`)
- symbols:
  - `FirebasePostRepository._watchFriendsFeed`
  - `FirebasePostRepository._mergeStreams`
- evidence: `final perAuthorStreams = authorIds.take(30).map((authorId) { return _db.collection(_posts).where('authorId', isEqualTo: authorId).orderBy('createdAt', descending: true).limit(_perAuthorBuffer).snapshots()` (`firebase_post_repository.dart:176-187`) — N friend uids + self → `take(30)` author streams; plus `spaceMemberStream` (line 192-201). Result: 1 home open = up to 31 concurrent Firestore listeners.
- cost_model: 21 listeners × 20 docs each = 420 reads on first emit per 20-friend user. Each `_perAuthorBuffer = 20` (line 156). With Locket-parity baseline 50-200 posts/user/day, every new friend post triggers 1 listener × 20 docs re-read for the change-set. 100 emits/day/user × 20 friends ≈ 40 000 reads/user/day. Free Spark tier ceiling 50 000 reads/day → app exhausts quota at < 1 active user for the feed alone.
- risk: catastrophic Firebase bill + UI cold-start latency (21 stream subscriptions all need first emit before `_mergeStreams` yields anything — line 240 `latestValues.every((v) => v != null)`). Also burns battery — 21 active snapshot listeners hold network connection open. CLAUDE.md §LAYER-A Meep constraints: "Watch fan-out cho friend graph (mỗi friend → 1 listener)" — explicitly called out as P1-minimum cost concern; this is a P0 because the implementation matches the exact anti-pattern.
- fix: consolidate per-author fan-out into 1 query using `whereIn` (Firestore caps 30 values per `in`/`whereIn` array as of late 2024 → fits the `take(30)` ceiling already enforced). Replace lines 173-220 with:
  ```dart
  Stream<List<Post>> _watchFriendsFeed(String uid) {
    return _getFriendUids(uid).asStream().asyncExpand((friendUids) {
      final authorIds = [uid, ...friendUids].take(30).toList();
      if (authorIds.isEmpty) return Stream.value(<Post>[]);
      // 1 query, 1 listener, server-side OR.
      final friendsStream = _db.collection(_posts)
          .where('authorId', whereIn: authorIds)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots()
          .map((snap) => snap.docs.map((d) => Post.fromJson(d.data())).toList());
      final spaceStream = _db.collection(_posts)
          .where('memberIds', arrayContains: uid)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots()
          .map((snap) => snap.docs.map((d) => Post.fromJson(d.data())).toList());
      return _mergeStreams([friendsStream, spaceStream]).map((all) {
        final seen = <String>{};
        final unique = [for (final p in all) if (seen.add(p.postId)) p];
        unique.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return unique.take(10).toList();
      });
    });
  }
  ```
  Requires a composite index `(authorId ASC, createdAt DESC)` — already declared at `firebase/firestore.indexes.json:3-10`, no schema change needed. `whereIn` query against that index is what Firestore docs recommend for friend-feed fan-out vs N parallel `==` queries.
- authority: `apps/mobile/CLAUDE.md §Async/streams` ("Prefer `Stream` from Firestore for live data") + CLAUDE.md §LAYER-A Meep constraints "Firestore cost = ranked P1 minimum ... Watch fan-out cho friend graph" + Firestore official docs §Query operators `in / not-in / array-contains-any` (30-value limit). Cite Phase A `ARCH-FEED-ARCH-001` (provider self-construct) as **related context** — that issue is about DI pattern, this is the runtime cost it hides; fixing one does not fix the other.
- test: write `test/features/feed/data/firebase_post_repository_test.dart` test case `watchFeed(uid) emits merged friend posts with single whereIn query` using `fake_cloud_firestore`. Seed 25 posts across 20 authors, assert `MockQuery.snapshots()` call count is ≤ 2 (1 whereIn + 1 arrayContains), NOT 21. Run `flutter test test/features/feed/data/firebase_post_repository_test.dart`.
- deps: blocked-by ARCH-FEED-ARCH-001 only at the DI surface — refactor must keep provider override pattern; otherwise independent.

### ISSUE FRIEND-PERF-001

- sev: P0
- blocker: yes
- area: Firestore N+1 reads + listener cascade
- files:
  - `apps/mobile/lib/features/friend/data/firebase_friend_repository.dart`
- loc: 29-59 (`watchFriends`)
- symbols:
  - `FirebaseFriendRepository.watchFriends`
- evidence: `final userDocs = await Future.wait(friendUids.map((fuid) => _firestore.collection('users').doc(fuid).get()),);` (`firebase_friend_repository.dart:49-52`). Sits inside `.snapshots().asyncMap(...)` (line 33-34) — every `/friendships` snapshot emit re-runs the N parallel `get()`s, even when only 1 friendship doc changed.
- cost_model: 20 friends → 1 `/friendships` snap (20 docs in result set) + 20 parallel `/users/{fuid}.get()` per emit. Firestore charges 1 read per `get()`, regardless of whether the doc actually changed. Friend graph change rate is low but the listener also re-fires on profile updates to /users via the relationship (each friendship doc carries an `updatedAt` in some flows). Realistic estimate: 20 reads × 5 re-emits/session = 100 reads/session/user just to render the friend list pill.
- risk: doubles down on FEED-PERF-001 — every place that watches friends (`HomeScreen._HomeTopBar`, `CapturePreviewScreen._AudienceRow`, `FriendSheet`, `FriendSelectStep` for Space creation) pays the N+1 cost. Phase A `SEC-USER-SEC-001` (P0) flags the same path for privacy (any authed reads `/users/{uid}`) — fix interlocks: once SEC tightens `/users/{uid}` to `isOwner || isFriend`, this batch read still works but the migration to `/users/{uid}/public/profile` subcollection is the natural moment to also fix the N+1 here. Doing both at once avoids two consecutive client refactors.
- fix: 3 options ordered by preference:
  1. (recommended, pairs with SEC-USER-SEC-001 migration) replace the per-friend `.get()` loop with a single `whereIn` over the `/users/{uid}/public/profile` subcollection group after that subcollection is denormalized by the SEC fix's CF trigger. One snapshot listener instead of 1 + N.
  2. (intermediate, no SEC dependency) keep the parallel `get()` but cache `/users/{fuid}` Profile result keyed by `fuid` inside the repo for the lifetime of the friend list emit cycle (TTL 30s). Only re-fetch profiles whose friendship `updatedAt` changed since the last emit.
  3. (degenerate) denormalize `displayName + avatarUrl` directly into the `/friendships/{pairId}` doc via a CF trigger (`onUserProfileChanged`). Removes the second hop entirely but adds a fan-out write cost and the stale-name window users complain about.
  Option 1 is the right answer because SEC-USER-SEC-001 forces the public/profile subcollection to exist anyway.
- authority: `apps/mobile/CLAUDE.md §Common gotchas` ("Slow rebuild → `const` constructors, `ref.watch(provider.select(...))`") spirit + CLAUDE.md §LAYER-A "Firestore cost = ranked P1 minimum" + Phase A `SEC-USER-SEC-001` 6-step rollout plan (step 1: denormalize public profile)
- test: `flutter test test/features/friend/data/firebase_friend_repository_test.dart` — seed 10 friendship docs + 10 user docs in `fake_cloud_firestore`, drive `watchFriends`, assert `mockFirestore.collection('users').doc(_)` calls ≤ N on first emit AND 0 on subsequent emits when no profile field changed.
- deps: pair with `SEC-USER-SEC-001` (Phase A) — recommended option 1 only viable after `/users/{uid}/public/profile` migration

### ISSUE FEED-REBUILD-001

- sev: P1
- blocker: no
- area: UI rebuild — wasted side effects in itemBuilder
- files:
  - `apps/mobile/lib/features/feed/presentation/feed_section.dart`
- loc: 68-78
- symbols:
  - `FeedSection.build` → `SliverChildBuilderDelegate.itemBuilder`
- evidence:
  ```dart
  // Trigger prefetch after frame — never call state mutation during build
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(feedControllerProvider(filter: filter, filterUid: filterUid,).notifier)
        .onItemVisible(index);
  });
  ```
  (`feed_section.dart:69-78`) — fires inside `itemBuilder` which Flutter calls on every layout pass for every visible tile, not only when the item enters the viewport.
- cost_model: 5 visible posts × 60 fps = 300 post-frame callbacks/sec while user scrolls. Each callback walks `feedControllerProvider.notifier.onItemVisible(i)` → `state.valueOrNull?.posts ?? []` + index compare + (eventually) `loadMore()` call. `loadMore()` is currently a no-op (`feed_controller.dart:132`) so cost is bounded — but the moment KhoaLND wires real pagination per the TODO at `feed_controller.dart:130`, every scroll frame triggers a Firestore page query.
- risk: today wastes ~300 callback allocations/sec during scroll (minor); after pagination ships becomes a Firestore quota burner. Also schedules work outside the rebuild path so Flutter `dispose()` cannot cancel it cleanly — `_pendingHighlightPostId` style of post-frame callbacks (`home_screen.dart:290`) is the right pattern; this one is the wrong pattern.
- fix: use a `VisibilityDetector` (already a transitive dep via `cached_network_image` extras — verify) or track visible index inside `_HomeScreenState._onPageChanged` (already exists at `home_screen.dart:140-159` and already calls `onItemVisible(index - 1)`). The `_HomeScreenState` path is the single source of truth for "what page is visible"; `feed_section.dart` should NOT compute it independently. Delete lines 69-78. If the SliverList ever runs outside the `PageView` (vd Grid view at `/grid-view`), wire its own visibility detection there.
- authority: `apps/mobile/CLAUDE.md §Common gotchas` ("Future inside `build()` → Use FutureProvider / StreamProvider") spirit; `home_screen.dart:140-159` is the canonical visibility-tracking pattern in the codebase
- test: write `test/features/feed/presentation/feed_section_test.dart` with `pump()` then `pumpAndSettle()` after scroll; assert `mockFeedController.onItemVisibleCallCount` equals number of items entering viewport (not number of frames rendered). Run `flutter test test/features/feed/presentation/`.
- deps: blocked-by ARCH-LAYER-001 (Phase A) — that issue must clean up the same file's `FirebaseAuth.instance` direct call before the test harness can mount this widget at all.

### ISSUE NOTIF-PERF-001

- sev: P1
- blocker: no
- area: Firestore over-fetch — unbounded collection read
- files:
  - `apps/mobile/lib/features/notification/data/firebase_notification_repository.dart`
- loc: 64-76
- symbols:
  - `FirebaseNotificationRepository.getNotifications`
- evidence: `final snap = await _notificationsRef(uid).orderBy('createdAt', descending: true).get();` (`firebase_notification_repository.dart:65-67`) — no `.limit()` clause, no cursor pagination.
- cost_model: notifications persist forever (no TTL). 50-200 posts/user/day → reactions + friend requests + accepted-requests = realistic 5-50 notifications/day. After 6 months → 1000-9000 notif docs per user. Every time the user opens the notification screen → full collection scan + full deserialization to `List<AppNotification>` in memory.
- risk: Firebase cost grows linearly with user tenure (free Spark 50k reads/day exhausted after 5-10 opens for a tenured user); UI freeze on parsing thousands of `AppNotification.fromJson` in the build thread. Pair with `NOTIF-PERF-002` style "no archive policy" — CF triggers write the doc forever, never delete old ones.
- fix:
  1. add `.limit(50)` to the query.
  2. add cursor pagination: change interface signature to `Future<List<AppNotification>> getNotifications(String uid, {String? afterNotifId, int limit = 50})` and resolve cursor via `startAfterDocument(await _firestore.doc(afterNotifId).get())`.
  3. either (a) add CF cleanup function `pruneOldNotifications` (runs daily, deletes notif > 30 days where `read == true`) — keeps server cost bounded; or (b) accept storage growth and rely on client-side pagination.
- authority: `apps/mobile/CLAUDE.md §Common gotchas` ("Slow rebuild") + Firestore docs §Pagination (cursor patterns) + Locket-parity baseline `~50-200 posts/user/day` (CLAUDE.md §LAYER-A)
- test: `flutter test test/features/notification/data/firebase_notification_repository_test.dart` — seed 200 notification docs, call `getNotifications(uid)`, assert returned list size ≤ 50 AND `mockFirestore.collection(...).orderBy(...).limit(50).get` was called.
- deps: none

### ISSUE IMG-PERF-001

- sev: P1
- blocker: no
- area: Image memory pressure — decoded bitmap size mismatch
- files (13 sites — `rg "CachedNetworkImage\(" apps/mobile/lib` returns 13 hits, 0 of them set memCacheWidth):
  - `apps/mobile/lib/features/feed/presentation/grid_photo_tile.dart` (3-col grid, ~120px)
  - `apps/mobile/lib/shared/widgets/post_card.dart` (full-width cover + dual PiP)
  - `apps/mobile/lib/shared/widgets/app_avatar.dart` (28-50px avatar)
  - `apps/mobile/lib/shared/widgets/photo_detail_screen.dart` (350px carousel + 60px thumbnail strip)
  - `apps/mobile/lib/features/profile/presentation/profile_screen.dart` (92px profile avatar)
  - `apps/mobile/lib/features/profile/presentation/friend_profile_screen.dart` (92px friend avatar)
  - `apps/mobile/lib/features/profile/presentation/edit_profile_screen.dart` (72px avatar)
  - `apps/mobile/lib/features/streak/presentation/widgets/calendar_day_cell.dart` (37×35px calendar cell)
  - `apps/mobile/lib/features/chat/presentation/widgets/message_quoted_post.dart` (270×270 quoted thumb)
  - `apps/mobile/lib/features/chat/presentation/widgets/quoted_photo_block.dart` (301×301 quoted block)
  - `apps/mobile/lib/features/feed/presentation/camera_section.dart` (26×26 history button thumbnail)
- loc: `grid_photo_tile.dart:28-34`; `post_card.dart:78-87, 153-170`; `app_avatar.dart:61-79`; `photo_detail_screen.dart:344-350, 562-568`; `profile_screen.dart:282-287`; `friend_profile_screen.dart:354`; `edit_profile_screen.dart:344-351`; `calendar_day_cell.dart:57-64`; `message_quoted_post.dart:44-59`; `quoted_photo_block.dart:43-60`; `camera_section.dart:560-567`
- symbols:
  - `GridPhotoTile.build` / `PostCard._build` / `_NetworkImage.build` (dual) / `AppAvatar.build` / `_PhotoCarousel.build` / `_ThumbnailStrip._thumbImage` / `_ProfileAvatar.build` (×2) / `_AvatarSection.build` / `_CalendarDayCell.build` / `MessageQuotedPost.build` / `QuotedPhotoBlock.build` / `_HistoryButton.build`
- evidence:
  - `grid_photo_tile.dart:28`: `CachedNetworkImage(imageUrl: post.coverImageUrl, fit: BoxFit.cover, placeholder: ..., errorWidget: ...)` — no `memCacheWidth`/`memCacheHeight`/`maxWidthDiskCache`.
  - `calendar_day_cell.dart:57`: same shape, displayed at 37×35px. Worst-case ratio: 4.67 MB decoded into ~5 KB display = 99.9% waste.
  - `photo_detail_screen.dart:562`: thumbnail strip at 36-60px renders full 1080px source.
  - `rg "cacheWidth|memCacheWidth" apps/mobile/lib` returns 0 hits → no image is sized to display dimensions anywhere in the codebase.
- cost_model: post compress target (post_controller.dart:24 `_maxWidthPx = 1080`). 1080×1080 RGBA decoded = 1080×1080×4 bytes = 4.67 MB per bitmap in memory. Worst case = streak calendar 30 days × 1 image each = 140 MB sitting in Flutter `ImageCache` (default cap 100 MB → starts evicting → flash on re-scroll). Grid tile: 30 cached tiles × 4.6 MB waste each = 138 MB. Avatar in 50-friend inbox: 50 × 4.6 MB = 230 MB. On a low-end Android with 2 GB RAM, this triggers `LowMemoryKiller` and the OS drops the app.
- risk: Android crash on low-end devices (Galaxy A-series, Xiaomi Redmi entry-level — both within Meep target user base); jank during grid/feed scroll due to GC pressure; `Image cache` defaults to 100 MB max — Flutter starts dropping cached entries → flash on re-scroll → users feel app is slow.
- fix:
  - `grid_photo_tile.dart:28` — add `memCacheWidth: (MediaQuery.sizeOf(context).width / 3 * MediaQuery.devicePixelRatioOf(context)).round()` (or accept the tile width as a constructor arg and compute from it).
  - `app_avatar.dart:61` — add `memCacheWidth: (inner * MediaQuery.devicePixelRatioOf(context)).round()`.
  - `post_card.dart:78` cover — add `memCacheWidth: (s.width * MediaQuery.devicePixelRatioOf(context)).round()` (full-width display).
  - `_NetworkImage.build` (dual) — similar via `LayoutBuilder.constraints.maxWidth * pxRatio`.
  - Also set `maxWidthDiskCache` to the same to bound disk cache footprint.
- authority: `apps/mobile/CLAUDE.md §Widget-specific` ("NEVER pass huge inline `Map`/`List` as widget props — extract to `static const`") spirit (memory hygiene); Flutter `Image` API doc — `cacheWidth` to bound decoded bitmap size; CachedNetworkImage README → `memCacheWidth` parameter exists for exactly this case.
- test:
  - widget test `test/shared/widgets/app_avatar_test.dart` — render `AppAvatar(imageUrl: 'http://x', size: 40)`, inspect rendered `CachedNetworkImage.memCacheWidth ≈ 40 * 3` (xxhdpi).
  - profile test `test/features/feed/presentation/grid_photo_tile_test.dart` — render in a 360-wide test viewport, assert `memCacheWidth ≈ 120 * pxRatio`.
  - run `flutter test test/shared/widgets/ test/features/feed/presentation/`.
- deps: none

### ISSUE PROFILE-PERF-001

- sev: P1
- blocker: no
- area: Firestore over-fetch — author post history unbounded
- files:
  - `apps/mobile/lib/features/feed/data/firebase_post_repository.dart`
  - `apps/mobile/lib/features/profile/application/profile_posts_provider.dart`
  - `apps/mobile/lib/features/profile/application/friend_posts_provider.dart`
- loc: `firebase_post_repository.dart:279-287` (`getPostsByAuthor`); `profile_posts_provider.dart:19-26`; `friend_posts_provider.dart:23-41`
- symbols:
  - `FirebasePostRepository.getPostsByAuthor`
  - `profilePosts` provider (calls `getPostsByAuthor(uid)`)
  - `friendPosts` provider (calls `getPostsByAuthor(friendUid)` then client-filters audience)
- evidence:
  - `firebase_post_repository.dart:279-287`:
    ```dart
    Future<List<Post>> getPostsByAuthor(String authorId) async {
      final snap = await _db.collection(_posts)
          .where('authorId', isEqualTo: authorId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => Post.fromJson(d.data())).toList();
    }
    ```
    No `.limit()`.
  - `profile_posts_provider.dart:19-21` calls it directly + sorts defensively.
  - `friend_posts_provider.dart:28-29` calls it AND THEN client-filters by `audienceType` + `audienceUids` — meaning the wire payload includes posts the caller can't even render.
- cost_model: power-user posts 100-200/year (Locket parity). After 1 year, 1 profile open = 200 reads + 200 doc parses. After 2 years = 400. Visiting a friend profile pays the same cost AND fetches posts the viewer is not in the audience for (wasted read). For a 50-friend user who scrolls 5 friend profiles per day → 5 × 400 = 2 000 reads/day just for profile browsing.
- risk: same Firebase cost class as FEED-PERF-001 but slower-growing. UX: profile open feels slow on a 4G connection after the post count grows. Friend-profile case is the worse one because the rule-side denormalized index `[authorId, createdAt DESC]` doesn't filter by audience → server sends posts the client can't show.
- fix:
  1. add `.limit(30)` to `getPostsByAuthor` (page 1 default).
  2. extend the abstract `PostRepository` interface with `Future<List<Post>> getPostsByAuthor(String authorId, {DateTime? before, int limit = 30})` and use `startAfter(Timestamp.fromDate(before))` for the next page.
  3. for friend-profile case, **also** push audience filter server-side: query `where('authorId', '==', friendUid)` AND `where('audienceUids', 'array-contains', currentUid)` for `audienceType == 'select'`; or split into two queries (one for `all`, one for `select+contains`) and merge — Firestore doesn't allow OR across `==` + `array-contains` on different fields in a single query. Tradeoff with index count.
  4. add a "Tải thêm" CTA at the bottom of the profile grid wired to `ref.invalidate(profilePostsProvider(uid))` with a higher page index, OR migrate to a `PagedListView` style provider.
- authority: `apps/mobile/CLAUDE.md §Common gotchas` (Slow rebuild via Firestore over-fetch); CLAUDE.md §LAYER-A "Firestore cost = ranked P1 minimum"; Phase A `ARCH-FEED-ARCH-001` already flags the missing pagination contract on `PostRepository` — same root cause, broader fix.
- test:
  - `test/features/feed/data/firebase_post_repository_test.dart` — seed 50 posts for one author, assert `getPostsByAuthor(uid)` returns ≤ 30 AND the query carries `.limit(30)`.
  - `test/features/profile/application/profile_posts_provider_test.dart` — verify default page size + cursor advances correctly.
  - run `flutter test test/features/feed/data/ test/features/profile/application/`.
- deps: depends on `PostRepository` interface change — touches the abstract contract per leader gate (CLAUDE.md §Strict gate "Đổi signature của abstract interface")

### ISSUE WIDGET-PERF-001

- sev: P1
- blocker: no
- area: Battery + user data drain — WorkManager network constraint
- files:
  - `apps/mobile/android/app/src/main/kotlin/dev/meep/meep/WidgetSyncWorker.kt`
- loc: 300-315 (`schedulePeriodic`), 322-334 (`enqueueOneTime`)
- symbols:
  - `WidgetSyncWorker.Companion.schedulePeriodic`
  - `WidgetSyncWorker.Companion.enqueueOneTime`
- evidence:
  - line 301-303: `val constraints = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()`
  - line 323-325 same constraint for one-time work.
  - line 305-306: `PERIODIC_INTERVAL_MINUTES = 15L` minimum WorkManager floor.
  - `loadBitmap` (line 189-204) downloads photo (target 720px) + avatar (target 128px) per tick via Glide HTTP fetch (cache miss path).
- cost_model: 15 min × 24 h = 96 ticks/day. Worst-case (Glide cache miss every tick): 720×720 jpeg ≈ 150-300 KB photo + 128×128 jpeg ≈ 20 KB avatar = 320 KB/tick. 96 ticks × 320 KB = ~30 MB/day per user just for the widget — over mobile data when WiFi unavailable. Battery: 96 wake-ups + Firestore SDK init + Glide thread + RemoteViews IPC = noticeable on devices already on low battery.
- risk: user-data overage charges for users on capped plans (common in Vietnamese capstone target audience); user complaints "app drains pin" without knowing the widget is the culprit; Play Store reviews tank app rating. WorkManager has `setRequiresBatteryNotLow(true)` + `setRequiresDeviceIdle(false)` knobs explicitly for this scenario.
- fix:
  1. change `NetworkType.CONNECTED` → `NetworkType.UNMETERED` (WiFi-only) for the periodic work. Users on mobile data still get the widget refreshed when they open the app via `enqueueOneTime` (`MeepWidget.onUpdate` enqueues it once on system trigger).
  2. add `.setRequiresBatteryNotLow(true)` to both constraint builders — skip ticks when battery < 15%.
  3. for `enqueueOneTime` (user-triggered via app open), keep `NetworkType.CONNECTED` since the user expects immediate refresh.
  4. add a settings toggle `Sync widget on mobile data` (off by default) wired to `notification_preferences.dart` style preferences. Re-enqueue periodic with the chosen NetworkType when toggled.
- authority: Android WorkManager docs §Constraints "Use UNMETERED for image-heavy work"; CLAUDE.md §LAYER-A "Widget native (Kotlin) chạy WorkManager periodic — battery/data cost cao nếu poll quá thường"; spec `docs/specs/2026-05-23-widget-android.md` §Worst path (referenced by WidgetSyncWorker.kt:55 — should also call out the network constraint trade-off).
- test:
  - integration test on a Pixel emulator with metered network simulated — verify the worker does NOT run.
  - unit test `apps/mobile/android/app/src/test/kotlin/dev/meep/meep/WidgetSyncWorkerTest.kt` using `work-testing` artifact (already in inventory map `android_native.test_deps`): seed `TestDriver.setAllConstraintsMet(false)` then assert no execution.
- deps: none

### ISSUE FUNC-PERF-003

- sev: P1
- blocker: no
- area: Cloud Function query schema drift — cleanup query never matches
- files:
  - `firebase/functions/src/friend/onFriendshipDeleted.ts`
- loc: 57-89
- symbols:
  - `onFriendshipDeleted` Step 3 cross-feed cleanup
- evidence:
  ```ts
  // Step 3: Batch delete cross-feed entries (preserve Space posts)
  const uid1FeedQuery = db.collection('users').doc(uid1).collection('feed')
    .where('authorId', '==', uid2)
    .where('spaceId', '==', null);
  const uid2FeedQuery = db.collection('users').doc(uid2).collection('feed')
    .where('authorId', '==', uid1)
    .where('spaceId', '==', null);
  ```
  (`onFriendshipDeleted.ts:57-66`). BUT feed docs are written by `onPostCreated.ts:83-88` as `{postId, authorId, spaceIds: [] as string[], createdAt}` and by `spacePostFanOut.ts:74-79` as `{postId, authorId, spaceIds: FieldValue.arrayUnion(spaceId), createdAt}`. Neither writes a `spaceId` singular field. Same drift documented for streak in `firebase_streak_repository.dart:10-16`: "Post documents không có field `spaceId` (chỉ có `spaceIds` plural) ... query null trên field absent return empty trong production".
- cost_model: query `.where('spaceId', '==', null)` against feed docs that have no `spaceId` field → returns 0 docs in production (fake_cloud_firestore is lenient and may pass tests). Result: every unfriend leaves N stale feed entries per side (where N = friend's post count) forever orphaned in `/users/{uid}/feed/`. Each orphan doc costs 1 read on every subsequent `watchFeed` call. After 1 unfriend with 50 posts: +100 orphans (50 each side). After 10 unfriend cycles over user lifetime: +1000 orphans. Each home feed open then pays +1000 reads even though only 10 are rendered. Compounds with FEED-PERF-001's fan-out cost.
- risk: 3 concrete failure modes:
  1. **Correctness**: unfriended user's posts continue showing in `/users/{uid}/feed/` query — UX bug (privacy boundary leak — same data class as `SEC-USER-SEC-001` but via stale denormalized doc).
  2. **Cost**: orphan feed docs accumulate forever → linear Firestore read growth per user lifetime.
  3. **Server side log noise**: CF runs the batch but `deleteCount` stays 0 → looks like CF succeeded but did nothing.
  Pair concern with `firebase/firestore.indexes.json:19-35` declaring 2 indexes on `posts(authorId, spaceId, createdAt)` (singular `spaceId`) — dead index noted in `no_issue_notes` further confirms `spaceId` was the old field name that got refactored to `spaceIds` plural; the CF was missed in the refactor.
- fix: 2 options:
  1. (minimal correctness fix) change query to filter post-fetch: drop the `.where('spaceId', '==', null)` constraint, fetch all `authorId == uid2` feed docs, then `.filter(d => !(d.data().spaceIds as string[]).length)` in Node before deleting. Cost: 1 extra round-trip if Space posts dominate, but the cleanup actually runs.
  2. (preferred — match Space exclusion semantically) since Space posts already have lifecycle handled by `onSpaceMemberRemoved` (member removal triggers their own feed cleanup), we can delete ALL feed entries authored by the now-ex-friend, including Space posts. The non-friend can still get them re-added on next `spacePostFanOut` if both are in the same Space. Drop `.where('spaceId', '==', null)` entirely:
     ```ts
     const uid1FeedQuery = db.collection('users').doc(uid1).collection('feed')
       .where('authorId', '==', uid2);
     ```
     Simpler + idempotent — re-running unfriend produces correct state. Caveat: if both ex-friends share a Space, the ex-friend's Space posts get briefly removed from uid1's feed until next Space post fan-out re-includes uid1 → spec decision needed.
  3. (additional cleanup) sweep firestore.indexes.json:19-35 of the legacy `(authorId, spaceId, createdAt)` indexes which are no longer queried by anyone.
- authority: `firebase/functions/CLAUDE.md §Firestore data modeling` ("`serverTimestamp()` for `createdAt`/`updatedAt` — **never trust client clocks**") spirit of "the doc shape is the contract"; `firebase_streak_repository.dart:10-16` documents the same trap from the client side; CLAUDE.md §LAYER-A "Firestore cost = ranked P1 minimum"
- test:
  - vitest `firebase/functions/src/friend/onFriendshipDeleted.test.ts` (new): seed user-A feed with `{authorId: B, spaceIds: []}`, delete friendship A-B, assert feed doc is deleted (currently fails because of the bug — that's the regression test).
  - vitest extra case: seed Space post in user-A feed `{authorId: B, spaceIds: ['spaceX']}`, delete friendship, assert behavior matches whichever fix option (1 or 2) is chosen.
  - emulator integration test: setup CF + friendship, unfriend, verify `/users/{uid}/feed` does not contain ex-friend's posts after CF completion.
- deps: none — independent of FEED-PERF-001 fix (different code path) but compounds the cost; should fix in same sprint

### ISSUE IMG-PERF-002

- sev: P2
- blocker: no
- area: Image caching — wrong primitive (Image.network vs CachedNetworkImage)
- files (3 sites — `rg "Image\.network" apps/mobile/lib` returns 3 hits):
  - `apps/mobile/lib/features/profile/presentation/widgets/photo_grid.dart` (profile grid 120px)
  - `apps/mobile/lib/features/diary/presentation/diary_canvas_screen.dart` (mood cover 102px height)
  - `apps/mobile/lib/features/diary/presentation/widgets/polaroid_image_block.dart` (inline polaroid 247×247)
- loc: `photo_grid.dart:55-61`; `diary_canvas_screen.dart:641-649`; `polaroid_image_block.dart:50-56`
- symbols:
  - `_PhotoItem.build` / `_DiaryCanvasScreen._buildMoodZone` / `PolaroidImageBlock.build`
- evidence:
  - `photo_grid.dart:55`: `Image.network(url, fit: BoxFit.cover, errorBuilder: ..., loadingBuilder: ...)`
  - `diary_canvas_screen.dart:641`: `Image.network(coverUrl, fit: BoxFit.contain, errorBuilder: ...)`
  - `polaroid_image_block.dart:50`: `Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: ..., loadingBuilder: ...)`
- cost_model: `Image.network` only does in-memory cache via `ImageCache`. On screen pop + push, cached image survives only if still in the LRU (default 100 MB / 1000 entries). For a 30+ post profile + 5+ diary entries with inline images, navigating away → all images re-downloaded next visit. Storage egress cost on the Firebase project; latency cost for the user. Diary entries can hold up to 5 inline images per entry — multiply the egress.
- risk: inconsistent cache strategy across the app (cached_network_image elsewhere → disk cache survives process restart; here doesn't); friend-profile photo grid + diary read mode feel slower than feed/grid view on re-open. Pure code-consistency issue.
- fix: replace `Image.network(...)` with `CachedNetworkImage(imageUrl: ..., fit: ..., memCacheWidth: ..., placeholder: ..., errorWidget: ...)` matching `grid_photo_tile.dart:28-34`. Also wire `memCacheWidth` per IMG-PERF-001 fix recommendation.
- authority: `apps/mobile/CLAUDE.md §Common gotchas` (consistency); `pubspec.yaml` already has `cached_network_image: ^3.4`; every other grid in the codebase uses it.
- test:
  - widget test `test/features/profile/presentation/widgets/photo_grid_test.dart` — render with 5 urls, assert the rendered widget tree contains `CachedNetworkImage` (not `Image`).
  - widget test `test/features/diary/presentation/widgets/polaroid_image_block_test.dart` — render with URL, assert `CachedNetworkImage` used + `memCacheWidth` set.
  - widget test `test/features/diary/presentation/diary_canvas_screen_test.dart` (or section thereof) — mood cover region renders `CachedNetworkImage`.
- deps: pair with IMG-PERF-001 fix to set memCacheWidth at the same site

### ISSUE PERF-LOG-001

- sev: P2
- blocker: no
- area: Debug logging in hot path — string-interpolation cost in release
- files (9 files — `rg "debugPrint" apps/mobile/lib` returns 57 total):
  - `apps/mobile/lib/features/feed/data/firebase_post_repository.dart` (16)
  - `apps/mobile/lib/features/feed/application/feed_controller.dart` (6)
  - `apps/mobile/lib/features/feed/presentation/home_screen.dart` (4)
  - `apps/mobile/lib/features/feed/presentation/grid_view_screen.dart` (4)
  - `apps/mobile/lib/features/feed/application/feed_filter_controller.dart` (4)
  - `apps/mobile/lib/features/feed/data/image_flip.dart` (14)
  - `apps/mobile/lib/features/feed/application/app_camera_controller.dart` (3)
  - `apps/mobile/lib/features/feed/application/post_controller.dart` (2)
  - `apps/mobile/lib/features/widget/application/widget_data_service.dart` (4)
- loc: per-file
- symbols:
  - 16 `debugPrint` in `firebase_post_repository.dart` (Space feed instrumentation)
  - 14 in `image_flip.dart` (orientation/flip instrumentation — fires on every capture)
  - 6 in `feed_controller.dart` (stream listener callback)
  - 4 each in home_screen / grid_view_screen / feed_filter_controller / widget_data_service
  - 3 in app_camera_controller (capture path)
  - 2 in post_controller (compress path)
- evidence:
  - `rg -c "debugPrint" apps/mobile/lib` returns 57 hits across 9 files.
  - `firebase_post_repository.dart:88-91`: `debugPrint('[Space Feed] _watchSpaceFeed snapshot — caller=$callerUid trả về ${snap.docs.length} doc (raw, chưa filter spaceId)',);` — fires on every snapshot emit (potentially per-friend-listener per change).
  - `feed_controller.dart:93-96`: similar inside the `.listen((posts) { ... debugPrint... })` callback.
  - `image_flip.dart:11-110`: 14 `debugPrint('[ImageOrientation] ...')` interleaved through `fixOrientationInPlace` + `flipImageHorizontallyInPlace`. Fires per capture even in release.
- cost_model: `debugPrint` itself is a no-op in release for the FINAL print call (it routes through `debugPrint` static, which checks `kDebugMode` and `Zone.current[#flutter.trackPrintCalls]`). BUT string interpolation `'... ${snap.docs.length} ... ${spaceId}'` is evaluated BEFORE the function call → release mode still allocates the string + boxed primitives + concatenates, then throws it away. With FEED-PERF-001 listener fan-out (21 streams × 5 emits/sec scroll) → 100+ throwaway string allocs/sec.
- risk: GC pressure during scroll (already low-margin given IMG-PERF-001 bitmap waste); minor perf bug. Not catastrophic. Easy to fix.
- fix: wrap each `debugPrint` site in `if (kDebugMode) debugPrint(...)`. This makes the WHOLE expression dead-code in release, including the interpolation. Or remove the logs entirely once the Space-feed debugging session is finished — these logs are clearly diagnostic per the `[Space Feed]` prefix and `[DEBUG/Space Feed]` comments throughout. CLAUDE.md §Cấm bans "debug logs in production code".
- authority: `apps/mobile/CLAUDE.md §Common gotchas` (slow rebuild — anything in hot path); `firebase/functions/CLAUDE.md §Logging` ("Don't `console.log` in production code") — same spirit for client; `kDebugMode` Flutter idiom.
- test: `rg "debugPrint\(" apps/mobile/lib/features/feed --type dart` should produce 0 hits OR every hit prefixed by `if (kDebugMode)` after fix. Manual: build release APK, run `adb logcat -s flutter | grep "Space Feed"` while scrolling — expect zero output.
- deps: none

### ISSUE PERF-DIARY-001

- sev: P2
- blocker: no
- area: Firestore over-fetch — diary unbounded reads
- files:
  - `apps/mobile/lib/features/diary/data/firebase_diary_repository.dart`
- loc: 73-80 (`watchEntries`), 101-112 (`getPublicEntries`), 115-139 (`searchEntries`)
- symbols:
  - `FirebaseDiaryRepository.watchEntries`
  - `FirebaseDiaryRepository.getPublicEntries`
  - `FirebaseDiaryRepository.searchEntries`
- evidence:
  - `watchEntries` line 74-80: `_col.where('authorUid', isEqualTo: authorUid).orderBy('createdAt', descending: true).snapshots()` — no limit. Streams ALL entries forever.
  - `getPublicEntries` line 103-107: same shape with extra `.where('privacy', isEqualTo: 'public')`, no limit.
  - `searchEntries` line 123-126: pulls ALL author entries then `.where((entry) { … entry.moodCaption.toLowerCase().contains(normalized) … })` client-side.
- cost_model: 1 entry/day baseline → 365 entries/year. After 2 years, watch emits 730 docs on every snapshot change. Search downloads 730 then filters in memory. Free Spark 50k reads/day → 70 search opens/day saturates quota for a 2-year user.
- risk: same cost-growth profile as PROFILE-PERF-001 but on a different module owner. `watchEntries` is a stream → cost paid continuously, not per open. Search functionality scales O(N) on author size, will feel slow on slow devices.
- fix:
  - `watchEntries`: add `.limit(50)`; expose a separate `loadMoreEntries(String authorUid, DateTime before)` for pagination.
  - `getPublicEntries`: add `.limit(30)` (caller is friend-profile diary tab, defer pagination scope).
  - `searchEntries`: this is the hardest one. Firestore does not natively support full-text search. Options: (a) integrate Algolia / Typesense as docs/adr/00XX (out of MVP scope), (b) keep client-side but ENFORCE a server-side cap `.limit(200)` so worst case is bounded, (c) downscope search to title-only (`moodCaption`) and add a Firestore `array-contains` field with prefix-tokens of moodCaption — index-able but adds write cost. Recommend (b) as the minimum bar.
- authority: `apps/mobile/CLAUDE.md §Common gotchas` (Slow rebuild); CLAUDE.md §LAYER-A `Firestore cost = ranked P1 minimum`; Locket-parity baseline does not include diary so no benchmark — apply conservative 50/30 caps.
- test: `flutter test test/features/diary/data/firebase_diary_repository_test.dart` — seed 100 entries, assert `watchEntries(uid).first` returns ≤ 50; assert `searchEntries(uid, q)` issues a `.limit(200)` query.
- deps: none

### ISSUE CHAT-PERF-001

- sev: P2
- blocker: no
- area: ListView constructor — non-builder for unbounded list
- files:
  - `apps/mobile/lib/features/chat/presentation/chat_thread_view.dart`
- loc: 93-113
- symbols:
  - `_ChatThreadViewState.build` → `ListView(children: [...])`
- evidence:
  ```dart
  return ListView(
    controller: _scrollController,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    children: [
      for (var i = 0; i < widget.messages.length; i++) ...[
        if (_showSeparatorBefore(i))
          _TimeSeparator(time: widget.messages[i].createdAt),
        _ThreadMessageRow(...),
      ],
    ],
  );
  ```
  (`chat_thread_view.dart:93-113`) — `ListView` with eager `children` instead of `ListView.builder`.
- cost_model: `MessageLimit.build = 50` default (`chat_providers.dart:35`); `loadMore` += 50. After 3 loadMores → 200 messages × 2 widgets each (separator + bubble) = 400 widget objects materialized eagerly even if only 5 are on screen. Each `_ThreadMessageRow` is a `ConsumerWidget` watching `chatUserProfileProvider(senderId)` (for group) + `chatQuotedPostProvider` — Riverpod subscribes immediately for ALL 200 rows on first build, NOT just visible ones. `chat_providers.dart:83-86` `chatUserProfileProvider` is a `Future` provider → 200 future subscriptions instantiated.
- risk: jank when opening a long thread; Riverpod provider tree bloat; quoted-post `chatQuotedPostProvider` triggers a Firestore `.get()` per unique post regardless of whether the row is on screen (Riverpod dedupes by family arg so the *unique* set bounds it, but a 200-msg thread with 30 distinct quoted posts = 30 reads on open even though user only scrolls 5).
- fix:
  1. swap to `ListView.builder` with `itemCount: widget.messages.length` and an `itemBuilder` that handles separator + row inline.
  2. (optional) only watch `chatQuotedPostProvider` from inside an `if (_isVisible)` guard via `VisibilityDetector` — Phase B perf polish.
  3. add `addAutomaticKeepAlives: false` if Flutter's default keep-alive is keeping rows in memory after they scroll off (`ListView.builder` default is true; can drop for chat).
- authority: `apps/mobile/CLAUDE.md §Widget-specific` ("`ListView.builder` for lists > 5 items. NEVER `ListView(children: [...])` for unbounded lists.") — exactly the rule violated here.
- test: widget test `test/features/chat/presentation/chat_thread_view_test.dart` — pump with 200 fake messages, dispatch a `pumpAndSettle()`, assert no overflow + frame budget; build-only assert that the rendered tree contains `Sliver*BuilderDelegate` (proxy for builder usage).
- deps: none

### ISSUE BOOT-PERF-001

- sev: P2
- blocker: no
- area: App bootstrap latency — first frame blocked on network
- files:
  - `apps/mobile/lib/main.dart`
  - `apps/mobile/lib/features/auth/data/firebase_auth_repository.dart` (via `revalidateSession`)
- loc: `main.dart:52-76`
- symbols:
  - `main`
  - `FirebaseAuthRepository.revalidateSession` (call site `main.dart:74`)
- evidence:
  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (_useEmulator) { ... }
    final prefs = await SharedPreferences.getInstance();
    final authRepo = FirebaseAuthRepository( ... );
    // Đồng bộ cached session với server — phát hiện account đã delete/disable...
    // Network errors swallow để app vẫn launch được offline.
    await authRepo.revalidateSession();
    runApp(ProviderScope( ... ));
  }
  ```
  (`main.dart:52-76`) — `await authRepo.revalidateSession()` blocks `runApp` on a network round-trip to Firebase Auth (`user.reload()`).
- cost_model: Firebase Auth `reload()` default timeout 60s. On a flaky 3G connection the user stares at a blank splash for 5-10s. Cold start to first frame budget per Google Play is < 2s — Meep blows past it on poor networks.
- risk: poor cold-start UX. The comment claims "swallow để app vẫn launch được offline" — true that errors don't crash, but the await still blocks for the network timeout duration before swallowing. Users on slow networks see a black splash. CLAUDE.md §LAYER-A doesn't call this out explicitly, but Locket-class apps treat splash time as a P0 polish item.
- fix:
  1. (recommended) make `revalidateSession()` fire-and-forget by removing the `await`: `unawaited(authRepo.revalidateSession());` — the result triggers a sign-out via the `currentUidProvider` stream once it resolves, NO splash blocking. The orphan-auth check in `MeepApp.build` (`main.dart:184-198`) already handles the "uid valid but profile gone" race window, so dropping the await is safe.
  2. wrap `revalidateSession()` with `.timeout(const Duration(seconds: 2))` if the await must stay for some ordering reason — at least cap the blocking window.
  3. profile with `flutter run --trace-startup` to confirm the reload call is the bottleneck (not Firebase init or SharedPreferences); if Firebase init is comparable, accept the latency.
- authority: Google Play §App vitals (cold start budget); CLAUDE.md §Surgical changes (don't await what doesn't need awaiting); `MeepApp.build:184-198` already handles the race window the await is trying to prevent.
- test: instrument `main` with a timestamp before/after `revalidateSession`; run `flutter run --trace-startup --profile` and confirm reduced "Time to first frame" metric post-fix. Manual: enable airplane mode, launch app — first frame should appear within 2s instead of timing out.
- deps: none

### ISSUE IMG-PERF-003

- sev: P3
- blocker: no
- area: Image pipeline — `Image.file` for dual-camera preview no resampling
- files:
  - `apps/mobile/lib/features/feed/presentation/capture_preview_screen.dart`
  - `apps/mobile/lib/features/feed/presentation/camera_section.dart`
- loc: `capture_preview_screen.dart:743-763`; `camera_section.dart:451-452`
- symbols:
  - `_DualPreviewImage.build` → 2x `Image.file(File(path), fit: BoxFit.cover)`
  - `_DualSlot.build` (camera viewfinder frozen frame)
- evidence: `Image.file(File(primary), fit: BoxFit.cover, width: double.infinity)` (`capture_preview_screen.dart:744-748`) and `Image.file(File(frozenPath!), fit: BoxFit.cover)` (`camera_section.dart:452`) — no `cacheWidth`/`cacheHeight`.
- cost_model: capture writes a full-res photo (1080×1080 after compress, but takePicture before `fixOrientationInPlace` could be 3000×4000+ depending on `ResolutionPreset.high`). PiP secondary slot renders at ~96-128px (`AppProportions.pipSize`). Decoded 4000×4000×4 = 64 MB per preview, half wasted on PiP.
- risk: memory spike on capture screen; potential OOM if user shoots dual rapid-fire on a 2GB Android.
- fix: add `cacheWidth: (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context)).round()` to both `Image.file` sites. For PiP, the cache width should be `(pipSize * pxRatio).round()`. Re-use the `LayoutBuilder.constraints.maxWidth` already in scope.
- authority: Flutter `Image.file` docs §cacheWidth; same pattern as IMG-PERF-001.
- test: widget test that pumps `_DualPreviewImage` in a sized box, asserts the rendered `Image` has `cacheWidth` set; visual check unchanged.
- deps: shares fix surface with IMG-PERF-001 — bundle in one PR

### ISSUE CHAT-PERF-002

- sev: P3
- blocker: no
- area: Scroll animation — keyboard frame storm
- files:
  - `apps/mobile/lib/features/chat/presentation/chat_thread_view.dart`
- loc: 63-66
- symbols:
  - `_ChatThreadViewState.didChangeMetrics`
- evidence:
  ```dart
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }
  ```
  (`chat_thread_view.dart:63-66`) — `didChangeMetrics` fires per-frame while the keyboard slides in/out; each call schedules a fresh 250ms `animateTo` to `maxScrollExtent`.
- cost_model: keyboard slides over ~300ms → ~18 metric callbacks → 18 overlapping `animateTo(...)` calls. Animation curves fight each other; user sees jittery scroll.
- risk: visual jitter on keyboard open/close — purely UX polish, no data cost.
- fix:
  1. debounce `didChangeMetrics` by checking `_scrollController.position.pixels != position.maxScrollExtent` before kicking off a new animation, AND/OR replace `animateTo` with `jumpTo` (no curve = no overlap).
  2. or only schedule on `prev.viewInsets.bottom < next.viewInsets.bottom` transition (keyboard appearing), not every frame.
- authority: Messenger/iMessage pattern uses single jump-on-show; Flutter docs on `WidgetsBindingObserver.didChangeMetrics` warn about frame-rate fires.
- test: integration test (Phase B `06_testing` audit gap-closer) that opens chat + focuses input + asserts only 1 scroll animation completed.
- deps: none

### ISSUE WIDGET-PERF-002

- sev: P3
- blocker: no
- area: Widget native render flash — double render on add
- files:
  - `apps/mobile/android/app/src/main/kotlin/dev/meep/meep/MeepWidget.kt`
- loc: 31-44
- symbols:
  - `MeepWidget.onUpdate`
- evidence:
  ```kotlin
  override fun onUpdate(context, appWidgetManager, appWidgetIds) {
      val data = WidgetDataStore.read(context)
      val views = buildRemoteViews(context, data)
      appWidgetIds.forEach { id -> appWidgetManager.updateAppWidget(id, views) }
      // Kick a one-time background refresh ...
      WidgetSyncWorker.enqueueOneTime(context)
  }
  ```
  (`MeepWidget.kt:31-44`) — first `updateAppWidget` renders the cached caption + default avatar + GONE photo + GONE count; then `WidgetSyncWorker.enqueueOneTime` runs and re-issues `updateAppWidget` with the real photo + count. User sees fast text path → flash → photo appears.
- cost_model: ~1-3 second flash window depending on Glide cache state and network latency. Cache hit on Glide → ~100ms, cache miss → up to BITMAP_LOAD_TIMEOUT_SECONDS = 20s.
- risk: minor visual jank when user first pins the widget or after system periodic. No data/cost concern.
- fix: 2 options:
  1. (preserve fast path) accept the flash for cold cases but skip the second render if the cached `data.imageUrl` equals what the Worker would render — Worker can read prefs first and short-circuit if cached postId matches Worker's fetched postId AND Glide already has bitmaps. Adds a getter to `WidgetDataStore` for last-rendered postId. Cost: more code, less flash.
  2. (degraded fast path) skip the fast text path entirely — render only the placeholder until Worker completes. User sees placeholder for 1-3s but no flash. Simpler.
  Phase B polish — defer unless QA flags.
- authority: spec `docs/specs/2026-05-23-widget-android.md` §Worst path explicitly documents two-phase render; this is the symptom of that contract.
- test: manual on a Pixel emulator — pin widget, observe flash. Hard to automate without screen recording.
- deps: none

### ISSUE FUNC-PERF-001

- sev: P3
- blocker: no
- area: Cloud Function fan-out — sequential per spaceId
- files:
  - `firebase/functions/src/feed/onPostCreated.ts`
  - `firebase/functions/src/space/spacePostFanOut.ts`
- loc: `onPostCreated.ts:56-69`; `spacePostFanOut.ts:31-110`
- symbols:
  - `onPostCreated` (calls `spacePostFanOut` per spaceId via `Promise.all`)
  - `spacePostFanOut` (sequential within one spaceId)
- evidence:
  - `onPostCreated.ts:57-67`: `await Promise.all(spaceIds.map((spaceId) => spacePostFanOut({...})))` — outer parallel: OK.
  - `spacePostFanOut.ts:36-66`: sequential reads — `spaceDoc.get()` (line 36) → `membersSnap.get()` (line 49). 2 round-trips before the batch fan-out.
  - Then `await Promise.all(batches.map((b) => b.commit()))` (line 95) — batches parallel: OK.
  - Then `await Promise.all(recipientUids.map((uid) => sendFcmToUser(...)))` (line 139-141) — FCM parallel: OK.
- cost_model: per Space post: ~200ms (`spaceDoc.get` + `membersSnap.get` sequential, ~100ms each) + fan-out batch (~50ms) + FCM (~200ms). Total ~500ms CF wall time per Space. Multi-Space post → multiplied by spaceIds.length, but the outer Promise.all parallelizes, so end-user latency is the slowest single Space's 500ms. CF invocation cost = 500ms × 1GB memory (default v2) × invocations.
- risk: scope: this is a CF cost concern, not a UX one — post creation feels instant on client (CF runs async). Bills `0.4 × $0.0000025 per 100ms` ≈ negligible at MVP scale. Flag as P3 because the `spaceDoc.get` and `membersSnap.get` could run in parallel for ~100ms savings each (50% wall reduction).
- fix: at `spacePostFanOut.ts:36-49`, run the two gets in parallel:
  ```ts
  const [spaceDoc, membersSnap] = await Promise.all([
    db.collection('spaces').doc(spaceId).get(),
    db.collection('space_members').doc(spaceId).collection('members').get(),
  ]);
  ```
  Then check `spaceDoc.exists` and `spaceData?.deletedAt` afterward. Same semantics, half the latency.
- authority: `firebase/functions/CLAUDE.md §Cloud Functions v2 specifics` ("Cold start: lazy-import expensive packages"); the same parallelism principle from `_fcm.ts:51` lazy-import.
- test: `firebase/functions/src/space/spacePostFanOut.test.ts` (does not exist — would be new file under Phase B `06_testing`). Mock `getFirestore`, assert exactly 2 awaits before the batch loop, not 3.
- deps: none

### ISSUE FUNC-PERF-002

- sev: P3
- blocker: no
- area: Cloud Function globalOpts — timeout + memory defaults
- files:
  - `firebase/functions/src/index.ts`
- loc: 16-20
- symbols:
  - `setGlobalOptions` call
- evidence: `setGlobalOptions({ region: 'asia-southeast1', maxInstances: 10, timeoutSeconds: 60 });` (`index.ts:16-20`) — `timeoutSeconds: 60` applies globally, `memory` not set (defaults to 256MB v2). Some CFs are clearly short (auth checks) but inherit 60s timeout; `onPostCreated` could legitimately need > 60s for a 9-member Space with image processing in future.
- cost_model: GCF v2 charges by CPU-time + memory-time. Setting 60s timeout per default doesn't cost anything UNTIL the function hangs (no hang observed in audit, just the latent risk). `memory: 256MB` default is plenty for current CFs (largest is `spacePostFanOut` doing batched writes — well under 256MB).
- risk: defense-in-depth — a hung CF burns up to 60s of compute at 256MB before timing out and retrying. Setting per-function `timeoutSeconds: 10` for `blockUser`, `deleteAccount`, etc. caps blast radius if any single CF develops a bug.
- fix:
  - keep globalOpts `timeoutSeconds: 60` for triggers (`onPostCreated`, `spacePostFanOut`, `onSpaceMemberAdded`...) that can validly take longer.
  - override per-callable: `export const blockUser = onCall({ timeoutSeconds: 10, memory: '256MiB' }, ...)` — etc. for `createSpace` (10s OK), `updateSpace` (10s), `acceptFriendRequest` (10s), `kickMember`/`leaveSpace`/`transferOwnership` (10s).
  - leave `deleteAccount` at the default 60s since it cascades many collections.
- authority: `firebase/functions/CLAUDE.md §Cloud Functions v2 specifics` ("Set `timeoutSeconds` and `memory` explicitly per function.") — exactly the rule not followed here.
- test: `npm test` (vitest) for each function with the new per-function options compiles; no functional change.
- deps: none

## fix_order

### batch_1_p0

1. **FRIEND-PERF-001** — implement either option 1 (after `SEC-USER-SEC-001` migration) or interim cache; eliminates N+1. Pairs with SEC for one round of client + server refactor.
2. **FEED-PERF-001** — collapse per-author fan-out to single `whereIn`. Foundation for FEED-REBUILD-001 sanity (only 1 listener to reason about). Depends on `ARCH-FEED-ARCH-001` (Phase A) DI cleanup to keep the override pattern intact.

### batch_2_p1

3. **FUNC-PERF-003** — fix `onFriendshipDeleted` cleanup query (drop `.where('spaceId', '==', null)` or filter post-fetch). 1-PR fix; pair with index sweep of dead `(authorId, spaceId, createdAt)` composite indexes.
4. **NOTIF-PERF-001** — `.limit(50)` + cursor pagination on `getNotifications`. 1-line change for the limit; interface change for cursor.
5. **PROFILE-PERF-001** — `.limit(30)` + cursor on `getPostsByAuthor`; pushes audience filter server-side for friend-profile path.
6. **IMG-PERF-001** — wire `memCacheWidth`/`memCacheHeight` in 13 sites (AppAvatar, PostCard, GridPhotoTile, photo_detail carousel/thumb, 3× profile avatars, calendar_day_cell, 2× chat quoted post widgets, camera_section history thumb). Cap decoded bitmap memory.
7. **FEED-REBUILD-001** — delete `addPostFrameCallback` from `feed_section.dart:69-78`; rely on `_HomeScreenState._onPageChanged` as single source of truth.
8. **WIDGET-PERF-001** — `NetworkType.UNMETERED` + `setRequiresBatteryNotLow(true)` for periodic; settings toggle for mobile-data sync.

### batch_3_p2

8. **IMG-PERF-002** — swap `Image.network` → `CachedNetworkImage` in `photo_grid.dart`; wire memCacheWidth.
9. **PERF-LOG-001** — wrap 53 `debugPrint` calls in `if (kDebugMode)` or delete now that Space-feed debugging is concluded.
10. **PERF-DIARY-001** — `.limit(50)` on `watchEntries`, `.limit(30)` on `getPublicEntries`, `.limit(200)` cap on `searchEntries` client filter.
11. **CHAT-PERF-001** — `ListView.builder` swap in `chat_thread_view.dart`; consider `addAutomaticKeepAlives: false`.
12. **BOOT-PERF-001** — drop `await` on `revalidateSession()` (or `.timeout(Duration(seconds: 2))`); rely on orphan-auth-check fallback already in `MeepApp.build`.

### batch_4_p3

13. **IMG-PERF-003** — `cacheWidth` on `Image.file` in capture preview + camera frozen frame. Bundle with IMG-PERF-001 PR.
14. **CHAT-PERF-002** — debounce `didChangeMetrics` `_jumpToBottom`; skip frames where scroll already at max.
15. **WIDGET-PERF-002** — short-circuit second-pass render when cached postId matches Worker's fetched postId.
16. **FUNC-PERF-001** — parallel `spaceDoc.get()` + `membersSnap.get()` in `spacePostFanOut`.
17. **FUNC-PERF-002** — per-function `timeoutSeconds` overrides for short callables.

## test_plan_after_fix

- `FEED-PERF-001`: `flutter test test/features/feed/data/firebase_post_repository_test.dart` — seed 25 posts × 20 authors, assert `.snapshots()` call count ≤ 2 (1 whereIn + 1 arrayContains).
- `FRIEND-PERF-001`: `flutter test test/features/friend/data/firebase_friend_repository_test.dart` — seed 10 friendships + 10 user docs; assert N `/users/{fuid}.get()` ≤ 10 on first emit AND 0 on subsequent emits when no friendship changes.
- `FUNC-PERF-003`: vitest `firebase/functions/src/friend/onFriendshipDeleted.test.ts` — seed user-A feed `{authorId: B, spaceIds: []}`, delete friendship A-B, assert feed doc IS deleted (currently fails). Add Space-post variant to lock chosen fix option behavior.
- `FEED-REBUILD-001`: `flutter test test/features/feed/presentation/feed_section_test.dart` — verify `mockFeedController.onItemVisibleCallCount` matches visible-item-enter events, not frame count. Requires ARCH-LAYER-001 (Phase A) fix first.
- `NOTIF-PERF-001`: `flutter test test/features/notification/data/firebase_notification_repository_test.dart` — seed 200 notif docs, assert `getNotifications(uid)` returns ≤ 50 AND query carries `.limit(50)`.
- `IMG-PERF-001`: `flutter test test/shared/widgets/app_avatar_test.dart test/features/feed/presentation/grid_photo_tile_test.dart` — assert rendered `CachedNetworkImage.memCacheWidth ≈ display_size × pxRatio`.
- `PROFILE-PERF-001`: `flutter test test/features/feed/data/firebase_post_repository_test.dart test/features/profile/application/profile_posts_provider_test.dart` — assert pagination + cursor + audience filter server-side for friend path.
- `WIDGET-PERF-001`: write `apps/mobile/android/app/src/test/kotlin/dev/meep/meep/WidgetSyncWorkerTest.kt` using `work-testing` — `TestDriver.setAllConstraintsMet(false)` then assert no execution; integration on Pixel emulator with metered network simulated.
- `IMG-PERF-002`: `flutter test test/features/profile/presentation/widgets/photo_grid_test.dart` — assert rendered tree contains `CachedNetworkImage`, not `Image`.
- `PERF-LOG-001`: `rg "debugPrint\(" apps/mobile/lib/features/feed --type dart` → 0 ungated hits; manual `adb logcat -s flutter | grep "Space Feed"` on release APK shows 0 output.
- `PERF-DIARY-001`: `flutter test test/features/diary/data/firebase_diary_repository_test.dart` — seed 100 entries, assert `watchEntries(uid).first.length ≤ 50`, `getPublicEntries` returns ≤ 30, `searchEntries` query carries `.limit(200)`.
- `CHAT-PERF-001`: widget test `test/features/chat/presentation/chat_thread_view_test.dart` — pump with 200 messages, assert builder used + no overflow.
- `BOOT-PERF-001`: `flutter run --trace-startup --profile` → assert "Time to first frame" reduced; manual airplane-mode launch — first frame appears within 2s.
- `IMG-PERF-003`: widget test `_DualPreviewImage` in sized box — assert rendered `Image` has `cacheWidth` set.
- `CHAT-PERF-002`: integration test that opens chat + focuses input + asserts exactly 1 scroll animation completed during keyboard open.
- `WIDGET-PERF-002`: manual screen recording — verify no flash when cached postId matches.
- `FUNC-PERF-001`: vitest `firebase/functions/src/space/spacePostFanOut.test.ts` — mock `getFirestore`, assert exactly 2 awaits (the `Promise.all` of get + members) before the batch loop.
- `FUNC-PERF-002`: `npm test` compiles after per-function `timeoutSeconds` overrides; no functional change.

## no_issue_notes

Compact notes for important areas checked with no NEW issue found.

### Covered by Phase A — skipped to avoid duplicates

- **Widget calls `FirebaseAuth.instance.currentUser?.uid` directly** in `feed_section.dart:80` + `home_screen.dart:589` — covered by `ARCH-LAYER-001` (P0). Not re-flagged. Performance angle would be "rebuild prevents `.select()` granularity" — but the layering fix is the prerequisite.
- **Controller calls `FirebaseAuth.instance` / `FirebaseFirestore.instance.collection('posts').doc().id` directly** in `feed_controller.dart:56`, `post_controller.dart:85,107,173` — covered by `ARCH-LAYER-002` (P0). Performance impact (mint of postId outside repo) noted in ARCH issue. Not re-flagged.
- **`postRepositoryProvider` self-constructs `FirebasePostRepository`** instead of stub+override — covered by `ARCH-FEED-ARCH-001` (P1). FEED-PERF-001 fix interacts (must keep refactored watchFeed routed through the same provider). Cited as `deps`.
- **`FirebasePostRepository._getFriendUids` queries `/friendships` directly** instead of via `FriendRepository` — covered by `ARCH-FEED-ARCH-002` (P1). Performance angle: extra `.get()` per home open — but is bounded (1 read) and a side-effect of the architecture issue. Fix piggybacks on ARCH issue.
- **`feed_section.dart` 1031 lines / `home_screen.dart` 630 lines** — covered by `ARCH-ARCH-002` (P1). Rebuild excess is a symptom but the file-size fix is the right intervention.
- **Raw `FirebaseException` thrown from repos** (5 modules) — covered by `ARCH-DATA-ARCH-001` (P1). Performance impact (controllers re-implement error mapping) noted there.
- **App Check not activated** — covered by `SEC-APPCHECK-001` (P0). Quota path open for automated traffic is a SEC concern, not directly a PERF one.
- **`/users/{uid}` read by any authed user** — covered by `SEC-USER-SEC-001` (P0). Pairs with `FRIEND-PERF-001` for the migration step.
- **`getNotifications` reads `/users/{uid}/notifications`** rule allows owner only (no SEC issue); the perf issue is unbounded read — flagged as `NOTIF-PERF-001`.

### Other areas checked, no NEW issue

- **`const` constructor coverage**: spot-checked 22 `shared/widgets/` files + feed/home/inbox/streak/diary screens. Most `EdgeInsets.symmetric(...)`, `Text(...)`, `Icon(...)`, `SizedBox(...)` are already `const`-prefixed. No systematic gap. P3 polish — defer.
- **Riverpod `keepAlive` discipline**: 22 `@Riverpod(keepAlive: true)` sites across the codebase (per Phase A `ARCH` audit). Each is either a repository (correctly kept alive — repos hold no per-user state and avoid re-construction) or a controller spanning route transitions (e.g., `notificationController`, `diaryController`). Profile-posts / friend-posts providers are `autoDispose` (no annotation modifier) — correct for screens that should reload on revisit. Spot-checked all 22 — no waste.
- **Stream subscription leaks**: 24 `StreamSubscription | .listen(` sites across `features/`. Each one I read (notification_controller 3 subs + bannerTimer, friend_controller 3 subs + 3 retry timers, space_controller 1 sub + 1 retry, diary_controller 1 sub, feed_controller via completer, reaction_controller 1 sub) is paired with `ref.onDispose(() => sub.cancel())`. No leak observed. Phase A `01_arch §pass_3_reverify_notes` also confirms this for the same 24 sites.
- **`AnimationController` / `TextEditingController` / `ScrollController` / `FocusNode` disposal**: every `*State.dispose()` reviewed in `_HomeScreenState`, `_CameraSectionState`, `_FriendSheetState`, `_ChatThreadViewState`, `_ComposerSheetState`, `_EmojiBubbleState` calls `.dispose()` on each owned controller. Pattern holds.
- **`MeepApp._bannerOverlay` cleanup**: `MeepApp._MeepAppState.dispose` at `main.dart:163-167` removes `_bannerOverlay` + observer. OK.
- **`FirebaseMessaging.onMessage.listen` registered once**: `NotificationController._fcmInitialized` flag (`notification_controller.dart:62`) gates `initFcm` against re-entry; `resetForLogout` (line 263-278) clears flag for next user. Pattern correct.
- **Firestore composite index coverage**: cross-checked all 9 distinct client query shapes against `firestore.indexes.json`:
  - `/posts (authorId ==, createdAt DESC)` × `limit` — covered by index 1.
  - `/posts (memberIds array-contains, createdAt DESC)` × `limit` — covered by index 2.
  - `/posts (authorId ==, createdAt range, createdAt DESC)` (streak watchUserMonth) — implicit single-field range works without composite.
  - `/friend_requests (receiverId/senderId ==, status ==, createdAt DESC)` — covered by indexes 5+6.
  - `/spaces (memberIds array-contains, createdAt DESC)` — covered by index 7.
  - `/conversations (participantIds array-contains, lastMessageAt DESC)` — covered by index 8.
  - `/diary (authorUid ==, createdAt DESC)` — covered by index 9.
  - `/diary (authorUid ==, privacy ==, createdAt DESC)` — covered by index 10.
  - `/blocks (blockerUid ==)` — single-field, no composite needed.
  - `/users (username ==)` (searchUser) — single-field, no composite needed.
  - `/space_members/{spaceId}/members` snapshot — collection scan on subcollection, no composite needed.
  - `/conversations/{id}/messages (createdAt DESC, limit)` — single-field range, no composite needed.
  All client queries match an existing index or don't need one. No INDEX gap to log.
- **Dead/legacy index**: `firestore.indexes.json:19-35` declares 2 indexes on `posts(authorId ASC, spaceId ASC, createdAt ASC/DESC)`. Schema uses `spaceIds` (plural array). These two indexes match a query that no client issues. Sweep candidate for a separate index-cleanup PR (not a PERF issue per se). Already noted in Phase A `SEC §pass_7_reverify_notes` as "OBSERVATION (note-only, non-security)". Echoed here for cross-audit awareness.
- **`watchUserMonth` (streak)** uses range `where('createdAt', ≥ startOfMonth)` + `where('createdAt', < startOfNextMonth)` + `orderBy('createdAt', desc)` on a query already filtered by `authorId`. Works against the existing `(authorId, createdAt DESC)` composite index. OK.
- **Counter increment idempotency**: `onPostCreated.ts:49-52` uses `FieldValue.increment(1)` — atomic. `onSpaceMemberAdded.ts:30-33` same. `onSpaceMemberAdded` acknowledges its at-least-once trigger limitation (line 14-18 comment); trade-off accepted per Phase A `SEC FUNC-SEC-002`. No new PERF issue.
- **Function batch size**: `onPostCreated.ts:97-103` and `spacePostFanOut.ts:88-93` both cap at 499 ops/batch (Firestore 500 limit + 1 margin). Pattern correct.
- **Cold-start lazy imports**: `_fcm.ts:51` imports `firebase-admin/messaging` inside the handler. `sharp` not used anywhere (no server-side image processing). OK.
- **`saveFcmToken` write frequency**: 1 token = 1 SHA-256 doc-id; `onTokenRefresh` rare (Android FCM token rotates on user-initiated reinstall / data clear). `saveFcmToken` is idempotent for same-device re-login via the SHA-256 doc id. Acceptable.
- **`getOrCreateConversation` race**: line 122-138 of `firebase_conversation_repository.dart` falls back to client-side create if conversation doc missing. Server CF `acceptFriendRequest` normally creates it. Idempotent (set merge equivalent via dot-notation). OK.
- **`chatUserProfileProvider` / `chatSpaceProvider` / `chatQuotedPostProvider` Riverpod dedup**: `chat_providers.dart:83-118` family providers — Riverpod auto-dedupes by family arg, so 200 messages with 30 distinct senders = 30 Firestore reads (not 200). Reasonable for MVP. After CHAT-PERF-001 (ListView.builder), only visible rows watch → fewer providers materialized.
- **`AggregateSource.SERVER` count() in widget worker**: `WidgetSyncWorker.kt:171` uses `AggregateSource.SERVER` for unread count — 1 read per call (counts as 1 read by Firestore billing regardless of result set size). Better than the alternative of fetching all docs. OK.
- **`recordLastViewedAt` write frequency**: `widget_data_service.dart:76-83` writes on every `AppLifecycleState.resumed`. SharedPreferences only — no Firestore. OK.
- **`spacePostFanOut` per-Space FCM fan-out**: members.length ≤ 10 per Space (`createSpace.ts:23` zod schema cap). Worst-case 9 FCM calls per Space post. Trivial scale.
- **`captionType` denorm + caption pre-render**: caption text resolution in `post_controller.dart:52-62` is in-memory; no network calls. OK.
- **`profileControllerProvider`** + `friendControllerProvider` keepAlive — pulls profile/friends stream subs on first watch, holds through route transitions. Correct per `auth.md` Pattern #6 keepAlive guidance.
- **Tier 2 scope drift** (`GroupChatScreen`, `/group-chat/:conversationId`, `space/spacePostFanOut`): out of scope for THIS audit per `scope_filter` — shipped feature beyond MVP commitment but no performance issue introduced. Cross-audit awareness only. Phase A `ARCH no_issue_notes` already records this.
- **`MessageLimit` provider**: `chat_providers.dart:33-38` — auto-disposed family per `conversationId`. Default 50, `loadMore += 50`. Pagination wired correctly.

## postcheck

- git_status_after: `?? docs/audits/04_performance_audit.md` (new file, intended) + `?? tmp/docs/ThienPDM/04-performance-audit` (audit staging, unchanged baseline)
- changed_files_after: `docs/audits/04_performance_audit.md` only
- unexpected_modified_files: none

## self_verification_log

<!-- 4 passes recorded per audit prompt. -->

- pass_1_checklist: N=24 sub-items (across §Audit Checklist 24 bullet groups: UI rebuild excess, const coverage, provider scope, stream leaks, async after dispose, Firestore over-fetch, N+1 fan-out, index coverage, duplicate reads on rebuild, listener fan-out cost, batch/transaction, image pipeline, upload retry/cleanup, bootstrap latency, FCM token, widget Kotlin refresh, background work, function cost, heavy sync work, logs/debug, memory pressure, RepaintBoundary, AutomaticKeepAlive misuse — plus 1 implicit "indexes coverage" cross-check), M=17 issues, K=21 no_issue_notes mappings (each checklist item mapped to ≥ 1 issue OR ≥ 1 explicit note; "RepaintBoundary opportunities" + "AutomaticKeepAlive misuse" mapped to no_issue because grep returned 0 hits in `apps/mobile/lib` AND no scroll-jank symptom flagged elsewhere — accept current state; "batch/transaction" mapped to no_issue with explicit batch cap evidence). gap=0
- pass_2_schema: total=17, missing_field_fixed=0 (every issue has sev/blocker/area/files/loc/symbols/evidence/cost_model/risk/fix/authority/test/deps), severity_demoted=0 (severity calibrated per definitions: FEED-PERF-001 + FRIEND-PERF-001 = catastrophic Firebase cost → P0; FEED-REBUILD-001 + NOTIF-PERF-001 + IMG-PERF-001 + PROFILE-PERF-001 + WIDGET-PERF-001 = significant cost / battery / memory → P1; rest = optimization opportunities → P2/P3), evidence_failed_grep=0 — re-verified 17 evidence quotes against source: `firebase_post_repository.dart:176-187 take(30)` ✓, `firebase_friend_repository.dart:49-52 Future.wait` ✓, `feed_section.dart:69-78 addPostFrameCallback` ✓, `firebase_notification_repository.dart:65-67 no limit` ✓, `grid_photo_tile.dart:28-34 CachedNetworkImage no memCacheWidth` ✓, `firebase_post_repository.dart:279-287 getPostsByAuthor no limit` ✓, `WidgetSyncWorker.kt:301-303 NetworkType.CONNECTED` ✓, `photo_grid.dart:55-61 Image.network` ✓, `firebase_post_repository.dart 53 debugPrint` ✓ via `rg -c`, `firebase_diary_repository.dart:73-80 watchEntries no limit` ✓, `chat_thread_view.dart:93-113 ListView(children)` ✓, `main.dart:74 await revalidateSession` ✓, `capture_preview_screen.dart:744 Image.file no cacheWidth` ✓, `chat_thread_view.dart:63-66 didChangeMetrics` ✓, `MeepWidget.kt:31-44 onUpdate double-render` ✓, `spacePostFanOut.ts:36+49 sequential gets` ✓, `index.ts:16-20 setGlobalOptions no memory` ✓. All evidence grep-able and ≤ 80 chars in quote form.
- pass_3_dedupe: before=17, after=17, consolidations=0 — no two issues share files[0]+symbols+root_cause with same fix:
  - FEED-PERF-001 (perAuthorStreams fan-out in `firebase_post_repository.dart`) vs FRIEND-PERF-001 (watchFriends N+1 in `firebase_friend_repository.dart`) — different files, different N+1 patterns.
  - FEED-PERF-001 vs PROFILE-PERF-001 — both in `firebase_post_repository.dart` but different methods (`watchFeed` vs `getPostsByAuthor`) and different fix shapes (whereIn merge vs limit+cursor).
  - IMG-PERF-001 (memCacheWidth on CachedNetworkImage) vs IMG-PERF-002 (Image.network → CachedNetworkImage) — different anti-patterns; IMG-PERF-002 fix should bundle IMG-PERF-001 wire-up but the diagnoses are independent.
  - IMG-PERF-001 vs IMG-PERF-003 (Image.file no cacheWidth) — different image source primitives; separate issues but fix surface adjacent.
  - PERF-DIARY-001 vs PROFILE-PERF-001 vs NOTIF-PERF-001 — all "no limit on get()" pattern but on different repos with different fix details (page size + audience filter + cursor strategy differ per call site). Logged separately so each module owner can claim.
  - CHAT-PERF-001 (ListView constructor) vs CHAT-PERF-002 (didChangeMetrics scroll storm) — different mechanisms.
- pass_4_coverage: checked=10, partial=0, blocked=1 (`flutter analyze --no-pub` blocked by audit-only constraint per LAYER-B), total=11, verdict=full — every "checked" area backed by file reads enumerated in `commands` table:
  pass_5_deep_scan + pass_6_cross_cutting + pass_7_evidence_reverify + pass_8_antidupe — see notes blocks below.
  - UI rebuild patterns: read feed (4 files), home (1), streak (1), chat (3), inbox (1), diary (2), profile (3) + grep for `Consumer*Widget`/`ref.watch`.
  - Firestore queries client: read all 9 Firebase*Repository implementations + their abstract interfaces.
  - Firestore queries functions: read 6 CF files (onPostCreated, spacePostFanOut, onReactionCreated, createSpace, onSpaceMemberAdded, _fcm) + index.ts.
  - Streams/listeners lifecycle: read 6 controllers (feed/friend/space/notification/diary/reaction) + `ref.onDispose` discipline cross-checked per Phase A's 24-site enumeration.
  - Image pipeline: read post_controller (compress 85→60), image_flip (orientation), image_picker_service (gallery), profile compress (5MB cap, 512px), AppAvatar, PostCard, GridPhotoTile, PhotoGrid, _DualPreviewImage.
  - Functions cost/cold-start: read globalOpts + 6 CF files; verified lazy-import + region + maxInstances + idempotency markers.
  - Widget native (Kotlin) refresh: read WidgetSyncWorker (full 341 lines), WidgetDataStore, MeepWidget.
  - Indexes coverage: read firestore.indexes.json + cross-mapped to 9 distinct client query shapes (enumerated in no_issue_notes).
  - FCM token write frequency: read FirebaseNotificationRepository.saveFcmToken + _fcm.ts.
  - App bootstrap: read main.dart end-to-end (267 lines) + cross-checked with revalidateSession call site comment.

## final_verdict

verdict: not_ready

**Rationale:** 2× P0 (FEED-PERF-001 perAuthor fan-out + FRIEND-PERF-001 watchFriends N+1) cause Firebase quota exhaust at single-digit active-user count on Spark plan — explicit violation of CLAUDE.md §LAYER-A "Firestore cost = ranked P1 minimum". 6× P1 (NOTIF/PROFILE unbounded reads + IMG memory + FEED rebuild + WIDGET battery + FUNC-PERF-003 schema-drift cleanup that leaves orphan feed docs forever) — all real user-impact + cost-growth concerns for Locket-parity MVP. P2/P3 are polish.

**Recommended path:** Fix batch_1_p0 (2 issues) in the same sprint as `ARCH-FEED-ARCH-001` + `SEC-USER-SEC-001` so the data-layer rewrite happens once for perf + arch + sec. Then batch_2_p1 (6 issues, 2-3 days dev). Re-audit after both batches, then ship M3.

Final distribution: **P0=2, P1=6, P2=5, P3=5 — total 18 issues** (pass 5-8 reverify added FUNC-PERF-003 P1 + expanded IMG-PERF-001 from 3→13 sites + IMG-PERF-002 from 1→3 sites + PERF-LOG-001 from 53→57 hits across 9 files).

pass_5_deep_scan_notes (reverify per user request):
- READ FULL: photo_detail_screen, share_modal, share_photo_sheet, profile_screen, friend_profile_screen, edit_profile_screen, notification_banner, space_management_sheet, message_quoted_post, quoted_photo_block, calendar_day_cell, polaroid_image_block, diary_canvas_screen (mood region), onSpaceMemberRemoved.ts, onSpaceDeleted.ts, deleteAccount.ts, leaveSpace.ts, kickMember.ts, transferOwnership.ts, updateSpace.ts, blockUser.ts, acceptFriendRequest.ts, onFriendRequestCreated.ts, onFriendshipDeleted.ts.
- NEW ISSUE FUNC-PERF-003 (P1): `onFriendshipDeleted.ts:60-66` queries `where('spaceId', '==', null)` but feed docs use `spaceIds` (plural). Cross-feed cleanup never matches → orphan feed entries forever. Confirmed by reading `onPostCreated.ts:83-88` feedDoc schema + `spacePostFanOut.ts:74-79` feedDoc schema (both use `spaceIds`, not `spaceId`). Compounds Firestore read cost over user lifetime and leaks unfriended-user posts in feed.
- IMG-PERF-001 file list EXPANDED 3 → 13: `rg "CachedNetworkImage\(" apps/mobile/lib` returns 13 hits; verified each is missing memCacheWidth. Worst-case offender: `calendar_day_cell.dart:57` renders 1080px source into 37×35px cell (99.9% waste).
- IMG-PERF-002 file list EXPANDED 1 → 3: `rg "Image\.network" apps/mobile/lib` returns 3 hits (photo_grid + diary_canvas mood cover + polaroid_image_block).
- PERF-LOG-001 expanded 53 → 57 across 9 files: `widget_data_service.dart` has 4 more debugPrint calls not counted before.
- IMAGE.FILE sites flagged in IMG-PERF-003 confirmed: `camera_section.dart:452` + `capture_preview_screen.dart:197,743,759` — 4 sites, fix bundles with IMG-PERF-001.
- N+1 in `space_management_sheet._loadMemberProfiles` (line 21-36): cap ≤ 10 members per Space + self-documented at line 18-20. Acknowledged, not a new issue. Worth noting that profiles re-fetched per sheet open (no cache) — minor cost.
- No issue from share_modal http.get / share_photo_sheet http.get re-download cost — fires once on user-explicit tap, < 5 MB image, acceptable for MVP.

pass_6_cross_cutting_notes:
- Timer / TextEditingController / ScrollController / FocusNode / AnimationController disposal — re-grep `Timer\(|Timer\.periodic` returns 11 sites; spot-checked login_password_page._cooldownTimer (line 50 cancel), widget_confirm_sheet._autoDismissTimer (line 253 cancel), notification_controller._bannerTimer (line 53 cancel) — all paired with cancel in dispose. No leak.
- setState patterns: `_ComposerSheetState._controller.addListener(() => setState({}))` at feed_section.dart:708 fires on every keystroke — bounded subtree (modal sheet only), acceptable.
- `.select()` discipline: 13 sites use `.select((s) => s.field)` for granular rebuild; rest uses full state. Profile screen could improve with `.select((s) => s.profile)` — minor polish, not flagged.
- collectionGroup usage: 1 site (`onPostDeleted.ts:38 collectionGroup('feed')`) — correct for cross-uid feed cleanup. No client-side collectionGroup → no missing `__name__` index gap.
- Setting state in build: feed_section.dart:69 `addPostFrameCallback` in itemBuilder — already covered by FEED-REBUILD-001.
- jsonDecode/Encode in build: `rg "jsonDecode|jsonEncode" apps/mobile/lib` returns 0 hits — clean.
- FieldValue.increment / runTransaction: `rg "FieldValue.increment|runTransaction|WriteBatch" apps/mobile/lib` returns 0 hits — all write batch + increment lives server-side in CF (correct).

pass_7_evidence_reverify_notes:
- 17 evidence quotes re-grep'd in source on 2026-06-08. All locations confirmed:
  - `feed_section.dart:69` addPostFrameCallback ✓
  - `feed_section.dart:80` FirebaseAuth.instance.currentUser ✓ (noted as ARCH-LAYER-001 cite)
  - `firebase_post_repository.dart:176 perAuthorStreams take(30)` ✓ + `:280 getPostsByAuthor` ✓
  - `firebase_friend_repository.dart:49-51 Future.wait + users get` ✓
  - `firebase_notification_repository.dart:66 orderBy createdAt no limit` ✓
  - `WidgetSyncWorker.kt:302 NetworkType.CONNECTED` ✓
  - `main.dart:74 await revalidateSession` ✓
  - `firebase_diary_repository.dart:73 watchEntries no limit` ✓ + `:101 getPublicEntries no limit` ✓ + `:115 searchEntries client filter` ✓
  - `chat_thread_view.dart:93 ListView(children: [...])` ✓ + `:64 didChangeMetrics jumpToBottom` ✓
  - `post_controller.dart:23 _compressQuality = 85, :25 _maxSizeBytes 1MB, :288 _compress, :298 quality 60 fallback` ✓
  - `onFriendshipDeleted.ts:60 .where('spaceId', '==', null)` ✓ (NEW for FUNC-PERF-003)
  - `onPostCreated.ts:83-86 feedDoc spaceIds plural` ✓ + `spacePostFanOut.ts:74-79 feedDoc spaceIds plural` ✓
- 1 evidence size correction: previously claimed `_perAuthorBuffer = 20` — verified `:156 static const _perAuthorBuffer = 20` ✓.

pass_8_antidupe_recheck_notes:
- Re-walked Phase A `00_inventory_map.md` + `A_PHASE_BASELINE_SUMMARY.md` anti-duplicate map.
- ARCH-001 (Post model misplaced): not a perf concern — skip.
- ARCH-002 (oversized widgets): perf consequence covered as DEPS of FEED-REBUILD-001; not re-flagged.
- ARCH-LAYER-001/002 (Firebase singleton): cited as `deps` of FEED-REBUILD-001 only; my perf issues describe different code paths.
- ARCH-FEED-ARCH-001 (self-construct provider): cited as `deps` of FEED-PERF-001 fix; not re-flagged.
- ARCH-FEED-ARCH-002 (`_getFriendUids` direct query): the same `_getFriendUids` triggers FEED-PERF-001's fan-out cascade — cited as related but the perf fix collapses the fan-out regardless of which repo issues the friend query.
- ARCH-DATA-ARCH-001 (raw FirebaseException): orthogonal to perf — skip.
- SEC-APPCHECK-001 (App Check): noted in no_issue_notes as security concern outside perf scope.
- SEC-USER-SEC-001 (`/users/{uid}` read): cited as `deps` of FRIEND-PERF-001 fix option 1.
- SEC-STORAGE-001/002 (Storage friend boundary): orthogonal to perf — skip.
- No new duplicate detected. All my P0/P1 issues describe code paths/symptoms that Phase A did not cover.


