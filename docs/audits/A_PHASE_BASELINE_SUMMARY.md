# A_PHASE_BASELINE_SUMMARY — Phase A → Phase B handoff

> **Mục đích:** Compact summary của 2 audit Phase A (ARCH PR #293 + SEC PR #294) để 4 sub-agent Phase B đọc TRƯỚC, tránh log duplicate issue mà Phase A đã cover.
>
> **Cách dùng (Phase B sub-agent):**
> 1. Đọc file này TRƯỚC khi quét audit checklist.
> 2. Với mỗi issue định log, check section "Anti-duplicate map" — nếu trùng file + symbol → SKIP, ghi `## no_issue_notes: covered by ARCH-NNN` thay vì log mới.
> 3. Section "Coverage gap" liệt kê area mà Phase A KHÔNG cover → Phase B nên focus.

---

## Phase A scoreboard

| Audit | PR | Total issues | P0 | P1 | P2 | P3 | Self-verify passes | Coverage |
|---|---|---:|---:|---:|---:|---:|---|---|
| 01 Architecture | #293 | 20 | 2 | 7 | 5 | 6 | 4 pass | full + 1 partial (space module) |
| 05 Firebase rules | #294 | 22 | 2 | 6 | 7 | 7 | 7 pass | full |
| **Tổng** | — | **42** | **4** | **13** | **12** | **13** | — | — |

**4 P0 release blocker:**
- ARCH `LAYER-001` — widget gọi `FirebaseAuth.instance.currentUser` direct trong `feed/presentation/{feed_section,home_screen}.dart`
- ARCH `LAYER-002` — controller gọi `FirebaseAuth.instance` + `FirebaseFirestore.instance.collection(...).doc().id` trong `feed/application/{feed_controller,post_controller}.dart`
- SEC `APPCHECK-001` — chưa activate Firebase App Check → production blocker (CLAUDE.md §Security Guardrails)
- SEC `USER-SEC-001` — `/users/{uid}` `allow read: if isAuthed()` → bất cứ user nào đọc email + friend graph của user khác

---

## Module-level hotspot map

> Phase B sub-agent dùng map này để biết module nào đã được flag nặng (Phase A đã cover hết khía cạnh đó) vs module nào chưa được flag (Phase B nên đào sâu).

| Module | ARCH issues | SEC issues | Hotspot phía Phase A đã cover | Gap mà Phase B nên đào |
|---|---:|---:|---|---|
| **feed** | 7 | 1 (POST-SEC-001) | Layering violation toàn diện (LAYER-001/-002/-003), self-construct provider (FEED-ARCH-001), cross-module data bypass (FEED-ARCH-002), oversized widgets 1031/771/630 lines (ARCH-002), Post model shared (ARCH-001) | UX states (loading/empty/error 4-state), pagination cursor UX, image cache, reaction sheet UX, performance N+1, image pipeline compress |
| **chat** | 1 (ARCH-001 import Post) | 2 (CHAT-SEC-001/-002) | Conversation create privacy + update field whitelist | Mark-as-read UX, send retry UX, presence UX, message pagination perf |
| **friend** | 1 (DATA-ARCH-001 raw exception) | 2 (FRIEND-SEC-001/-002) | Pid format guard + stranger search dependency | Search empty state, request accept/decline UX, unfriend confirm dialog, watchFriends N+1 |
| **notification** | 1 (DATA-ARCH-001 raw exception) | 0 | Raw FirebaseException ở repo boundary | Banner foreground vs background route consistency, permission UX, FCM token write frequency perf |
| **reaction** | 1 (DATA-ARCH-001) | 1 (REACTION-SEC-001) | Update field whitelist thiếu type+size cap | Emoji picker UX, count display optimistic vs server-side |
| **profile** | 1 (ARCH-001) | 1 (USER-SEC-002) | Display name length cap rule | Edit profile UX, avatar upload progress, friend profile vs own profile |
| **diary** | 0 | 2 (DIARY-SEC-001 + STORAGE-002) | Storage path readable + privacy enum check thiếu | Diary autosave UX, image picker pipeline, image_picker_service test coverage |
| **space** | 0 (ARCH partial coverage) | 0 | KHÔNG cover sâu (Phase A đã note partial) | Space create steps UX, member role UX, space owner transfer perf, fan-out cost |
| **settings** | 1 (SETTINGS-ARCH-001 fan-out) | 1 (AUTH-SEC-001 reauth) | Logout/delete orchestrator + reauth window | Block dialog UX, delete account multi-step UX, settings sheet a11y |
| **streak** | 1 (ARCH-001 import Post) | 0 | Cross-module Post import | Calendar UX, streak stat pill, calendar_day_cell coverage |
| **widget** (Flutter) | 0 | 1 (WIDGET-SEC-001 clearData on logout) | Widget cache cleanup on logout | WorkManager interval perf, widget refresh trigger UX, AppWidget battery cost |
| **home** | 1 (HOME-ARCH-001 duplicate) | 0 | Duplicate `home_page.dart` vs `home_screen.dart` | Home tab transition UX, home cold start latency |
| **auth** | 0 (canonical reference) | 1 (AUTH-SEC-002 email verify) | Email verify pre-auth signup | Auth form UX edge cases, OAuth cancel handling |
| **rollcall** | 1 (ARCH-003 missing module) | 0 | Module skeleton missing | Toàn bộ module — Phase B skip (Tier 0+ chưa ship) |
| **core/router** | 2 (ROUTER-001 debug bypass, DEV-001 dev route in prod) | 0 | Auth guard + dev route | Deeplink cold vs warm start UX, redirect loop |
| **core/utils** | 1 (CORE-001 duplicate hex_color) | 0 | Duplicate helper | — |
| **shared/widgets** | 1 (SHARED-001 PostCard coupling) | 0 | PostCard depend Post model | API consistency thresholds, button heights cross-feature |


---

## Cross-cutting themes (Phase B đọc kỹ)

### Theme 1 — Layering violation tập trung ở feed module (P0)

**ARCH covers (4 issue):**
- `LAYER-001` (presentation), `LAYER-002` (application), `LAYER-003` (state has DocumentSnapshot), `FEED-ARCH-001` (provider self-construct)
- `DATA-ARCH-001` (repos throw raw FirebaseException, 5 modules)
- `LAYER-004` (debug widget imports FirebaseException — P3, OK)

**Phase B implication:**
- **UX audit (03):** widget test cho feed sẽ fail vì widget call Firebase direct → flag UX-FEED-LOADING-* về Phase A LAYER-001/-002 KHÔNG báo lại như P0 UX issue.
- **PERF audit (04):** rebuild excess trong feed có thể là **symptom** của LAYER-001/-002 (provider self-construct → no granular `.select()` opportunity). Cite ARCH-FEED-001 nếu duplicate.
- **TEST audit (06):** test coverage feed gap là **consequence** của Phase A blocker — không thể widget test khi widget call Firebase direct. Báo gap nhưng cite ARCH LAYER-001/-002 làm root cause.

### Theme 2 — Privacy boundary rộng ở client read paths (P0)

**SEC covers:**
- `USER-SEC-001` (P0): client đọc `/users/{uid}` qua 4 repository file (FirebaseUserRepository, FirebaseProfileRepository, FirebaseFriendRepository.searchUser, FirebaseFriendRepository.watchFriends batch)
- `FRIEND-SEC-002` (P2 blocker for USER-SEC-001 rollout): friend stranger search implementation blocker
- `STORAGE-001` + `STORAGE-002` (P1): post + diary image readable bởi any authed → bypass friend boundary

**Phase B implication:**
- **UX audit (03):** profile screen friend vs own UX có thể design assume friend xem được full profile — nhưng sau khi fix USER-SEC-001 rule sẽ tighten. Flag UX edge case nhưng cite USER-SEC-001 làm dependency.
- **CQ audit (02):** repository search code có magic strings như field `username` — flag CQ issue nhưng không re-flag privacy aspect (covered SEC).
- **PERF audit (04):** N+1 trong `watchFriends` batch reads `/users/{fuid}` — flag perf nhưng cite USER-SEC-001 sẽ fix N+1 luôn (chuyển sang `/users/{uid}/public/profile` subcollection 1 batch query).
- **TEST audit (06):** rules tests for USER-SEC-001 fix sẽ cần update — flag test gap nhưng cite Phase A 6-step migration plan.

### Theme 3 — Repository boundary error mapping thiếu (P1)

**ARCH covers:** `DATA-ARCH-001` — 5 repository file throw raw FirebaseException (post, storage, friend, reaction, notification)

**Phase B implication:**
- **CQ audit (02):** error mapping consistency là CQ concern, nhưng Phase A đã flag P1 cho 5 file. CQ KHÔNG re-flag 5 file đó. CQ có thể flag tương tự trong file Phase A chưa kiểm tra (e.g., `firebase_diary_repository.dart`, `firebase_space_repository.dart`, `firebase_conversation_repository.dart`, `firebase_settings_repository.dart`) NẾU phát hiện cùng pattern.

### Theme 4 — Cross-module Post entity coupling (P1)

**ARCH covers:** `ARCH-001` — Post model ở `features/feed/data/post.dart` nhưng import bởi 11 file ngoài feed module (chat/streak/profile/shared/widgets + router).

**Phase B implication:**
- **CQ audit (02):** Post-related code quality issue (duplicate logic, abstraction) trong các module importer — flag bình thường, nhưng KHÔNG re-flag Post should move to shared (Phase A đã cover).
- **PERF audit (04):** Post deserialization N+1 patterns trong importer modules — flag bình thường.

### Theme 5 — Oversized widget files (P1)

**ARCH covers:** `ARCH-002` — 17 file vượt threshold, top 3: `feed_section.dart` 1031 lines, `capture_preview_screen.dart` 771, `home_screen.dart` 630.

**Phase B implication:**
- **UX audit (03):** layout/overflow issue trong 17 file này có thể tồn tại nhưng KHÔNG re-flag oversize. Flag UX riêng (overflow Text, missing SafeArea, etc.).
- **PERF audit (04):** rebuild excess trong oversized widget — flag perf riêng cite ARCH-002 làm context.

### Theme 6 — Deeplink invite/share drift (P1)

**ARCH covers:** `DEEPLINK-001` — scheme drift `meep://profile/...` vs `https://meep.app/invite/...`, AndroidManifest mismatch, `/invite/:uid` route to HomePage placeholder.

**Phase B implication:**
- **UX audit (03):** invite/share UX cold start vs warm start — KHÔNG re-flag scheme drift (cover bởi ARCH). Flag share UX (haptic, confirmation, error state) riêng.
- **TEST audit (06):** integration test for deeplink — flag gap, cite ARCH DEEPLINK-001 làm baseline.


---

## Anti-duplicate map (file:symbol → covered-by)

> Phase B sub-agent search file/symbol trong map này TRƯỚC khi log issue. Trùng → skip log mới + ghi `no_issue_notes`.

### apps/mobile/lib/features/feed/

| File | Symbol | Covered by | Sev |
|---|---|---|---|
| `feed/presentation/feed_section.dart` | `FeedSection.build` (call FirebaseAuth direct) | ARCH-LAYER-001 | P0 |
| `feed/presentation/home_screen.dart` | `_PostPage.build` (call FirebaseAuth direct) | ARCH-LAYER-001 | P0 |
| `feed/application/feed_controller.dart` | `FeedController.build` (FirebaseAuth direct) | ARCH-LAYER-002 | P0 |
| `feed/application/feed_controller.dart` | `postRepositoryProvider`, `storageRepositoryProvider` (self-construct) | ARCH-FEED-ARCH-001 | P1 |
| `feed/application/post_controller.dart` | `PostController.submit` (Firebase direct) | ARCH-LAYER-002 | P0 |
| `feed/application/feed_state.dart` | `FeedState.lastDoc` (DocumentSnapshot exposed) | ARCH-LAYER-003 | P1 |
| `feed/data/firebase_post_repository.dart` | repo error mapping (raw FirebaseException) | ARCH-DATA-ARCH-001 | P1 |
| `feed/data/firebase_post_repository.dart` | `_getFriendUids` (direct friendships query) | ARCH-FEED-ARCH-002 | P1 |
| `feed/data/firebase_storage_repository.dart` | repo error mapping | ARCH-DATA-ARCH-001 | P1 |
| `feed/presentation/feed_section.dart` | file size 1031 lines | ARCH-ARCH-002 | P1 |
| `feed/presentation/capture_preview_screen.dart` | file size 771 lines | ARCH-ARCH-002 | P1 |
| `feed/presentation/home_screen.dart` | file size 630 lines | ARCH-ARCH-002 | P1 |
| `feed/data/post.dart` | Post model misplaced | ARCH-ARCH-001 | P1 |

### apps/mobile/lib/features/{friend,notification,reaction}/

| File | Symbol | Covered by | Sev |
|---|---|---|---|
| `friend/data/firebase_friend_repository.dart` | repo error mapping | ARCH-DATA-ARCH-001 | P1 |
| `friend/data/firebase_friend_repository.dart` | `searchUser` (stranger search dependency) | SEC-FRIEND-SEC-002 | P2 |
| `notification/data/firebase_notification_repository.dart` | repo error mapping | ARCH-DATA-ARCH-001 | P1 |
| `reaction/data/firebase_reaction_repository.dart` | repo error mapping | ARCH-DATA-ARCH-001 | P1 |

### apps/mobile/lib/core/ + main.dart

| File | Symbol | Covered by | Sev |
|---|---|---|---|
| `core/router/app_router.dart` | `authRedirect` debug bypass | ARCH-ROUTER-001 | P3 |
| `core/router/app_router.dart` | `/dev/widgets` route in prod | ARCH-DEV-001 | P3 |
| `core/router/app_router.dart` | `/invite/:uid` → HomePage placeholder | ARCH-DEEPLINK-001 | P1 |
| `core/utils/hex_color.dart` + `core/theme/hex_color.dart` | duplicate helper | ARCH-CORE-001 | P2 |
| `main.dart` | missing `FirebaseAppCheck.activate` | SEC-APPCHECK-001 | P0 |
| `firebase_options.dart` | hardcoded staging apiKey (context for APPCHECK) | SEC-APPCHECK-001 | P0 |

### firebase/

| File | Symbol | Covered by | Sev |
|---|---|---|---|
| `firestore.rules:62` | `/users/{uid}` allow read if isAuthed | SEC-USER-SEC-001 | P0 |
| `firestore.rules:69-72` | `/users/{uid}` update mutable field length | SEC-USER-SEC-002 | P2 |
| `firestore.rules:104` | `/usernames` allow read if true | SEC-USERNAME-SEC-001 | P2 |
| `firestore.rules:105-106` | `/usernames` create lacks cross-doc check | SEC-USERNAME-SEC-002 | P3 |
| `firestore.rules:147-150` | `/posts` update no field whitelist | SEC-POST-SEC-001 | P1 |
| `firestore.rules:163-168` | `/posts/{postId}/reactions` update whitelist | SEC-REACTION-SEC-001 | P2 |
| `firestore.rules:174-180` | `/friendships/{pid}` no pid format guard | SEC-FRIEND-SEC-001 | P3 |
| `firestore.rules:288-289` | `/conversations` create arbitrary participants | SEC-CHAT-SEC-001 | P1 |
| `firestore.rules:294-302` | `/conversations` update value validation | SEC-CHAT-SEC-002 | P2 |
| `firestore.rules:338-345` | `/diary` update privacy enum + type guard | SEC-DIARY-SEC-001 | P2 |
| `storage.rules:9` | `/posts/{uid}` read by any authed | SEC-STORAGE-001 | P1 |
| `storage.rules:30` | `/diary/{uid}` read by any authed | SEC-STORAGE-002 | P1 |
| `functions/src/settings/deleteAccount.ts:148` | no server-side reauth | SEC-AUTH-SEC-001 | P1 |
| `functions/src/firestore.rules.test.ts` | missing /conversations test | SEC-TESTING-SEC-001 | P2 |
| `.github/workflows/pr-check.yml:153-160` | rules tests CI fallback warning | SEC-CI-SEC-001 | P3 |

### Cross-cutting

| File | Symbol | Covered by | Sev |
|---|---|---|---|
| `shared/widgets/post_card.dart` | imports `features/feed/data/post.dart` | ARCH-SHARED-001 / ARCH-ARCH-001 | P2/P1 |
| `chat/application/chat_providers.dart` | imports Post | ARCH-ARCH-001 | P1 |
| `chat/data/chat_seed_data.dart` | imports Post | ARCH-ARCH-001 | P1 |
| `streak/data/streak_repository.dart` | imports Post | ARCH-ARCH-001 | P1 |
| `profile/application/friend_posts_provider.dart` | imports Post | ARCH-ARCH-001 | P1 |
| `home/presentation/home_page.dart` vs `feed/presentation/home_screen.dart` | duplicate Home | ARCH-HOME-ARCH-001 | P2 |
| `settings/application/settings_controller.dart:78-115,127-158` | logout + deleteAccount fan-out | ARCH-SETTINGS-ARCH-001 | P2 |
| `chat/presentation/widgets/debug_error_view.dart:3,90` | FirebaseException in widget (debug) | ARCH-LAYER-004 | P3 |
| `widget/application/widget_data_service.dart:112-117` | clearData not called on logout | SEC-WIDGET-SEC-001 | P3 |
| `pubspec.yaml:58` | unused `sign_in_with_apple` dep | ARCH-PUBSPEC-001 | P3 |
| `android/app/src/main/AndroidManifest.xml` | missing RECEIVE_BOOT_COMPLETED | SEC-PERM-001 | P3 |
| `apps/mobile/lib/features/rollcall/` | folder missing | ARCH-ARCH-003 | P3 |


---

## Coverage gap — Phase B nên focus

Phase A đã cover sâu **architecture layering + Firebase rules privacy + boundary error mapping + secrets/permissions**. Phase B nên đào sâu các area mà Phase A KHÔNG cover (do scope khác):

### CQ audit (02) — focus area

- Naming consistency cross-module (anti-terms `user_id`/`friend_id` chưa scan đủ)
- Dead code (unused providers, commented blocks ≥ 3 lines)
- Duplicate logic giữa repository không phải feed (post/storage/friend/reaction/notification đã cover bởi ARCH-DATA-ARCH-001)
- Magic strings (Firestore collection names hardcode multiple sites)
- Test code quality (mock-only assertions, placeholder asserts)
- TS Functions strict mode + ESLint disable
- Pubspec/package.json dep version range too loose

### UX audit (03) — focus area

- **4 required states** (loading/error/empty/data) per screen — Phase A KHÔNG audit
- Form validation feedback inline (AutovalidateMode)
- Pull-to-refresh consistency
- Caption length cap UX (≤30 chars enforce — Phase A audit cap ở rule layer, UX khác)
- Notification permission UX (Android 13+ POST_NOTIFICATIONS)
- Camera permission denied fallback UX
- Image placeholder + error widget (CachedNetworkImage)
- Theme consistency (hardcoded Color/TextStyle ngoài core/theme)
- A11y (Semantics, tooltip, touch target 48dp)
- Destructive action confirm dialog (unfriend, block, delete account)
- SafeArea + keyboard resize
- Hero animation tag conflict
- PopScope unsaved changes warn
- Date formatting DateTime.toString() vs intl

### PERF audit (04) — focus area

- `const` constructor coverage (Phase A flag oversize widgets ARCH-002, không flag const)
- RepaintBoundary opportunities trên feed grid + camera overlay
- Riverpod `.select()` granularity (Phase A flag self-construct provider, không flag select)
- Image pipeline compress (`flutter_image_compress` + `imageQuality` + `cacheWidth/cacheHeight`)
- WorkManager interval cho widget sync (battery cost)
- FCM token write frequency
- Firestore listener fan-out count trên home screen
- Index coverage cho query `where + orderBy` khác field
- N+1 reads trong `watchFriends` batch (sẽ improve sau khi fix USER-SEC-001 baseline)
- Function cold-start cost + memory config
- Function fan-out idempotency (spacePostFanOut)

### TEST audit (06) — focus area

- **Integration test ZERO files** — flag P0/P1 cho golden path (login + post + feed loop minimum per CLAUDE.md)
- Widget test coverage cho critical screens (sẽ KHÔNG khả thi cho feed cho đến khi fix ARCH-LAYER-001/-002 — flag test gap cite ARCH dependency)
- Codegen freshness (`.g.dart`/`.freezed.dart` committed vs gitignored mismatch — ARCH-ARCH-004 đã flag docs/code drift)
- CI Flutter version pin
- CI matrix Android API levels
- Golden tests theme regression
- Test isolation (ProviderContainer disposal)
- Android release signing config (debug key in release per inventory map)
- Release readiness gate (Crashlytics, App Check verify, Play Store listing)
- ProGuard rules for Riverpod/Firebase reflection

---

## Recommendation cho Phase B order

| Worktree | Audit | Suggested start order | Rationale |
|---|---|---|---|
| 02 CQ | Code quality | First | Light dependency on Phase A, can run independently |
| 04 PERF | Performance | First | Independent depth on perf hotspots |
| 03 UX | UX Flutter | Second | Needs theme/state baseline — Phase A flag layering affects UX testability |
| 06 TEST | Testing/CI/Release | Last | Depends on layering fix recommendation from ARCH for widget test feasibility |

Hoặc anh chạy 4 song song theo recommended trong KICKOFF_PROMPTS Phase B — không có dependency strict, baseline summary này đã đủ context cho cả 4.

---

## Final verdict cho Phase A

`verdict: not_ready` (4 P0 + 13 P1 blocker, mọi P0 cần fix trước M3 release).

**Quality của 2 audit:** xuất sắc. ARCH chạy 4 pass self-verify, SEC chạy 7 pass. Evidence chi tiết với line number cụ thể. Fix instruction có step-by-step migration plan (SEC USER-SEC-001 có 6 step rollout order). Authority cite specific (CLAUDE.md §, prompt §, line number).

Sau khi Phase B xong, em consolidate cuối → `99_global_fix_order.md` với batch P0/P1 fix order + effort estimate.
