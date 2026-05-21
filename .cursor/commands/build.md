# /build — Incremental Implementation (TDD)

Implement task từ `tasks/todo-<feature>.md`. Mỗi task = 1 chu kỳ Red-Green-Refactor. Mỗi commit để codebase ở trạng thái working.

## Cách dùng

Gõ trong chat: `/build` hoặc `/build T2.1` (chỉ định task cụ thể).

## Hành động

Apply rule `.cursor/rules/workflow-build.mdc`. Bắt buộc:

1. Pre-flight: invoke skills `tdd`, `karpathy-guidelines`, `flutter-firebase-patterns` (Flutter) hoặc `nodejs-ts-backend` (BE).
2. Confirm branch là `feature/<DevName>/<short-desc>` (KHÔNG phải `develop`/`deploy`).
3. Infra-file guard: nếu touch `.cursor/`, `.windsurf/`, `.github/`, `docs/adr/`, `scripts/` → STOP, đổi branch `chore/<DevName>/...`.
4. Identify task tiếp theo (first `- [ ]` chưa tick).
5. Run TDD cycle (RED → GREEN → REFACTOR).
6. Verify (skill `verification-before-completion`).
7. Commit theo Conventional Commits + tiếng Việt, scope nhỏ.
8. Tick todo box.

## Khi tất cả task done

Run `/review` TRƯỚC khi tạo PR. Không bao giờ `gh pr create` trước `/review`.
