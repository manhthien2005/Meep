---
name: Task (sprint-level)
about: Task cụ thể trong sprint — break-down từ feature/spec, có owner và estimate.
title: '<type>(<scope>): '
labels: ['status/backlog']
assignees: ''
---

<!--
Template này dùng cho task execution unit trong sprint (đã được break-down từ
feature/spec). Title theo Conventional Commits, vd:
  - feat(auth): tạo màn hình đăng nhập Google
  - fix(feed): xử lý feed rỗng khi chưa có bạn
  - chore(ci): thêm path filter cho develop-staging workflow

Nếu là feature request mới (chưa break-down) → dùng template "Yêu cầu tính năng mới".
Nếu là bug → dùng template "Báo cáo bug".
Đọc ADR-0003 (`docs/adr/0003-task-management-process.md`) để hiểu quy trình.
-->

## Mô tả

<!-- 1-2 câu: việc cần làm + lý do (tại sao). -->

## Acceptance criteria

<!-- ≥ 3 bullet, đo được. Tick khi đạt. -->

- [ ] 
- [ ] 
- [ ] 

## Estimate

<!-- Tick 1 ô. Task > L bắt buộc break thành nhiều task nhỏ hơn. -->

- [ ] **XS** — ≤ 2h (config tweak, doc update, bug nhỏ)
- [ ] **S** — nửa ngày, ~4h (1 widget UI đơn giản, 1 test file)
- [ ] **M** — 1 ngày, ~8h (1 feature screen có state, 1 Cloud Function + tests)
- [ ] **L** — 2-3 ngày (1 module phức tạp: friend graph, post + storage)

## Module ownership

<!-- Module nào của task này. Module owner = assignee. Cross-module touch (đụng module dev khác) phải qua leader trước. -->

- **Module:** `<auth | feed | post | friend | camera | diary | space | rollcall | profile | widget | notification | reaction | core | functions>`
- **Module owner (assignee):** @<github-username>

## Files có thể chạm

<!-- Preview scope cho reviewer. Solo-dev → owner full-stack module mình. -->

- Data layer: `apps/mobile/lib/features/<module>/data/`
- Application layer: `apps/mobile/lib/features/<module>/application/`
- Presentation layer: `apps/mobile/lib/features/<module>/presentation/`
- Cloud Functions (nếu module có): `firebase/functions/src/<module>/`
- Native (nếu module có widget Android): `apps/mobile/android/app/src/main/kotlin/<module>/`

> ⚠️ **Đụng `core/`, `shared/widgets/`, `firestore.rules`, hoặc module dev khác → khoá lại, ping leader trước.** Chi tiết: `.cursor/rules/25-dev-code-standards.mdc` §Cross-module touch.

## Files phải đọc trước (context)

<!--
Danh sách files agent/dev PHẢI đọc để hiểu existing contract trước khi bắt đầu code.
Thường là: abstract interfaces, freezed models, providers liên quan, error types.
Ví dụ:
  - `lib/features/auth/data/auth_repository.dart` — existing interface + method signatures
  - `lib/core/error/app_error.dart` — AppError hierarchy cần implement đúng
  - `lib/features/auth/application/auth_controller.dart` — xem provider đang expect gì
-->

- 

## Dependencies / blockers

<!-- Issue/PR khác phải xong trước task này. Để trống nếu không có. -->

- Refs #
- Blocked by #

## Test plan

<!-- File test sẽ tạo/sửa + cách verify thủ công. -->

- **Test file:** `<path>/<feature>/<file>_test.dart` hoặc `<file>.test.ts`
- **Manual repro:** 
  1. 
  2. 
  3. 

## Spec / plan reference

<!-- Link tới spec/plan/ADR liên quan nếu có. -->

- Spec: `docs/specs/`
- Plan: `docs/plans/`
- ADR: `docs/adr/`

## Sprint + milestone

<!-- Sprint nào, milestone nào. Set qua GitHub Projects custom field, không cần điền tay nếu auto-add đã chạy. -->

- Sprint: [ ] 1 [ ] 2 [ ] 3
- Milestone: [ ] M1 (auth + setup) [ ] M2 (social core) [ ] M3 (widget + polish)
