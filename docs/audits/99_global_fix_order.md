# 99 — Global Fix Order — Audit Pass 1 Consolidation

> **Mục đích:** Meta-consolidate của 6 audit (Phase A: ARCH + SEC; Phase B: CQ + UX + PERF + TEST) thành 1 DAG fix order ưu tiên P0 trước, với dependency map + effort estimate cho Phase 2 (fix loop).
>
> **Reference PRs:** #293 (ARCH), #294 (SEC), #296 (Baseline Summary), #297 (PERF), #298 (CQ), #299 (TEST), #300 (UX).
> **Generated:** 2026-06-08 sau khi 7 PR audit-only merged vào develop.

---

## Final scoreboard

| Audit | PR | Issues | P0 | P1 | P2 | P3 | Self-verify | Coverage |
|---|---|---:|---:|---:|---:|---:|---|---|
| 01 Architecture | #293 | 20 | 2 | 7 | 5 | 6 | 4 pass | full + 1 partial |
| 02 Code Quality | #298 | 14 | 0 | 3 | 6 | 5 | 4 pass | full |
| 03 UX Flutter | #300 | 21 | 1 | 6 | 11 | 3 | 4 pass | full |
| 04 Performance | #297 | 18 | 2 | 6 | 5 | 5 | 4 pass | full |
| 05 Firebase Rules | #294 | 22 | 2 | 6 | 7 | 7 | 7 pass | full |
| 06 Testing/CI/Release | #299 | 19 | 2 | 6 | 6 | 5 | 4 pass | full |
| **TỔNG** | — | **114** | **9** | **34** | **40** | **31** | — | — |

**Quality:** 6 audit chạy đủ self-verify (min 4 pass, max 7 pass SEC). 0 audit fail coverage truthfulness check.


---

## 9 P0 release blocker — TOP PRIORITY

> Anh KHÔNG ship M3 cho đến khi 9 P0 này done. Mỗi P0 có dependency rõ ràng.

| ID | Audit | Module | Risk tóm tắt | Effort | Blocks |
|---|---|---|---|---:|---|
| **ARCH-LAYER-001** | 01 | feed/presentation | Widget gọi FirebaseAuth direct → widget test impossible | M | UX-CAMERA + UX state tests |
| **ARCH-LAYER-002** | 01 | feed/application | Controller gọi FirebaseAuth + Firestore direct → controller test impossible | M | UX state tests + PERF rebuild fix |
| **SEC-APPCHECK-001** | 05 | client+config | Chưa activate App Check → production abuse (Firestore/Storage/Functions exposed cho automated traffic) | S | none |
| **SEC-USER-SEC-001** | 05 | rules | /users/{uid} read by any authed → email + friend graph leak (P0 PII) | XL | FRIEND-PERF-001 fix path |
| **UX-CAMERA-UX-001** | 03 | feed/camera | Camera permission denied UX golden path broken (no fallback) | S | none (post-LAYER fix) |
| **PERF-FEED-001** | 04 | feed/data | 31 concurrent Firestore listeners per home open → quota crusher + battery | L | none (post-LAYER fix recommended) |
| **PERF-FRIEND-001** | 04 | friend/data | watchFriends N+1: 20 friends → 100+ reads/session re-fired | M | Best fixed via SEC-USER-SEC-001 migration (public/profile subcollection eliminates N+1) |
| **TEST-E2E-001** | 06 | integration_test/ | ZERO integration test files → no golden path regression coverage per CLAUDE.md baseline | L | All UX/PERF P0 needs E2E test post-fix |
| **TEST-SIGN-001** | 06 | android/release | Release build signed với debug key → Play Store rejects + cannot update | S | Production release |

**Effort legend:** S = ≤ 2h, M = ½ ngày, L = 1 ngày, XL = 2-3 ngày.


---

## Fix DAG — execution order

```
Phase 2 Batch 1 (PARALLEL, ngày 1-2)
├── SEC-APPCHECK-001       [S]   ← độc lập, deploy trước nhất
├── TEST-SIGN-001          [S]   ← độc lập, fix signing config
├── UX-CAMERA-UX-001       [S]   ← độc lập, add fallback UI
└── ARCH-LAYER-001/002     [M]   ← foundation cho FEED-PERF + UX states
    └── unblock: UX state tests, PERF FEED rebuild fixes

Phase 2 Batch 2 (sequential after Batch 1, ngày 3-5)
├── SEC-USER-SEC-001       [XL]  ← 6-step migration (CF trigger + backfill + client + rule)
│   └── unblock: PERF-FRIEND-001 (subcollection eliminates N+1)
├── PERF-FEED-001          [L]   ← cần ARCH-LAYER-002 fix trước (provider injectable)
└── PERF-FRIEND-001        [M]   ← merge với SEC-USER-SEC-001 migration

Phase 2 Batch 3 (PARALLEL, ngày 6-8)
└── TEST-E2E-001           [L]   ← write golden path E2E after Batch 1 + 2 stable
    ├── auth_flow_test.dart
    ├── post_creation_test.dart
    ├── feed_reaction_test.dart
    └── friend_request_test.dart
```

**Tổng effort P0:** ~8 ngày dev đầy đủ. Khoảng 1.5-2 tuần với buffer cho review + CI.


---

## P1 by impact area (34 issues)

> Sau khi 9 P0 done, fix P1 theo nhóm để hạn chế cross-module touch.

### Group 1 — Architecture cleanup (7 P1 từ ARCH)

| ID | File | Fix |
|---|---|---|
| ARCH-FEED-001 | feed_controller.dart | Wire postRepositoryProvider/storageRepositoryProvider qua main.dart override (Pattern #1 skeleton rule) |
| ARCH-LAYER-003 | feed_state.dart | Đổi DocumentSnapshot `lastDoc` sang String `lastDocId` |
| ARCH-DATA-001 | 5 repos | Wrap try/catch FirebaseException sang AppError trong post/storage/friend/reaction/notification |
| ARCH-FEED-002 | firebase_post_repository.dart | Dùng FriendRepository thay vì direct query (sau khi unblock stub) |
| ARCH-001 | post.dart | Move Post model lên `lib/shared/models/` hoặc `core/models/` |
| ARCH-002 | 3 widget oversize | Split feed_section.dart, capture_preview_screen.dart, home_screen.dart |
| ARCH-DEEPLINK-001 | app_config + router + manifest | Unify scheme + intent-filter + implement /invite/:uid landing |

### Group 2 — Firebase rules hardening (6 P1 từ SEC)

| ID | File | Fix |
|---|---|---|
| SEC-STORAGE-001 | storage.rules:9 | Tighten /posts/{uid} read by friend boundary |
| SEC-STORAGE-002 | storage.rules:30 | Tighten /diary/{uid} read by author only |
| SEC-POST-SEC-001 | firestore.rules:147 | Add field whitelist + caption.size() cap cho update |
| SEC-CHAT-SEC-001 | firestore.rules:288 | Enforce participantIds subset of {sender, friend} on create |
| SEC-AUTH-SEC-001 | deleteAccount.ts:148 | Add server-side auth_time reauth window check |
| SEC-AUTH-SEC-002 | auth signup | Add sendEmailVerification + emailVerified check |

### Group 3 — UX states + permissions (6 P1 từ UX)

| ID | File | Fix |
|---|---|---|
| STATE-UX-EMPTY-001 | feed empty | Vietnamese CTA + action button |
| STATE-UX-ERROR-001 | various | Replace bare error text với retry button + actionable hint |
| NOTIF-UX-PERM-001 | notification onboarding | Permission rationale dialog + in-app fallback banner |
| CHAT-UX-SEND-001 | chat send | Inline spinner + retry on fail |
| NAV-UX-POPSCOPE-001 | forms with unsaved | PopScope warn before pop |
| UPLOAD-UX-001 | post upload | Progress indicator + retry button on fail |

### Group 4 — Performance (6 P1 từ PERF)

| ID | File | Fix |
|---|---|---|
| FEED-REBUILD-001 | feed page | Use `.select()` for granular watch |
| NOTIF-PERF-001 | FCM token write | Compare local cache trước khi write Firestore |
| IMG-PERF-001 | post images | Add cacheWidth/cacheHeight + flutter_image_compress |
| PROFILE-PERF-001 | profile load | Dedupe redundant listener |
| WIDGET-PERF-001 | WorkManager interval | Increase to 30min minimum (battery) |
| FUNC-PERF-003 | spacePostFanOut | Add idempotency marker + batch write |

### Group 5 — Testing + CI (6 P1 từ TEST)

| ID | File | Fix |
|---|---|---|
| CTRL-TEST-001 | controllers | Add ProviderContainer tests for state transitions |
| WIDGET-TEST-001 | critical screens | Add WidgetTester tests cho LoginPage/FeedPage/CameraPage |
| REL-MINIFY-001 | build.gradle.kts | Enable minifyEnabled + shrinkResources cho release |
| CRASHLYTICS-001 | crashlytics setup | Enable collection prod, disable debug + PII scrub |
| FUNC-TEST-001 | functions | Add idempotency tests cho fan-out functions |
| CI-MOBILE-001 | pr-check.yml | Pin Flutter version + cache pub-cache |

### Group 6 — Code quality (3 P1 từ CQ)

| ID | Fix |
|---|---|
| CQ-001 | Anti-terms cleanup (user_id/friend_id → uid/pairId) cross-module |
| CQ-002 | Dead code removal (unused providers, commented blocks ≥ 3 lines) |
| CQ-014 | Magic strings (Firestore collection names) → const top-level |


---

## P2/P3 — backlog after MVP (71 issues)

> Tracker only — không block M3 release. Fix theo capacity sau khi P0/P1 done.

| Category | Count | Recommendation |
|---|---:|---|
| Theme consistency (P2) | 3 | Centralize hardcoded colors/fonts vào core/theme/ |
| A11y (P2) | 2-3 | Semantics labels + touch target ≥ 48dp |
| Test mirror + quality (P2-P3) | 5 | Audit pass 2 sau khi cấu trúc ổn |
| Function micro-perf (P3) | 4 | Cold-start optimize, region pin |
| Docs/release polish (P2-P3) | 3 | Release readiness checklist + version strategy |
| Misc cleanup | rest | One-off small fixes |

---

## Phase 2 plan — Audit → Fix loop

**Em recommend workflow (tối ưu 8 skill đã import):**

```
Step 1 — Anh assign module owner per P0 group
  ├── ARCH-LAYER-001/002 + FEED-PERF-001        → feed module owner
  ├── SEC-USER-SEC-001 + FRIEND-PERF-001         → 1 person (multi-touch backend + client + rules)
  ├── SEC-APPCHECK-001 + TEST-SIGN-001           → leader (config-only)
  ├── UX-CAMERA-UX-001                            → camera/feed UX dev
  └── TEST-E2E-001                                → test infrastructure dev

Step 2 — Mỗi P0 → 1 feature/fix branch + 1 PR
  Branch format: fix/<DevName>/<short-desc>
  PR description cite issue ID + audit PR reference
  
Step 3 — Sub-agent skill usage (per skill imported)
  ├── flutter-apply-architecture-best-practices  → ARCH-LAYER-001/002 fix anchor
  ├── flutter-fix-layout-issues                  → ARCH-002 oversize split UX
  ├── flutter-add-widget-test                    → CTRL-TEST-001 + WIDGET-TEST-001 anchor
  ├── flutter-add-integration-test               → TEST-E2E-001 4 file E2E
  ├── dart-add-unit-test                         → ARCH-DATA-001 repo error mapping tests
  ├── dart-generate-test-mocks                   → mocktail patterns cho controller tests
  ├── dart-run-static-analysis                   → CQ-001/002 cleanup loop
  └── dart-fix-runtime-errors                    → debug session khi P0 fix gặp runtime issue

Step 4 — Sau khi 9 P0 PR merged → audit pass 2 verification
  Em chạy 1 mini-audit pass kiểm verify 9 P0 đã close + không regress.
```

---

## Self-consolidation log

- Total issues processed: 114
- Cross-audit duplicates removed: ~0 (Phase B sub-agent đã skip duplicate qua A_PHASE_BASELINE_SUMMARY → 0 P0/P1 trong Phase B chồng lên Phase A)
- P0 expansion: 4 (Phase A) → 9 (after Phase B) — 5 P0 mới từ Phase B đều orthogonal với Phase A P0
- Fix order DAG: 3 batch over ~2 tuần
- Total P0/P1 effort: ~30-40 dev-days

---

## Final verdict

`verdict: not_ready — 9 P0 + 34 P1 to resolve before M3 release`

App đã hoàn thiện feature-wise (Tier 0 + Tier 0+ all shipped) nhưng cần hardening pass theo fix order ở trên. Sau khi 9 P0 merged + đủ Group 1+2+5 P1 → release candidate ready.
