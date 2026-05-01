<!-- 
PR Template — Meep
Vui lòng điền đầy đủ các phần dưới. CI sẽ check format commit + branch name.
Title của PR cũng phải tiếng Việt theo format: <type>(<scope>): <mô tả>
-->

## Mô tả

<!-- 2-3 câu tiếng Việt: PR này làm gì, tại sao cần. -->

## Refs

<!-- Link issue + spec/plan nếu có. Dùng "Closes" để auto-close issue khi merge. -->

- Closes #
- Spec: `docs/specs/`
- Plan: `docs/plans/`

## Thay đổi chính

<!-- List các file/module quan trọng đã thay đổi. -->

- `<path/to/file>`: <thay đổi gì>
- `<path/to/file>`: <thay đổi gì>

## Loại thay đổi

<!-- Tick ô phù hợp. -->

- [ ] feat — Tính năng mới
- [ ] fix — Sửa bug
- [ ] chore — Maintenance, deps, config
- [ ] refactor — Refactor không thêm feature/fix bug
- [ ] docs — Tài liệu
- [ ] test — Thêm/sửa test
- [ ] style — Format/lint, không ảnh hưởng logic
- [ ] perf — Cải thiện performance

## Test

- [ ] Đã chạy `flutter test` PASS
- [ ] Đã chạy `flutter analyze` clean (0 warning)
- [ ] Đã chạy `dart format --set-exit-if-changed .` PASS
- [ ] (Nếu sửa Functions) `npm test` + `npm run lint` PASS
- [ ] (Nếu sửa Firestore rules) Rules tests PASS
- [ ] Đã test thủ công trên Android/iOS (mô tả luồng test bên dưới)

### Cách test thủ công

<!-- Bước 1, 2, 3... mà reviewer có thể follow để verify. -->

1. 
2. 
3. 

## Screenshot / video (bắt buộc nếu có UI thay đổi)

<!-- Drag-drop ảnh/video vào đây. Có thể link Loom/YouTube. -->

## Lưu ý cho reviewer

<!-- Edge case, decision đặc biệt, hoặc câu hỏi cần reviewer feedback. -->

## Self-review checklist

- [ ] Branch name đúng format `<type>/<DevName>/<desc>`
- [ ] Commit message tiếng Việt, theo Conventional Commits
- [ ] Không có file lớn vô tình (`.env`, keystore, service account)
- [ ] Không có `console.log` / `print` debug còn sót
- [ ] Không có `// TODO` chưa link issue
- [ ] Không có code comment-out dead code
- [ ] Đã review chính diff của mình một lần trước khi mở PR

---

> Nếu PR này deploy được sang production (merge vào `deploy`), em sẽ confirm thêm với reviewer trước khi merge.
