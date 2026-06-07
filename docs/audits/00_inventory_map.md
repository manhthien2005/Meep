# 00 — Meep Inventory Map (shared baseline cho 6 audit sub-agent)

> **Purpose:** 6 audit worktree đọc file này TRƯỚC khi build mental map.
> Tránh lặp `git ls-files` 6 lần. Tránh báo false-positive cho known-state.
> **Generated:** 2026-06-07 (audit pass 1)

---

## meta

- repo: Meep
- root: D:/Meep
- branch: `develop`
- last_commits:
  - `6afc953` refactor(cross-module): wire profile data + shared AppTopAvatar + diary stream (#291)
  - `f93cb29` docs: overhaul README (#290)
  - `8f99ae6` fix(notification,home,widget): sửa 6 bug review (#289)
  - `d7b56fe` test(notification): rules tests (#288)
  - `69ac6cb` fix(notification): tap banner foreground → route (#287)
- mode: shared-baseline-for-6-audit-subagents

## baseline_git_status (known-dirty — KHÔNG flag là blocker)

```
M apps/mobile/pubspec.lock     ← known modified, not user in-progress
?? tmp/                          ← audit prompt staging, NOT part of repo
```

→ Sub-agent precheck thấy 2 entry này → ghi `existing_user_changes: no` và bỏ qua.

## stack

- **mobile:** Flutter SDK `^3.5.0` (>=3.22.0) + Riverpod 2 codegen + freezed + json_serializable + go_router 14.6 + cached_network_image 3.4 + camera 0.12 + home_widget 0.7
- **backend:** Firebase (Auth 5.3, Firestore 5.4, Storage 12.3, Functions 5.1, FCM 15.1, Crashlytics 4.1, Analytics 11.3) + Node 20 + TypeScript strict
- **testing:** flutter_test, fake_cloud_firestore, firebase_auth_mocks (mobile); vitest + firestore emulator (functions)
- **platform:** Android-only MVP per ADR-0002. iOS deferred.
- **Android native:** Kotlin (WidgetSyncWorker WorkManager + MeepWidget AppWidget + Glide); minSdk/targetSdk pull từ Flutter SDK defaults; applicationId `dev.meep.meep`; JVM 17.

## adr_index

| id | title |
|---|---|
| 0001 | Firebase-first backend |
| 0002 | Android-first defer iOS |
| 0003 | Task management process |
| 0004 | Solo-dev module ownership |
| 0005 | Deeplink architecture |

## reference_architecture

- **canonical:** `.claude/reference-architectures/auth.md` (status: ready, PR #170 Round D, last-reviewed 2026-05-26)
- **patterns_documented:** 11 patterns
  1. Folder layout — feature-first, strict 3 layers (`data/` + `application/` + `presentation/`)
  2. Repository pattern — abstract + Firebase impl + error mapping
  3. Error model — `AppError` sealed + `fromUnknown` + `OperationCancelledError`
  4. Controller pattern — `@riverpod` NotifierProvider
  5. State pattern — `@freezed` state class
  6. keepAlive decisions (session-scope cho auth, NOT default cho mọi module)
  7. Provider scope/override consistency
  8. Test stratification (data/application/presentation)
  9. Session lifecycle (auth-only — KHÔNG copy mù cho module khác)
  10. Vietnamese error message tại boundary
  11. Folder/file naming snake_case

## modules (13 features)

| module | owner_inferred | layers | notes |
|---|---|---|---|
| auth | ThienPDM | data+app+pres | **canonical reference** |
| chat | ? | data+app+pres | 1-1 chat (Tier 1 stretch) |
| diary | ? | data+app+pres | Diary basic (Tier 0+) |
| feed | ? | data+app+pres | Tier 0 |
| friend | ? | data+app+pres | Tier 0 |
| home | ? | data+app+pres | shell |
| notification | ? | data+app+pres | Tier 0 |
| profile | ? | data+app+pres | Tier 0+ |
| reaction | ? | data+app+pres | Tier 0 |
| settings | ? | data+app+pres | Tier 1 — includes BlockUser + DeleteAccount |
| space | ? | data+app+pres | Tier 0+ |
| streak | ? | data+app+pres | Tier 1 — Streak/Kỷ niệm |
| widget | ? | data+app+pres | Flutter side of home_widget |

> Owner inference: code đã merge từ nhiều dev qua 290+ PR — không thể infer chính xác per-file owner. Sub-agent KHÔNG cần biết owner để audit; chỉ cần áp dụng "no cross-module touch" pattern + solo-dev rule khi report.

## core/

| folder | purpose |
|---|---|
| `core/config/` | environment/flavor config |
| `core/error/` | `AppError` sealed family + `fromUnknown` |
| `core/router/` | `go_router` + deeplink (ADR-0005) |
| `core/theme/` | design tokens — colorScheme/textTheme/proportions |
| `core/utils/` | helpers (hex_color, etc.) |
| `core/validators/` | input validators (auth_validators tested) |

## shared/widgets/ (22 files)

`app_act_text_bar`, `app_avatar`, `app_back_button`, `app_bottom_sheet`, `app_camera_button`, `app_circle_icon_button`, `app_confirm_dialog`, `app_dots_indicator`, `app_glass_surface`, `app_google_button`, `app_note_pill`, `app_photo_frame`, `app_primary_button`, `app_taskbar`, `app_taskbar_widgets`, `app_text_input`, `or_divider`, `photo_detail_screen`, `post_card`, `share_modal`, `share_photo_sheet`, `share_profile_sheet`

## firebase_surface

- `firebase/firestore.rules` — security rules (rules tested PR #288)
- `firebase/storage.rules` — Storage security rules
- `firebase/firestore.indexes.json` — composite indexes
- `firebase/firebase.json` — project config

**Functions entrypoint:** `firebase/functions/src/index.ts`
**Functions modules:**
- `chat/onMessageCreated`
- `feed/onPostCreated`, `feed/onPostDeleted`
- `friend/acceptFriendRequest`, `friend/onFriendshipDeleted`
- `notification/onFriendRequestCreated`, `onFriendRequestAccepted`, `onReactionCreated`, `_fcm`, `_helpers`
- `settings/blockUser`, `settings/deleteAccount`
- `space/createSpace`, `kickMember`, `leaveSpace`, `transferOwnership`, `updateSpace`, `onSpaceDeleted`, `onSpaceMemberAdded`, `onSpaceMemberRemoved`, `spacePostFanOut`

**Functions tests:**
- `firestore.rules.test.ts`
- `storage.rules.test.ts`
- `feed/onPostCreated.test.ts`
- `index.test.ts`

## tests_inventory

| layer | count |
|---|---|
| flutter unit + widget (`apps/mobile/test/**`) | ~80 files |
| flutter integration (`apps/mobile/integration_test/`) | **0** (folder missing) |
| functions unit + rules tests | 4 files |
| Kotlin tests (Android widget) | TBD per build.gradle.kts có configuration |

**Notable test gaps:**
- Không có `integration_test/` folder → ZERO E2E coverage
- CLAUDE.md gốc require: "Integration test for login + post + feed loop minimum"

## android_native

- **applicationId:** `dev.meep.meep`
- **namespace:** `dev.meep.meep`
- **JVM:** 17
- **minSdk/targetSdk:** Flutter SDK defaults (không pin explicit)
- **deeplink hosts:**
  - `meep-staging.firebaseapp.com`
  - `meep-staging.web.app`
- **release signing:** ⚠️ `signingConfig = signingConfigs.getByName("debug")` — TODO release signing not setup
- **uses-permission:** chỉ `INTERNET` (không có `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `CAMERA`, `READ_MEDIA_IMAGES`...)
- **Kotlin native files:**
  - `MainActivity.kt`
  - `MeepWidget.kt` (AppWidget receiver)
  - `WidgetDataStore.kt` (data layer)
  - `WidgetSyncWorker.kt` (WorkManager background sync)
- **Native deps:** WorkManager 2.9.1, kotlinx-coroutines 1.8.1, firebase-bom 33.5.1 (auth+firestore), Glide 4.16.0
- **Test deps:** junit 4.13.2, mockk 1.13.13, robolectric 4.13, work-testing 2.9.1

## ci_workflows

- `.github/workflows/deploy-production.yml`
- `.github/workflows/develop-staging.yml`
- `.github/workflows/pr-check.yml`

## docs_index

- `docs/adr/` — 5 ADRs + README
- `docs/architecture/`, `docs/milestones/`, `docs/plans/`, `docs/product/`, `docs/roadmap/`, `docs/specs/`, `docs/team-onboarding/`
- `docs/dev-guide.html` (59KB), `docs/setup.md`, `docs/team-workflow.md`

## scope_filter (BẮT BUỘC đọc trước khi report issue)

### in-scope (Tier 0 / Tier 0+ — must ship M3)

- Auth, Friend, Camera, ShareePhoto, Feed, PushNotification, Reaction, WidgetAndroid (Tier 0)
- Diary basic, Space basic, RollCall basic, Profile (Tier 0+)

### in-scope-stretch (Tier 1)

- Settings basic, Streak/Kỷ niệm, Chat 1-1 từ ảnh

### out-of-scope — KHÔNG report là gap

- Dual camera, video, memory cards, caption stickers, group chat in Space
- block/report (đã có scaffolding nhưng full ko require)
- account deletion (đã có scaffolding nhưng full ko require)
- **iOS support** — ADR-0002 explicitly defers iOS
- Web target — không trong scope MVP

### platform_filter

- Android-only. Không report iOS-specific gaps là P0.
- Không report missing iOS .plist, Apple Sign-In iOS native config, etc.

## audit_routing_hint

| audit | primary_paths | secondary |
|---|---|---|
| 01_architecture | `apps/mobile/lib/{core,features,shared}`, `main.dart`, `pubspec.yaml` | `firebase/` (boundary only) |
| 02_code_quality | `apps/mobile/lib/**`, `apps/mobile/test/**`, `firebase/functions/src/**` | configs |
| 03_ux_flutter | `apps/mobile/lib/features/**/presentation/**`, `shared/widgets/**`, `core/{router,theme,error,validators}/**` | `android/**` user-facing |
| 04_performance | `apps/mobile/lib/**`, `android/**`, `firebase/functions/**`, `firestore.indexes.json` | rules cost path |
| 05_security_firebase | `firebase/{firestore.rules,storage.rules,functions/**}`, `apps/mobile/lib/**` client surface, `android/**/AndroidManifest.xml`, secrets/env | CI deploy |
| 06_testing_ci_release | `apps/mobile/test/**`, `integration_test/**`, `firebase/functions/test/**`, `.github/workflows/**`, `android/app/build.gradle.kts` release | docs/release |

## reference_authority (cite, KHÔNG import)

Khi report issue, sub-agent có thể cite các source này làm authority anchor (không link out, không fetch — chỉ tham chiếu để justify):

- **Flutter official patterns:** `flutter/skills` repo (10 skills incl. apply-architecture-best-practices, fix-layout-issues, add-widget-test, add-integration-test, build-responsive-layout, setup-declarative-routing)
- **Dart official patterns:** `dart-lang/skills` repo (9 skills incl. add-unit-test, generate-test-mocks, run-static-analysis, fix-runtime-errors, collect-coverage)
- **Meep canonical:** `.claude/reference-architectures/auth.md` (11 patterns)
- **Meep root:** `CLAUDE.md` + `apps/mobile/CLAUDE.md`
- **Meep ADRs:** `docs/adr/0001..0005`

---

## CRITICAL — pre-flight cho mọi audit sub-agent

1. **Đọc file này TRƯỚC** khi build mental map riêng.
2. **Đọc `CLAUDE.md` root + `apps/mobile/CLAUDE.md`** một lần.
3. **Đọc `.claude/reference-architectures/auth.md`** nếu audit chạm `data/` / `application/` / `presentation/` layering.
4. **Precheck git status:** thấy `M apps/mobile/pubspec.lock` + `?? tmp/` → ghi `existing_user_changes: no` (known baseline), KHÔNG abort.
5. **Scope filter:** trước khi log P0/P1, check `scope_filter` — issue về iOS / dual-camera / video / group chat / account-deletion / block-report **KHÔNG báo là gap**.
6. **Authority cite:** khi đề xuất fix pattern, cite `auth.md` hoặc `flutter/skills` / `dart-lang/skills` để justify.
