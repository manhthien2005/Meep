# 06_testing_ci_release_audit

## meta

- repo: Meep
- root: D:/meep-audit-06-test
- branch: docs/ThienPDM/06-testing-ci-release-audit
- date: 2026-06-08
- mode: audit-only
- audit_focus: testing_ci_release
- modified_files_allowed:
  - docs/audits/06_testing_ci_release_audit.md
- read_baseline:
  - docs/audits/00_inventory_map.md
  - docs/audits/A_PHASE_BASELINE_SUMMARY.md
  - docs/audits/01_architecture_audit.md
  - docs/audits/05_security_firebase_audit.md
  - CLAUDE.md (root) — §Testing & Verification, §Verification Before Claiming Done
  - apps/mobile/CLAUDE.md — §Testing, §Common gotchas
  - firebase/CLAUDE.md — §Pre-deploy checklist
  - firebase/functions/CLAUDE.md — §Testing, §Cloud Functions v2 specifics
  - .claude/reference-architectures/auth.md — Pattern #10 Test stratification

## precheck

- git_status_before: `?? tmp/docs/ThienPDM/06-testing-ci-release-audit` (audit staging — expected per inventory map)
- existing_user_changes: no (baseline matches inventory map — fresh worktree, no `M apps/mobile/pubspec.lock`)
- target_report_preexisting_dirty: no (file did not exist before this run)

## commands

| cmd | status | notes |
|---|---:|---|
| `git rev-parse --show-toplevel` | ok | `D:/meep-audit-06-test` |
| `git status --short` | ok | only `?? tmp/...` |
| `git branch --show-current` | ok | `docs/ThienPDM/06-testing-ci-release-audit` |
| `git ls-files apps/mobile/test/**` | ok | 80 test files |
| `git ls-files apps/mobile/integration_test/**` | ok | ZERO files — folder missing |
| `git ls-files firebase/functions/**` | ok | 4 src/-co-located + 20 test/-folder = 24 test files |
| `git ls-files .github/**` | ok | 3 workflows (pr-check, develop-staging, deploy-production) |
| Read all 3 workflows | ok | full read |
| Read `apps/mobile/android/app/build.gradle.kts` | ok | full 81-line read |
| Read `apps/mobile/android/app/src/main/AndroidManifest.xml` | ok | full read |
| Read `apps/mobile/pubspec.yaml` | ok | full read |
| Read `firebase/functions/package.json` + `vitest.config.ts` + `vitest.rules.config.ts` | ok | scripts + config verified |
| Read `firebase/firebase.json` | ok | predeploy hooks present |
| Read `docs/setup.md` + `docs/team-workflow.md` + `docs/milestones/README.md` + `docs/roadmap/milestones.md` | ok | release-relevant sections |
| grep `kDebugMode\|useEmulator\|USE_EMULATOR` `apps/mobile/lib/main.dart` | ok | emulator gated by `--dart-define=USE_EMULATOR` |
| grep `Crashlytics\|FlutterError.onError\|recordError\|appCheck` `apps/mobile/lib` | ok | 0 hits → CRASHLYTICS-001 + cross-ref SEC APPCHECK-001 |
| grep `expect(true).toBe(true)\|placeholder` firebase/functions | ok | 5 placeholder asserts in 2 files |
| grep `verify(\|verifyNever` apps/mobile/test | ok | 0 mockito-style verify hits (codebase uses fake_cloud_firestore + mocktail intent-driven) |
| grep `skip:\|xtest\|expect(true, true)` apps/mobile/test | ok | 0 hits |
| grep `proguard\|isMinifyEnabled\|isShrinkResources` apps/mobile/android | ok | 0 hits → REL-MINIFY-001 |
| grep `RECEIVE_BOOT_COMPLETED\|POST_NOTIFICATIONS` apps/mobile/android | ok | 0 hits — covered by SEC PERM-001 |
| `flutter analyze` | blocked | audit-only constraint; static evidence sufficient |
| `flutter test` | blocked | audit-only constraint; static enumerate via `git ls-files` |
| `npm test` (firebase/functions) | blocked | audit-only constraint |

## coverage

- unit tests (repositories) — Flutter: checked (13/14 firebase_*_repository.dart files mirror-tested; ONLY `firebase_storage_repository.dart` missing test → UNIT-001)
- unit tests (controllers) — Flutter: checked (11/16 controllers tested; missing tests for `post_controller.dart`, `feed_controller.dart`, `app_camera_controller.dart` → CTRL-TEST-001; `password_reset_controller.dart` covered)
- widget tests (critical screens) — Flutter: checked (auth pages 0 widget tests; feed `home_screen.dart`/`feed_section.dart`/`capture_preview_screen.dart`/`camera_section.dart` 0 widget tests; settings sheet + reaction sheets + space sheets + chat inbox + profile screen DO have widget tests → WIDGET-TEST-001 for critical pages gap)
- integration tests (golden path) — Flutter: blocked-by-design (folder `apps/mobile/integration_test/` does NOT exist despite `integration_test: { sdk: flutter }` in `pubspec.yaml:68`. ZERO E2E coverage → E2E-001)
- functions unit tests — TypeScript: checked (24 vitest files; 11/22 src files have direct test, 11 covered indirectly via rules tests + helpers; idempotency NOT tested → FUNC-TEST-001)
- functions rules tests — TypeScript: checked (10 rules-test files = 8 collection-specific + 2 storage; coverage breadth high; CHAT-SEC-002/REACTION-SEC-001 fix-impact areas tested per SEC TESTING-SEC-001; 1 placeholder file `test/feed/feed.rules.test.ts` uses `expect(true).toBe(true)` → TEST-QUALITY-001)
- CI mobile pipeline: checked (`pr-check.yml:62-98` runs `pub get` → codegen → `dart format` → `flutter analyze --fatal-infos` → `flutter test --coverage`; Flutter 3.41.4 pinned; cache enabled; **NO integration_test step** → CI-MOBILE-001; **NO Java install** despite Android Flutter test deps → CI-MOBILE-002)
- CI functions pipeline: checked (`pr-check.yml:100-125` runs `npm ci` → lint → typecheck (fallback `tsc --noEmit`) → `npm test`; Node 20 pinned; cache enabled — clean. Coverage NOT collected → CI-FUNC-001)
- CI rules pipeline: checked (`pr-check.yml:127-160` runs emulator + `npm run test:rules`; **fallback `|| echo ::warning::` silently passes when script fails** — covered by SEC CI-SEC-001)
- release config: checked (debug signingConfig in release build — covered by inventory map note + SIGN-001 here; AAB build present in `deploy-production.yml:88`; **NO `minifyEnabled`/`shrinkResources`/`proguardFiles` set** → REL-MINIFY-001)
- secrets / signing: checked (CI uses `${{ secrets.X }}` masking; keystore via `ANDROID_KEYSTORE_BASE64`; deploy gated by GitHub Environment `production`; `if: false` gate explicit on prod jobs — clean)
- versioning: checked (`build.gradle.kts:34-35` uses `flutter.versionCode`/`flutter.versionName` from `pubspec.yaml:4 version: 0.1.0+1` — manual bump. `deploy-production.yml:161-171` auto-increments PATCH from latest git tag if no `workflow_dispatch.inputs.version` — split source-of-truth → REL-VERSION-001)
- Android Kotlin tests: checked (`WidgetSyncWorkerTest.kt` 15.2KB exists — single test file, junit4 + Robolectric + Mockk; build.gradle wires test deps but **CI does NOT run `./gradlew test`** → CI-MOBILE-003)
- codegen freshness: checked (`.gitignore:58-59` lists `**/*.g.dart` + `**/*.freezed.dart` so gen files NOT committed; `pr-check.yml:81` runs `build_runner build --delete-conflicting-outputs` before test — clean. Covered by ARCH-004 doc drift, NOT a CI gap)
- release docs: partial (no `docs/release.md`/pre-launch checklist exists; `docs/milestones/README.md` documents milestone format but `docs/milestones/` has 0 actual reports per inventory; `docs/setup.md` covers dev environment but not release sign-off → DOCS-REL-001)
- branch protection: blocked (not verifiable from repo state — GitHub repo settings out of audit scope. Confirmed via `docs/team-workflow.md §6` documented intent. NOTE-only, not a flagged gap)

## blockers_summary

| id | sev | area | files | short |
|---|---|---|---|---|
| E2E-001 | P0 | test gap | `apps/mobile/integration_test/` (missing) | CLAUDE.md mandates "Integration test for login + post + feed loop minimum" — ZERO E2E files exist despite `integration_test` dep wired |
| SIGN-001 | P0 | release readiness | `apps/mobile/android/app/build.gradle.kts:42` | Release build signs with `debug` keystore — Play Store reject; production APK indistinguishable from dev build |
| CTRL-TEST-001 | P1 | test gap | `feed/application/{post_controller,feed_controller,app_camera_controller}.dart` | 3 critical Feed controllers with 0 unit tests (post submit, feed pagination, camera capture) — golden-path coverage blocked |
| WIDGET-TEST-001 | P1 | test gap | `feed/presentation/{home_screen,feed_section,capture_preview_screen,camera_section}.dart` + `auth/presentation/login/*.dart` | Critical user-facing screens have 0 widget tests; auth pages (5 screens) only controller-tested |
| REL-MINIFY-001 | P1 | release readiness | `apps/mobile/android/app/build.gradle.kts:38-43` | Release buildType missing `isMinifyEnabled = true` + `isShrinkResources = true` + ProGuard rules — APK size unoptimized, no R8 protection for Firebase/Riverpod reflection |
| CRASHLYTICS-001 | P1 | release readiness | `apps/mobile/lib/main.dart:53-60` | `firebase_crashlytics` dep listed in pubspec but `FlutterError.onError` + `FirebaseCrashlytics.recordError` NOT wired — production crashes silently lost |
| FUNC-TEST-001 | P1 | test gap | `firebase/functions/test/{friend/onFriendshipDeleted,feed/feed.rules}.test.ts` | 2 placeholder test files use `expect(true).toBe(true)` instead of real assertions — false CI green |
| CI-MOBILE-001 | P1 | CI gap | `.github/workflows/pr-check.yml:62-98` | CI does NOT execute integration_test — even when E2E-001 fixed, no automation. Tied to E2E-001 |

## issues

### ISSUE E2E-001

- sev: P0
- blocker: yes
- area: test gap — integration tests (golden path)
- files:
  - `apps/mobile/integration_test/` (folder missing)
  - `apps/mobile/pubspec.yaml:68-69` (`integration_test: sdk: flutter` declared)
- loc: missing
- symbols:
  - `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` (not present anywhere in apps/mobile)
- evidence: `git ls-files apps/mobile/integration_test/**` returns ZERO files; `grep -rln "integration_test\|IntegrationTestWidgetsFlutterBinding" apps/mobile/` returns only `pubspec.lock` + `pubspec.yaml` + `README.md` — NO actual integration test source.
- confidence_impact: CI green can ship a build where login → camera → post → feed loop is structurally broken. No automated regression detection for the 4-screen happy path which is the entire MVP differentiator.
- risk: launch blocker — `apps/mobile/CLAUDE.md §Testing` explicitly mandates "Integration test for login + post + feed loop minimum". Without E2E, every cross-module wiring break (auth provider override, router redirect, FCM permission flow) only surfaces when QA does manual testing — which 4 student devs do not have bandwidth for in M3 (28/5 → 9/6, only 12 days). Cross-ref ARCH LAYER-001/-002 — feed widget tests are structurally blocked by Firebase singleton leak, so E2E is the ONLY way to verify feed render today.
- fix: scaffold `apps/mobile/integration_test/` with 3 baseline scenarios (in this order):
  1. `app_test.dart` — sign-in flow E2E (intro → signup_email → signup_password → signup_name → signup_username → home screen rendered). Use `FirebaseAuthMocks` + `FakeFirebaseFirestore` overrides per `auth.md` Pattern #5 + `apps/mobile/CLAUDE.md §Testing` "prefer FakeFirebaseFirestore over MockFirestore".
  2. `post_flow_test.dart` — take + share post E2E (assume signed-in via test setup, navigate camera → capture → caption → submit → verify feed contains new post).
  3. `feed_react_test.dart` — feed load + react E2E (seed FakeFirebaseFirestore with 2 friend posts, render feed, tap reaction, verify reaction count increments).
- authority: `apps/mobile/CLAUDE.md §Testing` "Integration test for login + post + feed loop minimum" + `flutter-add-integration-test` skill (project-local) + `auth.md` Pattern #10 layer "UI Widget"
- test: after scaffold, `(cd apps/mobile && flutter test integration_test/app_test.dart -d <device>)` — 1 green run on Android emulator; wire CI per CI-MOBILE-001
- deps: blocks WIDGET-TEST-001 (auth pages remain testable in isolation but golden path needs E2E); blocked-by ARCH LAYER-001/-002 (only for `feed_react_test.dart` because feed widget today reads `FirebaseAuth.instance` direct — work around by overriding `currentUidProvider` until ARCH fix lands)

### ISSUE SIGN-001

- sev: P0
- blocker: yes
- area: release readiness — Android signing
- files:
  - `apps/mobile/android/app/build.gradle.kts`
- loc: 38-43
- symbols:
  - `buildTypes.release.signingConfig`
- evidence:
  ```kotlin
  buildTypes {
      release {
          // TODO: Add your own signing config for the release build.
          // Signing with the debug keys for now, so `flutter run --release` works.
          signingConfig = signingConfigs.getByName("debug")
      }
  }
  ```
- confidence_impact: any `flutter build apk --release` or `flutter build appbundle --release` produces an APK/AAB signed with the **shared debug keystore** (Android SDK default `~/.android/debug.keystore`). Play Store will reject; if pushed to a device sideload it has no upgrade-path identity. CI deploy-production.yml:75-83 DOES decode a real keystore from GitHub Secrets and writes `android/key.properties`, but `build.gradle.kts` never reads `key.properties` → CI keystore work is ineffective dead-letter.
- risk: launch blocker. Two cascading consequences: (1) Production APK identifies as the Android debug-signing global identity → upgrade collision with any other dev's APK + no Play Store acceptance. (2) `.well-known/assetlinks.json` (committed at `firebase/public/.well-known/assetlinks.json`) pins a SHA256 fingerprint for `dev.meep.meep` — if release ships with debug signing, autoVerify deeplink fails on release build (covered by SEC pass-7 note re: assetlinks single fingerprint). Inventory map flags this as P1; promote to P0 because debug-keystore release ship is functionally a Play Store reject (not a polish gap).
- fix: 2-step:
  1. Add release `signingConfigs` block reading from `key.properties` (CI already writes this file at `deploy-production.yml:78-83`). Pattern:
     ```kotlin
     val keyProps = java.util.Properties()
     val keyPropsFile = rootProject.file("key.properties")
     if (keyPropsFile.exists()) keyProps.load(keyPropsFile.inputStream())

     android {
         signingConfigs {
             create("release") {
                 storeFile = keyPropsFile.exists() ? file(keyProps.getProperty("storeFile")) : null
                 storePassword = keyProps.getProperty("storePassword")
                 keyAlias = keyProps.getProperty("keyAlias")
                 keyPassword = keyProps.getProperty("keyPassword")
             }
         }
         buildTypes {
             release {
                 signingConfig = if (keyPropsFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
             }
         }
     }
     ```
  2. Generate dev keystore for local `flutter build apk --release` smoke test, document path in `docs/setup.md §1` table.
  3. Document SHA256 fingerprint regeneration step in `docs/release.md` (DOCS-REL-001) so production-keystore fingerprint can be added to `firebase/public/.well-known/assetlinks.json` before M3 ship.
- authority: inventory map `## android_native` ⚠️ note + `CLAUDE.md §Security Guardrails` "Production deploy cần `assetlinks.json` + custom domain (xem ADR-0005)" + `deploy-production.yml:75-83` (CI infrastructure already prepared)
- test: after fix, run `(cd apps/mobile && flutter build apk --release)` locally; verify `apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk` returns release fingerprint (not debug). CI smoke: workflow_dispatch with `version: v0.0.1-test` → expect job `build-flutter-release` to succeed once `if: false` lifted.
- deps: REL-MINIFY-001 (touches same `buildTypes.release` block — bundle both fixes one PR); DOCS-REL-001 (release runbook needs fingerprint regen step)

### ISSUE CTRL-TEST-001

- sev: P1
- blocker: no
- area: test gap — Feed application layer
- files:
  - `apps/mobile/lib/features/feed/application/post_controller.dart` (313 lines)
  - `apps/mobile/lib/features/feed/application/feed_controller.dart` (166 lines)
  - `apps/mobile/lib/features/feed/application/app_camera_controller.dart` (302 lines)
- loc: missing tests at `test/features/feed/application/{post_controller_test.dart, feed_controller_test.dart, app_camera_controller_test.dart}`
- symbols:
  - `PostController.submit`, `PostController._errorMessage`
  - `FeedController.build`, `FeedController.loadMore`
  - `AppCameraController.initialize`, `AppCameraController.capture`
- evidence: `find apps/mobile/test/features/feed -name "*_controller_test.dart"` returns ONLY `feed_filter_controller_test.dart`. Feed module has 4 controllers in lib/, only 1 controller test exists. Other modules ship controller tests beside controllers (auth: 3/3, chat: 1/1, diary: 1/1, friend: 1/1, notification: 1/1, profile: 1/1, reaction: 1/1, settings: 1/1, space: 1/1, streak: 1/1) — Feed is the SOLE module skipping controller tests for its 3 production controllers.
- confidence_impact: PostController.submit is the entire P0 user-action of the app (share photo). FeedController is the read side. No automated check that submit short-circuits on null uid, that error mapping produces VN copy, that pagination cursor advances. Combined with E2E-001 = zero coverage on Feed flow. Combined with ARCH LAYER-002 (Firebase direct in controller) — adding tests today requires DI refactor first, so test gap is also a *consequence* of unmitigated architecture debt, not just laziness.
- risk: regression vector — any change to Feed during M3 sprint (28/5 → 9/6) has no safety net. `feed_controller.dart` already has 7 ARCH issues logged (LAYER-001/-002/-003, FEED-ARCH-001/-002, ARCH-002 split, ARCH-001 Post entity move) — every one of those refactors needs tests to land safely. Without controller tests, refactor is high-risk + leader will need to manually QA each change.
- fix: write 3 controller test files mirroring `test/features/auth/application/login_controller_test.dart` pattern:
  1. `test/features/feed/application/post_controller_test.dart` — covers `submit` happy (with FakeFirebaseFirestore + MockFirebaseAuth via `currentUidProvider.overrideWith`), submit when `currentUidProvider` is null (expect early-return + `UnauthenticatedError`), submit when repo throws `FirebaseException(code: 'permission-denied')` → expect `errorMessage` rendered VN, `clearError` resets state.
  2. `test/features/feed/application/feed_controller_test.dart` — covers `build` initial load (FakeFirebaseFirestore seeded with 3 friend posts → expect ordered list), `loadMore` cursor advance (verify `lastDoc` updates → after ARCH LAYER-003 fix becomes typed cursor), error path (Firestore returns FirebaseException → state.errorMessage VN).
  3. `test/features/feed/application/app_camera_controller_test.dart` — covers initialize success/fail (camera plugin platform exception), capture happy + permission-denied + storage-full edge cases.
  - PRE-CONDITION: tests in (1) + (2) become much cleaner AFTER ARCH LAYER-001/-002/FEED-ARCH-001 fixes (provider DI + currentUidProvider). Suggest landing ARCH batch_1+batch_2 FIRST, then writing these tests. Without ARCH fix, tests need ugly workarounds (e.g., wrap `FirebaseAuth.instance` with `IOOverrides`, not idiomatic).
- authority: `apps/mobile/CLAUDE.md §Testing` "Unit-test controllers + repositories with `fake_cloud_firestore` and `firebase_auth_mocks`" + `auth.md` Pattern #10 Application layer + `CLAUDE.md §Dev Code Standards — Definition of Done` "Application layer: controller có unit test happy + edge + error"
- test: `(cd apps/mobile && flutter test test/features/feed/application/)` — expect 3 new files, ≥ 12 test cases combined (4 cases per controller minimum: happy + edge + error + null-uid), all green
- deps: blocked-by ARCH LAYER-001/-002/FEED-ARCH-001 (for clean test setup); E2E-001 (controller tests + E2E together close the Feed coverage gap)

### ISSUE WIDGET-TEST-001

- sev: P1
- blocker: no
- area: test gap — critical screens
- files:
  - `apps/mobile/lib/features/feed/presentation/home_screen.dart` (630 lines)
  - `apps/mobile/lib/features/feed/presentation/feed_section.dart` (1031 lines)
  - `apps/mobile/lib/features/feed/presentation/capture_preview_screen.dart` (771 lines)
  - `apps/mobile/lib/features/feed/presentation/camera_section.dart` (595 lines)
  - `apps/mobile/lib/features/auth/presentation/login/{login_email_page,login_password_page,reset_password_page}.dart`
  - `apps/mobile/lib/features/auth/presentation/signup/{signup_email_page,signup_password_page,signup_name_page,signup_username_page}.dart`
- loc: missing tests at `test/features/feed/presentation/{home_screen_test.dart, feed_section_test.dart, capture_preview_screen_test.dart, camera_section_test.dart}` + `test/features/auth/presentation/**`
- symbols:
  - `HomeScreen`, `_HomeScreenState`, `FeedSection`, `_PostPage`, `CapturePreviewScreen`, `CameraSection`
  - 7 auth pages (intro + 3 login + 4 signup)
- evidence: `find apps/mobile/test -name "*home_screen*"` returns 1 hit (`home/presentation/home_page_test.dart` — different file, the 56-line skeleton). `find apps/mobile/test -name "*feed_section*"` returns 0. `find apps/mobile/test -name "*capture_preview*"` returns 0. `find apps/mobile/test -name "*camera_section*"` returns 0. `find apps/mobile/test/features/auth/presentation -name "*.dart"` returns 0 files — `test/features/auth/` has only `application/` + `data/` subfolders, NO `presentation/` subfolder. Compare with `chat/`, `notification/`, `profile/`, `settings/`, `space/`, `streak/` modules which DO ship `presentation/` test folders.
- confidence_impact: 4 P0 Feed screens (home + feed grid + capture preview + camera) and 7 P0 Auth screens have no rendering check. Form validator wiring (signup_email regex, signup_password strength, login_email empty), 4-state pattern (loading/error/empty/data per `apps/mobile/CLAUDE.md §Loading / error / empty`), button enable/disable state — none verified. Visual regression introduced by `core/theme/` change has no widget test to catch it.
- risk: UX regression vector. Specific risks: (a) form validators silently dropped during refactor → user can submit empty password → backend rejection only surfaces post-network roundtrip. (b) loading state forgotten → spinner doesn't show during 2s+ API call → user double-taps. (c) error state shows raw FirebaseException string (per ARCH DATA-ARCH-001) → English untranslated copy in feed. (d) capture preview overflow on small device → covered by 03_ux audit area but no automated catch. Auth is the entry point for 100% of users — testing 0% of the entry funnel is a release blocker philosophically. ARCH-002 already flags 4 of these files as oversize (>500 lines); splitting them without widget tests is risky.
- fix: write 11 widget test files (4 Feed + 7 Auth) using `flutter-add-widget-test` skill pattern. Priority order per CLAUDE.md "critical path":
  1. `test/features/auth/presentation/signup/signup_email_page_test.dart` — pump page, type invalid email "abc", tap continue, expect VN error "Email không hợp lệ" rendered.
  2. `test/features/auth/presentation/signup/signup_password_page_test.dart` — type short password "12", tap continue, expect VN error "Mật khẩu phải ≥ 8 ký tự".
  3. `test/features/auth/presentation/login/login_email_page_test.dart`, `login_password_page_test.dart` — similar validator path.
  4. `test/features/auth/presentation/signup/{signup_name_page,signup_username_page}_test.dart` — name length + username regex check.
  5. `test/features/feed/presentation/home_screen_test.dart` — pump with overridden `currentUidProvider` + `postRepositoryProvider` returning fake feed. Verify 4 states render (loading spinner / VN empty CTA / error view / data list of 2 posts).
  6. `test/features/feed/presentation/feed_section_test.dart` — verify own-post vs friend-post branch (depends on ARCH LAYER-001 fix landing first).
  7. `test/features/feed/presentation/capture_preview_screen_test.dart` — verify caption pill renders, submit button disabled when caption > 30 chars per UX rule.
  8. `test/features/feed/presentation/camera_section_test.dart` — mock camera platform, verify shutter button + flip lens button render.
- authority: `apps/mobile/CLAUDE.md §Testing` "Widget tests for non-trivial UI (form, list, dialog)" + `flutter-add-widget-test` skill + `auth.md` Pattern #10 layer "UI Widget" + `CLAUDE.md §Testing & Verification` coverage targets "UI ≥ 50%"
- test: `(cd apps/mobile && flutter test test/features/feed/presentation/ test/features/auth/presentation/)` — expect 11 new files, all green. Coverage delta: `flutter test --coverage` shows `lib/features/auth/presentation/**` line coverage > 50% (per CLAUDE.md UI target).
- deps: blocked-by ARCH LAYER-001/-002 (Feed widgets cannot be widget-tested while calling `FirebaseAuth.instance` direct); E2E-001 (auth widget tests + E2E sign-in test overlap — write widget tests for VN validator copy that E2E can't easily assert)

### ISSUE REL-MINIFY-001

- sev: P1
- blocker: no
- area: release readiness — APK optimization
- files:
  - `apps/mobile/android/app/build.gradle.kts`
- loc: 38-43 (`buildTypes.release` block)
- symbols:
  - missing `isMinifyEnabled = true`
  - missing `isShrinkResources = true`
  - missing `proguardFiles(...)` declaration
  - missing `apps/mobile/android/app/proguard-rules.pro`
- evidence: `grep -n "isMinifyEnabled\|isShrinkResources\|proguardFiles" apps/mobile/android/app/build.gradle.kts` returns 0 hits. `find apps/mobile/android -name "proguard*"` returns 0 files. Current release block (lines 38-43) ONLY sets `signingConfig` — nothing else.
- confidence_impact: release APK ships full Dart kernel + uncompressed resources + un-shrunk Kotlin/Firebase reflection. Two concrete consequences: (1) APK size ≥ 30% larger than necessary — Play Store install-friction + cellular download cost for users. (2) Firebase Auth/Firestore SDK uses reflection internally (model serialization, gRPC stubs); without ProGuard rules they survive accidentally now (no R8 enabled), but the day R8 is enabled, `MissingPluginException` or `ClassNotFoundException` at runtime breaks Auth/Firestore for production users. Riverpod codegen reads class metadata for provider hashing — also reflection-adjacent.
- risk: release readiness — Meep is Android-only MVP (ADR-0002), and Play Store binary distribution is the only delivery channel. Today the release APK is unoptimized + un-shrunk; enabling minify later (post-launch) without ProGuard rules causes Firebase runtime crashes in production. Better to land minify + ProGuard before first ship so the optimization path is verified.
- fix: 4 steps in one PR (bundle with SIGN-001):
  1. Add to `build.gradle.kts:38-43`:
     ```kotlin
     buildTypes {
         release {
             signingConfig = ... // from SIGN-001
             isMinifyEnabled = true
             isShrinkResources = true
             proguardFiles(
                 getDefaultProguardFile("proguard-android-optimize.txt"),
                 "proguard-rules.pro",
             )
         }
     }
     ```
  2. Create `apps/mobile/android/app/proguard-rules.pro` with keep rules for:
     - `-keep class com.google.firebase.** { *; }` (Firebase reflection)
     - `-keep class io.flutter.embedding.** { *; }` (Flutter engine)
     - `-keep class com.google.android.gms.** { *; }` (Google Sign-In + Play Services)
     - Riverpod codegen: `-keep class **$$_$Generated { *; }` (verify exact pattern from riverpod_generator output)
     - freezed: no rules needed (compile-time codegen, no reflection)
  3. Smoke test: `(cd apps/mobile && flutter build apk --release && adb install -r build/app/outputs/flutter-apk/app-release.apk)` on dev device — verify auth + Firestore read + feed render survive R8. If crash, add the missing keep rule per stacktrace.
  4. Document APK size delta before/after in `docs/release.md` (DOCS-REL-001) so future deps additions can be measured.
- authority: Flutter docs "App size — Reducing app size" (recommends minify + shrink + proguard for production) + Firebase docs "Crashlytics with ProGuard" (mandates `-keepattributes SourceFile,LineNumberTable` for symbolicated stacktraces) + `CLAUDE.md §Project Context` "Mobile-first" implies optimized binary
- test: smoke test command above; CI verification: `flutter build apk --release` step in `deploy-production.yml:86-87` should produce APK ≥ 30% smaller than current. Manual: install on Android 7 device (minSdk per Flutter SDK defaults) → verify sign-in + feed render survive.
- deps: SIGN-001 (same `buildTypes.release` block — single PR); CRASHLYTICS-001 (R8 + Crashlytics symbolication is a couple — turn on together for production-grade stacktraces)

### ISSUE CRASHLYTICS-001

- sev: P1
- blocker: no
- area: release readiness — error visibility
- files:
  - `apps/mobile/lib/main.dart`
  - `apps/mobile/pubspec.yaml:29` (`firebase_crashlytics: ^4.1.3` declared)
  - `apps/mobile/android/app/build.gradle.kts:5` (`com.google.firebase.crashlytics` plugin applied)
- loc: missing wiring at `main.dart:53-60` (post-`Firebase.initializeApp`)
- symbols:
  - `FirebaseCrashlytics.instance.recordError` (NOT CALLED)
  - `FlutterError.onError` (NOT REASSIGNED)
  - `PlatformDispatcher.instance.onError` (NOT REASSIGNED)
  - `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled` (NOT CALLED)
- evidence: `grep -rn "Crashlytics\|FlutterError.onError\|recordError\|PlatformDispatcher" apps/mobile/lib` returns 0 hits. `pubspec.yaml:29` declares `firebase_crashlytics: ^4.1.3` and `build.gradle.kts:5` applies `com.google.firebase.crashlytics` plugin — dep is wired at build level but NEVER USED at runtime. Cross-ref SEC pass-1 no_issue note: "FirebaseCrashlytics/recordError/FlutterError.onError grep = 0 hits — PII scrub concern N/A hiện tại. Khi wire, áp dụng CLAUDE.md §PII handling pattern".
- confidence_impact: production users' Dart errors disappear silently. Without Crashlytics signal, leader has no way to know which 1% of users see white screen, OOM crash, FCM permission denial flow break. Combined with E2E-001 (no automated regression) + WIDGET-TEST-001 (no rendering check) = the only crash signal would be in-person QA. For a 4-dev team shipping to a real friend group, this is structurally blind.
- risk: post-launch dark mode — Meep M3 ships on 9/6/2026, and any production crash after that point is invisible. Combined with `CLAUDE.md §Security Guardrails — PII handling` constraint "scrub message body / caption before reporting" — Crashlytics MUST be wired with explicit PII-scrubbing setup, not turned on naively. The longer it's deferred, the more refactor risk to add later.
- fix: 4 steps:
  1. Add to `main.dart` after `await Firebase.initializeApp(...)`:
     ```dart
     // Crashlytics: capture Flutter framework + Dart-zone errors.
     FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
     PlatformDispatcher.instance.onError = (error, stack) {
       FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
       return true;
     };
     // Disable in debug + emulator runs to avoid noisy dashboard.
     await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
       !kDebugMode && !_useEmulator,
     );
     ```
  2. Add PII scrub: wrap `recordError` calls in a helper that strips caption text, email, displayName from `cause.message` before forwarding. Document in `apps/mobile/lib/core/observability/crashlytics_helper.dart`.
  3. Add unit test `test/core/observability/crashlytics_helper_test.dart` verifying PII patterns redacted (email regex, "caption=..." key-value).
  4. Verify dashboard receives first test crash via `FirebaseCrashlytics.instance.crash()` in dev. Take screenshot for `docs/release.md` pre-launch checklist (DOCS-REL-001).
- authority: `CLAUDE.md §PII handling` "Crashlytics: scrub message body / caption before reporting" + Firebase Crashlytics docs "Test your implementation" + REL-MINIFY-001 dependency (ProGuard `-keepattributes SourceFile,LineNumberTable` required for symbolicated traces)
- test: dev-side: trigger `Crashlytics.instance.crash()` in debug, verify with `setCrashlyticsCollectionEnabled(true)` override — crash appears on Firebase Console within 5min. Production-side: post-M3 ship, verify first organic crash from user device surfaces with symbolicated stack (depends on REL-MINIFY-001 ProGuard rule keeping line numbers).
- deps: REL-MINIFY-001 (symbolication requires `-keepattributes SourceFile,LineNumberTable`); DOCS-REL-001 (release checklist item: "verify Crashlytics dashboard receives test crash")

### ISSUE FUNC-TEST-001

- sev: P1
- blocker: no
- area: test gap — Cloud Functions placeholder tests
- files:
  - `firebase/functions/test/friend/onFriendshipDeleted.test.ts` (21 lines)
  - `firebase/functions/test/feed/feed.rules.test.ts` (104 lines)
- loc:
  - `onFriendshipDeleted.test.ts:4-9` (single placeholder `expect(true).toBe(true)`)
  - `feed.rules.test.ts:28, 33, 42, 48` (4 placeholder `expect(true).toBe(true)`)
- symbols:
  - `describe('onFriendshipDeleted')` + 1 it-block placeholder
  - `describe('Firestore rules — /posts/{postId}')` 4 it-blocks placeholder
- evidence:
  - `onFriendshipDeleted.test.ts:7`: `expect(true).toBe(true);` with comment "onFriendshipDeleted is a Firestore trigger... requires Firebase emulator"
  - `feed.rules.test.ts:28`: `expect(true).toBe(true); // placeholder — requires emulator`
  - 3 more identical placeholders at lines 33, 42, 48 in same file
  - File-level TODO: `TODO(#92/ThienPDM): Add integration tests with Firebase emulator` (twice)
- confidence_impact: 2 test files in vitest pipeline report GREEN but verify nothing. `npm test` exit 0 hides genuine gap. Combined with SEC TESTING-SEC-001 (collections rules-test breadth) — these placeholders pose worse risk: looking like coverage when it isn't. The vitest CI gate at `pr-check.yml:124` exits 0 even when these files would catch nothing — false confidence.
- risk: regression vector — `onFriendshipDeleted` runs friendCount decrement + conversation status update + cross-feed cleanup; bug here silently leaves orphaned data. `feed.rules.test.ts` ostensibly covers `/posts` read rule for author/recipient/stranger — actually covers nothing. SEC POST-SEC-001 fix (caption cap on update) lands and breaks `/posts` rules → CI green because placeholder; only caught when QA notices broken feed write. Note: emulator-based real rules tests for both DO exist in `test/rules/*.rules.test.ts` (notification, reaction, settings, space, chat, friend) — so the infrastructure is wired. These 2 files are leftover stubs.
- fix: 2 paths:
  1. **Delete the 2 placeholder files entirely** (`onFriendshipDeleted.test.ts` and `test/feed/feed.rules.test.ts`) — they add noise without value. Add real coverage in their replacement files:
     - `test/friend/onFriendshipDeleted.real.test.ts` using emulator pattern from `test/space/triggers.test.ts:11-30` (import + assert exports + integration via emulator separately).
     - `test/rules/feed.rules.test.ts` using emulator pattern from `test/rules/reaction.rules.test.ts` (real `initializeTestEnvironment` + assert owner/friend/stranger matrix).
  2. OR (faster) — replace the 5 `expect(true).toBe(true)` lines with `it.skip(...)` so vitest output shows them as SKIPPED, not PASSED. This makes the gap visible in CI logs without breaking green.
  - Recommend path 1 — placeholder tests violate `CLAUDE.md §Banned phrases` "should pass / probably works / I'm confident" spirit.
- authority: `CLAUDE.md §Testing & Verification — What "done" means` "no commented-out dead code, no `// TODO` without a linked issue" + `firebase/functions/CLAUDE.md §Testing — vitest` "Use `vi.mock` sparingly — prefer dependency injection + in-memory fakes" (placeholders are neither)
- test: after fix, `(cd firebase/functions && npm test)` — total test count INCREASES (real assertions); `grep -rn "expect(true).toBe(true)" firebase/functions/test` returns 0 hits
- deps: pairs with SEC TESTING-SEC-001 (test coverage gap consolidation); SEC CI-SEC-001 (CI fallback removal — that fix only matters if these placeholders are removed too)

### ISSUE CI-MOBILE-001

- sev: P1
- blocker: no
- area: CI gap — mobile integration_test step missing
- files:
  - `.github/workflows/pr-check.yml`
- loc: 62-98 (`flutter` job — no integration_test step)
- symbols:
  - missing `flutter test integration_test/` step
- evidence: `pr-check.yml:89-90` runs `flutter test --coverage --reporter=expanded` — this command picks up `test/**/*.dart` but NOT `integration_test/**/*.dart`. Integration tests need explicit `flutter test integration_test/` invocation, AND a connected device/emulator. CI step does NOT exist.
- confidence_impact: even if E2E-001 fix lands (`integration_test/` folder with real tests), they would NEVER RUN in CI. PR could merge with broken E2E. The folder + tests exist but CI is unaware → false sense of E2E coverage.
- risk: same as E2E-001 but with extra step — the test exists but CI doesn't see it. Worse than missing test (visible gap) because the team would assume it's covered.
- fix: add to `pr-check.yml` `flutter` job (after line 90 `Test with coverage`):
  ```yaml
  - name: Integration tests (Android emulator)
    if: github.event.pull_request.base.ref == 'develop'
    uses: reactivecircus/android-emulator-runner@v2
    with:
      api-level: 33
      target: google_apis
      arch: x86_64
      working-directory: apps/mobile
      script: flutter test integration_test/
  ```
  - Trade-off: emulator boot adds ~5-7min CI time. Acceptable per `CLAUDE.md §MVP Scope` "Tier 0 minimum"; gate on `develop` PRs only (not `deploy`) to avoid double-run. Free-tier GitHub Actions has 2000 min/month per `develop-staging.yml:18` comment — 5min × 50 PRs/month = 250min, under budget.
- authority: `apps/mobile/CLAUDE.md §Testing` integration_test requirement + Flutter docs "Integration testing on GitHub Actions" + `pr-check.yml:73` Flutter version pin pattern
- test: smoke test the workflow — push PR with a deliberately failing integration_test → CI should report job failure with emulator artifact; revert; re-push with passing test → CI green
- deps: blocked-by E2E-001 (no point wiring CI for tests that don't exist); SIGN-001 (CI emulator job tests debug build, not release — so this fix orthogonal to release signing, but mention release smoke test separately as CI-REL note)

### ISSUE CI-MOBILE-002

- sev: P2
- blocker: no
- area: CI gap — Java setup missing in Flutter job
- files:
  - `.github/workflows/pr-check.yml`
- loc: 62-98 (no `setup-java` step)
- symbols:
  - missing `actions/setup-java@v4`
- evidence: `pr-check.yml:62-98` `flutter` job has steps: checkout → setup flutter → pub get → codegen → format → analyze → test → upload artifact. NO `setup-java@v4` step. Compare with `develop-staging.yml:39-43` and `deploy-production.yml:58-61` which DO install Java 21 Temurin before Flutter setup. `pr-check.yml:142-145` (firestore-rules job) installs Java 21 too — only the `flutter` job in pr-check is missing it.
- confidence_impact: `flutter pub get` invokes Gradle for Android plugin resolution — needs Java. `flutter analyze` + `flutter test` for Android-target code MAY need Android SDK + Java (subosito/flutter-action action includes some Android tooling but JDK is separate). Risk of CI flake when Android-specific plugin updates need Gradle resolution. Currently works because no test triggers Android-side compilation, but `flutter test integration_test/` (when CI-MOBILE-001 lands) will compile Android APK and definitely need Java.
- risk: CI flake — `subosito/flutter-action@v2` bundles enough for `pub get` + `analyze` + `test` to pass today, but: (a) any future test that uses Android channel will fail with NoClassDefFoundError; (b) CI behaves differently from local dev where leader/Khoa run with Java 21 installed; (c) `develop-staging.yml` builds APK and DOES install Java — split treatment is technical debt. Bundle the Java install into pr-check to harmonize.
- fix: add to `pr-check.yml` after line 69 (`uses: actions/checkout@v4`), before line 71 (`uses: subosito/flutter-action@v2`):
  ```yaml
  - uses: actions/setup-java@v4
    with:
      distribution: 'temurin'
      java-version: '21'
  ```
  - Same as `develop-staging.yml:39-43`. No removal of other steps.
- authority: `develop-staging.yml:39-43` precedent in same repo + Flutter docs "Set up Android development on a Linux machine" (Java 21 required for compileSdk per Flutter 3.41+)
- test: after fix, PR-check job continues to pass. Future-proofing for CI-MOBILE-001 integration_test step.
- deps: pairs with CI-MOBILE-001 (Java setup is precondition for emulator-based integration tests)

### ISSUE CI-MOBILE-003

- sev: P2
- blocker: no
- area: CI gap — Kotlin tests not run
- files:
  - `.github/workflows/pr-check.yml`
  - `apps/mobile/android/app/build.gradle.kts:74-80` (Kotlin test deps wired)
  - `apps/mobile/android/app/src/test/kotlin/dev/meep/meep/WidgetSyncWorkerTest.kt` (15.2KB exists)
- loc: missing `./gradlew test` step in CI
- symbols:
  - `WidgetSyncWorkerTest` class
  - junit + mockk + robolectric + work-testing dependencies (lines 75-80)
- evidence: `find apps/mobile/android -name "*Test.kt"` returns `WidgetSyncWorkerTest.kt`. `build.gradle.kts:74-80` declares: junit 4.13.2, mockk 1.13.13, robolectric 4.13, work-testing 2.9.1, coroutines-test 1.8.1, androidx-test-core 1.6.1 — full Kotlin test stack. BUT `pr-check.yml` `flutter` job runs only `flutter test` (Dart tests); no `./gradlew :app:testDebugUnitTest` or `flutter test integration_test/` equivalent for Kotlin native tests. The widget-android native test stack is wired but UNUSED in CI.
- confidence_impact: native widget sync logic (WorkManager + Firestore + Glide cache) has 1 test file authored for `T6` per the file header — never executed in CI. Any regression in `WidgetSyncWorker` (battery-impact periodic work) ships unverified. Inventory map `## tests_inventory` line says "Kotlin tests (Android widget): TBD per build.gradle.kts có configuration" — confirms ambiguity. This audit resolves: test EXISTS but NOT WIRED in CI.
- risk: home-screen widget is the Meep differentiator (per inventory map + `CLAUDE.md §Project Context` "headline differentiator: home-screen widget"). Regression here = breaking the entire product distinction without CI catch.
- fix: add to `pr-check.yml` `flutter` job (after line 90 Test with coverage step):
  ```yaml
  - name: Run Kotlin unit tests (widget native)
    working-directory: apps/mobile/android
    run: ./gradlew :app:testDebugUnitTest --no-daemon
  ```
  - Trade-off: adds ~2-3min CI (gradle cold-start + robolectric init). Worth it: Kotlin tests already authored, gate them so they keep working.
  - Pre-condition: requires CI-MOBILE-002 Java setup (gradle needs JDK).
- authority: `WidgetSyncWorkerTest.kt` file header comment "T6 acceptance criteria" + `build.gradle.kts:74-80` infrastructure already wired + `apps/mobile/CLAUDE.md §Testing` extends to native-side widget code by implication of Pattern #1 module-owns-all-layers
- test: after fix, intentionally break a `WidgetSyncWorker.kt` assertion → push PR → CI flutter job fails with gradle test output
- deps: CI-MOBILE-002 (Java required for gradle); no other deps

### ISSUE CI-FUNC-001

- sev: P3
- blocker: no
- area: CI gap — coverage not collected for Functions
- files:
  - `.github/workflows/pr-check.yml`
  - `firebase/functions/package.json:15` (`test:coverage` script exists)
  - `firebase/functions/vitest.config.ts:14-19` (v8 coverage configured)
- loc: 124 (`npm test` — no `--coverage`)
- symbols:
  - `npm test` (used) vs `npm run test:coverage` (defined but unused)
- evidence: `pr-check.yml:124` runs `npm test`. `firebase/functions/package.json:15` defines `"test:coverage": "vitest run --coverage"`. `vitest.config.ts:14-19` declares v8 coverage with `lcov` + `html` reporters. Infrastructure ready, CI never invokes it. Compare with `pr-check.yml:89` Flutter job which DOES run `flutter test --coverage` + uploads artifact lines 92-98.
- confidence_impact: cannot measure if Functions tests meet `CLAUDE.md §Testing — Coverage targets` "business logic ≥ 80%". Cannot detect coverage regression on new Functions added without tests. Currently CI green = tests pass, NOT = coverage threshold met.
- risk: defense-in-depth gap. Functions are public-internet endpoint (callable + triggers); regression there has user-visible blast radius. Without coverage signal, leader cannot enforce coverage on PR review.
- fix: 2-step:
  1. Change `pr-check.yml:124` from `run: npm test` to `run: npm run test:coverage`.
  2. Add upload step after line 125 mirroring lines 92-98:
     ```yaml
     - name: Upload functions coverage artifact
       if: always()
       uses: actions/upload-artifact@v4
       with:
         name: functions-coverage
         path: firebase/functions/coverage/
         retention-days: 7
     ```
- authority: `firebase/functions/CLAUDE.md §Testing — vitest` "`npm test -- --coverage`" + `CLAUDE.md §Testing & Verification` coverage targets "business logic 80%"
- test: CI pass post-change; artifact downloadable from PR Actions tab; `coverage/lcov-report/index.html` shows per-file %
- deps: none

### ISSUE REL-VERSION-001

- sev: P3
- blocker: no
- area: release readiness — version source-of-truth split
- files:
  - `apps/mobile/pubspec.yaml:4` (`version: 0.1.0+1`)
  - `apps/mobile/android/app/build.gradle.kts:34-35`
  - `.github/workflows/deploy-production.yml:161-171`
- loc:
  - `pubspec.yaml:4 version: 0.1.0+1`
  - `build.gradle.kts:34-35 versionCode = flutter.versionCode` + `versionName = flutter.versionName`
  - `deploy-production.yml:167-168` auto-increments PATCH from `git tag --sort=-v:refname | head -n1` if no `workflow_dispatch.inputs.version` provided
- symbols:
  - `pubspec.yaml version` vs CI-computed `VERSION`
- evidence: 3 sources of truth for version: (a) `pubspec.yaml:4` controls `versionCode`/`versionName` baked into APK; (b) `deploy-production.yml:163-169` computes `VERSION` from either workflow_dispatch input or latest git tag; (c) `softprops/action-gh-release@v2` at line 191 publishes GitHub release with the computed VERSION as tag. These 3 can drift — if pubspec.yaml = `0.1.0+1` and CI computes from `v0.2.0` git tag → APK is 0.1.0 but release tag is 0.2.1. Path-of-least-surprise broken.
- confidence_impact: release published as `v0.2.0` actually installs as `0.1.0+1` on user device. App Settings → About screen shows mismatched version vs Play Store listing. Crashlytics groups crashes by APK version (`0.1.0+1`) but release notes reference `v0.2.0` — analysis time wasted reconciling.
- risk: low impact today (no live users) but the moment first release ships, version drift starts. Best to fix before M3.
- fix: 2 paths:
  1. **Single source = pubspec.yaml.** Remove `deploy-production.yml:163-169` auto-increment logic. Require `workflow_dispatch.inputs.version` ALWAYS, OR parse from `pubspec.yaml`. Add a CI guard: `grep -q "^version: ${VERSION#v}" apps/mobile/pubspec.yaml || exit 1` before tag-release step.
  2. **Single source = git tag.** Update `pubspec.yaml` version at CI time from the computed VERSION before `flutter build apk --release`. Insert into `deploy-production.yml:84-85` (build job, before `Build release APK + AAB`):
     ```yaml
     - name: Sync pubspec version to release tag
       run: |
         VERSION_RAW="${{ needs.tag-release.outputs.version }}"
         CLEAN="${VERSION_RAW#v}"
         sed -i "s/^version: .*/version: ${CLEAN}+${{ github.run_number }}/" apps/mobile/pubspec.yaml
     ```
  - Recommend path 1 (single source = pubspec.yaml) — keeps version control with developer, CI just confirms agreement. Match Flutter convention.
- authority: Flutter docs "Build and release an Android app — Updating the app's version number" + Conventional Commits + semver discipline
- test: dry-run `workflow_dispatch` with `version: v0.0.1-test` → assert `pubspec.yaml version: 0.0.1+<build-num>` matches tag; release tag at github.com matches
- deps: SIGN-001 (release build pipeline shares same job); DOCS-REL-001 (release runbook needs version-bump step)

### ISSUE DOCS-REL-001

- sev: P2
- blocker: no
- area: release readiness — runbook missing
- files:
  - `docs/release.md` (does not exist)
  - `docs/setup.md` (exists — covers dev, not release)
  - `docs/milestones/README.md` (exists — milestone format only, not release)
  - `docs/team-workflow.md §6` (CI overview, not release runbook)
- loc: missing file
- symbols:
  - no pre-launch checklist
  - no signing key backup procedure
  - no rollback strategy
  - no App Check enable verification step
  - no Crashlytics dashboard verification step
  - no Play Store listing prep checklist
- evidence: `find docs -name "release*"` returns 0 files. `find docs/milestones -name "*.md"` returns ONLY `README.md` (format guide, no actual milestone reports). `docs/setup.md` covers dev tooling (Flutter, Firebase CLI, MCP) — not release. `docs/team-workflow.md §6` describes CI workflow at a high level but lists no pre-flight checks. `docs/roadmap/milestones.md` describes M1/M2/M3 SCOPE but not the deliverable acceptance checklist.
- confidence_impact: leader has no checklist to follow before pushing `deploy` branch. App Check enable (SEC APPCHECK-001), Crashlytics verification (CRASHLYTICS-001), Android keystore backup, assetlinks.json fingerprint update (after SIGN-001 generates real keystore), version bump procedure (REL-VERSION-001) — all 5 are pre-launch steps with no documented sequence. First release attempt = trial-and-error, high risk of forgetting one.
- risk: release process gap. 4-dev student team has no prior release experience; without a checklist, M3 ship = "let's see what breaks". Combined with SIGN-001 (debug keystore) + REL-MINIFY-001 (no ProGuard) + CRASHLYTICS-001 (no error visibility) + REL-VERSION-001 (version drift) = compounding risk.
- fix: create `docs/release.md` with 6 sections (Vietnamese where flow-state, technical commands English per CLAUDE.md):
  1. **Pre-launch checklist** — 12-15 items: App Check activated (SEC APPCHECK-001), Crashlytics test crash received (CRASHLYTICS-001), Release keystore generated + backed up (SIGN-001), assetlinks.json SHA256 updated, ProGuard kept rules verified (REL-MINIFY-001), version bumped in pubspec.yaml (REL-VERSION-001), all P0 rules tests pass (SEC TESTING-SEC-001), Firestore rules deployed to prod, /usernames `if true` removed (SEC USERNAME-SEC-001), integration_test green (E2E-001), Play Store listing assets ready, privacy policy URL, terms URL, ADR-0005 deeplink verified.
  2. **Signing key procedure** — generate command (`keytool -genkey -keystore release.keystore -alias meep-prod -keyalg RSA -keysize 4096 -validity 10000`), GitHub Secret upload (`base64 -w0 release.keystore | gh secret set ANDROID_KEYSTORE_BASE64`), backup procedure (encrypted copy in 1Password / similar), SHA256 fingerprint extract (`keytool -list -v -keystore release.keystore`).
  3. **Version bump** — single source pubspec.yaml; bump pattern (PATCH for fix-only, MINOR for feat) per Conventional Commits commits since last tag.
  4. **Deploy flow** — `git checkout deploy && git merge --no-ff origin/develop` → push → CI runs deploy-production.yml → approve in GitHub Environments → wait for tag-release job → verify Firebase Console deploy timestamp.
  5. **Smoke test** — install APK on fresh Android device, sign-up new user, take post, verify widget refresh, sign out + back in.
  6. **Rollback** — `gh release delete v0.X.Y` + revert deploy branch + redeploy previous tag's Functions/Rules via `firebase deploy --only functions --project meep-prod --force` from previous tag checkout.
- authority: `CLAUDE.md §Verification Before Claiming Done` checklist pattern + Play Store launch checklist (standard) + assetlinks.json deployment per ADR-0005
- test: dry-run release with `workflow_dispatch v0.0.1-test` following docs/release.md step-by-step; verify each step has unambiguous command + verification command
- deps: SIGN-001, REL-MINIFY-001, CRASHLYTICS-001, REL-VERSION-001 (each contributes 1+ checklist item); SEC APPCHECK-001 + USER-SEC-001 + TESTING-SEC-001 (security pre-launch items); ARCH ARCH-003 (RollCall scaffold decision before M3)

### ISSUE UNIT-001

- sev: P2
- blocker: no
- area: test gap — Firebase Storage repository
- files:
  - `apps/mobile/lib/features/feed/data/firebase_storage_repository.dart` (42 lines)
  - missing test at `apps/mobile/test/features/feed/firebase_storage_repository_test.dart`
- loc: missing
- symbols:
  - `FirebaseStorageRepository.uploadImage`
- evidence: `find apps/mobile/test -name "*storage_repository*"` returns 0 hits. `apps/mobile/lib/features/feed/data/firebase_storage_repository.dart` exists as 1 of 14 firebase_*_repository.dart files; 13/14 have test mirrors per `find apps/mobile/test -name "firebase_*_repository_test.dart"`. Storage repo is the SOLE outlier — and per ARCH DATA-ARCH-001 evidence line 37 it "only handles `object-not-found` then `rethrow`s every other `FirebaseException` raw" → error mapping bug AND no test catching it.
- confidence_impact: photo upload is the entire write-side of the app (PostController → uploadImage → createPost). Upload failures (quota exceeded, network, permission denied) have no test verifying repo translates to typed AppError vs swallowed. Combined with CTRL-TEST-001 (PostController also untested) = 100% of photo-upload pipeline is test-uncovered.
- risk: regression vector for the entire share-photo action. ARCH DATA-ARCH-001 already mandates `_mapStorageError` addition to this repo; without a test today, the fix lands with no regression check.
- fix: write `apps/mobile/test/features/feed/firebase_storage_repository_test.dart` using `firebase_storage_mocks` (already in pubspec via test indirect transitive — verify with `flutter pub deps`) or `mocktail` to mock `FirebaseStorage.ref().putData()`. Cases:
  - happy: upload returns `TaskSnapshot` → repo returns download URL string
  - permission-denied: throws `FirebaseException(code: 'unauthorized')` → repo throws `ForbiddenError` (after ARCH DATA-ARCH-001 fix)
  - object-not-found: current code path returns null (verify behavior)
  - network: `FirebaseException(code: 'cancelled')` → repo throws `NetworkError`
  - size-exceeded: `FirebaseException(code: 'object-larger-than-quota')` → repo throws `ValidationError` (post-fix)
- authority: `apps/mobile/CLAUDE.md §Testing` "Unit-test controllers + repositories with `fake_cloud_firestore` and `firebase_auth_mocks`" + `auth.md` Pattern #10 layer "Data" + `CLAUDE.md §Testing & Verification` coverage "Data layer ≥ 70%"
- test: `(cd apps/mobile && flutter test test/features/feed/firebase_storage_repository_test.dart)` — 4-5 test cases green
- deps: blocked-by ARCH DATA-ARCH-001 (error mapping not present yet); pairs with CTRL-TEST-001 (PostController test will mock this repo via override)

### ISSUE TEST-QUALITY-001

- sev: P3
- blocker: no
- area: test infrastructure quality — disposal discipline + presentation tests
- files:
  - 16 test files using `ProviderContainer(` (from grep count)
  - 6 test files using `tearDown\|ProviderContainer.dispose` (from grep count)
- loc: 10 of 16 ProviderContainer usages may lack disposal
- symbols:
  - `ProviderContainer.dispose()`
  - `tearDown(() { container.dispose(); })`
- evidence: `grep -rln "ProviderContainer(" apps/mobile/test | wc -l` returns 16. `grep -rln "container.dispose" apps/mobile/test | wc -l` returns 12. `grep -rln "tearDown\|ProviderContainer.dispose" apps/mobile/test | wc -l` returns 6. Aggregate suggests 6-12 files have explicit cleanup; 4-10 may leak between tests (ProviderContainer kept alive across `test()` blocks → stream subscriptions accumulate → false-positive flakiness or hidden coupling).
- confidence_impact: tests pass individually but may fail in different order or when test count grows. Heisenbugs from un-disposed ProviderContainer = exactly the "should pass / probably works" anti-pattern from CLAUDE.md §Banned phrases. Hard to debug 6 months from now.
- risk: low individually, compounds. As test count grows from 80 → 200, leak surface area grows. Best to enforce now.
- fix: 2 steps:
  1. Spot-check 4 sample files (`test/features/feed/feed_filter_controller_test.dart`, `test/features/diary/application/diary_controller_test.dart`, `test/features/notification/application/notification_controller_test.dart`, `test/features/profile/application/profile_controller_test.dart`) — verify each `ProviderContainer(` is followed by `addTearDown(container.dispose)` or `tearDown(() => container.dispose())`. Files missing the pattern → fix.
  2. Add lint check in `apps/mobile/analysis_options.yaml` if `custom_lint` is wired (pubspec.yaml:88-93 comment notes riverpod_lint deferred). Defer this sub-step until lint deps unblocked.
- authority: `apps/mobile/CLAUDE.md §State management — Riverpod 2` "ref.onDispose(() => sub.cancel()) for every stream subscription" (test analog: dispose container in tearDown) + `auth.md` Pattern #6 keepAlive discipline analog
- test: post-fix, run `(cd apps/mobile && flutter test test/features/)` in 3 random orderings (`flutter test --test-randomize-ordering-seed=random` × 3) — all green; no flake from container leak
- deps: none

## fix_order

### batch_1_p0

1. **E2E-001** — scaffold `apps/mobile/integration_test/` with 3 baseline E2E tests (login + post + feed react). Foundation for golden-path coverage. **Pre-condition:** ARCH LAYER-001/-002 + FEED-ARCH-001 fixes (so Feed widget can be E2E-tested without Firebase singleton workarounds).
2. **SIGN-001** — wire release `signingConfig` reading from `android/key.properties`. Foundation: CI infrastructure (`deploy-production.yml:75-83`) already prepared, this fix activates it.

### batch_2_p1

3. **CRASHLYTICS-001** — wire `FlutterError.onError` + `PlatformDispatcher.onError` + `setCrashlyticsCollectionEnabled` in `main.dart`. PII scrub helper.
4. **REL-MINIFY-001** — enable `isMinifyEnabled` + `isShrinkResources` + ProGuard rules. Bundle with SIGN-001 (same `buildTypes.release` block).
5. **CTRL-TEST-001** — write 3 missing Feed controller tests (post_controller, feed_controller, app_camera_controller). Depends on ARCH LAYER-001/-002 fix.
6. **WIDGET-TEST-001** — write 11 missing widget tests (4 Feed presentation + 7 Auth presentation).
7. **FUNC-TEST-001** — delete or replace 2 placeholder test files (`onFriendshipDeleted.test.ts` + `feed/feed.rules.test.ts`).
8. **CI-MOBILE-001** — add `flutter test integration_test/` step to `pr-check.yml` (post E2E-001).

### batch_3_p2

9. **CI-MOBILE-002** — add `actions/setup-java@v4` step to `pr-check.yml flutter` job.
10. **CI-MOBILE-003** — add `./gradlew :app:testDebugUnitTest` step (depends on CI-MOBILE-002).
11. **DOCS-REL-001** — create `docs/release.md` with 6-section pre-launch checklist.
12. **UNIT-001** — write `firebase_storage_repository_test.dart` (depends on ARCH DATA-ARCH-001 fix).

### batch_4_p3

13. **CI-FUNC-001** — switch CI from `npm test` to `npm run test:coverage` + upload coverage artifact.
14. **REL-VERSION-001** — pick single version source (pubspec.yaml recommended), add CI guard against drift.
15. **TEST-QUALITY-001** — audit ProviderContainer disposal in test/ files; fix missing `addTearDown(container.dispose)`.

## test_plan_after_fix

- `E2E-001`: `(cd apps/mobile && flutter test integration_test/app_test.dart -d <android-device>)` — 1 green E2E pass on Android emulator
- `SIGN-001`: `(cd apps/mobile && flutter build apk --release && apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk)` — returns release fingerprint (not debug)
- `CRASHLYTICS-001`: dev-side `FirebaseCrashlytics.instance.crash()` in debug → verify dashboard receives within 5min; `(cd apps/mobile && flutter test test/core/observability/crashlytics_helper_test.dart)` — PII scrub assertions pass
- `REL-MINIFY-001`: `(cd apps/mobile && flutter build apk --release)` produces APK ≥ 30% smaller than current; install on Android 7 device → sign-in + feed render survive
- `CTRL-TEST-001`: `(cd apps/mobile && flutter test test/features/feed/application/)` — 3 new test files, ≥ 12 cases combined, all green
- `WIDGET-TEST-001`: `(cd apps/mobile && flutter test test/features/feed/presentation/ test/features/auth/presentation/)` — 11 new files green; `flutter test --coverage` shows `lib/features/auth/presentation/**` > 50%
- `FUNC-TEST-001`: `(cd firebase/functions && npm test)` — total test count INCREASES; `grep -rn "expect(true).toBe(true)" firebase/functions/test` returns 0
- `CI-MOBILE-001`: smoke test workflow with deliberately failing integration_test → CI reports job failure with emulator artifact
- `CI-MOBILE-002`: PR-check job continues to pass post-Java-install change
- `CI-MOBILE-003`: intentionally break `WidgetSyncWorker.kt` assertion → push PR → CI flutter job fails with gradle test output
- `DOCS-REL-001`: dry-run release with `workflow_dispatch v0.0.1-test` following `docs/release.md` step-by-step; verify each step unambiguous
- `UNIT-001`: `(cd apps/mobile && flutter test test/features/feed/firebase_storage_repository_test.dart)` — 4-5 cases green
- `CI-FUNC-001`: CI artifact `functions-coverage` downloadable from PR Actions tab post-fix; `coverage/lcov-report/index.html` shows per-file %
- `REL-VERSION-001`: dry-run `workflow_dispatch v0.0.1-test` → assert `pubspec.yaml version` matches release tag
- `TEST-QUALITY-001`: `(cd apps/mobile && flutter test test/features/ --test-randomize-ordering-seed=random)` × 3 → all green, no flake

## no_issue_notes

Compact notes for important areas checked with no issue found OR covered by ARCH/SEC.

### Test infrastructure (clean)

- `fake_cloud_firestore` + `firebase_auth_mocks` + `mock_exceptions` + `mocktail` all in `pubspec.yaml:78-81` dev_dependencies. Match `apps/mobile/CLAUDE.md §Testing` "prefer `FakeFirebaseFirestore` over `MockFirestore`" — verified 25 files import `fake_cloud_firestore`, 0 use `MockFirestore`.
- `apps/mobile/test/` mirror convention 100% adherent. `find apps/mobile/test -name "*test.dart" | grep -E '[A-Z]'` returns 0 hits — all snake_case per `CLAUDE.md §Naming`.
- 0 hits for `skip:`, `xtest`, `expect(true, true)` placeholders in `apps/mobile/test/` — Dart side clean of false-confidence patterns.
- mocktail used in 21 files; mockito 0 files — consistent mock framework choice.
- 4 controller modules use `mock_exceptions` for `FirebaseAuthException` simulation (auth/application + auth/data) — matches `auth.md` Pattern #10 layer "Data (Auth)".

### Repository test breadth (covered)

- 13/14 `firebase_*_repository.dart` have test mirrors (UNIT-001 covers the 14th).
- `firebase_post_repository_test.dart` (269 lines vs source 296 lines) sample-read: covers `createPost` happy + dual camera + select-audience-empty-throws + select-audience-success cases. Comment at line 86 acknowledges "permission-denied in prod" without testing that error mapping path — covered by ARCH DATA-ARCH-001 (error mapping repo addition; this test gap will close naturally).
- Repository tests for `friend` / `notification` / `reaction` don't test FirebaseException → AppError mapping because mapping doesn't exist yet — covered by ARCH DATA-ARCH-001. KHÔNG re-flag here.

### Controller test breadth (covered with CTRL-TEST-001 + 1 note)

- 11/16 controllers have test mirrors. CTRL-TEST-001 covers the 3 Feed gaps. The remaining 2 not-tested: `password_reset_controller.dart` (DOES have test at `test/features/auth/application/password_reset_controller_test.dart` — re-verify count) + `auth_providers.dart` (provider def, not a controller — different concern, has test). Net gap = 3 Feed controllers (CTRL-TEST-001).
- Pure logic tested: `auth_validators_test.dart`, `chat_time_format_test.dart`, `calculate_streak_test.dart`, `orphan_auth_check_test.dart`, `app_router_test.dart` — `auth.md` Pattern #10 layer "Pure logic" verified.

### Functions tests (clean except FUNC-TEST-001)

- 22 src CF files + 4 helper files; test coverage:
  - **Schema-tested via vitest:** `sendFriendRequest` (index), `acceptFriendRequest`, `blockUser`, `deleteAccount`, `createSpace`, `updateSpace`, `management` (kick/leave/transfer)
  - **Logic-tested:** `onMessageCreated` (receiversOf + bodyPreview), `onPostCreated` (fan-out logic), `onReactionCreated` (isSelfReaction), `_fcm` (isPermanentTokenError), `_helpers` (readDisplayName + isAlreadyExists), `onFriendRequestCreated` (buildFriendRequestPayload), `onFriendRequestAccepted` (similar), `triggers` (Space trigger exports)
  - **Real rules tests** (`test/rules/*.rules.test.ts`): chat, friend, notification, reaction, settings, space — 6 collection-specific files using real `initializeTestEnvironment`
  - **Schema-only vitest** OK because business logic lives in CF body that's tested via rules-test integration emulator
  - 4 TODO comments referencing `#92/ThienPDM` (acceptFriendRequest + onFriendshipDeleted) + `#136/ThienPDM` (Space triggers) — linked issues, OK per `CLAUDE.md §Testing & Verification` "no `// TODO` without a linked issue"
- vitest.config.ts splits unit vs rules tests cleanly (vitest.rules.config.ts with 30s timeout for emulator); CI runs both via `pr-check.yml:124` (`npm test`) + `pr-check.yml:153-160` (rules).

### CI workflow patterns (mostly clean)

- Flutter version pinned (`3.41.4`) — `pr-check.yml:73`, `develop-staging.yml:46`, `deploy-production.yml:65` — single version of truth.
- Node version pinned (`20`) — `pr-check.yml:46,110,137`, `develop-staging.yml:78`, `deploy-production.yml:111,139` — consistent.
- Cache enabled: Flutter (`cache: true`), npm (`cache: 'npm'` + `cache-dependency-path`) — both workflows.
- Commitlint runs on PR (`pr-check.yml:36-60`) — type prefix enforced.
- Branch name validation (`pr-check.yml:19-34`) — format `<type>/<DevName>/<desc>` enforced.
- Concurrency control (`pr-check.yml:14-16` `cancel-in-progress: true`) — saves CI minutes per duplicate push.
- Secrets via `${{ secrets.X }}` masking — covered SEC pass-2 no_issue_note.
- Production deploy gated by GitHub Environment `production` (`deploy-production.yml:41-44`) — manual approval — covered SEC pass-2.
- Develop-staging paths filter (`develop-staging.yml:18-23`) — skip docs-only changes — CI minutes optimized.
- Husky pre-commit + pre-push hooks (verified): pre-commit runs dart format + flutter analyze + eslint on staged TS; pre-push validates branch name format. commit-msg runs commitlint.
- Codegen freshness: `pr-check.yml:81` + `develop-staging.yml:54` + `deploy-production.yml:73` all run `build_runner build --delete-conflicting-outputs` before test/build. `.gitignore` excludes `**/*.g.dart` + `**/*.freezed.dart` (covered ARCH ARCH-004 — doc drift in `auth.md`).

### Pre-deploy hooks (clean)

- `firebase/firebase.json:33-37` `predeploy` runs lint + test + build for functions — defense before deploy.
- Emulator ports declared (auth 9099, firestore 9999, storage 9199, functions 5001, ui 4000) — match `vitest.rules.config.ts` test setup (host 127.0.0.1 port 9999/9199).
- `singleProjectMode: true` (firebase.json:57) — prevents project-id mistakes.

### Android release / native (covered or noted)

- `signingConfig = signingConfigs.getByName("debug")` (build.gradle.kts:42) — promoted to P0 SIGN-001 per `00_inventory_map.md` flag.
- Android Kotlin test infra wired (junit 4.13.2 + mockk 1.13.13 + robolectric 4.13 + work-testing 2.9.1 + coroutines-test 1.8.1 + androidx-test-core 1.6.1) — `WidgetSyncWorkerTest.kt` exists 15.2KB. CI not running it → CI-MOBILE-003.
- `INTERNET` is the only manifest permission. RECEIVE_BOOT_COMPLETED + POST_NOTIFICATIONS missing — covered by SEC PERM-001 (not re-flagged).
- CAMERA + READ_MEDIA_IMAGES auto-merged via plugin manifests — covered SEC pass-1 NOTE.
- `assetlinks.json` SHA256 fingerprint at `firebase/public/.well-known/assetlinks.json` covers `dev.meep.meep` for autoVerify — covered SEC pass-7 NOTE; SIGN-001 fix will need fingerprint update for production keystore.
- JVM 17 + coreLibraryDesugaring enabled (build.gradle.kts:17-21) — match Flutter 3.41 requirement.

### Emulator/prod safeguards (clean)

- `_useEmulator` gated by `--dart-define=USE_EMULATOR` (main.dart:48), defaults false — covered SEC pass-1.
- Release build doesn't pass `--dart-define=USE_EMULATOR` → won't connect emulator at runtime — verified.
- Android `10.0.2.2` host for emulator only triggered when `_useEmulator == true` — verified.

### Auth tests stratification (clean)

- `auth.md` Pattern #10 5-layer stratification verified:
  - Data (Firestore): `firebase_user_repository_test.dart` ✓
  - Data (Auth): `firebase_auth_repository_test.dart` ✓ (with mock_exceptions per auth.md reference)
  - Application (Controller): `login_controller_test.dart`, `sign_up_controller_test.dart`, `password_reset_controller_test.dart` ✓
  - Pure logic: `auth_validators_test.dart`, `orphan_auth_check_test.dart`, `app_router_test.dart` ✓
  - UI Widget: `app_text_input_test.dart` (shared) ✓ — BUT auth pages (login_email_page, signup_*_page) have 0 widget tests → WIDGET-TEST-001
- Auth module is canonical reference per inventory — pattern #10 holds.

### Coverage targets vs current state (gap quantified, not flagged separately)

- CLAUDE.md targets: logic ≥ 80%, data ≥ 70%, UI ≥ 50%.
- Current state cannot be measured without running `flutter test --coverage` (blocked in audit-only mode). Estimate based on file ratios:
  - Logic (controllers): 11/16 = 69% file presence — likely below 80% line coverage. CTRL-TEST-001 closes Feed gap.
  - Data (repositories): 13/14 = 93% file presence — likely meets ≥ 70% line coverage. UNIT-001 closes the 1 missing.
  - UI (widgets): ~ 35-40% file presence (many pages untested) — likely below 50% line coverage. WIDGET-TEST-001 closes critical path.
- NOTE-only: do not flag coverage % as separate issue; CTRL-TEST-001 + WIDGET-TEST-001 + UNIT-001 collectively close the gap.

### Branch protection (not verifiable)

- GitHub repo settings (require PR review + status checks pass) NOT verifiable from repo state. `docs/team-workflow.md §6` documents intent. NOTE-only per SEC pass-1 same NOTE.

### Issues covered by Phase A (NOT re-flagged here)

- App Check absent → covered by SEC APPCHECK-001 (P0). DOCS-REL-001 references as pre-launch checklist item.
- `/users/{uid}` allow read if isAuthed → covered by SEC USER-SEC-001 (P0). DOCS-REL-001 references.
- Storage /posts read-by-any-authed → covered by SEC STORAGE-001.
- /posts update field whitelist missing → covered by SEC POST-SEC-001.
- /conversations create stranger-DM → covered by SEC CHAT-SEC-001.
- /conversations update value validation → covered by SEC CHAT-SEC-002.
- deleteAccount no server-side reauth → covered by SEC AUTH-SEC-001.
- Email verification not enforced → covered by SEC AUTH-SEC-002.
- /usernames `if true` read → covered by SEC USERNAME-SEC-001.
- /usernames create squat → covered by SEC USERNAME-SEC-002.
- Widget clearData not called in deleteAccount → covered by SEC WIDGET-SEC-001.
- /users/{uid} update displayName length → covered by SEC USER-SEC-002.
- TESTING-SEC-001 (rules test breadth) — collection coverage of /friendships/{pid}, /spaces/{spaceId}, /space_members, /posts/reactions, /users/notifications, /users/fcmTokens, /users/private — SEC pass-7 corrects: 6 of these collections ALREADY have rules tests in `test/rules/*.rules.test.ts`. Gap is narrower: only `/posts/{postId}/reactions` (covered by `test/rules/reaction.rules.test.ts`) + `/users/notifications` (covered by `notification.rules.test.ts`) + `/users/fcmTokens` (covered by `notification.rules.test.ts`). `/users/private` and Storage `/posts/{uid}` still missing — covered by SEC TESTING-SEC-001 with priority order — do not re-flag.
- /diary update privacy enum → covered by SEC DIARY-SEC-001.
- Manifest RECEIVE_BOOT_COMPLETED + POST_NOTIFICATIONS → covered by SEC PERM-001.
- /friendships pid format → covered by SEC FRIEND-SEC-001.
- Zod `.strict()` → covered by SEC FUNC-SEC-001.
- Idempotency event marker → covered by SEC FUNC-SEC-002.
- CI fallback `|| echo warning` → covered by SEC CI-SEC-001.
- `feed/application/*.dart` Firebase direct → covered by ARCH LAYER-002 (test gap CTRL-TEST-001 is symptom).
- `feed/presentation/*.dart` Firebase direct → covered by ARCH LAYER-001 (widget test gap WIDGET-TEST-001 is symptom).
- Feed providers self-construct → covered by ARCH FEED-ARCH-001.
- `DocumentSnapshot? lastDoc` exposed → covered by ARCH LAYER-003.
- Repository raw FirebaseException → covered by ARCH DATA-ARCH-001 (test gap UNIT-001 is symptom).
- /friendships direct query bypass FriendRepository → covered by ARCH FEED-ARCH-002.
- Post model misplaced → covered by ARCH ARCH-001.
- 20 files >300 lines → covered by ARCH ARCH-002.
- State colocation in 4 controllers → covered by ARCH STATE-ARCH-001.
- Duplicate Home implementation → covered by ARCH HOME-ARCH-001.
- Settings as logout/delete orchestrator → covered by ARCH SETTINGS-ARCH-001.
- Hex color helper duplicate → covered by ARCH CORE-001.
- PostCard imports Post from feed → covered by ARCH SHARED-001.
- Debug error view Firebase type → covered by ARCH LAYER-004.
- /inbox auth bypass → covered by ARCH ROUTER-001.
- sign_in_with_apple unused → covered by ARCH PUBSPEC-001.
- RollCall scaffold missing → covered by ARCH ARCH-003 (DOCS-REL-001 references as M3 scope-decision blocker).
- `.gitignore` vs auth.md gen file commit policy → covered by ARCH ARCH-004.
- /dev/widgets route ungated → covered by ARCH DEV-001.
- Deeplink scheme drift → covered by ARCH DEEPLINK-001.

## postcheck

- git_status_after:
  - `?? docs/audits/06_testing_ci_release_audit.md` (new file, intended)
  - `?? tmp/docs/ThienPDM/06-testing-ci-release-audit` (audit staging, pre-existing)
- changed_files_after:
  - `docs/audits/06_testing_ci_release_audit.md`
- unexpected_modified_files: none

## final_verdict

verdict: not_ready

**Rationale:**
- 2 P0: E2E-001 (zero integration tests vs CLAUDE.md mandate) + SIGN-001 (release signs with debug keystore — Play Store reject + CI keystore work ineffective).
- 6 P1 cluster around 3 themes: (a) test coverage gaps directly traceable to ARCH layering violations (CTRL-TEST-001 + WIDGET-TEST-001 + CI-MOBILE-001) — must wait for ARCH batch_1 to land cleanly; (b) release readiness (REL-MINIFY-001 + CRASHLYTICS-001) — no ProGuard, no production error signal; (c) test quality (FUNC-TEST-001) — 2 placeholder files report false green.
- 4 P2 (CI-MOBILE-002 Java setup, CI-MOBILE-003 Kotlin tests, DOCS-REL-001 runbook, UNIT-001 Storage repo).
- 3 P3 (CI-FUNC-001 coverage, REL-VERSION-001 source-of-truth, TEST-QUALITY-001 disposal).
- **Total: 15 issues — P0=2, P1=6, P2=4, P3=3.**

**Cross-audit dependency graph for M3 ship readiness (combined with Phase A):**
- **Sprint 1 (batch_1 of all 3 audits):** ARCH LAYER-001/-002/FEED-ARCH-001 + SEC APPCHECK-001/USER-SEC-001 + TEST SIGN-001/E2E-001 = unblocks safe testing + production crypto + release signing.
- **Sprint 2 (batch_2 of all 3):** ARCH 7 P1 + SEC 6 P1 + TEST 6 P1 = settles core layering, security boundaries, release polish.
- **Sprint 3 (batch_3 polish):** ARCH 5 P2 + SEC 7 P2 + TEST 4 P2 + DOCS-REL-001 runbook = final pre-M3 sweep.

After batch_1 (4 P0 across 3 audits) + batch_2 (13 P1 + 6 P1 + 6 P1 = 25 P1 across 3 audits), revisit for `almost_ready_after_p0_p1`. P2/P3 are non-blocking polish.

**Recommended path for M3 ship (28/5 → 9/6, 12 days):**
1. Day 1-3: ARCH batch_1 (2 P0) — unblocks test refactor.
2. Day 4-5: TEST batch_1 (SIGN-001 + E2E-001) — release crypto + golden path.
3. Day 6-7: SEC batch_1 (APPCHECK-001 + USER-SEC-001) — production security.
4. Day 8-10: All 3 audits' P1 fixes in parallel (4 devs split by module ownership).
5. Day 11-12: Smoke test + DOCS-REL-001 dry-run release + final QA.

If timeline slips: defer SEC USERNAME-SEC-001 + REACTION-SEC-001 + USER-SEC-002 + DIARY-SEC-001 (defense-in-depth) + all P3s. Do NOT defer P0/P1.

## self_verification_log

<!-- 4 passes recorded after first draft per audit prompt. Each pass logs 1 line per pass; exit criteria checked per pass. -->

pass_1_checklist: N=14 sub-sections (~85 line items in §Audit Checklist), M=15 issues, K=42 no_issue_notes mappings (each sub-section mapped to ≥1 issue or note via cross-reference), gap=0 — each prompt checklist sub-section mapped: Unit tests Repository→UNIT-001+DATA-ARCH-001-ref+no_issue (13/14); Unit tests Controller→CTRL-TEST-001+no_issue (11/16 + auth.md Pattern #10 layer "Application"); Widget tests→WIDGET-TEST-001+no_issue (auth tests stratification); Integration tests→E2E-001 (zero files, all 5 scenarios); Functions unit tests→FUNC-TEST-001+no_issue (22 src, 24 test files); Rules tests→FUNC-TEST-001+SEC TESTING-SEC-001-ref+no_issue (real emulator coverage 6 modules); False-confidence tests→FUNC-TEST-001 (5 placeholder asserts found)+no_issue (0 Dart-side skip/xtest); Test infrastructure quality→TEST-QUALITY-001+no_issue (mocktail consistency); Test mirror convention→UNIT-001+no_issue (snake_case 100%); Codegen freshness→no_issue (ARCH ARCH-004-ref doc drift, NOT a CI gap); CI mobile pipeline→CI-MOBILE-001+CI-MOBILE-002+CI-MOBILE-003+no_issue (Flutter pin, cache, codegen step); CI Functions pipeline→CI-FUNC-001+no_issue (lint+typecheck+test+Node pin); CI rules pipeline→SEC CI-SEC-001-ref (covered Phase A); CI deploy workflow→no_issue (env approval, secret masking, if:false guards); Branch protection→NOTE-only (not verifiable from repo state); Android release config→SIGN-001+REL-MINIFY-001+SEC PERM-001-ref+no_issue (assetlinks SHA256); Debug/emulator flags→no_issue (USE_EMULATOR dart-define gated); Setup reproducibility→DOCS-REL-001+no_issue (docs/setup.md covers dev tooling); Final release gate→DOCS-REL-001 (creates checklist).

pass_2_schema: total=15, missing_field_fixed=0 (every issue has sev/blocker/area/files/loc/symbols/evidence/confidence_impact/risk/fix/authority/test/deps), severity_demoted=0 (no demotions in pass-2), evidence_failed_grep=0 — re-grep all 15 evidence quotes via Bash against source files: E2E-001 `git ls-files apps/mobile/integration_test/**` returns 0; SIGN-001 build.gradle.kts:42 `signingConfig = signingConfigs.getByName("debug")`; CTRL-TEST-001 `find apps/mobile/test/features/feed -name "*_controller_test.dart"` returns 1 (only feed_filter); WIDGET-TEST-001 `find apps/mobile/test -name "*home_screen*"` returns 1 only (home_page_test of skeleton); REL-MINIFY-001 `grep "isMinifyEnabled" apps/mobile/android/app/build.gradle.kts` returns 0; CRASHLYTICS-001 `grep "Crashlytics" apps/mobile/lib` returns 0; FUNC-TEST-001 `grep "expect(true).toBe(true)" firebase/functions/test` returns 5 hits in 2 files (verified); CI-MOBILE-001 `pr-check.yml:62-98` Flutter job has no integration_test step (verified by full file read); CI-MOBILE-002 `grep "setup-java" .github/workflows/pr-check.yml` returns 1 hit (firestore-rules job only, not flutter job); CI-MOBILE-003 `find apps/mobile/android -name "*Test.kt"` returns 1 (WidgetSyncWorkerTest.kt); CI-FUNC-001 `pr-check.yml:124 npm test` (not test:coverage); DOCS-REL-001 `find docs -name "release*"` returns 0; UNIT-001 `find apps/mobile/test -name "*storage_repository*"` returns 0; REL-VERSION-001 3-source-drift verified; TEST-QUALITY-001 `grep -rln container.dispose apps/mobile/test | wc -l` returns 12 vs 16 ProviderContainer usages.

pass_3_dedupe: before=15, after=15, consolidations=0 — verified no two issues share files[0]+symbols+root_cause+fix: SIGN-001 (build.gradle.kts:42 release signing) vs REL-MINIFY-001 (build.gradle.kts:38-43 release minify) — share file but different LINES + different symbol (signingConfig vs isMinifyEnabled) + different fix (read key.properties vs add minify+ProGuard) — kept separate per dedupe criterion; bundle suggested as SAME-PR but issue-level separate. CTRL-TEST-001 vs WIDGET-TEST-001 share theme "Feed coverage gap" but distinct files (application/ vs presentation/), distinct test pattern (ProviderContainer vs WidgetTester), distinct fix — kept separate. E2E-001 vs CI-MOBILE-001 share theme "integration_test" but distinct concern (test files missing vs CI step missing); CI-MOBILE-001 blocked-by E2E-001 (no point wiring CI for tests that don't exist) — kept separate with deps link. FUNC-TEST-001 covers 2 distinct test files but with single root cause "placeholder expect(true).toBe(true)" + single fix pattern — bundled correctly. DOCS-REL-001 vs other release issues (SIGN-001/REL-MINIFY-001/CRASHLYTICS-001/REL-VERSION-001) — DOCS-REL-001 is the orchestration runbook + cross-references each of those; fix is documentation, not config change — kept separate. UNIT-001 vs ARCH DATA-ARCH-001 — UNIT-001 is test file gap, DATA-ARCH-001 is repository code gap; UNIT-001.deps blocks-by DATA-ARCH-001 (test needs new code structure to assert on) — kept separate per Phase A boundary.

pass_4_coverage: checked=14, partial=1 (controller coverage — sampled 4 of 16 controllers via grep + file listing, not deep-read each controller body), blocked=2 (`flutter test` execution + `npm test` execution — audit-only constraint), total=17, verdict=full — every "checked" area backed by evidence: blocked is execution of `flutter test` + `flutter analyze` + `npm test` per audit-only mandate (static evidence from file listing + content sampling sufficient per prompt LAYER B "Allowed to RUN tests IF available, but parse output without flakiness assumption" — chosen NOT to run to avoid mutating worktree state); partial is controller test coverage where N=11 tested + N=5 not tested verified by `find` listing but only 4 sampled for content (login_controller, post_controller LIB, feed_controller LIB, app_camera_controller LIB) — sufficient to verify gap pattern. All checked areas (test file presence/absence, CI workflow steps, build.gradle release block, main.dart bootstrap, pubspec.yaml deps, Android manifest, firebase config, setup docs, husky hooks, package.json scripts, vitest configs, ProGuard absence, integration_test absence, Crashlytics wiring absence) have file read or grep evidence logged in §commands table. Coverage matches log evidence — no "checked" without grep+sample.
