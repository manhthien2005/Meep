# /plan — Planning & Task Breakdown

> "Vertical slices, not horizontal layers."

Transform a spec → an ordered list of small verifiable tasks. Each task delivers end-to-end functionality.

## Pre-flight

1. Read the spec at `docs/specs/<feature>.md` (must be approved).
2. Does the spec have measurable acceptance criteria? If not → go back to `/spec`.
3. Read [`docs/plans/2026-05-04-auth.md`](../../docs/plans/2026-05-04-auth.md) — reference plan format (Part 1 Contract artifacts, Part 2 Tasks T1-Tn với acceptance criteria + cross-module imports, Part 3 Dependency graph, Part 4 Open questions). Format đã proven qua AUTH — copy structure khi plan module mới.

## Phase 1 — Analysis (read-only)

1. Read the spec end-to-end.
2. Survey codebase: which files already exist, what integration points.
3. Map dependencies: which task depends on which.

**Do NOT modify code in this phase.**

## Phase 2 — File structure mapping

List before defining tasks:
- Files to **create**: [full path + 1-line responsibility]
- Files to **modify**: [path + line range + reason]
- **Test** files: [corresponding test path]

Each file: one clear responsibility. Files that change together → live together.

## Phase 3 — Vertical slice ordering

```
❌ Horizontal:
   T1: All Firestore models
   T2: All Cloud Functions
   T3: All Flutter UI

✅ Vertical:
   T1: Create + view one post (model + repo + controller + minimal UI)
   T2: Like a post (FieldValue.increment + button + count)
   T3: Comment on a post (subcollection + UI + rule)
```

Order by:
1. **Foundation first** — types, DI, shared utilities.
2. **Risk-first** — uncertain items early to fail-fast.
3. **Dependency order** — respect the graph.
4. **Quick wins** — small tasks first for momentum.

## Phase 4 — Task definition

```markdown
### Task N: [Component name]

**Files:**
- Create: `apps/mobile/lib/features/feed/data/post_repository.dart`
- Create: `apps/mobile/test/features/feed/post_repository_test.dart`
- Modify: `apps/mobile/lib/features/feed/feed.dart` (add export)

**Dependencies:** Task 1, 2

- [ ] **Step 1: Write failing test**

\`\`\`dart
test('createPost saves to Firestore with serverTimestamp', () async {
  final repo = PostRepository(firestore: fakeFirestore);
  await repo.createPost(authorId: 'u1', caption: 'hello', imageUrl: 'x.jpg');
  final docs = await fakeFirestore.collection('posts').get();
  expect(docs.docs.length, 1);
  expect(docs.docs.first.data()['createdAt'], isNotNull);
});
\`\`\`

- [ ] **Step 2: Run test → confirm FAIL**

\`\`\`bash
flutter test test/features/feed/post_repository_test.dart
\`\`\`

Expected: FAIL — `PostRepository` not defined.

- [ ] **Step 3: Implement minimal**

\`\`\`dart
// exact code here — no "implement X here" placeholders
\`\`\`

- [ ] **Step 4: Run test → confirm PASS**

\`\`\`bash
flutter test test/features/feed/post_repository_test.dart
\`\`\`

Expected: PASS 1/1.

- [ ] **Step 5: Commit**

\`\`\`bash
git add apps/mobile/lib/features/feed/ apps/mobile/test/features/feed/
git commit -m "feat(feed): add PostRepository.createPost"
\`\`\`
```

## No placeholders — plan failure

Never write:
- "TBD", "TODO", "implement later"
- "Add appropriate error handling" without exact code
- "Similar to Task N" — repeat the code; executor may read out of order
- Steps describing WHAT without showing HOW

Every step MUST have real content: exact file paths, exact code, exact commands.

## Phase 5 — Checkpoints

Insert between major phases:

```markdown
---
## Checkpoint: [Phase name] complete

Verify:
- [ ] All tests in this phase pass
- [ ] Lint clean
- [ ] Manual test: [specific scenario]
- [ ] Coverage didn't drop below baseline
---
```

## Phase 6 — Output files

### `docs/plans/YYYY-MM-DD-<feature>.md`

Full plan header:

```markdown
# [Feature Name] Implementation Plan

> **For executor:** Follow TDD cycle for each step.

**Goal:** [1 sentence]
**Architecture:** [2-3 sentences]
**Tech stack:** [key libs/tech]
**Spec:** `docs/specs/<spec-file>.md`

---
```

### `tasks/todo-<feature>.md`

```markdown
# TODO: [Feature]

> Plan: docs/plans/YYYY-MM-DD-<feature>.md

## Phase 1: Foundation
- [ ] T1.1: ...
- [ ] T1.2: ...

## Checkpoint: Foundation complete

## Phase 2: Core features
- [ ] T2.1: ...
```

## Phase 7 — Self-review

1. **Spec coverage:** task for each requirement? List gaps.
2. **Placeholder scan:** search for "TBD", "TODO", "implement later". Fix.
3. **Type/name consistency:** function named `clearLayers()` in T3 but `clearFullLayers()` in T7 = bug.

## Phase 8 — Commit + handoff

```bash
git add docs/plans/<file>.md tasks/todo-<feature>.md
git commit -m "docs(plan): chia nhỏ <feature> thành tasks"
```

Notify user:
> "Plan done tại `docs/plans/<file>.md`, todo tại `tasks/todo-<feature>.md`. X tasks, Y checkpoints. Anh muốn em bắt đầu Task 1 hay review trước?"

## Output

- ✅ `docs/plans/<file>.md` committed.
- ✅ `tasks/todo-<feature>.md` committed.
- ✅ Each task: exact files, exact code/commands, no placeholders.
- ✅ Order respects dependencies + risk.
