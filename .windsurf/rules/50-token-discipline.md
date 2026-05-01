---
trigger: always_on
---

# Token Discipline

Be efficient with the user's context window. Long sessions and big PRs eat tokens fast.

## Read smart, not greedy

- **Search before reading.** Use `grep` / `code_search` / `find_by_name` to locate a symbol before opening files. A 30-line read beats a 1500-line read.
- **Read with offset + limit** when you only need a region. Don't read 1000 lines if you need lines 200-260.
- **Don't re-read** a file already shown in this conversation unless it has been edited since.
- **Don't list whole large directories.** Filter by extension, name pattern, or path scope.

## Output smart, not chatty

- No filler ("Sure!", "Great question!", "Let me start by ...").
- No restating what the user just said.
- No re-summarizing what you just did in the previous turn.
- Code blocks **only when** the code is part of the answer or a snippet the user needs to act on. Don't echo back files you just edited.
- **Diffs > full files.** When showing changes, show only the changed lines with context.

## Tool calls

- Batch independent reads + searches in parallel when there's no dependency.
- Don't open the same tool twice with similar args — fold them into one call.
- Prefer `code_search` (subagent) over many `grep` rounds for exploratory questions.

## Plans, todos, progress notes

- Keep `tasks/todo-<feature>.md` short — checkboxes, not paragraphs.
- Don't auto-create progress notes unless they actually save the next session time. The plan file in `docs/plans/` already has the detail.
- Don't paste the same paragraph in three places (rules, AGENTS.md, the spec). Pick one home.

## Long-running shell output

Common noisy commands and their tame equivalents:

| Noisy | Quieter |
|---|---|
| `git status` | `git status --short` |
| `git log` | `git log -n 10 --oneline` |
| `git diff` | `git diff --stat` then `git diff <file>` if needed |
| `flutter test` (full) | `flutter test test/<feature>/` first |
| `npm test` (full) | `npm test -- <file>` first |
| `firebase functions:log` | `firebase functions:log --limit 50 --only <fn>` |
| `find` / `ls -R` | `find_by_name` tool with extension filter |

## Optional: RTK (Rust Token Killer)

`rtk` is a CLI proxy that compresses noisy command output before it reaches the agent context (60–90% savings on `git status`, test runners, etc.).

**Check whether it's installed:**

```pwsh
rtk --version
```

- **If installed** → Windsurf integration is already active when `.codeium/windsurf/hooks/` was wired by `rtk init --agent windsurf`.
- **If not installed** → use the standard commands above with the quieter flags. **Do not auto-install RTK on the user's machine** — only suggest it if the user asks. Install instructions are in `AGENTS.md` section 7.

## When in doubt

If a single response would be very long, ask the user whether they want:

- A short summary now + details on demand, or
- The full long version.

Don't dump 2000 lines of code or output on the user "just in case".
