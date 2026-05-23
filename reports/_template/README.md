# `_template/` — Khung báo cáo SRS (trích từ mẫu)

Thư mục này chứa **khung chuẩn** của báo cáo SRS môn học, trích tự động từ file mẫu
`Doctor Nearby` (nhóm khác) để tái dùng cho báo cáo đồ án **Meep**.

## File

| File | Là gì | Sinh kiểu nào |
|---|---|---|
| `tools/extract_outline.py` | Parser đọc Mục lục PDF → JSON | chạy tay |
| `srs-sample-outline.json` | Outline thật của bản mẫu (6 chương, 62 mục, 48 hình) | **auto-generated**, đừng sửa tay |
| `srs-template.schema.json` | Khung trừu tượng: mỗi mục gắn `content_type` + pattern viết | viết tay, review được |

## Tái sinh outline

```bash
python reports/_template/tools/extract_outline.py
```

Đọc PDF `Nhom1_*SRS_FinalProject*.pdf` trong `reports/`, ghi đè `srs-sample-outline.json`.
Deterministic — không gõ tay, nên JSON luôn khớp Mục lục gốc.

## Lưu ý về bản mẫu

- Bản mẫu **nhảy số Hình 32**: Mục lục đi Hình 31 → Hình 33; trong body lại ghi nhầm
  "Hình 32" cho màn "Lấy lại mật khẩu". Đây là lỗi của nhóm mẫu — parser đọc đúng
  Mục lục nên giữ Hình 33.

## Bước tiếp theo

`srs-template.schema.json` → mục `meep_adaptation` còn `open_questions` cần leader chốt
trước khi sinh nội dung báo cáo Meep (scope, cách chia chương 3, format DB Firestore, output).
