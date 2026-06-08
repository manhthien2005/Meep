# Phase 2 Quick Plan — Fix 114 issues qua 8 PR

> **TL;DR:** PR #1 APPCHECK đã xong. Còn 7 PR. 3 wave. 3 worktree song song. ~5-7 ngày solo.
>
> Anh không cần đọc playbook 1302 dòng. Chỉ cần: scroll xuống PR muốn làm → copy prompt → paste session pair → em review artifact.

---

## Wave roadmap

| Wave | PR | Branch | Closes |
|---|---|---|---|
| done | PR-1 | fix/ThienPDM/firebase-app-check | SEC-APPCHECK-001 |
| 1 | PR-2 | fix/ThienPDM/release-config-rest | TEST-SIGN-001, REL-MINIFY-001, CI-MOBILE-001/002/003, CI-FUNC-001, CRASHLYTICS-001, REL-VERSION-001, DOCS-REL-001 |
| 1 | PR-3 | fix/ThienPDM/rules-hardening | 17 issue rules + storage + functions auth/input/idempotency (trừ USER-SEC + FRIEND-SEC) |
| 1 | PR-4 | fix/ThienPDM/auth-notification-polish | AUTH-SEC-001/002, NOTIF-PERF-001, NOTIF-UX-PERM-001, FCM token frequency |
| 2 | PR-5 | fix/ThienPDM/feed-refactor | ARCH-LAYER-001/002/003/004, ARCH-001/002, FEED-ARCH-001/002, FEED-PERF-001, FEED-REBUILD-001, UX-CAMERA-UX-001, IMG-PERF-001, feed UX states |
| 2 | PR-6 | fix/ThienPDM/other-modules-polish | DATA-ARCH-001 (5 repo), HOME/SETTINGS/SHARED/ROUTER/DEV/DEEPLINK/PUBSPEC/ARCH-003/004/CORE-001 + UX diary/space/chat/reaction/profile/settings + perf module |
| 3 | PR-7 | fix/ThienPDM/users-public-profile-migration | SEC-USER-SEC-001/002 + PERF-FRIEND-001 + FRIEND-SEC-001/002 (sau PR-3 merged) |
| 3 | PR-8 | feat/ThienPDM/tests-and-quality | TEST-E2E-001, CTRL/WIDGET/FUNC/UNIT TEST, CQ-001..014, THEME, A11Y, polish P2/P3 còn lại |

**Wave 1 (3 worktree song song, 1-2 ngày):** PR-2 + PR-3 + PR-4 độc lập file scope.
**Wave 2 (2 worktree song song, 2-3 ngày):** PR-5 + PR-6 sau wave 1 merged.
**Wave 3 (sequential, 2-3 ngày):** PR-7 sau PR-3 merged. PR-8 sau cùng vì test cần code stable.

---

## Setup worktree 1 lần

```bash
cd /d/Meep
git pull origin develop
git worktree add ../meep-fix-config -b fix/ThienPDM/release-config-rest develop
git worktree add ../meep-fix-rules -b fix/ThienPDM/rules-hardening develop
git worktree add ../meep-fix-auth -b fix/ThienPDM/auth-notification-polish develop
```

Wave 2 dựng thêm sau khi wave 1 merged:
```bash
git pull origin develop
git worktree add ../meep-fix-feed -b fix/ThienPDM/feed-refactor develop
git worktree add ../meep-fix-other -b fix/ThienPDM/other-modules-polish develop
```

Wave 3 tương tự.

---

## Workflow cho mỗi PR

1. Mở Git Bash + Windows Terminal tab mới
2. `cd` vào worktree
3. Mở Claude Code mới (Opus 4.7 1M, max effort)
4. Copy prompt PR đó (block bên dưới) → paste
5. Pair session đọc audit + implement + verify → output SPEC + DIFF + VERIFY
6. Anh copy artifact về session orchestrator (chính)
7. Em review → approve push hoặc request changes
8. Anh push + tạo PR + merge → next PR


---

# PROMPT — PR-2 release-config-rest (Wave 1)

Worktree: `D:/meep-fix-config`. Paste vào session pair mới:

```
Tôi là ThienPDM, solo dev Meep. Phase 2 polish.

Task: Fix 8 issue release config trong 1 PR.

Pre-flight reads:
1. CLAUDE.md (root) + apps/mobile/CLAUDE.md
2. docs/audits/06_testing_ci_release_audit.md — section SIGN-001, REL-MINIFY-001, CRASHLYTICS-001, CI-MOBILE-001/002/003, CI-FUNC-001, REL-VERSION-001, DOCS-REL-001
3. apps/mobile/android/app/build.gradle.kts hiện tại
4. .github/workflows/pr-check.yml hiện tại

Scope:
- Upload keystore + key.properties (gitignored) — anh tự tạo + backup vault
- build.gradle.kts: signingConfigs.release + minifyEnabled + shrinkResources + ProGuard
- Crashlytics: enable collection release, disable debug, PII scrub
- pr-check.yml: pin Flutter version + cache pub-cache + Node version + Android API matrix
- docs/release-checklist.md (new) — keystore restore + Play Store upload steps

Workflow:
1. Chia thành 3-4 commit nhỏ theo logical group (signing / ci / crashlytics / docs)
2. flutter build appbundle --release verify signed by upload key
3. flutter analyze + flutter test pass

Verify checklist:
- flutter build appbundle --release: BUILD SUCCESSFUL
- jarsigner -verify aab: alias upload (không androiddebugkey)
- git status: key.properties + *.jks không tracked
- flutter analyze: 0 errors
- flutter test --no-pub: all pass

Output SPEC + DIFF + VERIFY về orchestrator session. KHÔNG push yet.
```

---

# PROMPT — PR-3 rules-hardening (Wave 1)

Worktree: `D:/meep-fix-rules`. Paste:

```
Tôi là ThienPDM, solo dev Meep. Phase 2 polish.

Task: Fix 17 issue Firebase rules + storage rules + functions auth/input/idempotency trong 1 PR.

Pre-flight reads:
1. CLAUDE.md root §Security Guardrails
2. docs/audits/05_security_firebase_audit.md — đọc tất cả issue TRỪ APPCHECK-001 (đã done PR #1) và USER-SEC-001/002 + FRIEND-SEC-001/002 (để PR-7 migration làm sau)
3. firebase/firestore.rules + firebase/storage.rules hiện tại
4. firebase/functions/src/firestore.rules.test.ts pattern

Scope PR này:
- POST-SEC-001 (rules:147 update field whitelist + caption cap)
- STORAGE-001/002 (storage rules tighten posts + diary read by friend boundary)
- CHAT-SEC-001/002 (conversations create participantIds + update value validation)
- USERNAME-SEC-001/002 (usernames cross-doc check)
- REACTION-SEC-001 (reactions field whitelist + type guard)
- DIARY-SEC-001 (diary update privacy enum + type guard)
- AUTH-SEC-001 (deleteAccount server-side auth_time reauth window)
- FUNC-SEC-001/002 (functions input validation + idempotency)
- TESTING-SEC-001 (rules tests gap cho conversations)
- PERM-001 (AndroidManifest RECEIVE_BOOT_COMPLETED)
- CI-SEC-001 (workflow rules tests fallback removal)

KHÔNG fix USER-SEC-001/002 hoặc FRIEND-SEC-001/002 trong PR này — để PR-7 migration.

Workflow:
1. Sửa firestore.rules theo từng issue evidence (mỗi rule có line:N cụ thể)
2. Sửa storage.rules
3. Sửa deleteAccount.ts thêm auth_time check
4. Thêm rules tests cover positive + negative cho mỗi collection P1
5. AndroidManifest.xml thêm permission nếu cần
6. firebase emulators:exec --only=firestore "cd functions && npm test"

Verify:
- npm test rules: case mới pass cho mỗi collection
- npm run lint: 0 errors
- flutter analyze (nếu touch client): 0 errors

Output SPEC + DIFF + VERIFY về orchestrator. KHÔNG push yet.
```

---

# PROMPT — PR-4 auth-notification-polish (Wave 1)

Worktree: `D:/meep-fix-auth`. Paste:

```
Tôi là ThienPDM, solo dev Meep. Phase 2 polish.

Task: Fix auth flow + notification module trong 1 PR.

Pre-flight reads:
1. CLAUDE.md root + apps/mobile/CLAUDE.md
2. docs/audits/05_security_firebase_audit.md — AUTH-SEC-002 (email verify)
3. docs/audits/03_ux_flutter_audit.md — NOTIF-UX-PERM-001
4. docs/audits/04_performance_audit.md — NOTIF-PERF-001 (FCM token write frequency)
5. .claude/reference-architectures/auth.md Pattern #2 (error mapping VN message)

Scope:
- AUTH-SEC-002: add sendEmailVerification + emailVerified check vào signup
- NOTIF-UX-PERM-001: Android 13+ POST_NOTIFICATIONS rationale dialog + in-app fallback banner
- NOTIF-PERF-001: FCM token write compare local cache trước khi write Firestore
- UX edge case: OAuth cancel handling, session expired redirect, sign-out clear navigation stack

Files touch chính:
- features/auth/application/{sign_up_controller,login_controller}.dart
- features/notification/application/notification_controller.dart
- features/notification/data/firebase_notification_repository.dart
- features/notification/presentation/notification_permission_dialog.dart (new)

Workflow:
1. SignUpController: sau createUserWithEmailAndPassword gọi sendEmailVerification + emit state requireVerify
2. LoginController: check user.emailVerified, nếu false → state có resend CTA
3. NotificationController.requestPermission: nếu denied permanent → fallback banner + Mở Cài đặt
4. FCM token write: SharedPreferences cache, compare trước write Firestore
5. Add unit test cho mỗi controller transition mới

Verify:
- flutter analyze: 0 errors
- flutter test test/features/{auth,notification}/: pass
- Manual: signup → email verify → login flow OK
- Manual: notif permission deny → fallback banner

Output SPEC + DIFF + VERIFY. KHÔNG push yet.
```


---

# PROMPT — PR-5 feed-refactor (Wave 2)

Worktree: `D:/meep-fix-feed`. CHỈ start sau khi Wave 1 (PR-2/3/4) merged. Paste:

```
Tôi là ThienPDM, solo dev Meep. Phase 2 polish — Wave 2.

Task: Refactor feed module toàn diện. Fix 14 issue trong 1 PR.

Pre-flight reads:
1. CLAUDE.md root + apps/mobile/CLAUDE.md
2. .claude/reference-architectures/auth.md (full 11 patterns)
3. docs/audits/01_architecture_audit.md — LAYER-001/002/003/004, ARCH-001/002, FEED-ARCH-001/002
4. docs/audits/04_performance_audit.md — FEED-PERF-001, FEED-REBUILD-001, IMG-PERF-001/002/003
5. docs/audits/03_ux_flutter_audit.md — UX-CAMERA-UX-001, STATE-UX-EMPTY-001, STATE-UX-ERROR-001, UPLOAD-UX-001
6. .claude/skills/flutter-apply-architecture-best-practices/MEEP-ADAPTER.md
7. .claude/skills/flutter-add-widget-test/MEEP-ADAPTER.md

Scope:
A. Architecture (LAYER-001/002 P0 + FEED-ARCH-001 P1):
   - Remove FirebaseAuth + FirebaseFirestore direct trong feed/{presentation,application}
   - currentUidProvider injection
   - PostRepository.submitPost trả Future<String> postId (server-side mint)
   - Provider stub UnimplementedError + main.dart override
B. State (LAYER-003 P1): FeedState.lastDoc DocumentSnapshot sang lastDocId String
C. Performance (FEED-PERF-001 P0 + FEED-REBUILD-001 P1):
   - _watchFriendsFeed: 30 per-author streams → 1 batched whereIn query
   - Riverpod .select() granularity
D. Module move (ARCH-001 P1):
   - Move features/feed/data/post.dart → lib/shared/models/post.dart
   - Update 11 import sites
E. UX (UX-CAMERA-UX-001 P0 + states P1):
   - CameraPermissionFallback widget với Thử lại + Mở Cài đặt CTA
   - Feed empty state Vietnamese CTA
   - Feed error retry button
   - Upload progress + retry on fail
F. Image (IMG-PERF-001 P1): cacheWidth/cacheHeight + flutter_image_compress imageQuality

KHÔNG touch:
- Cross-module file ngoài feed (chat/profile/streak coupling — PR-6)
- Widget oversize split toàn diện (ARCH-002 — gộp PR-6)
- FEED-ARCH-002 cross-module data bypass — PR-6 (cần FriendRepo stable)

Workflow:
1. Refactor layer (A+B)
2. Refactor perf (C)
3. Move Post model (D) — 11 import update
4. UX states (E)
5. Image opt (F)
6. Widget test FeedSection + CameraPermissionFallback + EmptyState
7. Codegen + analyze + test

Verify:
- grep FirebaseAuth.instance + FirebaseFirestore.instance trong lib/features/feed/{presentation,application} = 0
- flutter analyze: 0 errors
- flutter test test/features/feed/: pass
- Manual emulator: golden path post creation + scroll + reaction
- Firebase Console listener count: ≤ 3 (thay vì 31)

Output SPEC + DIFF + VERIFY. KHÔNG push yet.
```

---

# PROMPT — PR-6 other-modules-polish (Wave 2)

Worktree: `D:/meep-fix-other`. Start sau wave 1 merged. Paste:

```
Tôi là ThienPDM, solo dev Meep. Phase 2 polish — Wave 2.

Task: Polish các module còn lại + cross-cutting cleanup trong 1 PR LỚN.

Pre-flight reads:
1. docs/audits/01_architecture_audit.md — DATA-ARCH-001, HOME-ARCH-001, SETTINGS-ARCH-001, SHARED-001, ROUTER-001, DEV-001, DEEPLINK-001, PUBSPEC-001, ARCH-003/004, CORE-001, ARCH-002 oversize, FEED-ARCH-002
2. docs/audits/04_performance_audit.md — CHAT-PERF-001/002, PROFILE-PERF-001, WIDGET-PERF-001/002, FUNC-PERF-001/002/003, BOOT-PERF-001, PERF-DIARY-001, PERF-LOG-001
3. docs/audits/03_ux_flutter_audit.md — UX diary/space/chat/reaction/profile/settings (skip feed UX — PR-5)
4. docs/audits/05_security_firebase_audit.md — WIDGET-SEC-001 (clearData on logout)

Scope chia 7 sub-group, commit theo nhóm để dễ review:

A. Repository error mapping (4 repo trừ feed):
   - friend, reaction, notification + diary/space/chat nếu raw Exception
   - Wrap try/catch FirebaseException sang AppError VN message (Pattern #2)
B. Cross-module cleanup:
   - HOME-ARCH-001: merge home_page.dart vs home_screen.dart
   - SETTINGS-ARCH-001: split logout/deleteAccount orchestrator
   - SHARED-001 + FEED-ARCH-002: SharedPostCard sau Post moved, feed repo dùng FriendRepository
   - ROUTER-001 + DEV-001 + DEEPLINK-001: auth bypass + dev route + invite scheme
   - CORE-001: hex_color duplicate consolidate
   - PUBSPEC-001: remove sign_in_with_apple
C. Performance polish:
   - PROFILE-PERF-001 dedup listener
   - WIDGET-PERF-001/002 WorkManager interval + battery
   - CHAT-PERF-001/002 pagination + cleanup
   - FUNC-PERF-001/002/003 cold-start + region + idempotency
   - BOOT-PERF-001 main lazy init
   - PERF-DIARY-001 + PERF-LOG-001
D. UX polish (non-feed):
   - Diary autosave + empty state
   - Space create progress + member role
   - Chat send retry + presence (CHAT-UX-SEND-001 P1)
   - Reaction emoji picker + count
   - Profile edit + avatar
   - Settings block + delete account multi-step
   - PopScope warn (NAV-UX-POPSCOPE-001 P1)
E. Widget oversize split (ARCH-002 P1):
   - feed_section/capture_preview/home_screen ≤ 300 lines (post-PR-5 partial)
F. Widget security (WIDGET-SEC-001 P3): clearData on logout call site
G. RollCall skeleton (ARCH-003): folder + stub provider + route

PR LỚN — anh chia ~7 commit theo group A-G để dễ self-review.

Verify:
- flutter analyze: 0 errors
- flutter test full: pass
- File size: 3 widget feed ≤ 300 lines
- Manual: navigate all modules golden path không crash

Output SPEC + DIFF + VERIFY. KHÔNG push yet.
```


---

# PROMPT — PR-7 users-public-profile-migration (Wave 3)

Tạo worktree sau khi PR-3 rules merged:
```bash
git pull origin develop
git worktree add ../meep-fix-users -b fix/ThienPDM/users-public-profile-migration develop
```

Paste:

```
Tôi là ThienPDM, solo dev Meep. Phase 2 polish — Wave 3.

Task: 6-step migration tách users doc thành public/profile subcollection.

Pre-flight reads:
1. docs/audits/05_security_firebase_audit.md — USER-SEC-001 (6-step migration plan đầy đủ), USER-SEC-002, FRIEND-SEC-001/002
2. docs/audits/04_performance_audit.md — FRIEND-PERF-001 (N+1 watchFriends)
3. docs/audits/A_PHASE_BASELINE_SUMMARY.md — Theme 2 (privacy boundary client read paths)

Scope:
- SEC-USER-SEC-001 P0 (rules + migration)
- SEC-USER-SEC-002 P2 (field length cap)
- PERF-FRIEND-001 P0 (N+1 fix qua subcollection batch)
- FRIEND-SEC-001/002 (rule pid format + searchUser migration sang collectionGroup public)

6-step rollout (CRITICAL — không đảo thứ tự):
1. CF trigger onUserProfileChanged → denormalize 3 field xuống /users/{uid}/public/profile
2. Migration CF migratePublicProfiles admin-only → backfill existing users
3. Client: thêm watchPublicProfile + PublicProfile freezed model
4. Client: rewrite watchFriends batch query whereIn (eliminate N+1) + searchUser dùng collectionGroup public
5. Rule tighten /users read isOwner+isFriend + /public/profile read isAuthed
6. Rules tests: stranger DENY full doc + ALLOW public + friend ALLOW + owner ALLOW

Workflow:
1. Implement 6 step theo audit USER-SEC-001 fix plan chi tiết
2. Composite index trong firestore.indexes.json cho collectionGroup public/username
3. Run rules emulator tests
4. Manual: simulate stranger access trong emulator (UID không trong friend graph) → confirm chỉ thấy public/profile

Verify:
- npm test rules: case mới pass
- flutter analyze: 0 errors
- flutter test: pass (regression)
- Manual: stranger access → public only; friend → full

Sau khi merge: rollout production theo audit checklist (deploy CF → trigger migration → deploy mobile → wait 24-48h → deploy rule tighten).

Output SPEC + DIFF + VERIFY. KHÔNG push yet.
```

---

# PROMPT — PR-8 tests-and-quality (Wave 3 cuối)

Tạo worktree sau khi PR-5/6/7 merged:
```bash
git pull origin develop
git worktree add ../meep-fix-tests -b feat/ThienPDM/tests-and-quality develop
```

Paste:

```
Tôi là ThienPDM, solo dev Meep. Phase 2 polish — Wave 3 cuối.

Task: Integration tests + widget tests + code quality cleanup trong 1 PR LỚN.

Pre-flight reads:
1. docs/audits/06_testing_ci_release_audit.md — TEST-E2E-001, CTRL-TEST-001, WIDGET-TEST-001, FUNC-TEST-001, UNIT-001, TEST-QUALITY-001, MIRROR-001, CI-TIMEOUT-001, HUSKY-PUSH-001, TEST-PURE-001
2. docs/audits/02_code_quality_audit.md — CQ-001 đến CQ-014 (14 issue)
3. docs/audits/03_ux_flutter_audit.md — THEME-001/002/003, A11Y-FRIEND-001, A11Y-INPUT-001, UX-* polish P2/P3 còn lại
4. .claude/skills/flutter-add-integration-test/MEEP-ADAPTER.md
5. .claude/skills/{dart-add-unit-test,dart-generate-test-mocks,flutter-add-widget-test}/MEEP-ADAPTER.md

Scope chia 4 sub-group:

A. Integration tests (TEST-E2E-001 P0):
   - integration_test/_helpers.dart (emulator setup)
   - test_driver/integration_test.dart
   - 4 file E2E: auth_flow / post_creation / feed_reaction / friend_request

B. Unit + widget tests:
   - CTRL-TEST-001: controller tests cho state transition (5 controller chưa cover)
   - WIDGET-TEST-001: widget tests LoginPage/FeedPage/CameraPage critical screens
   - FUNC-TEST-001: functions idempotency tests (spacePostFanOut, FCM)
   - UNIT-001 + TEST-QUALITY-001 + TEST-PURE-001: cleanup false-confidence tests

C. Code quality (CQ + theme + a11y ~40 issue P2/P3):
   - Anti-terms cleanup (user_id sang uid, friend_id sang pairId/friendUid)
   - Dead code (unused providers, commented blocks)
   - Magic strings sang const
   - dynamic/cast strictness
   - Hardcoded color/font sang core/theme tokens
   - Semantics labels + touch target 48dp
   - Format consistency (dart format)
   - Duplicate logic extract

D. CI improvements:
   - CI-MOBILE-002/003 + CI-TIMEOUT-001 + HUSKY-PUSH-001 (workflow polish)

Workflow:
1. Setup integration_test infrastructure
2. Write 4 E2E file
3. Run flutter drive local với emulator → all pass
4. Add controller + widget + functions tests
5. Bulk CQ cleanup (dart fix --apply sau khi review)
6. Theme/a11y polish

Verify:
- flutter drive 4 E2E pass
- flutter test full: all pass
- flutter analyze: 0 errors
- dart format --set-exit-if-changed: pass
- CI green

Output SPEC + DIFF + VERIFY. KHÔNG push yet.
```

---

# Sau khi 8 PR merged

Em chạy mini-audit pass 2 verify 114 issue close + 0 regression.

Anh ping `phase 2 done` → em start pass 2.

---

# Em standby cho mỗi PR

Anh start PR nào, copy prompt block đó, paste session pair mới, em review artifact (SPEC + DIFF + VERIFY) trong session orchestrator này.

Anh đừng đọc PHASE_2_PR_PLAYBOOK.md 1302 dòng — quá thừa cho solo. Mọi detail implementation đã trong 6 audit file gốc; pair session sẽ tự đọc khi cần.
