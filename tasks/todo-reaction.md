# TODO: Reaction

> Plan: `docs/plans/2026-05-23-reaction.md`
> Spec: `docs/specs/2026-05-23-reaction.md`
> Tier: T0 · Milestone M3
> Blocked by: Feed (Post model, ActTextBar M2 stub)

---

## Phase 1 — Data layer

- [ ] **T1** — `FirebaseReactionRepository` (upsertReaction với docId=reactorUid + deleteReaction + watchReactions + getMyReaction)

## Checkpoint: Data layer ✓
- [ ] `flutter test test/features/reaction/` — 0 failures

---

## Phase 2 — Application layer

- [ ] **T2** — `ReactionController.toggleReact` (react / un-react / change logic + optimistic update + in-flight lock)

## Checkpoint: App layer ✓
- [ ] `flutter test test/features/reaction/` — 0 failures

---

## Phase 3 — UI

- [ ] **T3** — `ActTextBar` M3 update (3 preset emoji: light-blue-heart/🤣/🥰 + count display + optimistic + M2 fallback khi controller null)
- [ ] **T4** — `EmojiPickerSheet` (emoji_picker_flutter, no search) + `ReactionListSheet` (list sort DESC)

---

## Phase 4 — Rules

- [ ] **T5** — Firestore rules tests `/posts/{id}/reactions/{uid}` (read gate: author hoặc feed doc)

## Checkpoint: Reaction complete ✓
- [ ] `flutter test test/features/reaction/` — 0 failures
- [ ] `flutter analyze` clean
- [ ] Manual: tap emoji → active; tap lại → un-react; tap emoji khác → change; EmojiPickerSheet; ReactionListSheet
