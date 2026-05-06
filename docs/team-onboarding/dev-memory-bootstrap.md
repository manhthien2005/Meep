# Dev Memory Bootstrap — Meep

Mỗi dev chạy bước này **một lần duy nhất** khi setup Windsurf IDE trên máy.
Mục đích: bơm identity context vào Windsurf Memory để agent luôn biết bạn là ai, scope của bạn là gì, mà không cần khai báo mỗi lần chat.

## Cách setup

1. Mở Windsurf IDE.
2. Mở chat với Cascade.
3. Paste đúng đoạn memory của bạn (xem bên dưới) vào chat và gửi.
4. Cascade sẽ tự tạo memory entry. Verify bằng cách hỏi: "Em biết anh là ai không?"

---

## KhoaLND (BE)

```
Please remember this about me permanently:

DevName: KhoaLND
GitHub handle: CatS1mp
Role: BE Developer

Allowed file scope:
  ✅ apps/mobile/lib/features/*/data/         — implement repositories
  ✅ apps/mobile/lib/features/*/application/  — implement controllers
  ✅ apps/mobile/test/features/*/data/        — repository tests
  ✅ apps/mobile/test/features/*/application/ — controller tests
  ✅ firebase/functions/src/                  — Cloud Functions

  ❌ apps/mobile/lib/features/*/presentation/ — FE scope, never touch
  ❌ apps/mobile/lib/core/router/             — Leader scope
  ❌ firebase/firestore.rules                 — ask ThienPDM first
  ❌ .windsurf/, .github/, docs/adr/, scripts/ — chore branch only, ask leader

Non-negotiables:
- Never create a Firestore collection or index without leader approval
- Never change an abstract interface unilaterally — ask ThienPDM first
- Never add a pub package without discussion
- Branch format: feature/KhoaLND/<desc>
- /review before gh pr create — no exceptions
- Commit message: Vietnamese description, English type prefix
```

---

## HanDHG (FE)

```
Please remember this about me permanently:

DevName: HanDHG
GitHub handle: katheramp
Role: FE Developer

Allowed file scope:
  ✅ apps/mobile/lib/features/*/presentation/ — build UI screens
  ✅ apps/mobile/lib/shared/widgets/           — shared UI components
  ✅ apps/mobile/test/features/*/presentation/ — widget tests

  ❌ apps/mobile/lib/features/*/data/          — BE scope, never touch
  ❌ apps/mobile/lib/features/*/application/   — BE scope, never touch
  ❌ firebase/                                 — never touch Firebase config/rules
  ❌ .windsurf/, .github/, docs/adr/, scripts/ — chore branch only, ask leader

Non-negotiables:
- Never call Firebase directly from UI — use Riverpod providers only
- Never invent a model — use the freezed model leader defined (compiler catches mismatches)
- Never use Map<String, dynamic> for mock data — typed mock only
- Contract check: before starting a screen, confirm freezed model exists on develop
- If model missing on develop → STOP, ping ThienPDM (do not start implementation)
- Branch format: feature/HanDHG/<desc>
- /review before gh pr create — no exceptions
- Commit message: Vietnamese description, English type prefix
```

---

## NganTNK (FE)

```
Please remember this about me permanently:

DevName: NganTNK
GitHub handle: JanaKimmm
Role: FE Developer

Allowed file scope:
  ✅ apps/mobile/lib/features/*/presentation/ — build UI screens
  ✅ apps/mobile/lib/shared/widgets/           — shared UI components
  ✅ apps/mobile/test/features/*/presentation/ — widget tests

  ❌ apps/mobile/lib/features/*/data/          — BE scope, never touch
  ❌ apps/mobile/lib/features/*/application/   — BE scope, never touch
  ❌ firebase/                                 — never touch Firebase config/rules
  ❌ .windsurf/, .github/, docs/adr/, scripts/ — chore branch only, ask leader

Non-negotiables:
- Never call Firebase directly from UI — use Riverpod providers only
- Never invent a model — use the freezed model leader defined (compiler catches mismatches)
- Never use Map<String, dynamic> for mock data — typed mock only
- Contract check: before starting a screen, confirm freezed model exists on develop
- If model missing on develop → STOP, ping ThienPDM (do not start implementation)
- Branch format: feature/NganTNK/<desc>
- /review before gh pr create — no exceptions
- Commit message: Vietnamese description, English type prefix
```

---

## ThienPDM (Leader)

```
Please remember this about me permanently:

DevName: ThienPDM
GitHub handle: manhthien2005
Role: Leader / Full-stack
Project: Meep — private photo-sharing app, Firebase-first, Flutter mobile

Responsibilities:
- Define freezed models + abstract interfaces BEFORE FE/BE starts
- Wire real implementations in main.dart (integration step)
- Review all PRs (CODEOWNERS)
- Firestore rules + indexes changes — sole owner
- Architecture decisions → ADR in docs/adr/

Team members:
  KhoaLND (CatS1mp)   — BE developer
  HanDHG (katheramp)  — FE developer
  NganTNK (JanaKimmm) — FE developer

Key rules:
- Freeze-before-FE: models must land on develop before FE starts
- Walking skeleton: app must compile and run at every commit
- /review before gh pr create — no exceptions
- Infra changes (.windsurf/, .github/, docs/adr/, scripts/) → chore branch, not feature branch
- Branch format: feature/ThienPDM/<desc> or chore/ThienPDM/<desc>
```

---

## Lưu ý

Memory này chỉ capture **identity cố định**: role, file scope, non-negotiables.
Sprint context (feature đang làm, milestone, plan) được load tự động bởi `/start <issue-id>` từ GitHub issue — không cần cập nhật memory khi chuyển sprint.

Chỉ cần update memory khi **role hoặc file scope thực sự thay đổi** (ví dụ: dev chuyển từ BE sang FE, hoặc onboard feature mới với scope khác).
