# /start — Task Kickoff

Khởi động làm việc trên 1 GitHub issue. Mọi lần dev pull task mới phải chạy command này TRƯỚC khi code.

## Cách dùng

Gõ trong chat: `/start <issue-id>`

Ví dụ: `/start 23` → load issue #23, check blockers, create branch, set status In Progress.

## Hành động

Apply rule `.cursor/rules/workflow-start.mdc` cho issue mà user truyền vào. Follow đầy đủ 7 step:

1. Fetch issue details (`gh issue view <id>`).
2. Check blockers (issue dependencies).
3. Load context files (read "Files phải đọc trước").
4. Identify module + load rule context.
5. Verify contract exists trên `develop`.
6. Create feature branch + set Project status "In Progress".
7. Print summary, sẵn sàng `/build`.

Nếu blocker chưa close hoặc contract chưa có → STOP, không tự ý code.

## Khi nào KHÔNG dùng

- Bug fix nhanh (không có issue) → dùng `/fix-issue` trực tiếp.
- Sửa infra/config (rule, hook, workflow) → tạo branch `chore/<DevName>/...` thủ công, không qua `/start`.
