# /review — Five-Axis Self Review

Self-review code đã viết TRƯỚC khi tạo PR. Bắt buộc trước `gh pr create`.

## Cách dùng

Gõ trong chat: `/review`

## Hành động

Apply rule `.cursor/rules/workflow-review.mdc`. Invoke skill `code-review-five-axis`. Đầy đủ 5 phase:

1. Read context (spec, plan, commit messages).
2. Run automated checks: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed`, `npm test`, `npm run lint` (phù hợp stack).
3. Manual 5-axis pass: Correctness / Readability / Architecture / Security / Performance.
4. Output: 🔴 Critical / 🟡 Important / 🟢 Suggestion / ✅ Highlights + Summary.
5. Action: 🔴/🟡 → return `/build` hoặc `/fix-issue`. Sạch → ready for PR.

## Meep-specific check (xem rule chi tiết)

- Firestore rules change → có rules unit test owner / friend / stranger / unauthenticated?
- Cloud Function trigger → region `asia-southeast1`, `maxInstances`, `timeoutSeconds` explicit?
- Image upload → size + MIME validate **server-side**, không chỉ client?
- PII trong logs (email, phone, displayName, caption)?
- Hardcoded secret trong Dart source?
- Native widget code → có call Firebase trực tiếp không (KHÔNG được)?
- Cross-module touch → có ping leader chưa?

## Sau review sạch

```bash
git push origin <branch>
gh pr create --base develop --title "<type>(<scope>): <mô tả tiếng Việt>" --body "$(cat .github/pull_request_template.md)"
```
