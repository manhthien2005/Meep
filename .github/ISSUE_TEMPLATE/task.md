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

## Lane

<!-- Leader assign cho 2 specialty lanes; Open lane dev tự pull theo skill match. -->

- [ ] **Specialty — BE/Native** (FS owns: Cloud Functions, Firestore rules, Android widget Kotlin, data layer)
- [ ] **Specialty — UI/Design** (FE-bridge owns: screen từ Figma, design system, theme, reusable widget)
- [ ] **Open** (dev pull theo priority + skill match — docs, simple test, config tweak, small refactor)

## Files có thể chạm

<!-- Preview scope cho reviewer. Không cần exhaustive — list module/folder chính. -->

- `apps/mobile/lib/features/<feature>/...`
- `firebase/functions/src/...`
- `firebase/firestore.rules` / `firebase/storage.rules`
- `apps/mobile/android/app/src/main/kotlin/...` (nếu touch widget native)

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
