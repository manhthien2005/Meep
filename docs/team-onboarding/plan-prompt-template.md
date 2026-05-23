# ROLE
You are a senior Flutter tech lead generating implementation plans for ALL modules of a project.
You will process 11 specs in strict dependency order, output a complete plan for each, then
run a final cross-module verification. Do not skip any step. Do not ask clarifying questions.

---

# PROJECT CONTEXT: Meep

## Tech stack (locked)
- Flutter + Dart, Riverpod 2 (code-gen @riverpod), freezed + json_serializable
- Firebase: Auth, Firestore, Storage, Cloud Functions (Node 20 + TypeScript), FCM, go_router
- Tests: flutter_test + fake_cloud_firestore + firebase_auth_mocks (Flutter), vitest (TS)

## File structure
apps/mobile/lib/
  core/theme/ | core/error/
  features/<feature>/data/ | application/ | presentation/
  shared/widgets/
firebase/functions/src/index.ts

## Rules (non-negotiable)
- Dart: snake_case files, UpperCamelCase classes, lowerCamelCase vars
- Firestore: plural lower_snake_case collections, camelCase fields
- Riverpod: always @riverpod code-gen, never manual Provider()
- Freezed: always @freezed, never plain classes for data models
- Repository pattern: abstract class in data/ + FirebaseXxxRepository implementation
- Contract-first: leader merges stubs to develop BEFORE dev starts. Stubs throw UnimplementedError.
- Stub TODO format: // TODO(<taskId>/<DevName>): <description>
- Devs never touch another module. Cross-module = import only, never edit.
- App always compiles. No broken imports.

## Team
- DevNames: ThienPDM (leader), KhoaLND, HanDHG, NganTNK
- Branch: <type>/<DevName>/<short-desc>
- Commit: <type>(<scope>): <Vietnamese description>

## Task sizes
- XS ≤ 2h | S ~4h | M ~8h | L 2-3 days | NEVER > L (break it down)

## Definition of Done
1. All acceptance criteria pass (measurable — no "should work", "properly", "correctly")
2. Unit tests: controller + repository happy + edge + error cases
3. Widget tests: critical UI flows
4. flutter analyze + dart format clean
5. PR approved by leader, CI green, merged to develop

---

# PROCESSING INSTRUCTIONS

Process each module in the exact order below. For each module:
1. Read its spec
2. Note which contracts it IMPORTS from other modules (already processed)
3. Generate its plan
4. Proceed to next module

PROCESSING ORDER (dependency-sorted):
1. auth          — no dependencies
2. friend        — imports: UserProfile from auth
3. settings      — imports: Friendship/FriendRequest from friend (blockUser unfriends)
4. chat          — imports: BlockRepository from settings, Friendship from friend
5. home-camera-feed — imports: Friendship from friend, BlockRepository from settings
6. notification  — imports: Post from home-camera-feed, Conversation from chat
7. reaction      — imports: Post from home-camera-feed
8. diary         — imports: UserProfile from auth
9. profile       — imports: DiaryRepository from diary, FriendCount from friend
10. space        — imports: Friendship from friend, NotificationRepository from notification
11. widget-android — imports: feed subcollection from home-camera-feed, Auth from auth

For EACH module, output the following 4 parts:

---
## MODULE: <name> (processing <N>/11)

### PART 1 — Contract artifacts (leader merges to develop FIRST)
Table format:
| File path | Type | Key contents |
|-----------|------|-------------|
| lib/features/<f>/data/<model>.dart | freezed model | list all fields with types |
| lib/features/<f>/data/<repo>.dart | abstract class | list all method signatures |
| lib/features/<f>/application/<ctrl>.dart | Riverpod stub | provider signature, throws UnimplementedError |
| firebase/functions/src/index.ts | CF stub | function name + signature |

### PART 2 — Tasks
Number tasks globally across ALL modules: T1, T2, T3... (never restart from T1 for a new module).

For each task:
---
**T<N> · <module> · <Conventional Commits title>**
| Field | Value |
|-------|-------|
| Assignee | <DevName or TBD> |
| Estimate | XS/S/M/L |
| Branch | `<type>/<DevName>/<desc>` |
| Blocked by | T<N> or "contracts from Part 1" or "None" |

Files:
- `path/to/file.dart` — what to implement
- `path/to/test_file.dart` — test cases: <list 3+ specific test descriptions>

Acceptance criteria:
- [ ] <measurable criterion — no vague words>
- [ ] <measurable criterion>
- [ ] <measurable criterion>

Cross-module imports: <list exact class names + source module, or "None">
---

### PART 3 — Module dependency graph
Show tasks as: T<N> → T<N> → (parallel: T<N>, T<N>) → T<N>

### PART 4 — Module open questions
Format: OQ: <question> | Blocks: <task IDs>
Write "None" if spec is complete.

---

After processing ALL 11 modules, output:

## FINAL CROSS-MODULE VERIFICATION

Run every check. Output ✅ or ❌ with a one-line note if ❌.

### A. Contract consistency
- [ ] Every abstract interface imported by another module exists in Part 1 of the source module
- [ ] No two modules define a class with the same name for different purposes
- [ ] BlockRepository is defined in settings, imported (not redefined) in chat and home-camera-feed
- [ ] DiaryRepository.getPublicEntries() exists in diary Part 1 and is imported by profile
- [ ] Feed subcollection (/users/{uid}/feed) access is only done by home-camera-feed and widget

### B. Firestore coverage
- [ ] Every collection from all specs has exactly one "repository owner" module
- [ ] No collection is written to directly from client without a CF or repository
- [ ] /users/{uid}/feed is written ONLY by onPostCreated and onFriendshipDeleted CFs
- [ ] /blocks is written ONLY by blockUser CF (never direct client write)
- [ ] /spaces member management is ONLY done by joinSpace/leaveSpace/createSpace CFs

### C. Cloud Function completeness
List all CFs across all specs and confirm each has a task:
| CF name | Module | Task ID | ✅/❌ |
|---------|--------|---------|-------|
(fill in every CF from every spec)

### D. Task numbering
- [ ] Task IDs are globally unique (no duplicate T<N>)
- [ ] No gaps in task numbering
- [ ] Total task count is reasonable (estimate: 60-100 tasks for 11 modules)

### E. Cross-module task conflicts
- [ ] No task in module A modifies a file owned by module B
- [ ] Shared components (shared/widgets/) are owned by leader (ThienPDM), not individual modules
- [ ] firestore.rules is NOT in any module task — it is a separate leader task

### F. End-to-end user flows
Verify each critical flow has tasks that cover it end-to-end:
- [ ] User registers → auth T<N> (screen) → T<N> (Firebase Auth) → T<N> (save /users doc)
- [ ] User posts photo → camera T<N> → upload T<N> → onPostCreated CF T<N> → feed fan-out T<N>
- [ ] User reacts → reaction T<N> (UI) → T<N> (Firestore write) → onReactionCreated T<N> (notif)
- [ ] User blocks → settings T<N> (UI) → blockUser CF T<N> → feed filters T<N>
- [ ] Widget shows latest photo → widget T<N> (WorkManager) → T<N> (Firestore read feed sub)

If ANY check is ❌, output a CORRECTION section listing exactly what to fix before using this plan.

---

# SPECS (paste each file in full)

## [SPEC_AUTH]
<paste 2026-05-04-auth.md here>

## [SPEC_FRIEND]
<paste 2026-05-22-friend.md here>

## [SPEC_SETTINGS]
<paste 2026-05-23-settings.md here>

## [SPEC_CHAT]
<paste 2026-05-23-chat.md here>

## [SPEC_HOME_CAMERA_FEED]
<paste 2026-05-22-home-camera-feed.md here>

## [SPEC_NOTIFICATION]
<paste 2026-05-23-notification.md here>

## [SPEC_REACTION]
<paste 2026-05-23-reaction.md here>

## [SPEC_DIARY]
<paste 2026-05-23-diary.md here>

## [SPEC_PROFILE]
<paste 2026-05-22-profile.md here>

## [SPEC_SPACE]
<paste 2026-05-23-space.md here>

## [SPEC_WIDGET]
<paste 2026-05-23-widget-android.md here>
