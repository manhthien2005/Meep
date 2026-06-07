# 02_code_quality_audit

## meta

- repo: Meep
- root: D:/meep-audit-02-cq
- branch: docs/ThienPDM/02-code-quality-audit
- date: 2026-06-07
- mode: audit-only
- audit_focus: code_quality
- modified_files_allowed:
  - docs/audits/02_code_quality_audit.md
- read_baseline:
  - docs/audits/00_inventory_map.md
  - docs/audits/A_PHASE_BASELINE_SUMMARY.md
  - docs/audits/01_architecture_audit.md
  - docs/audits/05_security_firebase_audit.md
  - CLAUDE.md (root)
  - apps/mobile/CLAUDE.md
  - apps/mobile/analysis_options.yaml
  - firebase/functions/tsconfig.json
  - firebase/functions/CLAUDE.md (system-reminder mounted)
  - firebase/CLAUDE.md (system-reminder mounted)
  - .claude/reference-architectures/auth.md

## precheck

- git_status_before: `?? tmp/docs/ThienPDM/02-code-quality-audit` (audit staging dir, expected per inventory map)
- existing_user_changes: no (baseline known — `?? tmp/` matches; fresh worktree so `M apps/mobile/pubspec.lock` absent — cleaner than baseline)
- target_report_preexisting_dirty: no (file did not exist before this run)

## commands

| cmd | status | notes |
|---|---:|---|
| `git rev-parse --show-toplevel` + `git status --short` + `git branch --show-current` | ok | worktree confirmed |
| Read 6 phase-A baseline files | ok | ARCH 20 issues + SEC 22 issues mapped before scan |
| `rg "TODO\|FIXME\|HACK\|XXX"` mobile + functions | ok | 41 TODOs in lib, 2 TODOs in functions; 0 FIXME/HACK/XXX |
| `rg "print\(\|debugPrint\(\|console\.log"` mobile + functions | ok | 57 `debugPrint` lib (9 files); 0 `print`; 1 `console.warn` in `onFriendshipDeleted.ts` |
| `rg "user_id\|friend_id\|friendId"` mobile + functions | ok | 0 hits — anti-terms clean |
| `rg ": any\|<any>\|as any"` functions/src | ok | 0 hits |
| `rg "@ts-ignore\|@ts-expect-error\|eslint-disable"` functions/src | ok | 0 hits |
| `rg "ignore:\|ignore_for_file"` lib + test | ok | 8 lib + 5 test — all with inline reason |
| `rg "Color\(0x"` lib | ok | 39 files (24 in features/, 5 shared/, 2 dev/core, etc.) |
| `rg "TextStyle\(fontSize:"` lib | ok | 14 files |
| `rg "Future\.delayed\|Future<void>\.delayed"` lib | ok | 4 hits — feed_section, friend_sheet, signup_username, reset_password |
| `find lib -name "*.dart" \| wc -l` largest | ok | 30 files >300 lines (ARCH-002 covers 20) |
| `find test -name "*.dart" \| wc -l` | ok | 80 test files |
| `rg "class TimestampConverter"` lib | ok | 12 copies (1 per data model file) |
| `rg "collection\('users'\|...'posts'..."` lib + functions/src | ok | 16 hits mobile (across 5 repos) + 46 functions (13 files) — no central const |
| `rg "verify\(\|verifyNever\("` test | ok | 70 hits in 11 files — manual spot-check confirms paired with state assertions, not tautology |
| Anti-duplicate map review (PHASE_A_BASELINE §Anti-duplicate map) | ok | 42 issues mapped; CQ scan flagged 2 candidates that ARCH/SEC already cover → moved to `no_issue_notes` |
| `flutter analyze --no-pub` | blocked | audit-only — prompt forbids running mutating commands; static evidence sufficient |
| `npm run lint` functions | blocked | same reason |

## coverage

- core/config/: checked — `app_config.dart` read (28 lines); `_prodUrl` TODO noted (covered ARCH-DEEPLINK-001)
- core/error/: checked — `app_error.dart` baseline used; sealed family complete per Pattern #3
- core/router/: checked — covered by ARCH-001/ROUTER-001/DEV-001 — no new CQ smell beyond those
- core/theme/: partial — `hex_color.dart` duplicate covered ARCH-CORE-001
- core/utils/: checked — `pair_id.dart` + `hex_color.dart` confirmed
- core/validators/: partial — `auth_validators.dart` listed only (tested per inventory map)
- features/auth: checked — `firebase_auth_repository.dart`, `auth_providers.dart`, `signup_username_page.dart`, `reset_password_page.dart` read; canonical reference
- features/chat: checked — `firebase_conversation_repository.dart`, `conversation.dart`, `message.dart`, `chat_controller.dart` head, `mark_as_read_listener_test.dart` head read
- features/diary: checked — `firebase_diary_repository.dart` (368 lines), `diary_entry.dart`, `diary_controller.dart` head+save block read; `diary_canvas_screen.dart` head + lines 350-456 read
- features/feed: checked — `firebase_post_repository.dart` full (296 lines), `feed_controller.dart` full (167), `post_controller.dart` full (313), `feed_filter_controller.dart` full (86), `caption_service_impl.dart` full (130), `feed_state.dart` full (17), `post.dart` full (68), `feed_section.dart` lines 350-385 read
- features/friend: checked — `firebase_friend_repository.dart`, `firebase_friend_request_repository.dart`, `friend_request.dart`, `friendship.dart`, `friend_sheet.dart` head read
- features/home: checked — `home_page.dart` read (skeleton, covered ARCH-HOME-ARCH-001)
- features/notification: checked — `firebase_notification_repository.dart` (101 lines), `app_notification.dart`, `notification_controller.dart` head read
- features/profile: checked — `profile_screen.dart` full (407 lines), `edit_profile_screen.dart` lines 449-528 read (8 TODOs)
- features/reaction: checked — `reaction_controller.dart` (161 lines), `firebase_reaction_repository.dart` (58 lines), `reaction.dart`, `reaction_list_sheet.dart` head read
- features/settings: checked — `settings_controller.dart` (170 lines), `space_quick_row.dart` (263 lines) read
- features/space: checked — `firebase_space_repository.dart`, `space_controller.dart`, `space.dart`, `space_member.dart` read
- features/streak: partial — Glob listed; `streak_repository.dart` skim covered ARCH-001
- features/widget: checked — `widget_data_service.dart` (145 lines) read
- shared/widgets: partial — Glob listed all 22; `post_card.dart` covered SHARED-001; 5 widgets read for hex color sampling
- test/: checked — file inventory (80 files), 11 verify-using files spot-checked; 0 `expect(true, true)`; 5 `// ignore: close_sinks` documented inline
- firebase/functions/src: checked — all 21 non-test `.ts` files read (index, _fcm, _helpers, settings/blockUser, settings/deleteAccount, friend/acceptFriendRequest, friend/onFriendshipDeleted, feed/onPostCreated, feed/onPostDeleted, chat/onMessageCreated, notification/onFriendRequestCreated, notification/onFriendRequestAccepted, notification/onReactionCreated, space/createSpace, space/updateSpace, space/kickMember, space/leaveSpace, space/transferOwnership, space/onSpaceDeleted, space/onSpaceMemberAdded, space/onSpaceMemberRemoved, space/spacePostFanOut)
- firebase/functions/test: partial — file list known; not deep-read (covered by SEC TESTING-SEC-001)
- pubspec.yaml + tsconfig.json + analysis_options.yaml: checked — full read

## blockers_summary

Only P0/P1. CQ found **0 P0** + **2 P1** (none release-blockers in code quality dimension; ARCH/SEC already cover all P0s).

| id | sev | area | files | short |
|---|---|---|---|---|
| CQ-001 | P1 | Production noise — Dart logging | `apps/mobile/lib/features/{feed,widget}/**` (9 files) | `debugPrint` 57 occurrences ships in release; throttles output but still logs to logcat — `apps/mobile/CLAUDE.md` "no logs in production code" spirit + analysis_options.yaml `avoid_print: true` lints `print` but not `debugPrint` (Dart gotcha) |
| CQ-002 | P1 | Duplicate logic — `TimestampConverter` | 12 data files in 12 modules (`auth/data/user_profile.dart`, `chat/data/{message,conversation}.dart`, `diary/data/diary_entry.dart`, `feed/data/post.dart`, `friend/data/{friend_request,friendship}.dart`, `notification/data/app_notification.dart`, `reaction/data/reaction.dart`, `settings/data/block.dart`, `space/data/{space,space_member}.dart`) | Same `class TimestampConverter implements JsonConverter<DateTime, Object>` body duplicated 12x; small drift (Object vs Object?) introduces subtle bugs (post.dart strict Object → freeze if Firestore returns null) |
| CQ-014 | P1 | Duplicate logic — `_mapXxxException` helpers across repos | `block/space` (`_mapFunctionsException` byte-for-byte), `conversation/block` (`_mapFirestoreException` byte-for-byte), `diary/profile/streak` (`_mapFirestoreError` near-identical) — 7 repo files | 5 repos copy-paste the same generic Firestore/Functions/Storage error mapping switch with VN action verb. Drift bug if new error code added to one but not others. Blocks ARCH-DATA-ARCH-001 wave (else 5 new repos re-duplicate this boilerplate) |

## issues

### ISSUE CQ-001

- sev: P1
- blocker: no
- area: Logging hygiene — Dart production noise
- files:
  - `apps/mobile/lib/features/feed/data/firebase_post_repository.dart`
  - `apps/mobile/lib/features/feed/data/image_flip.dart`
  - `apps/mobile/lib/features/feed/application/feed_controller.dart`
  - `apps/mobile/lib/features/feed/application/feed_filter_controller.dart`
  - `apps/mobile/lib/features/feed/application/post_controller.dart`
  - `apps/mobile/lib/features/feed/application/app_camera_controller.dart`
  - `apps/mobile/lib/features/feed/presentation/home_screen.dart`
  - `apps/mobile/lib/features/feed/presentation/grid_view_screen.dart`
  - `apps/mobile/lib/features/widget/application/widget_data_service.dart`
- loc: file-level — 57 `debugPrint(` occurrences in lib/ (16 trong `firebase_post_repository.dart`, 14 trong `image_flip.dart`, 6 trong `feed_controller.dart`, 4 trong `feed_filter_controller.dart`, 4 trong `home_screen.dart`, 4 trong `grid_view_screen.dart`, 4 trong `widget_data_service.dart`, 3 trong `app_camera_controller.dart`, 2 trong `post_controller.dart`)
- symbols:
  - `FirebasePostRepository.watchFeed/_watchSpaceFeed/_watchFriendsFeed` — 16 `debugPrint` cho diagnostic
  - `image_flip.fixOrientation/flipHorizontal` — 14 `debugPrint` step-by-step trace
  - `FeedController.build/_updateWidget` — 6 `debugPrint`
  - `FeedFilterController.selectAll/selectAuthor/selectSpace/seedFromRoute` — 4 `debugPrint`
  - `WidgetDataService.requestPinAppWidget/_safePoke` — 4 `debugPrint`
- evidence:
  - `firebase_post_repository.dart:40` `debugPrint('[Space Feed] watchFeed bắt đầu — uid=$uid, spaceId=${spaceId ?? "<null/feed chung>"}');` — repeated 16x in same file with `[Space Feed]` prefix tag
  - `feed_filter_controller.dart:52` `debugPrint('[Space Feed] FilterController.selectAll() — reset về "Mọi người"');`
  - `image_flip.dart:11` `debugPrint('$_tag fixOrientation START');` — START/STEP/DONE/FAILED trace
  - `analysis_options.yaml:30` `avoid_print: true` enables lint for `print()` but **not** `debugPrint()` — `debugPrint` is from `package:flutter/foundation.dart` and runs in BOTH debug AND release builds (per Flutter API doc; release just truncates >800B per line)
- risk:
  - **Performance:** every feed snapshot emit triggers 5-8 `debugPrint` calls trong `firebase_post_repository.dart` — `logcat` flood + string interpolation overhead on hot stream path (feed updates ~1x/sec when user scrolls). `_watchSpaceFeed` builds full-message logs even khi success path (lines 76-91 + lines 96-105).
  - **PII risk:** logs include uid (`firebase_post_repository.dart:40,75-80` log `callerUid` + friend uid count), Space name + ID. `CLAUDE.md §PII handling` says "Never log PII. Log IDs only." — uid is IDs OK, nhưng `feed_filter_controller.dart:70` cũng log `name="${space.name}"` (Space name có thể là PII nếu chứa real name).
  - **Maintenance:** 57 callsites mean any debugPrint format change requires 57 edits. Should be `developer.log` (filterable by name) or short `_log()` helper với `kDebugMode` gate (post_controller.dart:272-281 đã có pattern này — chỉ apply cho 1 controller).
  - **Architecture leak:** `firebase_post_repository.dart` `[Space Feed]` debug tag is symptom của ARCH-LAYER-002 (controller logic leaked vào repository) — debug log noise tăng theo bug history thay vì giảm.
- fix:
  1. Extract `_log()` helper với `kDebugMode` gate (mirror `post_controller.dart:272-281`):
     ```dart
     // core/utils/debug_log.dart
     void debugLog(String tag, String message, [Object? extra]) {
       if (!kDebugMode) return;
       developer.log(message, name: tag, error: extra is Exception ? extra : null);
     }
     ```
  2. `firebase_post_repository.dart`: thay 16 `debugPrint('[Space Feed] ...')` bằng `debugLog('feed', ...)` — `developer.log(name: 'feed')` filterable trong DevTools.
  3. `image_flip.dart`: delete 14 STEP/DONE/START traces sau khi feature ổn định (commit lịch sử để recover nếu cần debug lần sau). Giữ FAILED branch only.
  4. `feed_filter_controller.dart`: 4 selectXxx() logs xóa hết — controller logic clean enough, log không value cho prod.
  5. `widget_data_service.dart`: 4 `_safePoke` failure logs giữ vì exception trace cần thiết — chuyển sang `developer.log(name: 'widget', error: e)`.
  6. **Lint config:** thêm vào `apps/mobile/analysis_options.yaml linter.rules`: `avoid_debug_print: true` (Flutter SDK ≥ 3.7 hỗ trợ). Sau fix, lint sẽ fail PR có `debugPrint` mới.
- authority:
  - `apps/mobile/CLAUDE.md §Common gotchas` (spirit — "Slow rebuild" mentions string interpolation perf)
  - `CLAUDE.md §Security Guardrails — PII handling` "Never log PII. Log IDs only."
  - Flutter SDK doc: `debugPrint` runs in release (just throttles to avoid Logcat throttling)
  - `firebase/functions/CLAUDE.md §Logging` "Don't `console.log` in production code; use `pino` or Cloud Functions' built-in `logger`. Never log PII." — Dart parity
- test:
  - After refactor: `rg -n "debugPrint\(" apps/mobile/lib --glob '!*.g.dart'` should return ≤ 5 hits (only legit error-trace sites in repos).
  - Add `avoid_debug_print` linter rule + run `flutter analyze --no-pub` → 0 warnings.
  - Manual: `flutter run --release` then `adb logcat | grep '\[Space Feed\]'` → 0 hits.
- deps: blocked-by ARCH-LAYER-002 (fixing layering will naturally drop the per-line diagnostic logs); related to ARCH-DATA-ARCH-001 (repo error mapping reduces need for failure logs)

### ISSUE CQ-002

- sev: P1
- blocker: no
- area: Duplicate logic — `TimestampConverter` 12-copy duplication
- files:
  - `apps/mobile/lib/features/auth/data/user_profile.dart:40-52`
  - `apps/mobile/lib/features/chat/data/conversation.dart:47-59` (+ `TimestampMapConverter:65-90` reuses same `_parseDate` pattern)
  - `apps/mobile/lib/features/chat/data/message.dart:35-47`
  - `apps/mobile/lib/features/diary/data/diary_entry.dart:37-49`
  - `apps/mobile/lib/features/feed/data/post.dart:55-67`
  - `apps/mobile/lib/features/friend/data/friend_request.dart:29-42`
  - `apps/mobile/lib/features/friend/data/friendship.dart:26-39`
  - `apps/mobile/lib/features/notification/data/app_notification.dart:27-39`
  - `apps/mobile/lib/features/reaction/data/reaction.dart:27-39`
  - `apps/mobile/lib/features/settings/data/block.dart:21-33`
  - `apps/mobile/lib/features/space/data/space.dart:36-48`
  - `apps/mobile/lib/features/space/data/space_member.dart:21-33`
- loc: 12 class declarations, each 13-16 lines, IDENTICAL body modulo `JsonConverter<DateTime, Object>` vs `<DateTime, Object?>` (nullable variant)
- symbols:
  - 12x `class TimestampConverter implements JsonConverter<DateTime, Object?>` (chat/diary/feed/notification/reaction/settings/space/auth) — uses non-nullable `Object` for fromJson input
  - 2x `class TimestampConverter implements JsonConverter<DateTime, Object?>` (friend/friend_request, friend/friendship) — uses nullable `Object?` because serverTimestamp pending → null tolerance
- evidence:
  - Bodies identical except null-tolerance branch:
    ```dart
    // post.dart, message.dart, conversation.dart, etc. (10 copies — strict Object)
    DateTime fromJson(Object json) {
      if (json is Timestamp) return json.toDate();
      if (json is String) return DateTime.parse(json);
      return DateTime.fromMillisecondsSinceEpoch(json as int);
    }

    // friend_request.dart, friendship.dart (2 copies — nullable Object?)
    DateTime fromJson(Object? json) {
      if (json == null) return DateTime.now();        // ← only difference
      if (json is Timestamp) return json.toDate();
      if (json is String) return DateTime.parse(json);
      return DateTime.fromMillisecondsSinceEpoch(json as int);
    }
    ```
  - 12 × `Object toJson(DateTime date) => Timestamp.fromDate(date);` identical
  - `chat/data/conversation.dart:85-89` has a SECOND identical body inside `TimestampMapConverter._parseDate` (13th copy in 13th location, private static)
- risk:
  - **Subtle bug — null tolerance drift.** 10 copies reject null inputs (`Object` non-nullable), 2 copies accept null. The strict copies WILL crash with `as int` cast failure when Firestore serverTimestamp pending emit returns null. Currently mitigated by `@JsonKey(includeIfNull: false)` or by callers always passing Timestamp/String, BUT any data model with `serverTimestamp()` write (`Post.createdAt` set via `FieldValue.serverTimestamp()` in `firebase_post_repository.dart:30`) is theoretically vulnerable to fake_cloud_firestore behavior or offline emit. The `friend_request.dart:27-28` comment explicitly documents the null-tolerance reason — same reason applies to every other model but wasn't propagated.
  - **Maintenance:** any future timezone fix / Firestore SDK change requires 12 edits. Inconsistent test coverage — `user_profile_test.dart` tests fromJson roundtrip, but the other 11 models don't all have parallel tests.
  - **Code volume:** 12 × ~13 lines = 156 lines of trivial boilerplate cross-module. Onboarding cost — new owner of a future module copies the strict variant from `post.dart` and re-introduces the null bug.
- fix:
  - Extract to `apps/mobile/lib/core/utils/timestamp_converter.dart`:
    ```dart
    import 'package:cloud_firestore/cloud_firestore.dart';
    import 'package:freezed_annotation/freezed_annotation.dart';

    /// Single canonical Timestamp ↔ DateTime converter for all freezed models.
    /// Null-tolerant for pending serverTimestamp (Firestore emits null between
    /// client write and server confirm, ~0.3-0.5s window).
    class TimestampConverter implements JsonConverter<DateTime, Object?> {
      const TimestampConverter();

      @override
      DateTime fromJson(Object? json) {
        if (json == null) return DateTime.now();
        if (json is Timestamp) return json.toDate();
        if (json is String) return DateTime.parse(json);
        return DateTime.fromMillisecondsSinceEpoch(json as int);
      }

      @override
      Object toJson(DateTime date) => Timestamp.fromDate(date);
    }
    ```
  - Delete 12 local class declarations; update each data file's import to `package:meep/core/utils/timestamp_converter.dart`.
  - `chat/data/conversation.dart TimestampMapConverter._parseDate` (line 85-89): reuse `const TimestampConverter().fromJson(value)` instead of inline duplication.
  - Run `dart run build_runner build --delete-conflicting-outputs` — generated `.g.dart` files re-emit with new converter import.
  - **Order of operations:** do this AFTER ARCH-001 (Post move) if Post is being relocated, to avoid double-edit. If ARCH-001 deferred, this is independent.
- authority:
  - `CLAUDE.md §Surgical changes` "Mỗi line code mới phải trace được về yêu cầu. Nếu không trace được → bỏ." — 156 duplicate lines do not trace anywhere
  - `auth.md` Pattern #1 + Pattern #11 (Folder/file naming) — `core/utils/` is the canonical home for converters
  - `apps/mobile/CLAUDE.md §Data classes — freezed + json_serializable` "Convert `DocumentSnapshot` → model in a `fromFirestore(snap)` factory" — single converter is the natural place
- test:
  - Add `test/core/utils/timestamp_converter_test.dart` covering 4 cases: Timestamp roundtrip, String parse, int millis parse, null → now() fallback.
  - After refactor: `rg -n "class TimestampConverter" apps/mobile/lib --glob '!*.g.dart'` returns exactly 1 hit (the new core file).
  - `flutter test test/` full suite must pass — `.fromJson` codegen consumers should typecheck without change.
- deps: none (independent; light-touch if ARCH-001 deferred, otherwise bundle with Post move)

### ISSUE CQ-003

- sev: P2
- blocker: no
- area: Magic strings — hardcoded hex `Color()` in widgets
- files (39 files total, top offenders by usage count):
  - `apps/mobile/lib/features/profile/presentation/profile_screen.dart` (4 `Color(0xFF...)`)
  - `apps/mobile/lib/features/profile/presentation/edit_profile_screen.dart` (4)
  - `apps/mobile/lib/features/profile/presentation/avatar_picker_sheet.dart` (3)
  - `apps/mobile/lib/features/profile/presentation/friend_profile_screen.dart` (5)
  - `apps/mobile/lib/features/feed/presentation/home_screen.dart` (3)
  - `apps/mobile/lib/features/feed/presentation/feed_section.dart` (1)
  - `apps/mobile/lib/features/space/presentation/space_edit_sheet.dart`
  - `apps/mobile/lib/features/space/presentation/widgets/{friend_select_step,icon_builder_step,space_color_overlay,space_config_step}.dart`
  - `apps/mobile/lib/features/streak/presentation/{streak_screen.dart,widgets/{calendar_day_cell,empty_state_overlay,streak_calendar,streak_stats_pill}.dart}`
  - 24+ more
- loc: file-level — see counts; `profile_screen.dart:22-25` shows the canonical anti-pattern (block of file-level const `_cBg`/`_cButtonFill`/`_cButtonText`/`_cAvatarRing` with comment `// Missing design tokens — ping leader để add vào core/theme/`)
- symbols:
  - File-level `_cXxx` constants in 17 files (e.g. `profile_screen.dart:22 const _cBg = Color(0xFF050F10);`)
  - Inline `Color(0xFF...)` in `Container.decoration` / `TextStyle.color` (e.g. `profile_screen.dart:390 color: _cButtonFill, // TODO: AppColors.actionButtonFill`)
- evidence:
  - `profile_screen.dart:17-25`:
    ```dart
    // ─── Missing design tokens — ping leader để add vào core/theme/ ───────────
    // #0D0804 → profileBackground  (bw900=#050F10 là gần nhất)
    // #363636 → actionButtonFill
    // #DDDDDD → actionButtonText
    // #D9D9D9 → avatarRingIdle
    const _cBg = Color(0xFF050F10); // Black & White/900
    const _cButtonFill = Color(0xFF363636);
    const _cButtonText = Color(0xFFDDDDDD);
    const _cAvatarRing = Color(0xFFD9D9D9);
    ```
  - `profile_screen.dart:390-397` shows TODO acknowledging the leak: `color: _cButtonFill, // TODO: AppColors.actionButtonFill`
  - `widgets/profile_tab_bar.dart:5` `const _cInactiveIcon = Color(0xFF949494); // TODO: add AppColors.tabIconInactive`
- risk:
  - **Theme inconsistency:** `apps/mobile/CLAUDE.md §Design tokens — NO hardcoding` explicitly forbids `Color(0xFF1A73E8)` and says "Figma has new color/font not in theme → **add to `core/theme/` first via leader-gated PR**." 17 files file-level + 20+ inline = 37+ violations across 39 files. Leader (ThienPDM) likely unaware of cumulative breach.
  - **Dark mode break:** Hardcoded values bypass `Theme.of(context).colorScheme.x` so app dark theme transition (T9 stretch) will require touching all 39 files.
  - **Color drift:** Same intended color (`#363636` actionButtonFill) might be re-typed as `#363535` or `#373737` by another dev — leak grows.
  - **Lower than P1 because:** comments explicitly flag the leak (devs already know), MVP ships fine cosmetically. Polish concern.
- fix:
  1. Audit core/theme/app_colors.dart — what tokens already exist (`bw100..bw900`, `turquoise500`)?
  2. For each file with `_cXxx` block, propose token name (e.g. `_cButtonFill` → `AppColors.actionFill`) and add to `core/theme/app_colors.dart` via leader-gated PR (CLAUDE.md §Design tokens prerequisite).
  3. Replace inline `Color(0xFF...)` with `Theme.of(context).colorScheme.x` or `AppColors.x`.
  4. Add lint via custom_lint (currently disabled per `analysis_options.yaml:44-48` comment about freezed v2 clash) — when re-enabled, add `prefer_themed_color` custom rule.
  5. **DO NOT** add new tokens without leader review — module owner can't touch `core/theme/` per `apps/mobile/CLAUDE.md §Solo-dev module scope`.
- authority:
  - `apps/mobile/CLAUDE.md §Design tokens — NO hardcoding` (explicit ban) — section text: "Hardcoded color `Color(0xFF1A73E8)` → use `Theme.of(context).colorScheme.primary`."
  - `apps/mobile/CLAUDE.md §Solo-dev module scope` — `core/theme/` is leader-gated
  - Self-comment `profile_screen.dart:17 // Missing design tokens — ping leader để add vào core/theme/`
- test:
  - After fix: `rg "Color\(0x" apps/mobile/lib --glob '!core/theme/**' --glob '!*.g.dart'` returns ≤ 5 hits (only legit module-private colors).
  - Widget tests for affected screens should pass without theme override changes.
  - Manual: dark theme MVP3 transition test (when T9 ships) — verify no hardcoded color leaks remain.
- deps: blocks T9 (dark mode); no hard dependency on ARCH/SEC fixes

### ISSUE CQ-004

- sev: P2
- blocker: no
- area: Magic strings — hardcoded `TextStyle(fontSize:)` ignoring `Theme.of(context).textTheme`
- files (14 files):
  - `apps/mobile/lib/features/feed/presentation/{caption_preset_modal,capture_preview_screen,feed_filter_dropdown,feed_section}.dart`
  - `apps/mobile/lib/features/home/presentation/home_page.dart`
  - `apps/mobile/lib/features/reaction/presentation/{emoji_picker_sheet,reaction_list_sheet}.dart`
  - `apps/mobile/lib/features/space/presentation/{space_edit_sheet,widgets/{icon_builder_step,space_config_step,space_context_badge,space_list_tile}}.dart`
  - `apps/mobile/lib/features/settings/presentation/widgets/space_quick_row.dart`
  - `apps/mobile/lib/features/chat/presentation/widgets/chat_input_bar.dart`
- loc: file-level — search returns 14 hits matching `TextStyle(fontSize:`
- symbols: various `Text(... style: TextStyle(fontSize: <px>))` and inline declarations
- evidence:
  - `space_quick_row.dart:126` `child: Text(space.iconEmoji, style: const TextStyle(fontSize: 22),)` — should use `AppTextStyles.xs/sm/.../baseSemiBold.copyWith(fontSize: 22)` or add token.
  - `edit_profile_screen.dart:450-456`:
    ```dart
    style: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 24 / 18,
      color: _cSectionLabel,
    ),
    ```
  - `edit_profile_screen.dart:516-522` repeats fontSize 12 + Nunito family + w400 inline — should be `AppTextStyles.xsRegular` (assume token exists per other files importing it).
- risk:
  - **Theme drift:** `core/theme/app_text_styles.dart` defines `AppTextStyles.xsRegular/.../baseSemiBold` (confirmed used in `profile_screen.dart:113,121`, `space_quick_row.dart:51`) but 14 files bypass it. Font scaling (a11y) breaks for these — `apps/mobile/CLAUDE.md §Accessibility` "NEVER `fixedFontSize` on `Text`".
  - **a11y break:** fixedFontSize bypasses `MediaQuery.textScaleFactor` — users with large-font accessibility setting see app stuck at default size in 14 screens.
  - **Lower than P1 because:** UX cosmetic + MVP ships; flagged but not crash.
- fix:
  1. Each `TextStyle(fontSize: X, fontWeight: Y, ...)` → check if matches existing `AppTextStyles.xxx` — replace.
  2. Where exotic size needed (e.g. iconEmoji size 22), use `AppTextStyles.baseRegular.copyWith(fontSize: 22)` — keeps theme baseline.
  3. Add custom_lint rule when re-enabled: `avoid_inline_textstyle`.
- authority:
  - `apps/mobile/CLAUDE.md §Design tokens` "Hardcoded font `TextStyle(fontSize: 16)` → use `Theme.of(context).textTheme.bodyMedium`."
  - `apps/mobile/CLAUDE.md §Accessibility — minimum required` "NEVER `fixedFontSize` on `Text`."
- test:
  - After fix: `rg "TextStyle\(fontSize:" apps/mobile/lib --glob '!core/theme/**' --glob '!*.g.dart'` returns 0 hits in feature presentation dirs.
  - Manual: enable Android system-level "Largest font" + open each fixed screen — text scales up.
- deps: pairs with CQ-003 (same theme-tokens-not-used root cause)

### ISSUE CQ-005

- sev: P2
- blocker: no
- area: Magic strings — Firestore collection names hardcoded across modules
- files:
  - `apps/mobile/lib/features/feed/data/firebase_post_repository.dart:13,21,263` (`'posts'`, `'friendships'`)
  - `apps/mobile/lib/features/friend/data/firebase_friend_repository.dart:18,31,64,78` (`'users'`, `'friendships'`)
  - `apps/mobile/lib/features/friend/data/firebase_friend_request_repository.dart:17,37,70,78,95,103` (`'friend_requests'`)
  - `apps/mobile/lib/features/notification/data/firebase_notification_repository.dart:16,19` (`'users'`, `'fcmTokens'`, `'notifications'`)
  - `apps/mobile/lib/features/reaction/data/firebase_reaction_repository.dart:11` (`'posts'`, `'reactions'`)
  - `apps/mobile/lib/features/auth/data/firebase_user_repository.dart:13,16,21,24,32,38,46` (`'users/'`, `'usernames/'` — template-string literals, 7 sites; pass-5 finding)
  - `apps/mobile/lib/features/chat/data/firebase_conversation_repository.dart:17,18` (`_conversationsCol`, `_messagesSub` — already const, GOOD pattern)
  - `apps/mobile/lib/features/diary/data/firebase_diary_repository.dart:37` (`_collection = 'diary'` — already const, GOOD)
  - `apps/mobile/lib/features/space/data/firebase_space_repository.dart:15` (`_spacesCollection = 'spaces'` — already const, GOOD)
  - `firebase/functions/src/**` — 46 hits across 13 files: `db.collection('users')`, `db.collection('posts')`, `db.collection('friendships')`, `db.collection('conversations')`, `db.collection('blocks')`, `db.collection('diary')`, `db.collection('friend_requests')`, `db.collection('spaces')`, `db.collection('usernames')`, `db.collection('space_members')`
- loc: see above; **inconsistent pattern** — 4 repos use `static const _xxx = '...'` (chat/diary/space/post static `_posts`), 5 repos inline string literal repeatedly
- symbols:
  - `FirebasePostRepository._posts` (static const — good)
  - `FirebaseConversationRepository._conversationsCol` (good)
  - `FirebaseDiaryRepository._collection` (good)
  - `FirebaseSpaceRepository._spacesCollection` (good)
  - vs `FirebaseFriendRepository.watchFriends` inlines `'friendships'`, `'users'` (bad)
  - vs `FirebaseFriendRequestRepository.{watchPending,sendFriendRequest,...}` inline `'friend_requests'` 6 times
  - functions: 46 inline string literals, 0 module-level constants
- evidence:
  - `firebase_friend_request_repository.dart:17,37,70,78,95,103` — same string `'friend_requests'` typed 6 times in one file
  - `firebase_notification_repository.dart:16` `_firestore.collection('users').doc(uid).collection('fcmTokens')` — 2 collection names in 1 line, no constant
  - `firebase_post_repository.dart:13` `static const _posts = 'posts';` shows the GOOD pattern, BUT line 263 `_db.collection('friendships').where('members', arrayContains: uid)` inlines `'friendships'` despite same file having a const for `'posts'`
  - functions/src/feed/onPostCreated.ts uses `db.doc(`users/${authorId}`)` (line 49) — template string with collection inlined; same path repeated in onSpaceMemberAdded.ts:29, onSpaceMemberRemoved.ts:24
- risk:
  - **Rename safety:** if leader renames `friend_requests` → `friendRequests` (camelCase), 6 sites in 1 file + N other files break with no compiler help. Compare with `_posts` const — 1-line rename + IDE refactor catches all usages.
  - **Typo risk:** `'friendhsips'` (typo) returns empty query without throwing — silent bug. The pattern enables this class of bug.
  - **Cross-repo drift:** mobile + functions both reference same paths but diverge. Migration like SEC USER-SEC-001 (move `/users/{uid}` reads to `/users/{uid}/public/profile` subcollection) requires N+M edit sites across both languages — error-prone.
- fix:
  1. Mobile: create `apps/mobile/lib/core/firestore/firestore_paths.dart`:
     ```dart
     abstract class FirestorePaths {
       static const users = 'users';
       static const posts = 'posts';
       static const friendships = 'friendships';
       static const friendRequests = 'friend_requests';
       static const conversations = 'conversations';
       static const messages = 'messages';
       static const reactions = 'reactions';
       static const spaces = 'spaces';
       static const spaceMembers = 'space_members';
       static const diary = 'diary';
       static const blocks = 'blocks';
       static const usernames = 'usernames';
       // Subcollections
       static const fcmTokens = 'fcmTokens';
       static const notifications = 'notifications';
       static const userFeed = 'feed';
       static const userPrivate = 'private';
     }
     ```
  2. Functions: create `firebase/functions/src/constants/paths.ts` (mirror).
  3. Replace inline strings — single PR per module. Optional but recommended: enforce via lint rule (`no_inline_literal_collection_name` custom lint).
  4. **Scope warning:** this is a cross-module change and touches every Firebase repo. Coordinate with leader; bundle with ARCH-DATA-ARCH-001 fix wave so the 5 repos getting error-mapping refactor also get path constants.
- authority:
  - `CLAUDE.md §Surgical changes` (DRY spirit for repeated strings) — "Mỗi line code mới phải trace được về yêu cầu"
  - `auth.md` Pattern #1 — `core/` is canonical home for shared infra
  - `firebase/CLAUDE.md §Firestore data modeling` (spirit) — declarative path mapping reduces typo risk
- test:
  - After refactor: `rg "collection\('users'\|'posts'\|'friendships'\|..." apps/mobile/lib firebase/functions/src` returns 0 outside `firestore_paths.dart` / `paths.ts`.
  - Full test suite passes — `dart test`, `npm test`.
  - Code review verifies test files also use constants OR explicit inline (acceptable for test arrange phase).
- deps: pairs with ARCH-DATA-ARCH-001 (do in same wave to avoid re-touch); blocked-by SEC USER-SEC-001 if `'users'` access pattern changes (e.g. `/users/{uid}/public/profile`)

### ISSUE CQ-006

- sev: P2
- blocker: no
- area: Anti-pattern — `Future.delayed` for UX timing
- files:
  - `apps/mobile/lib/features/feed/presentation/feed_section.dart:370`
  - `apps/mobile/lib/features/friend/presentation/friend_sheet.dart:71`
  - `apps/mobile/lib/features/auth/presentation/signup/signup_username_page.dart:90`
  - `apps/mobile/lib/features/auth/presentation/login/reset_password_page.dart:54`
- loc: 4 specific call sites
- symbols:
  - `_spawnBubbles` (feed_section.dart) — staggered emoji animations
  - `_copyLink` (friend_sheet.dart) — 2s "copied" toast feedback
  - `_onSubmit` (signup_username_page.dart) — 800ms "Hoàn tất" pause before nav
  - `_onSave` (reset_password_page.dart) — 800ms "Thành công" pause before nav
- evidence:
  - `feed_section.dart:370` `Future.delayed(Duration(milliseconds: 150 * i), () { ... });` — emoji bubble stagger (animation usage, NOT state-wait)
  - `friend_sheet.dart:71` `await Future<void>.delayed(const Duration(seconds: 2));` — wait 2s then `setState(() => _linkCopied = false);` (UX feedback timing)
  - `signup_username_page.dart:90` `// Delay 800ms để user thấy "Hoàn tất" trước khi redirect\n      await Future<void>.delayed(const Duration(milliseconds: 800));` (UX feedback)
  - `reset_password_page.dart:54` `// Delay ngắn để user thấy trạng thái thành công trước khi vào app\n      await Future<void>.delayed(const Duration(milliseconds: 800));` (UX feedback)
- risk:
  - **Rule spirit:** `apps/mobile/CLAUDE.md §Async / streams` says "NEVER `Future.delayed(...)` to 'wait for state'." The strict-letter interpretation is "wait for async state to settle"; the 4 cases here are UX timing, not state-wait. So they don't directly break the rule.
  - **However:** the friend_sheet:71 + signup:90 + reset_password:54 patterns are testability anti-pattern — widget tests with `pumpAndSettle()` will hang for the full duration unless test framework intercepts. `flutter_test` does honor `Future.delayed` in widget tests but they slow down tests by 2s/800ms each.
  - **Bubble animation (feed_section:370):** is legitimate animation timing, NOT a violation. Can flag but lower priority.
  - **Lower than P1 because:** functional behavior correct; not bug-prone, just polish + testability concern.
- fix:
  - **friend_sheet.dart:67-75 — `_copyLink`:** replace with `Timer(Duration(seconds: 2), () { if (mounted) setState(() => _linkCopied = false); });` — cancellable on dispose, easier to test (timer mockable via `fake_async`).
  - **signup_username_page.dart:90 + reset_password_page.dart:54 — success delay:** consider replacing with controller-driven `success` state flag that triggers `Navigator.push` from a `ref.listen` in main MaterialApp router, with route transition animation providing natural visual continuity. Or accept current 800ms tolerance and add `// ignore: avoid_future_delayed` with explanatory comment.
  - **feed_section.dart:370 — `_spawnBubbles`:** wrap in `mounted` guard (already there per line 371). This is animation, OK to keep. Document with comment if not already.
  - Document explicit exception in `apps/mobile/CLAUDE.md §Async / streams`: "UX feedback timer (post-action visual hold) is acceptable when:
    1. Wrapped in `mounted` guard.
    2. Maximum 1000ms total.
    3. Not in critical flow (auth state change, payment, etc.)"
- authority:
  - `apps/mobile/CLAUDE.md §Async / streams` "NEVER `Future.delayed(...)` to 'wait for state'."
  - `apps/mobile/CLAUDE.md §Common gotchas` `Future` inside `build()` → Use `FutureProvider` / `StreamProvider` (related but different)
- test:
  - After fix: `rg "Future.*delayed" apps/mobile/lib --glob '!*.g.dart'` returns ≤ 1 hit (legit animation) or 0 if rewritten.
  - Widget tests for signup + reset_password don't need `await tester.pump(const Duration(milliseconds: 800))` — verify success state transitions via `pumpAndSettle()`.
- deps: none

### ISSUE CQ-007

- sev: P2
- blocker: no
- area: TODO format inconsistency violates CLAUDE.md §Stub standard
- files (16 files with non-conformant TODOs):
  - `apps/mobile/lib/features/profile/presentation/edit_profile_screen.dart:464,472,480,488,496,504,526,673` — `// TODO(T5): ...` (missing DevName)
  - `apps/mobile/lib/features/profile/presentation/profile_screen.dart:104,390,397` — `// TODO(P/T3/HanDHG): ...` OK; `// TODO: AppColors.actionButtonFill` and `// TODO: AppColors.actionButtonText` (no task id, no DevName)
  - `apps/mobile/lib/features/profile/presentation/widgets/profile_tab_bar.dart:5` — `// TODO: add AppColors.tabIconInactive` (no task id, no DevName)
  - `apps/mobile/lib/features/feed/application/caption_service_impl.dart:35` — `// TODO: link Streak module` (no task id)
  - `apps/mobile/lib/features/feed/application/feed_controller.dart:42,130` — `// TODO(FE/T6/KhoaLND):` OK format
  - `apps/mobile/lib/features/feed/presentation/home_screen.dart:221` — `// TODO(Feed/KhoaLND):` (missing task id)
  - `apps/mobile/lib/features/diary/presentation/diary_create_screen.dart:3` — `// TODO(D/T9/TBD):` (TBD instead of DevName — file may be deletable, scaffold leak)
  - `apps/mobile/lib/features/diary/presentation/diary_canvas_screen.dart:456` — `// TODO(D/T-share/HanDHG):` OK
  - `apps/mobile/lib/features/diary/presentation/diary_canvas_screen_toolbar.dart:50` — `// TODO(D/T9/HanDHG):` OK
  - `apps/mobile/lib/features/settings/presentation/widgets/settings_header.dart:62` — `// TODO(A/Router/ThienPDM):` OK
  - `apps/mobile/lib/shared/widgets/app_act_text_bar.dart:7` — `// TODO(R/T5/TBD):` (TBD missing DevName)
  - `apps/mobile/lib/shared/widgets/share_photo_sheet.dart:23,151` — `// TODO(ST3+/post-MVP):` (post-MVP defer flag, missing DevName)
  - `apps/mobile/lib/shared/widgets/share_profile_sheet.dart:120` — `// TODO(T6/HanDHG):` OK
  - `apps/mobile/lib/core/config/app_config.dart:17` — `// TODO(Round C/ThienPDM):` (close enough, but no task id)
  - `firebase/functions/src/index.ts:33,56` — `// TODO(impl): see comment above.` (no task id, no DevName)
- loc: 28 unique TODO comments across 16 files
- symbols: trivial — comment-only
- evidence:
  - `CLAUDE.md §Stub standard`: `Format: // TODO(<task-id>/<DevName>): <short description>`
  - Violators:
    - 8 in `edit_profile_screen.dart` use `// TODO(T5):` (missing DevName)
    - 3 inline `// TODO:` (no task id, no DevName) in `profile_screen.dart:390,397` + `profile_tab_bar.dart:5`
    - 2 `// TODO(impl):` in `functions/src/index.ts:33,56` (no DevName)
    - 1 `// TODO: link Streak module` in `caption_service_impl.dart:35` (zero metadata)
    - 2 `// TODO(R/T5/TBD)` + `// TODO(D/T9/TBD)` use literal "TBD" as DevName placeholder
- risk:
  - **Process drift:** team has 4 dev owners — task assignment from TODO is impossible if DevName missing. Build skill `/start <issue-id>` cannot route to owner.
  - **Stale work tracking:** TODOs without GH issue link become orphaned over time. Cumulative debt unobservable.
  - **Onboarding cost:** new dev seeing `// TODO(T5):` cannot find which task in GitHub corresponds → must ask leader → friction.
  - **Lower than P1 because:** cosmetic violation; code works; not bug-prone.
- fix:
  1. Audit pass: leader identify each TODO + assign owner (the dev whose module the file belongs to).
  2. Bulk rewrite via PR per module — `// TODO(<existing-task-or-issue>/<DevName>): ...`. Example: `edit_profile_screen.dart:464 // TODO(T5):` → `// TODO(P/T5/HanDHG): open displayName input sheet` (P = profile module per code style of other TODOs).
  3. Sweep `// TODO:` without parens entirely — these are zero-metadata orphans, link them OR delete (use git history if context needed).
  4. Add pre-commit lint script: `rg "// TODO[:(]" apps/mobile/lib --glob '!*.g.dart' | grep -v 'TODO([^/]*/[^/]*/[^/]*\):'` flags non-conformant (regex sketch — needs tuning).
  5. **Don't** create GH issues for each TODO retroactively — too much process overhead. Just enforce going forward.
- authority:
  - `CLAUDE.md §Stub / placeholder standard` — exact format spec
  - `CLAUDE.md §Dev Code Standards — 4 non-negotiable rules` #1 Skeleton, #2 Contract-first
- test:
  - After fix: `rg "// TODO[^(]" apps/mobile/lib firebase/functions/src --glob '!*.g.dart'` returns 0 (every TODO has parens).
  - `rg "// TODO\([^)]*TBD" apps/mobile/lib` returns 0 (no literal TBD as DevName).
- deps: none

### ISSUE CQ-008

- sev: P2
- blocker: no
- area: Debug logging artifact in production Cloud Function
- files:
  - `firebase/functions/src/chat/onMessageCreated.ts`
- loc: 40, 48, 54, 64, 73, 116, 121-122, 128, 136-139 — 9 `logger.info`/`logger.warn` calls all tagged `[CHAT-DEBUG]`
- symbols:
  - `onMessageCreated` trigger handler — heavy diagnostic logging
- evidence:
  - `onMessageCreated.ts:40` `logger.warn('[CHAT-DEBUG] event.data rỗng → bỏ qua');`
  - `onMessageCreated.ts:48-51`:
    ```ts
    logger.info(
      { conversationId, messageId, senderId, textLength: text.length },
      '[CHAT-DEBUG] Trigger onMessageCreated bắt đầu chạy',
    );
    ```
  - `onMessageCreated.ts:116-119`:
    ```ts
    logger.info(
      { receiverUid, conversationId, messageId },
      '[CHAT-DEBUG] Đã tạo notification doc cho receiver',
    );
    ```
  - 9 callsites all use `[CHAT-DEBUG]` prefix — clearly a debug breadcrumb that survived the bug-fix that introduced it
  - Compare with `_fcm.ts` (clean — only `logger.error` on multicast fail) and `onReactionCreated.ts` (clean — only `logger.warn` for missing data, `logger.info` for skip)
- risk:
  - **Cost:** Cloud Logging charges per log entry beyond free tier (50 GiB/month). High-volume chat traffic = 9 log entries per message × X messages/day → cost scales linearly. MVP fine, post-MVP risky.
  - **PII leak:** Log includes `textLength` (not full text — OK), but `senderId`, `conversationId`, `receiverUid` all leak — IDs OK per CLAUDE.md, but combined with FCM token leaks elsewhere could correlate. Lower concern.
  - **Production noise:** debug tag `[CHAT-DEBUG]` is an artifact of bug fix that wasn't cleaned up — code review smell.
  - **Lower than P1 because:** logging itself is functional, just verbose + cost concern; not a bug.
- fix:
  1. Demote 9 `[CHAT-DEBUG]` info logs to either:
     - Delete entirely if breadcrumb purpose served (FCM delivery now working)
     - Keep 2 ESSENTIAL ones (entry-point with `{conversationId, messageId, senderId}` + error path) without `[CHAT-DEBUG]` prefix
  2. Rule: use `logger.debug(...)` (filtered out at INFO level by default) for breadcrumb logs; reserve `logger.info`/`logger.warn`/`logger.error` for meaningful state transitions.
  3. Functions strict mode debug check: `firebase/functions/CLAUDE.md §Logging` "Don't `console.log` in production code; use `pino` or Cloud Functions' built-in `logger`." This applies — `[CHAT-DEBUG]` is functionally a `console.log` in spirit.
- authority:
  - `firebase/functions/CLAUDE.md §Logging` — "Never log PII — no email, phone, caption body, full request body. Log IDs only. Structured logs: `logger.info({ uid, postId }, 'post created')`."
  - Compare to `onReactionCreated.ts` + `_fcm.ts` (clean — established pattern in same codebase)
- test:
  - After fix: `rg "\[CHAT-DEBUG\]" firebase/functions/src` returns 0 hits.
  - Manual: trigger 1 chat message via emulator, verify Functions log shows ≤ 2 entries (entry + (success OR error)).
- deps: none

### ISSUE CQ-009

- sev: P3
- blocker: no
- area: TS Functions — `console.warn` violation of Functions CLAUDE.md
- files:
  - `firebase/functions/src/friend/onFriendshipDeleted.ts:25`
- loc: 25
- symbols: `onFriendshipDeleted` trigger handler
- evidence:
  - `onFriendshipDeleted.ts:25` `console.warn(`onFriendshipDeleted: no data for ${pairId}`);`
  - 1 of only 2 `console.*` hits in entire `firebase/functions/src/` (the other is `console.warn` in the same file's comment in test files which is fine)
  - Compare with peer trigger `onSpaceDeleted.ts:74` `logger.error(`onSpaceDeleted failed for ${spaceId}`, e);` — uses `logger` correctly
  - Already documented in ARCH-LAYER-004 self_verification_log: "1 `console.warn` (line 25) vi phạm Functions CLAUDE.md ... defer."
- risk:
  - **Lower than P2 because:** 1 line, 1 file; functionality identical to `logger.warn`; just style violation.
  - **Production impact:** Cloud Logging captures `console.warn` differently from `logger.warn` — search by `severity=WARNING` may miss console writes. Cosmetic but reduces operability.
- fix:
  - Replace `console.warn(`onFriendshipDeleted: no data for ${pairId}`);` with `logger.warn('onFriendshipDeleted: no data', { pairId });` (structured logging — separate string template into pair).
  - Add `import { logger } from 'firebase-functions/v2';` (currently missing in this file — file uses only `getFirestore` + `FieldValue`).
- authority:
  - `firebase/functions/CLAUDE.md §Logging` "Don't `console.log` in production code; use `pino` or Cloud Functions' built-in `logger`."
- test:
  - After fix: `rg "console\.(log\|warn\|error)" firebase/functions/src` returns 0 hits.
- deps: none

### ISSUE CQ-010

- sev: P3
- blocker: no
- area: Dead-ish code — unused `sendFriendRequest` stub
- files:
  - `firebase/functions/src/index.ts:30-58`
- loc: 30-58
- symbols:
  - `export const sendFriendRequest = onCall(...)` (line 39)
  - `sendFriendRequestSchema` (line 24)
- evidence:
  - `index.ts:33-37`:
    ```ts
    /**
     * Send a friend request from the calling user to `toUid`.
     *
     * TODO(impl):
     *   - check the requester is not blocked by the target
     *   - check no pending request already exists between the pair
     *   - write the request doc with serverTimestamp()
     *   - send an FCM notification to the target
     */
    ```
  - `index.ts:56-58`:
    ```ts
    // TODO(impl): see comment above.
    return { ok: true, fromUid, toUid };
    ```
  - The CF is exported (line 39 `export const sendFriendRequest`) and deployed but its body is a no-op returning `{ ok: true }` regardless of input.
  - Mobile client `firebase_friend_request_repository.dart:78-85` writes `/friend_requests` Firestore doc DIRECTLY (`_firestore.collection('friend_requests').add({...})`) — does NOT call the CF.
  - `acceptFriendRequest` IS implemented as a separate CF (line 66 — `friend/acceptFriendRequest.ts`).
  - This `sendFriendRequest` is a placeholder from an earlier design draft.
  - **Signature drift (pass-9 finding):** CF schema `{toUid: string}` (1 param, index.ts:24); mobile abstract `Future<void> sendFriendRequest({required String senderUid, required String receiverUid})` (2 params, friend_request_repository.dart:14). If a future dev tries to wire mobile → CF without re-checking shape, payload mismatch will throw `invalid-argument` at runtime.
  - `firebase/functions/src/index.test.ts` (28 lines, 4 tests) covers `sendFriendRequestSchema` ONLY — orphans together with the stub. Delete both in Option A.
- risk:
  - **Cost:** zero — CF deployed but not invoked.
  - **Confusion:** new dev seeing `sendFriendRequest` in Firebase Console function list may assume the friend-request flow goes through it. Wasted onboarding time.
  - **Cleanup:** the doc comment lists 4 TODOs that the client repo actually accomplishes via direct Firestore write — flow already works without this CF.
  - **Lower than P2 because:** no deployment cost concern, no client integration, no test impact.
- fix:
  - Decision needed: delete the stub OR implement it.
  - **Option A — delete (recommended):** Remove `sendFriendRequest` CF export + schema + comment block (`index.ts:24-58`) **AND** delete `index.test.ts` (4 orphan tests cover only the deleted schema). Run `firebase deploy --only functions` to remove from production. Doesn't break client (client uses direct Firestore write).
  - **Option B — implement:** if leader wants server-side validation (block check, dedupe), implement per the 4 TODO bullets. But this competes with FRIEND-SEC-002 (SEC audit) which proposes a different CF `searchUserByUsername`. Defer to leader.
- authority:
  - `CLAUDE.md §Surgical changes` "Mỗi line code mới phải trace được về yêu cầu. Nếu không trace được → bỏ."
- test:
  - After Option A: `gh api repos/<org>/<repo>/actions` deployments succeed without `sendFriendRequest` in function list.
  - Mobile `friend_controller_test.dart` continues to pass (no CF dependency).
- deps: pairs with FRIEND-SEC-002 (SEC) if Option B chosen

### ISSUE CQ-011

- sev: P3
- blocker: no
- area: Naming — anti-term `save*` violates CLAUDE.md anti-term table
- files:
  - `apps/mobile/lib/features/notification/data/notification_repository.dart:5`
  - `apps/mobile/lib/features/notification/data/firebase_notification_repository.dart:28`
  - `apps/mobile/lib/features/diary/application/diary_controller.dart:112`
- loc:
  - `notification_repository.dart:5` `Future<void> saveFcmToken(String uid, String token);`
  - `firebase_notification_repository.dart:28` `Future<void> saveFcmToken(String uid, String token) async {`
  - `diary_controller.dart:112` `Future<void> saveEntry({...})`
- symbols:
  - `NotificationRepository.saveFcmToken` (abstract)
  - `FirebaseNotificationRepository.saveFcmToken` (impl)
  - `DiaryController.saveEntry`
- evidence:
  - `CLAUDE.md §Domain Language — Anti-terms`:
    ```
    | "save" | "create" / "update" / "upsert" |
    ```
  - `saveFcmToken` is actually an upsert (line 21-22 comment: "wipe every existing fcmToken doc, then write the new one") → should be `upsertFcmToken`.
  - `saveEntry` (diary) is conditional create-or-update based on `state.mode == DiaryCanvasMode.create` (line 127) → should be split into `createEntry` + `updateEntry` OR named `upsertEntry`.
- risk:
  - **Cosmetic / domain language consistency:** breaks the team's anti-term discipline. New owner reading "saveFcmToken" can't tell if it's idempotent (no-op if already saved) or write-anyway.
  - **Lower than P2 because:** 2 method names, internal API; not bug-prone.
- fix:
  - Rename `NotificationRepository.saveFcmToken` → `upsertFcmToken`. Update abstract + impl + 1 call site in `notification_controller.dart`. Codegen freshness check (no .g.dart impact since abstract method).
  - Rename `DiaryController.saveEntry` → either:
    - `submitEntry` (UX action verb — fits state machine semantics, not anti-term)
    - or split into separate `createEntry` / `updateEntry` based on mode (cleaner separation)
  - Update tests `firebase_notification_repository_test.dart` and `diary_controller_test.dart` to use new name.
- authority:
  - `CLAUDE.md §Domain Language — Anti-terms` table — explicit `save → create/update/upsert`
- test:
  - After fix: `rg "saveFcm\|saveEntry" apps/mobile" returns 0 hits.
  - Full test suite passes.
- deps: none

### ISSUE CQ-014

- sev: P1
- blocker: no
- area: Duplicate logic — `_mapFunctionsException` + `_mapFirestoreException` + `_mapFirestoreError` duplicated across repos
- files:
  - `apps/mobile/lib/features/space/data/firebase_space_repository.dart:184-222` — `_mapFunctionsException`
  - `apps/mobile/lib/features/settings/data/firebase_block_repository.dart:127-167` — `_mapFunctionsException` (byte-for-byte identical to space version, self-comment line 126 admits "Pattern theo `firebase_space_repository.dart`")
  - `apps/mobile/lib/features/chat/data/firebase_conversation_repository.dart:221-251` — `_mapFirestoreException(FirebaseException, String action)`
  - `apps/mobile/lib/features/settings/data/firebase_block_repository.dart:96-124` — `_mapFirestoreException(FirebaseException, String action)` (byte-for-byte identical to conversation version)
  - `apps/mobile/lib/features/diary/data/firebase_diary_repository.dart:284-296` — `_mapFirestoreError(FirebaseException)` (no action param, different shape)
  - `apps/mobile/lib/features/profile/data/firebase_profile_repository.dart:165-178` — `_mapFirestoreError(FirebaseException)` (same shape as diary)
  - `apps/mobile/lib/features/streak/data/firebase_streak_repository.dart:84-95` — `_mapStreakError(FirebaseException)` (same shape as diary/profile)
  - `apps/mobile/lib/features/auth/data/firebase_auth_repository.dart:290-326` — 3 variants `_mapSignUpError` / `_mapSignInError` / `_mapGenericError` (FirebaseAuthException-specific, OK pattern for auth-specific codes)
- loc: 5 byte-for-byte / near-identical implementations across 5 repos
- symbols:
  - `_mapFunctionsException(FirebaseFunctionsException, String action) → AppError` — 2 copies (block + space)
  - `_mapFirestoreException(FirebaseException, String action) → AppError` — 2 copies (conversation + block)
  - `_mapFirestoreError(FirebaseException) → AppError` — 3 copies (diary + profile + streak), no `action` param
  - `_mapStorageError(FirebaseException) → AppError` — 2 copies (diary + profile)
- evidence:
  - `firebase_block_repository.dart:125` self-comment: `/// Pattern theo `firebase_space_repository.dart`.` — copy acknowledged in source.
  - Bodies verified identical via paired `sed -n` read:
    ```dart
    // _mapFunctionsException — IDENTICAL in block + space:
    switch (e.code) {
      case 'invalid-argument':
      case 'failed-precondition':
        return ValidationError(message: serverMessage ?? 'Không thể $action: dữ liệu không hợp lệ', code: e.code, cause: e);
      case 'permission-denied':
        return ForbiddenError(action);
      case 'not-found':
        return NotFoundError(serverMessage ?? action);
      case 'unauthenticated':
        return UnauthenticatedError(message: serverMessage ?? 'Cần đăng nhập để $action', code: e.code, cause: e);
      case 'unavailable':
      case 'deadline-exceeded':
        return NetworkError(message: serverMessage ?? 'Mất kết nối khi $action. Thử lại sau.', code: e.code, cause: e);
      default:
        return UnexpectedError(message: serverMessage ?? 'Không thể $action. Thử lại sau.', code: e.code, cause: e);
    }
    ```
  - `_mapFirestoreException` (conversation + block): handles `permission-denied / not-found / unavailable / deadline-exceeded / cancelled / failed-precondition` — also identical bodies.
  - `_mapFirestoreError` (diary + profile + streak): handles `permission-denied / not-found / unavailable / cancelled / deadline-exceeded / network-request-failed` — shape differs only by which fixed-string action label gets passed to the AppError ctor.
- risk:
  - **Drift bug:** if leader adds a new error code (e.g. `'aborted'` → `NetworkError`) to `_mapFunctionsException`, the dev MUST update both block + space repos. Forgetting one → block CF errors render via `UnexpectedError` fallback (wrong VN message) while space CF errors render properly. Same risk for the 3-way `_mapFirestoreError` variant.
  - **Onboarding cost:** new module owner (e.g. future T-friend module owner) faces a forking decision: 4 repos use long-form (5-case switch + AppError ctor), 3 repos use sugar `=> switch ... =>` expression. Convention split increases cognitive load.
  - **Test duplication:** each repo's error-mapping test re-tests the same 5-6 codes (permission-denied / not-found / unavailable / ...). Extracting to shared mapper deduplicates ~30 lines of test boilerplate per repo.
  - **Pattern #2 spirit violation:** `auth.md` Pattern #2 says "Private `_mapXxxError` ... switch trên `e.code` → `AppError` subclass" — meant per-module customization (auth has unique codes like `wrong-password`, `email-already-in-use`). For generic Firestore/Functions errors, the codes are identical → mapper is the same. Pattern was misapplied as "every repo copies the same generic mapping" instead of "each repo customizes when it has unique codes."
  - **Combined with ARCH-DATA-ARCH-001 fix wave:** when ARCH fixes the 5 missing mappers (feed/friend/reaction/notification/storage), the additions WILL re-duplicate this same code unless extracted to shared helper FIRST.
- fix:
  1. Extract 3 shared mappers to `apps/mobile/lib/core/error/firebase_error_mapper.dart`:
     ```dart
     import 'package:cloud_firestore/cloud_firestore.dart';
     import 'package:cloud_functions/cloud_functions.dart';
     import 'package:firebase_storage/firebase_storage.dart';

     import 'package:meep/core/error/app_error.dart';

     /// Map Firestore exception → AppError. Pattern #2 generic baseline.
     /// Module repos call this for non-customized codes; only override when
     /// module-specific codes need different handling (e.g. auth's wrong-password).
     AppError mapFirestoreException(FirebaseException e, String action) {
       final serverMessage = e.message;
       switch (e.code) {
         case 'permission-denied':
           return ForbiddenError(action);
         case 'not-found':
           return NotFoundError(serverMessage ?? action);
         case 'unavailable':
         case 'deadline-exceeded':
         case 'cancelled':
           return NetworkError(message: serverMessage ?? 'Mất kết nối khi $action. Thử lại sau.', code: e.code, cause: e);
         case 'failed-precondition':
           return ValidationError(message: serverMessage ?? 'Không thể $action: dữ liệu không hợp lệ', code: e.code, cause: e);
         default:
           return UnexpectedError(message: serverMessage ?? 'Không thể $action. Thử lại sau.', code: e.code, cause: e);
       }
     }

     /// Map Functions callable exception → AppError. Includes auth/permission/
     /// argument-validation codes that Firestore doesn't have.
     AppError mapFunctionsException(FirebaseFunctionsException e, String action) {
       // ... (combined block from block + space repos)
     }

     /// Map Storage exception → AppError.
     AppError mapStorageException(FirebaseException e, String action) {
       // ... (combined block from diary + profile repos)
     }
     ```
  2. Delete 7 local copies. Each repo imports the helper + calls `mapFirestoreException(e, 'tạo Space')` etc.
  3. `_mapFirestoreError` (no action param) in diary/profile/streak: pass the fixed action string at call site (e.g. `mapFirestoreException(e, 'truy cập hồ sơ')` instead of having a no-arg variant). Reduces repo-local boilerplate by 12 lines each.
  4. **Don't unify auth's `_mapSignInError` / `_mapSignUpError`** — those handle Auth-specific codes (`wrong-password`, `email-already-in-use`, `requires-recent-login`) that aren't applicable to Firestore/Functions. Keep auth's per-flow mappers.
  5. **Order of operations:** do BEFORE ARCH-DATA-ARCH-001 fix wave so the 5 new mappers (feed/friend/reaction/notification/storage) just `import + call helper` instead of re-creating the boilerplate. Saves ~150 lines across the 5 new repos.
- authority:
  - `CLAUDE.md §Surgical changes` "Mỗi line code mới phải trace được về yêu cầu" + DRY
  - `auth.md` Pattern #1 — `core/error/` is canonical home for error infrastructure
  - `auth.md` Pattern #2 spirit — per-module mappers for module-specific codes, shared mapper for generic Firestore/Functions/Storage codes
  - `firebase_block_repository.dart:125` self-comment acknowledges copy
- test:
  - After refactor: `rg "_mapFunctionsException\|_mapFirestoreException\|_mapFirestoreError" apps/mobile/lib/features` returns 0 hits (all moved to `core/error/firebase_error_mapper.dart`).
  - Add `test/core/error/firebase_error_mapper_test.dart` covering 6 codes × 3 mappers = 18 cases.
  - Existing repo tests continue to pass — just verify call site invokes the helper.
- deps: blocks ARCH-DATA-ARCH-001 (do CQ-014 FIRST to avoid re-duplicating boilerplate in the 5 new repos)

### ISSUE CQ-013

- sev: P3
- blocker: no
- area: Oversized test files — prompt checklist §Oversized constructs "Test file > 500 lines (split by behavior)"
- files:
  - `apps/mobile/test/features/space/space_controller_test.dart` (722 lines)
  - `apps/mobile/test/features/diary/application/diary_controller_test.dart` (587 lines)
  - `apps/mobile/test/features/chat/data/firebase_conversation_repository_test.dart` (532 lines)
  - `apps/mobile/test/features/diary/data/firebase_diary_repository_test.dart` (501 lines)
- loc: file-level (4 files > 500 lines)
- symbols:
  - `space_controller_test.dart` main() — multiple `group()` blocks covering build/createSpace/leaveSpace/deleteSpace/updateSpace/kickMember/transferOwnership
  - `diary_controller_test.dart` main() — saveEntry create + saveEntry update + loadEntry + delete + image upload paths
  - `firebase_conversation_repository_test.dart` main() — watchConversations + watchMessages + getOrCreate + sendMessage + markAsRead + error mapping
  - `firebase_diary_repository_test.dart` main() — createEntry + watchEntries + getEntry + getPublicEntries + searchEntries + updateEntry + updatePrivacy + deleteEntry + error mapping
- evidence:
  - `find apps/mobile/test -name "*.dart" -exec wc -l {} \; | sort -rn | head -4` returns the 4 entries above.
  - Each file contains 7-10 `group()` blocks per `setUp/tearDown` pattern — test count high, but file structure flat (single `main()`).
  - `apps/mobile/CLAUDE.md §Widget split thresholds` table says `Class > 300 lines → split by SRP`. Test files exceed by 200-400 lines.
  - Prompt v2 §Oversized constructs checklist explicitly includes "Test file > 500 lines (split by behavior)".
- risk:
  - **Maintenance:** any test failure in a 722-line file forces scrolling through unrelated `group()` blocks to find the failing test. PR review of test changes is harder.
  - **Test isolation:** large `setUp` blocks at top of file create implicit dependencies — adding a new test risks breaking older tests via shared mock state.
  - **Discovery cost:** new dev onboarding to module X reads `xxx_controller.dart` (300 lines) + `xxx_controller_test.dart` (700+ lines) — test file is 2x source size.
  - **Lower than P2 because:** tests work; no bug-prone. Pure organizational concern.
- fix:
  - Split each oversized test file by behavior group, mirroring `auth.md` Pattern #10 (test stratification):
    - `space_controller_test.dart` → split into:
      - `space_controller_build_test.dart` (build + watchMySpaces subscription)
      - `space_controller_create_test.dart` (createSpace validation + CF call)
      - `space_controller_mutations_test.dart` (leaveSpace + deleteSpace + updateSpace + kickMember + transferOwnership)
    - `diary_controller_test.dart` → split into `diary_controller_save_test.dart` + `diary_controller_load_test.dart` + `diary_controller_delete_test.dart`.
    - `firebase_conversation_repository_test.dart` → `..._reads_test.dart` (watch* methods) + `..._writes_test.dart` (sendMessage, markAsRead, getOrCreate) + `..._errors_test.dart` (error mapping cases).
    - `firebase_diary_repository_test.dart` → similar split.
  - Each new file imports shared test helpers from a sibling `_test_helpers.dart` to avoid duplicating mock setup. Pattern matches `auth.md` Pattern #5 test override discipline.
- authority:
  - prompt v2 §Audit Checklist §Oversized constructs ("Test file > 500 lines (split by behavior)")
  - `apps/mobile/CLAUDE.md §File organization` "Files ≤ 300 lines. Split if larger." (apply spirit to tests)
- test:
  - After split: `find apps/mobile/test -name "*.dart" -exec wc -l {} \; | awk '$1 > 500 { print }'` returns 0.
  - All tests still pass: `flutter test test/features/space test/features/diary test/features/chat`.
- deps: none

### ISSUE CQ-012

- sev: P3
- blocker: no
- area: Stale comment — wired repo still tagged as throwing UnimplementedError
- files:
  - `apps/mobile/lib/features/settings/application/settings_controller.dart:84-88, 139-142`
- loc: 84-88, 139-142
- symbols:
  - `SettingsController.logout` (line 78)
  - `SettingsController.deleteAccount` (line 127)
- evidence:
  - `settings_controller.dart:84-88`:
    ```dart
    // TODO(N/T1/KhoaLND): notificationRepositoryProvider throws
    // UnimplementedError. Settings swallow lỗi nhưng FCM token KHÔNG bị
    // xóa → user vẫn nhận push sau logout. Notification module = empty
    // scaffold. KhoaLND build N/T1 FirestoreNotificationRepository +
    // impl deleteFcmToken khi đến scope Notification.
    ```
  - `settings_controller.dart:139-142`: same block, copy-pasted for `deleteAccount` path.
  - **Reality (verified):** `main.dart:119-121`:
    ```dart
    notificationRepositoryProvider.overrideWithValue(
      FirebaseNotificationRepository(firestore: FirebaseFirestore.instance),
    ),
    ```
  - `FirebaseNotificationRepository.deleteFcmToken(uid)` IS implemented (`firebase_notification_repository.dart:46-54`) and IS called by both `logout` (line 89) + `deleteAccount` (line 142).
- risk:
  - **Maintenance debt:** code comments lie about runtime behavior. New dev reading line 84 will believe FCM token cleanup doesn't work → misdiagnoses any unrelated push notification bug.
  - **Process violation:** TODO points at KhoaLND to do work that's already done (work was completed in a separate PR, comment wasn't updated).
  - **Lower than P2 because:** behavior is correct; only comment is stale.
- fix:
  - Update both comment blocks to reflect current reality:
    ```dart
    // FCM token cleanup is best-effort — swallow errors to ensure
    // signOut/cascade-delete completes even if notification repo write fails
    // (offline, transient permission denial, etc.). Push delivery to logged-out
    // device may continue until token TTL expires (~weeks), but is harmless.
    ```
  - Remove `TODO(N/T1/KhoaLND)` mention — task is done.
- authority:
  - `CLAUDE.md §Tone — Sự thật & không chắc chắn` "Không bịa" — stale comments mislead future readers
  - `CLAUDE.md §Comments` (root project section spirit) — "Comments explain **why**, not **what**." Stale comments break this.
- test:
  - After fix: `rg "notificationRepositoryProvider throws" apps/mobile/lib` returns 0 hits.
  - Manual: `logout()` test continues to pass; `deleteAccount()` test continues to pass.
- deps: none

## fix_order

### batch_1_p0

None. (CQ found 0 P0; all release blockers covered by ARCH/SEC audits.)

### batch_2_p1

1. **CQ-014** — extract `mapFirestoreException` / `mapFunctionsException` / `mapStorageException` to `core/error/firebase_error_mapper.dart` FIRST. Delete 7 repo-local copies. **Must precede ARCH-DATA-ARCH-001** to avoid creating 5 new copies in feed/friend/reaction/notification/storage repos.
2. **CQ-002** — extract `TimestampConverter` to `core/utils/`. Independent fix, ~30 min. Delete 12 duplicates → uniform null-tolerance → reduces ~156 boilerplate lines.
3. **CQ-001** — `debugPrint` cleanup wave. Pairs naturally with ARCH-LAYER-002 fix (same files in feed module).

### batch_3_p2

4. **CQ-005** — Firestore path constants. Bundle with ARCH-DATA-ARCH-001 fix wave to avoid double-touching the same 5 repos.
5. **CQ-008** — `[CHAT-DEBUG]` cleanup in `onMessageCreated.ts`. Small focused PR.
6. **CQ-003** — hardcoded `Color(0x..)` → theme tokens. Leader-gated `core/theme/` additions per `apps/mobile/CLAUDE.md §Solo-dev module scope`. Per-module rollout.
7. **CQ-004** — hardcoded `TextStyle(fontSize:)` → `AppTextStyles`. Pairs with CQ-003 (same theme-token effort).
8. **CQ-006** — `Future.delayed` usages: convert friend_sheet to `Timer`; document exception for signup/reset success-hold pattern.
9. **CQ-007** — TODO format sweep. Leader assigns ownership.

### batch_4_p3

10. **CQ-009** — `console.warn` → `logger.warn` in `onFriendshipDeleted.ts:25`. 1-line fix.
11. **CQ-010** — delete `sendFriendRequest` stub from `index.ts` (Option A recommended). Note: also deletes orphan `index.test.ts` (4 tests cover stub schema only).
12. **CQ-011** — rename `saveFcmToken` → `upsertFcmToken`; `saveEntry` → `submitEntry`.
13. **CQ-012** — update stale comment in `settings_controller.dart:84-88, 139-142`.
14. **CQ-013** — split 4 test files > 500 lines (`space_controller_test.dart`, `diary_controller_test.dart`, `firebase_conversation_repository_test.dart`, `firebase_diary_repository_test.dart`).

## test_plan_after_fix

- `CQ-001`: `rg "debugPrint\(" apps/mobile/lib --glob '!*.g.dart' | wc -l` ≤ 5; `flutter analyze --no-pub` with `avoid_debug_print: true` returns 0 warnings.
- `CQ-002`: `rg "class TimestampConverter" apps/mobile/lib --glob '!*.g.dart' | wc -l` == 1; new `test/core/utils/timestamp_converter_test.dart` covers Timestamp / String / int / null variants; `flutter test test/` full suite passes.
- `CQ-003`: `rg "Color\(0x" apps/mobile/lib --glob '!core/theme/**' --glob '!*.g.dart' | wc -l` ≤ 5; widget tests for affected screens pass; manual dark-theme smoke test.
- `CQ-004`: `rg "TextStyle\(fontSize:" apps/mobile/lib --glob '!core/theme/**' --glob '!*.g.dart'` returns 0 hits in features.
- `CQ-005`: `rg "collection\('users'\|'posts'\|'friendships'\|'conversations'\|'spaces'\|'blocks'\|'friend_requests'\|'diary'\|'usernames'\|'space_members'\|'reactions'\|'fcmTokens'\|'notifications'\)" apps/mobile/lib firebase/functions/src` returns hits only inside `core/firestore/firestore_paths.dart` + `firebase/functions/src/constants/paths.ts`; `flutter test` + `npm test` pass.
- `CQ-006`: `rg "Future.*\.delayed" apps/mobile/lib --glob '!*.g.dart'` ≤ 1 hit; widget test for signup completes faster than 1s (current: ~900ms artificial wait).
- `CQ-007`: `rg "// TODO[^(]" apps/mobile/lib firebase/functions/src --glob '!*.g.dart'` returns 0 hits; `rg "TODO\([^)]*TBD" apps/mobile/lib` returns 0.
- `CQ-008`: `rg "\[CHAT-DEBUG\]" firebase/functions/src` returns 0; emulator integration test for chat trigger logs ≤ 2 entries per message.
- `CQ-009`: `rg "console\." firebase/functions/src` returns 0 (excluding test files).
- `CQ-010`: `firebase deploy --only functions` succeeds without `sendFriendRequest` in function list; `friend_controller_test.dart` + `friend_request_repository_test.dart` pass unchanged.
- `CQ-011`: `rg "\bsave[A-Z]" apps/mobile/lib --glob '!*.g.dart' --glob '!test/**'` returns 0 hits in feature code; tests updated to new names pass.
- `CQ-012`: `rg "notificationRepositoryProvider throws" apps/mobile/lib` returns 0; `settings_controller_test.dart` continues to pass.
- `CQ-013`: `find apps/mobile/test -name "*.dart" -exec wc -l {} \; | awk '$1 > 500 { print }'` returns 0; `flutter test test/features/{space,diary,chat}` passes unchanged.
- `CQ-014`: `rg "_mapFunctionsException\|_mapFirestoreException\|_mapFirestoreError\|_mapStorageError" apps/mobile/lib/features` returns 0 hits (moved to `core/error/firebase_error_mapper.dart`); new `test/core/error/firebase_error_mapper_test.dart` covers 6 codes × 3 mappers = 18 cases; existing repo tests pass (call site invokes helper).

## no_issue_notes

Compact notes for areas checked with no new issue (or item covered by Phase A and intentionally skipped per anti-duplicate rule).

### Anti-terms — clean
- `rg "user_id\|friend_id\|friendId"` mobile + functions returns 0 hits (mobile codebase uses `uid` + `pairId` + `friendUid` consistently). CLAUDE.md §Anti-terms compliance ✓.
- `// fetch` / `// save` / `// the database` / `// the backend` comments: 0 hits via Grep. ✓
- Method names `fetchX` / `fetchUser` / `fetchPost` / `fetchFeed` / `fetchFriend` / `fetchProfile`: 0 hits. Codebase uses `getX` (one-shot read), `watchX` (stream), `searchX` (query) — consistent with `auth.md` Pattern #2 spirit.

### TS Functions strictness — clean
- `firebase/functions/tsconfig.json` enables `strict: true`, `noUncheckedIndexedAccess: true`, `noImplicitOverride: true`, `noFallthroughCasesInSwitch: true`, `exactOptionalPropertyTypes: true`, target `ES2022`, module + moduleResolution `NodeNext`. Matches `firebase/functions/CLAUDE.md §Strictness — non-negotiable` exactly. ✓
- `rg ": any\|<any>\|as any" firebase/functions/src` returns 0 hits (excluding test files). ✓
- `rg "@ts-ignore\|@ts-expect-error\|eslint-disable" firebase/functions/src` returns 0 hits. ✓
- All 8 callable CFs use `safeParse` for input validation (blockUser, deleteAccount, acceptFriendRequest, createSpace, updateSpace, kickMember, leaveSpace, transferOwnership). ✓
- All 9 trigger CFs narrow `event.data?.data()` with defensive `as` casts on intermediate type guards (`typeof === 'string'` checks). ✓
- All CFs throw `HttpsError` with appropriate codes (`unauthenticated`, `invalid-argument`, `permission-denied`, `failed-precondition`, `not-found`). ✓
- Zod `.strict()` mode: missing on all 8 schemas — already covered by SEC FUNC-SEC-001 (P3). Do NOT re-log.

### Dart `dynamic` / `Object?` / unguarded casts — minor smell, not P1
- `dynamic` usage limited to JSON parsing boundary (`Map<String, dynamic>` from Firestore `.data()`) — accepted per audit prompt scope filter.
- `Object?` only in `JsonConverter<DateTime, Object?>` (covered by CQ-002), `core/error/app_error.dart:13` (cause field — appropriate sealed-class API).
- `as String?` casts in `core/router/app_router.dart:288, 359, 375, 381, 395, 405, 460, 461` are all guarded by `?? ''` or `?? 0` null-fallback — defensive coding pattern. NOT a smell.

### `// ignore:` directives — all justified
- `firebase_post_repository.dart:149` `// ignore: only_throw_errors — preserve original error type` — covered by ARCH-DATA-ARCH-001 refactor (will eliminate when error mapping added).
- `firebase_auth_repository.dart:141` `// ignore: deprecated_member_use` for `fetchSignInMethodsForEmail` (line 130-138 comment explains why deprecated API is intentional pending Firebase email-enumeration-protection rollout). ✓
- `debug_error_view.dart:30` `// ignore: library_private_types_in_public_api` — covered by ARCH-LAYER-004 (file may be deleted).
- `diary_canvas_screen.dart:402,409` `// ignore: unawaited_futures` — `Navigator.maybePop()` fire-and-forget, intentional. ✓
- `fake_conversation_repository.dart:50` `// ignore: close_sinks` — test fixture lifecycle. ✓
- `kick_member_dialog.dart:104` `// ignore: use_build_context_synchronously` — guarded by `mounted` check earlier. ✓
- 5 test `// ignore: close_sinks` in `mark_as_read_listener_test.dart` all paired with `addTearDown(repo.dispose)`. ✓

### Test code quality — generally good
- 80 test files; sorted by size top-15 reviewed.
- 11 files use `mocktail.verify(...)` — spot-checked `space_controller_test.dart`, `reaction_controller_test.dart`, `notification_controller_test.dart` — `verify()` paired with state assertions (`expect(state.spaces, hasLength(1))`) not tautology. ✓
- 0 `expect(true, true)` or `test('test1')` placeholders. ✓
- `home_page_test.dart:41 'shows TODO placeholder text'` is an intentional check for current placeholder content per home_page.dart skeleton state — not a placeholder test. ✓
- Test files mirror lib structure per `apps/mobile/CLAUDE.md §Testing` ("Test files mirror lib"). ✓
- `firebase/functions/test/` coverage gap covered by SEC TESTING-SEC-001; DO NOT re-log here.

### Repository pattern adherence — partial coverage
- 4 repos use `static const _xxx = 'collection_name'` (`FirebasePostRepository._posts`, `FirebaseConversationRepository._conversationsCol`, `FirebaseDiaryRepository._collection`, `FirebaseSpaceRepository._spacesCollection`) — GOOD pattern.
- 5 repos inline collection name strings — covered by CQ-005.
- 5 repos missing `_mapXxxError` per Pattern #2 — covered by ARCH-DATA-ARCH-001 (do NOT re-flag).
- Repositories that DO have `_mapXxxError` correctly:
  - `firebase_auth_repository.dart:50 _mapSignInError`, `_mapSignUpError`, `_mapGenericError` — canonical pattern
  - `firebase_diary_repository.dart:284 _mapFirestoreError`, `_mapStorageError`
  - `firebase_conversation_repository.dart:221 _mapFirestoreException`
  - `firebase_space_repository.dart:184 _mapFunctionsException`
  - `firebase_profile_repository.dart` — assumed clean (file not deep-read but profile/edit_profile_screen widget tests pass per inventory map).

### Freezed model pattern — uniform
- 12 data files all use `@freezed` + `@JsonSerializable` + `part 'x.freezed.dart'` + `part 'x.g.dart'`. Pattern uniform per `auth.md` Pattern #1. ✓
- Only divergence: `feed/data/post.dart` includes `const Post._();` (private constructor for `coverImageUrl` getter) — legitimate freezed pattern extension. ✓
- `feed_state.dart` has `DocumentSnapshot? lastDoc` Firestore-type leak — covered by ARCH-LAYER-003 (P1). DO NOT re-flag.

### Generated files — gitignored per repo policy
- `find lib -name "*.freezed.dart" -o -name "*.g.dart"` returns 0 hits in working tree.
- `.gitignore:58-59` excludes `**/*.g.dart` + `**/*.freezed.dart`. Auth.md drift covered by ARCH-004 (P3). DO NOT re-flag.

### Cross-module imports — covered by ARCH
- `streak/data/streak_repository.dart` imports `feed/data/post.dart`: ARCH-001 (P1)
- `chat/{application/chat_providers,data/chat_seed_data}.dart` imports `feed/data/post.dart`: ARCH-001
- `profile/application/{friend_posts,profile_posts}_provider.dart` imports `feed/data/post.dart`: ARCH-001
- `shared/widgets/post_card.dart` imports `feed/data/post.dart`: SHARED-001 + ARCH-001
- Other cross-module imports are via `auth_providers.dart` (currentUidProvider, currentUserProfileProvider) — canonical shared providers per `auth.md` Pattern #5. ✓

### Magic numbers — minor smell
- `firebase_post_repository.dart:60 _spaceFeedBuffer = 30`, `:156 _perAuthorBuffer = 20`, `apps/mobile/lib/features/feed/application/post_controller.dart:23-25` `_compressQuality = 85`, `_maxWidthPx = 1080`, `_maxSizeBytes = 1 MB`. All defined as `static const _xxx` with inline comment explaining choice — defensible.
- `caption_service_impl.dart:16 _geocodeCacheThresholdM = 100.0`, `:17 _timeoutSeconds = 5` — same pattern.
- `firebase/functions/src/settings/deleteAccount.ts:22 BATCH_LIMIT = 499` — defined as module const with comment. ✓

### Function name verb consistency — within repository OK
- `DiaryRepository`: `createEntry`, `watchEntries`, `getEntry`, `getPublicEntries`, `searchEntries`, `updateEntry`, `updatePrivacy`, `deleteEntry`, `reserveEntryId` — verbs distinct + action-aligned. ✓
- `FriendRepository`: `searchUser`, `watchFriends`, `getFriendUids`, `unfriend` — verbs aligned to operation type. ✓
- `NotificationRepository`: `saveFcmToken` (anti-term — covered CQ-011), `deleteFcmToken`, `getNotifications`, `markAsRead` — mostly OK.
- `ConversationRepository`: `watchConversations`, `watchMessages`, `getOrCreateConversation`, `sendMessage`, `markAsRead` — clear. ✓

### Cross-cutting themes (intentional skip per anti-duplicate rule)
- ARCH-LAYER-001/-002/-003 cover Firebase singleton usage in widgets + controllers + state. CQ does NOT re-flag.
- ARCH-DATA-ARCH-001 covers 5 repos missing `_mapXxxError` mapping. CQ confirmed 0 additional repos in the same boat (diary/space/conversation/auth all map correctly).
- ARCH-001 covers Post model cross-module coupling. CQ does NOT re-flag.
- ARCH-002 covers oversized widget files. CQ does NOT re-flag (different concern: file size vs internal duplication; CQ-002 timestamp dup is independent).
- SEC USER-SEC-001 fix migration will trigger CQ-005 path-constants update (`/users/{uid}/public/profile` subcollection adds new path). Pair the constants PR with USER-SEC-001 rollout step (c) — client repository refactor.
- SEC FUNC-SEC-001 covers zod `.strict()` polish — CQ does NOT re-flag.
- SEC CI-SEC-001 covers `pr-check.yml` rules-test fallback — CQ does NOT re-flag.
- ARCH-PUBSPEC-001 covers `sign_in_with_apple` unused dep — CQ does NOT re-flag.
- ARCH-CORE-001 covers duplicate `hex_color.dart` between `core/utils/` and `core/theme/`. CQ-002 (TimestampConverter dup) is independent — covers 12 model files, not 2 utility files.

### Async state ownership — clean
- All controllers with `StreamSubscription` paired with `ref.onDispose` cancel — verified for `space_controller`, `feed_controller`, `notification_controller`, `reaction_controller`, `friend_controller`, `diary_controller`, `chat_controller`. ✓
- Already noted in ARCH no_issue_notes pass_3_reverify. DO NOT re-flag.

### Validator pattern (`core/validators/`)
- Listed only; `auth_validators_test.dart` exists (per inventory map). Not deep-read.
- `auth_validators.dart` uses `static final RegExp _emailRegex = ...` per ARCH no_issue_notes — clean. ✓

### Shared widget API clarity (`shared/widgets/`)
- 22 files listed. Spot-checked: `app_primary_button.dart`, `app_text_input.dart`, `app_glass_surface.dart`, `app_avatar.dart`. Required vs optional params reasonable, no >5 named params explosion. ✓
- `post_card.dart` coupling to `Post` model: covered by SHARED-001 + ARCH-001.

### Notes — flagged for cross-audit awareness only (not standalone issues)
- `image_flip.dart` has 14 `debugPrint` STEP/DONE traces (covered in CQ-001) — also notable: file has comprehensive defensive `try-catch` returning null on every failure path (lines 24, 49, 56, 76, 100, 107) — over-defensive but not a bug. Cosmetic concern, not flagged.
- `caption_service_impl.dart` HTTP calls (open-meteo, nominatim) have 5s timeout + `User-Agent: Meep-App/1.0` header per nominatim policy — good citizen practice. Comment-only TODO `// TODO: link Streak module` (line 35) covered by CQ-007.
- `firebase_post_repository.dart._mergeStreams` (lines 224-257) custom stream merger — could use `rxdart.CombineLatestStream.list` but `rxdart` not in pubspec. Avoiding new dep is acceptable. Cosmetic concern, not flagged.
- `chat/data/conversation.dart` has `TimestampMapConverter` (lines 65-90) for `Map<String, DateTime>` field — distinct from `TimestampConverter` but reuses `_parseDate` logic identical to CQ-002 body. Recommend factoring `_parseDate` to share with single canonical `TimestampConverter` (CQ-002 fix).

## postcheck

- git_status_after:
  - `?? tmp/docs/ThienPDM/02-code-quality-audit` (pre-existing, untracked)
  - new file inside: `docs/audits/02_code_quality_audit.md`
- changed_files_after: `docs/audits/02_code_quality_audit.md` only
- unexpected_modified_files: none

## final_verdict

verdict: ready_with_polish

**Rationale:** CQ found 0 P0 issues (no release-blocker in code quality dimension — all P0s already covered by Phase A ARCH-LAYER-001/002 and SEC APPCHECK-001 / USER-SEC-001). 3 P1 issues (CQ-001 debugPrint flood, CQ-002 TimestampConverter dup, CQ-014 Firebase error-mapper dup) are maintenance/cost concerns that DO NOT block M3 ship but should fix before scaling chat/feed beyond MVP. 6 P2 + 5 P3 are polish.

**Recommended path:**
1. Fix Phase A P0 + P1 (covered by ARCH PR #293 + SEC PR #294 follow-ups) — pre-M3 must-fix.
2. CQ batch_2 (CQ-014 FIRST → CQ-002 → CQ-001) — CQ-014 must precede ARCH-DATA-ARCH-001 to avoid creating 5 new error-mapper copies in feed/friend/reaction/notification/storage repos.
3. CQ batch_3 (P2) — distribute across 2 sprints post-M3.
4. CQ batch_4 (P3) — opportunistic cleanup PRs.

**Distribution:** P0=0, P1=3, P2=6, P3=5 — total 14 issues.

## self_verification_log

<!-- 4 passes recorded after first draft per audit prompt. -->

pass_1_checklist: N=15 sub-sections (~75 line items in `## Audit Checklist`), M=13 issues, K=15 no_issue_notes mappings (each checklist sub-section sub-mapped to ≥1 issue or note), gap=0 — each prompt sub-section sub-mapped: Naming clarity → CQ-011 + no_issue (anti-terms clean, verbs OK); Dead code → CQ-010 (unused stub) + no_issue (no commented-blocks, all providers wired, deps OK); Duplicated logic → CQ-002 + no_issue (covered ARCH-CORE-001 for hex_color, ARCH-DATA-ARCH-001 for repo error mapping); Oversized → CQ-013 (test files > 500 lines) + no_issue (covered ARCH-002 for lib files); Misleading comments → CQ-012 + CQ-007; Production TODO/FIXME → CQ-007 + no_issue (0 FIXME/HACK); Error handling consistency → no_issue (covered ARCH-DATA-ARCH-001, repo error mapping clean for non-flagged 5); Type strictness → no_issue (TS clean, Dart dynamic boundary-only); Import hygiene → no_issue (clean — all package: imports); Abstraction quality → no_issue (interfaces 1-impl pattern is correct per Meep solo-dev); Model/freezed/repository consistency → CQ-002 + no_issue (uniform); Validators → no_issue (auth_validators tested); Shared widget API → no_issue (clean); Magic strings/numbers → CQ-003 + CQ-004 + CQ-005; Test quality → CQ-013 + no_issue (good content); TS Functions style → CQ-008 + CQ-009 + no_issue (strict mode OK); Unused/risky dep → no_issue (covered ARCH-PUBSPEC-001); Dart logging → CQ-001; Async timing → CQ-006; TS logging → CQ-008 + CQ-009.

pass_2_schema: total=13, missing_field_fixed=0 (every issue has sev/blocker/area/files/loc/symbols/evidence/risk/fix/authority/test/deps), severity_demoted=0 (initial draft severities held after re-verify), evidence_failed_grep=0 — re-grep all 13 evidence quotes:
- CQ-001: `debugPrint(` count 57 confirmed via `rg "debugPrint(" apps/mobile/lib --count-matches`; `firebase_post_repository.dart:40` text confirmed; `feed_filter_controller.dart:52` text confirmed; `analysis_options.yaml:30` `avoid_print: true` confirmed.
- CQ-002: 12 `class TimestampConverter` confirmed via Grep count; null-tolerance divergence verified by reading `friend_request.dart:33-38` vs `post.dart:59-63`.
- CQ-003: 39 files with `Color(0x` confirmed via Grep file count; `profile_screen.dart:17-25` block + line 390/397 TODOs confirmed.
- CQ-004: 14 files with `TextStyle(fontSize:` confirmed via Grep count.
- CQ-005: 16 hits mobile + 46 functions confirmed via Grep count; `firebase_friend_request_repository.dart:17,37,70,78,95,103` (6× 'friend_requests') confirmed.
- CQ-006: 4 `Future.delayed` callsites confirmed; `feed_section.dart:370` + `friend_sheet.dart:71` + `signup_username_page.dart:90` + `reset_password_page.dart:54` line numbers verified.
- CQ-007: 28 unique TODOs across 16 files counted via direct read of Grep results.
- CQ-008: 9 `[CHAT-DEBUG]` callsites in `onMessageCreated.ts` confirmed via re-reading file.
- CQ-009: 1 `console.warn` at `onFriendshipDeleted.ts:25` confirmed; cross-file `rg "console\." firebase/functions/src` returns this single hit.
- CQ-010: `index.ts:30-58` re-read confirms stub + TODO + no-op return.
- CQ-011: `notification_repository.dart:5` + `firebase_notification_repository.dart:28` + `diary_controller.dart:112` confirmed; `CLAUDE.md §Anti-terms` table confirmed.
- CQ-012: `settings_controller.dart:84-88,139-142` confirmed; `main.dart:119-121` notif wire confirmed; `firebase_notification_repository.dart:46-54` deleteFcmToken impl confirmed.
- CQ-013: 4 test files > 500 lines confirmed via `find apps/mobile/test -name "*.dart" -exec wc -l {} \;` sort: space_controller_test.dart 722, diary_controller_test.dart 587, firebase_conversation_repository_test.dart 532, firebase_diary_repository_test.dart 501.

pass_3_dedupe: before=13, after=13, consolidations=0 — verified no two issues share files[0]+symbols+root_cause+fix:
- CQ-003 (hex Color) vs CQ-004 (TextStyle fontSize) — same root cause (theme tokens not used) BUT distinct files[0] (CQ-003 39 files, CQ-004 14 files with partial overlap in 8 files). Fix steps distinct (CQ-003 → AppColors, CQ-004 → AppTextStyles). Kept separate; cross-linked in batch_3.
- CQ-007 (TODO format) vs CQ-012 (stale comment in settings_controller) — both about comment quality but distinct concerns. CQ-007 is format violation across 16 files; CQ-012 is stale FACTUAL content (comment lies about runtime). Kept separate.
- CQ-001 (debugPrint Dart) vs CQ-008 (CHAT-DEBUG Functions) vs CQ-009 (console.warn Functions) — all logging concerns but distinct languages + files + fix patterns. CQ-001 is mobile Dart wide cleanup; CQ-008 is single-file Functions cleanup; CQ-009 is 1-line console→logger swap. Kept separate per severity calibration.
- CQ-005 (Firestore paths) — single root cause spanning 5 mobile repos + 13 functions files. Already consolidated as 1 issue with bundled fix.
- CQ-013 (test files > 500 lines) vs ARCH-002 (lib files > 300 lines) — different file scope (test/ vs lib/). ARCH-002 explicitly excludes test files (uses `find apps/mobile/lib`). Prompt §Oversized constructs item "Test file > 500 lines" is a separate checklist item. Kept distinct.

pass_4_coverage: checked=24, partial=7, blocked=2, total=33, verdict=full — coverage matches log evidence. `checked`: core/error, core/config, features/{auth,chat,diary,feed,friend,home,notification,profile,reaction,settings,space,widget}, main.dart, firebase/functions/src/* (12 ts files re-read), pubspec.yaml, tsconfig.json, analysis_options.yaml, .gitignore, test inventory (80 files counted), shared/widgets (5 sampled). `partial`: core/theme (hex_color covered ARCH-CORE-001, theme tokens listed via Grep only), core/validators (listed only, auth_validators tested per inventory), core/utils (pair_id + hex_color listed), features/streak (sampled streak_repository.dart only), features/space (firebase_space_repository read, space_controller read, but presentation widgets only sampled), shared/widgets (22 files Glob-listed, 5 deep-read), firebase/functions/test (file list known, not deep-read — covered SEC TESTING-SEC-001). `blocked`: `flutter analyze --no-pub` + `npm run lint` (audit-only constraint forbids running; recorded in commands table). Verdict full because every "checked" area backed by Read tool evidence + Grep evidence in commands table; "partial" entries have explicit justification (covered by Phase A or out-of-scope-for-CQ).

pass_5_coverage_gap_deep_dive (post-PR reverify per user request — "đảm bảo không bỏ sót gì"):
- READ DEEP: `core/validators/auth_validators.dart` (49 lines) full — `static final _emailRegex` + `_usernameRegex` + 4 `bool isXxxValid()` methods. All uniform return type. No Vietnamese message (UI builds messages from bool flags). `auth_validators_test.dart` exists per inventory. ✓ no_issue confirmed.
- READ DEEP: `core/theme/app_colors.dart` (66 lines) — 60+ Color tokens in 8 groups (turquoise/bw/success/error/warning/info + 3 specials). bw900 = `Color(0xFF050F10)` — **CONFIRMED** matches `profile_screen.dart:22 const _cBg = Color(0xFF050F10); // Black & White/900` exactly. CQ-003 fix is straightforward — most "missing tokens" already exist in AppColors but devs hardcoded the same hex value. Reinforces CQ-003.
- READ DEEP: `core/theme/app_text_styles.dart` (107 lines) — 17 typed tokens xs/sm/base/md/lg/xl/xl2/xl3 × regular/medium/semiBold/bold. `baseBold` (line 51-56) = `TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700, height: 24/18)` — **CONFIRMED** matches `edit_profile_screen.dart:450-456` hardcoded inline byte-for-byte. CQ-004 fix even more obvious — token already exists.
- READ DEEP: `core/theme/app_theme.dart` (45 lines) — Material 3 `ColorScheme.fromSeed(seedColor: 0xFFE85D75)` for both light + dark themes wired in `main.dart:259`. Both define `scaffoldBackgroundColor: AppColors.bw900` — meaning dark theme is ALREADY dark; light theme is dark too (intentional Locket-style dark UI). Observation: no light-theme fork. Not an issue.
- READ DEEP: `core/theme/{app_proportions.dart,app_radii.dart,app_spacing.dart}` — AppProportions 100+ lines of Figma-driven scaling math, well-documented. AppRadii has 4 tokens (sm/md/circle/pill). AppSpacing has 7 tokens (xs..xxl + screenHorizontal). All proper abstract final classes.
- READ DEEP: 5 more `shared/widgets/` files: `app_primary_button.dart` (78), `app_avatar.dart` (193), `app_text_input.dart` (208), `app_confirm_dialog.dart` (113), `app_taskbar.dart` (244). All use AppColors/AppTextStyles/AppRadii properly. `app_taskbar.dart` defines its own file-private `_Const` class for taskbar-specific constants (animDuration/ringSize/pillRadius) — appropriate widget-scoped pattern.
- READ DEEP: `firebase/functions/src/index.test.ts` (28 lines) — 4 tests for `sendFriendRequestSchema` (the stub). If CQ-010 accepted (delete stub), this test becomes ORPHAN. Note added to CQ-010 fix step.
- FACT NEW (CQ-003 evidence boost): `app_text_input.dart:55, 184` has `const Color(0x80FFFFFF)` (50% white alpha) hardcoded with comment "Figma: password hint/icon dùng white 50%" — already in CQ-003's 39-file list, but specific siteworth noting as deep-grep-confirmed.
- FACT NEW (CQ-005 evidence boost): `firebase_user_repository.dart:13,16,21,24,32,38,46` uses `_firestore.doc('users/${profile.uid}')` template-string pattern (not `.collection('users')`) — STILL hardcoded `'users/'` literal. Adds 5 sites to CQ-005 file list. Should bundle into Firestore path constants fix.
- COVERAGE UPGRADE: partial → checked for core/theme (full read 5 files), core/validators (full read), shared/widgets (10/22 files deep-read, 12 listed-only). Updated pass_4 coverage stats below.

pass_6_cf_repo_pattern_verify:
- VERIFY: 19 CFs all declare `region: 'asia-southeast1'` explicitly. `index.ts:17 setGlobalOptions({ region: 'asia-southeast1', maxInstances: 10, timeoutSeconds: 60 })` sets global too. **Region declared 2× per CF (global + per-CF)** — defensible defensive pattern (per-CF overrides global), but technically redundant. Not P-level issue; cosmetic.
- VERIFY: Resource configs — only `deleteAccount.ts:144-145` overrides `timeoutSeconds: 540, memory: '512MiB'` (justified by cascade workload). Others rely on global 60s/256MiB defaults. ✓ no_issue.
- VERIFY: Repository naming uniformity across 7 abstract interfaces (auth/chat/diary/feed/friend/notification/profile/reaction/settings/space/streak). Verbs: `watchX` for streams, `getX`/`createX`/`updateX`/`deleteX` for one-shots, `upsertX` for create-or-update, `getOrCreateX` for combined op, `reserveEntryId` for ID reservation, `markAsRead` for state transition. Consistent across modules. Anti-term `saveFcmToken` + `saveEntry` already in CQ-011.
- VERIFY: 26 enum declarations counted — all in appropriate locations (data models or local file-private `_XxxMode`). Naming uniform. ✓ no_issue.
- NO NEW ISSUE after pass-6.

pass_7_hidden_duplication_scan:
- **FACT NEW (CQ-014 P1 added):** `_mapFunctionsException(FirebaseFunctionsException, String action)` IDENTICAL byte-for-byte between `firebase_block_repository.dart:127-167` and `firebase_space_repository.dart:184-222`. Comment at `block:125` self-admits "Pattern theo `firebase_space_repository.dart`".
- **FACT NEW (CQ-014):** `_mapFirestoreException(FirebaseException, String action)` IDENTICAL byte-for-byte between `firebase_conversation_repository.dart:221-251` and `firebase_block_repository.dart:96-124`.
- **FACT NEW (CQ-014):** `_mapFirestoreError(FirebaseException)` near-identical between `firebase_diary_repository.dart:284-296`, `firebase_profile_repository.dart:165-178`, `firebase_streak_repository.dart:84-95` (differ only in fixed action string passed to AppError ctor).
- **FACT NEW (CQ-014):** `_mapStorageError(FirebaseException)` near-identical between `firebase_diary_repository.dart:298-313` and `firebase_profile_repository.dart:180-200` (slight code overlap).
- ARCH-DATA-ARCH-001 covers 5 repos MISSING this pattern (feed/storage/friend/reaction/notification). CQ-014 covers 5+ repos that HAVE this pattern but DUPLICATED. Both findings co-exist. CQ-014 must be done FIRST so ARCH-DATA-ARCH-001 wave doesn't create 5 new copies.
- 13 hits of `DateTime.fromMillisecondsSinceEpoch(json as int)` confirmed (12 TimestampConverter + 1 TimestampMapConverter `_parseDate`). CQ-002 evidence reinforced.
- COUNT UPDATE: 13 → 14 issues. Distribution: P0=0, P1=3 (added CQ-014), P2=6, P3=5.

pass_8_magic_numbers_duration:
- VERIFY: 57 `Duration(seconds: |Duration(milliseconds:` callsites across lib/. Sample 30 — all are animation timing (200/220/250/300ms standard), debounce timers (300/500ms), or timeout (5s for network). Pattern uniform.
- OBSERVATION: 2 different debounce values for similar use cases — `signup_username_page.dart:42 _debounceDuration = Duration(milliseconds: 500)` vs `diary_search_screen.dart:41 _debounceDuration = Duration(milliseconds: 300)`. Not a CQ-worthy issue (different UX contexts), but worth flagging in note.
- VERIFY: Magic numbers in repos all properly `static const _xxx = value;` with explanatory comment (e.g. `firebase_post_repository.dart:60 _spaceFeedBuffer = 30`). ✓ no_issue confirmed.
- NO NEW ISSUE after pass-8.

pass_9_async_signature_drift:
- VERIFY: `.then(` chains in TS Functions = 0 hits. All async/await. ✓ no_issue.
- VERIFY: `unawaited()` pattern uniform — 13+ callsites + 2 `// ignore: unawaited_futures` (both intentional fire-and-forget in `diary_canvas_screen.dart:402,409`). All wrapped in `mounted` guard or `try-catch`. ✓
- **FACT NEW (CQ-010 evidence boost):** Mobile `firebase_friend_request_repository.dart:55 sendFriendRequest({required String senderUid, required String receiverUid})` vs CF stub `firebase/functions/src/index.ts:24 sendFriendRequestSchema = z.object({ toUid: z.string()... })`. **Signature drift:** CF expects `{toUid}` (1 param), mobile uses `{senderUid, receiverUid}` (2 params). If anyone wires the CF call, mobile would have to translate. Adds emphasis to CQ-010 risk that stub is even more deeply orphan (not just unused — incompatible with mobile shape). Updated CQ-010 evidence.
- VERIFY: `Future.wait` for stream subscription cleanup at `firebase_post_repository.dart:255` + diary at 355 — idiomatic. ✓
- NO NEW ISSUE after pass-9.

pass_10_final_evidence_crosscheck:
- VERIFY all 14 issue evidence quotes against actual source via Bash grep + sed:
  - CQ-014 NEW: paired `sed -n '127,167p' firebase_block_repository.dart` + `sed -n '184,222p' firebase_space_repository.dart` — byte-for-byte identical bodies confirmed.
  - CQ-001: 57 debugPrints across 9 files counted via `rg "debugPrint(" apps/mobile/lib --count-matches` → matches.
  - CQ-002: `rg "class TimestampConverter"` returns 12 hits; `rg "DateTime.fromMillisecondsSinceEpoch"` returns 13 hits (12 + 1 inside TimestampMapConverter).
  - CQ-003: 39 files via `rg -l "Color\(0x" apps/mobile/lib --include="*.dart"` re-confirmed.
  - CQ-004: 14 files via `rg -l "TextStyle\(fontSize:" apps/mobile/lib/features` re-confirmed.
  - CQ-005: 16 mobile + 46 functions = 62 hardcoded collection names re-confirmed. Adds `firebase_user_repository.dart` 5 sites to mobile list (template-string `users/` literals).
  - CQ-006: 4 callsites re-confirmed.
  - CQ-007: 28 TODOs across 16 files re-confirmed.
  - CQ-008: 9 `[CHAT-DEBUG]` callsites re-confirmed.
  - CQ-009: 1 `console.warn` re-confirmed (cross-file grep returns this single hit).
  - CQ-010: `index.ts:30-58` re-read confirms stub; signature drift `{toUid}` vs `{senderUid, receiverUid}` noted.
  - CQ-011: 2 `save*` callsites (`saveFcmToken`, `saveEntry`) re-confirmed.
  - CQ-012: stale comment `notificationRepositoryProvider throws UnimplementedError` × 2 in `settings_controller.dart:84-88, 139-142` re-confirmed; reality wire in `main.dart:119-121` re-confirmed.
  - CQ-013: 4 test files >500 lines re-confirmed.
- COUNT FINAL: 14 issues. Distribution: P0=0, P1=3 (CQ-001/-002/-014), P2=6 (CQ-003/-004/-005/-006/-007/-008), P3=5 (CQ-009/-010/-011/-012/-013).
- COVERAGE UPGRADE post-pass-5: checked=29 (added 5 deep-read files), partial=4 (reduced from 7 — core/theme, core/validators now fully read; remaining: features/streak deep, features/space deep, shared/widgets 12 listed-only, firebase/functions/test). Verdict still full per "every checked area backed by evidence" criterion.
- VERDICT confirm: ready_with_polish. CQ-014 added as P1 doesn't escalate verdict — no P0 release blocker created.
