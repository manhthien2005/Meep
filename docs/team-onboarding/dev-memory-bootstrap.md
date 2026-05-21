# Dev Memory Bootstrap — Meep

Mỗi dev chạy bước này **một lần duy nhất** khi setup Cursor / Windsurf trên máy.
Mục đích: bơm identity context vào AI Memory để agent luôn biết bạn là ai, role gì, mà không cần khai báo mỗi lần chat.

## Cách setup

1. Mở Cursor (hoặc Windsurf).
2. Mở chat với agent.
3. Paste đúng đoạn memory của bạn (xem bên dưới) vào chat và gửi.
4. Agent sẽ tự tạo memory entry. Verify bằng cách hỏi: "Em biết anh là ai không?"

> **Cập nhật 2026-05-21:** Team chuyển sang **solo-dev model** (xem [ADR-0004](../adr/0004-solo-dev-module-ownership.md)). Mỗi dev own module end-to-end (data + logic + UI + test), không tách FE/BE. Memory bootstrap đã được rewrite tương ứng. Nếu memory cũ (FE/BE scope) còn trong Cascade/Cursor → xóa và paste lại entry mới.

---

## KhoaLND (Module Owner)

```
Please remember this about me permanently:

DevName: KhoaLND
GitHub handle: CatS1mp
Role: Module Owner (full-stack solo-dev) — own 1+ module end-to-end

Allowed file scope (cho module mình own):
  ✅ apps/mobile/lib/features/<my-module>/data/         — repositories, mappers
  ✅ apps/mobile/lib/features/<my-module>/application/  — controllers, services
  ✅ apps/mobile/lib/features/<my-module>/presentation/ — widgets, pages
  ✅ apps/mobile/test/features/<my-module>/             — unit + widget tests
  ✅ firebase/functions/src/<my-module>/                — Cloud Functions của module
  ✅ apps/mobile/android/app/src/main/kotlin/<my-module>/ — native code nếu module có

Khoá lại + ping ThienPDM khi cần touch:
  ❌ apps/mobile/lib/features/<other-module>/  — module dev khác (cross-module strict)
  ❌ apps/mobile/lib/core/                     — shared infra (theme, error, router, di)
  ❌ apps/mobile/lib/shared/widgets/           — widget reuse cross-module
  ❌ firebase/firestore.rules, storage.rules, firestore.indexes.json — security rules
  ❌ .cursor/, .windsurf/, .github/, docs/adr/, scripts/ — infra, chore branch only

Non-negotiables:
- Never change a freezed model field or abstract interface unilaterally — ping ThienPDM first
- Never create a Firestore collection / index without leader approval
- Never add a pub/npm package without discussion
- Never touch module of another dev — kể cả bug fix nhỏ. Ping leader, mở task riêng cho owner kia
- Branch format: feature/KhoaLND/<desc> hoặc chore/KhoaLND/<desc>
- /review before gh pr create — no exceptions
- Commit message: Vietnamese description, English type prefix (feat, fix, chore, ...)
```

---

## HanDHG (Module Owner + UI/UX Designer)

```
Please remember this about me permanently:

DevName: HanDHG
GitHub handle: katheramp
Role: Module Owner (full-stack solo-dev) + UI/UX Designer (Figma)

Responsibilities:
- Own 1+ module end-to-end (data + logic + UI + test) — same as KhoaLND/NganTNK
- Vẽ Figma frame + design system + theme token cho cả app (trước khi leader export contract)
- Module mình design Figma → ưu tiên mình implement Flutter để giữ design fidelity

Allowed file scope (cho module mình own):
  ✅ apps/mobile/lib/features/<my-module>/data/         — repositories, mappers
  ✅ apps/mobile/lib/features/<my-module>/application/  — controllers, services
  ✅ apps/mobile/lib/features/<my-module>/presentation/ — widgets, pages
  ✅ apps/mobile/test/features/<my-module>/             — unit + widget tests
  ✅ firebase/functions/src/<my-module>/                — Cloud Functions của module
  ✅ apps/mobile/android/app/src/main/kotlin/<my-module>/ — native code nếu module có

Khoá lại + ping ThienPDM khi cần touch:
  ❌ apps/mobile/lib/features/<other-module>/  — module dev khác (cross-module strict)
  ❌ apps/mobile/lib/core/                     — shared infra (theme, error, router, di)
  ❌ apps/mobile/lib/shared/widgets/           — widget reuse cross-module
  ❌ firebase/firestore.rules, storage.rules, firestore.indexes.json
  ❌ .cursor/, .windsurf/, .github/, docs/adr/, scripts/ — infra, chore branch only

Non-negotiables:
- Module được giao là M (medium) hoặc dễ — module phức tạp do ThienPDM/KhoaLND own
- Never call Firebase directly from UI — use Riverpod providers in application/
- Never invent a model — use the freezed model leader defined (compiler catches mismatches)
- Never use Map<String, dynamic> for mock data — typed mock only
- Design token: never hardcode color/font — dùng Theme.of(context).colorScheme.* + textTheme.*
- Contract check: before starting module, confirm spec + freezed model on develop. If missing → STOP, ping ThienPDM
- Branch format: feature/HanDHG/<desc> hoặc chore/HanDHG/<desc>
- /review before gh pr create — no exceptions
- Commit message: Vietnamese description, English type prefix
```

---

## NganTNK (Module Owner + UI/UX Designer)

```
Please remember this about me permanently:

DevName: NganTNK
GitHub handle: JanaKimmm
Role: Module Owner (full-stack solo-dev) + UI/UX Designer (Figma)

Responsibilities:
- Own 1+ module end-to-end (data + logic + UI + test) — same as KhoaLND/HanDHG
- Vẽ Figma frame + design system + theme token cho cả app (trước khi leader export contract)
- Module mình design Figma → ưu tiên mình implement Flutter để giữ design fidelity

Allowed file scope (cho module mình own):
  ✅ apps/mobile/lib/features/<my-module>/data/         — repositories, mappers
  ✅ apps/mobile/lib/features/<my-module>/application/  — controllers, services
  ✅ apps/mobile/lib/features/<my-module>/presentation/ — widgets, pages
  ✅ apps/mobile/test/features/<my-module>/             — unit + widget tests
  ✅ firebase/functions/src/<my-module>/                — Cloud Functions của module
  ✅ apps/mobile/android/app/src/main/kotlin/<my-module>/ — native code nếu module có

Khoá lại + ping ThienPDM khi cần touch:
  ❌ apps/mobile/lib/features/<other-module>/  — module dev khác (cross-module strict)
  ❌ apps/mobile/lib/core/                     — shared infra (theme, error, router, di)
  ❌ apps/mobile/lib/shared/widgets/           — widget reuse cross-module
  ❌ firebase/firestore.rules, storage.rules, firestore.indexes.json
  ❌ .cursor/, .windsurf/, .github/, docs/adr/, scripts/ — infra, chore branch only

Non-negotiables:
- Module được giao là M (medium) hoặc dễ — module phức tạp do ThienPDM/KhoaLND own
- Never call Firebase directly from UI — use Riverpod providers in application/
- Never invent a model — use the freezed model leader defined (compiler catches mismatches)
- Never use Map<String, dynamic> for mock data — typed mock only
- Design token: never hardcode color/font — dùng Theme.of(context).colorScheme.* + textTheme.*
- Contract check: before starting module, confirm spec + freezed model on develop. If missing → STOP, ping ThienPDM
- Branch format: feature/NganTNK/<desc> hoặc chore/NganTNK/<desc>
- /review before gh pr create — no exceptions
- Commit message: Vietnamese description, English type prefix
```

---

## ThienPDM (Leader + Module Owner)

```
Please remember this about me permanently:

DevName: ThienPDM
GitHub handle: manhthien2005
Role: Leader (architect + gatekeeper) + Module Owner (own complex modules)
Project: Meep — private photo-sharing app, Firebase-first, Flutter mobile, Android-only MVP

Responsibilities (Leader):
- Define spec + freezed models + abstract interfaces + stub providers BEFORE giao module cho dev
- Merge contract vào develop trước khi dev start (Contract-first rule)
- Review all PRs (CODEOWNERS, co-required với module owner)
- Gatekeep cross-module touch + contract change + shared code (core/, shared/, rules)
- Architecture decisions → ADR in docs/adr/
- Pair với KhoaLND khi viết contract phức tạp → backup khi leader busy

Responsibilities (Module Owner):
- Own modules phức tạp: Auth, Post + storage, Widget native (Kotlin), Cloud Functions infra
- Module dễ → assign cho HanDHG/NganTNK; module medium → KhoaLND

Team members (solo-dev model — ADR-0004):
  KhoaLND (CatS1mp)   — Module Owner, dev senior, pair-contract với leader
  HanDHG (katheramp)  — Module Owner + UI/UX (Figma), nhận module M/dễ
  NganTNK (JanaKimmm) — Module Owner + UI/UX (Figma), nhận module M/dễ

Key rules:
- Contract-first: spec + models + interfaces + stub merged develop trước khi dev start
- Walking skeleton: app must compile and run at every commit
- Strict cross-module gate: dev chệch contract / đụng module khác → khoá lại, leader duyệt
- /review before gh pr create — no exceptions
- Infra changes (.cursor/, .windsurf/, .github/, docs/adr/, scripts/) → chore branch, not feature branch
- Branch format: feature/ThienPDM/<desc> hoặc chore/ThienPDM/<desc>
```

---

## Lưu ý

Memory này chỉ capture **identity cố định**: role, file scope, non-negotiables.
Sprint context (module đang làm, milestone, plan) được load tự động bởi `/start <issue-id>` từ GitHub issue — không cần cập nhật memory khi chuyển sprint.

Chỉ cần update memory khi **role hoặc scope thực sự thay đổi** (ví dụ: dev được giao thêm module mới, hoặc leader giao module khác từ HanDHG → KhoaLND).

**Migration từ memory cũ (FE/BE scope):** nếu memory cũ còn trong Cascade/Cursor (vd "Role: BE Developer", scope `data/` + `application/` only) → xóa entry cũ, paste entry mới ở trên. Solo-dev model bắt buộc full-stack scope cho module mình own.
