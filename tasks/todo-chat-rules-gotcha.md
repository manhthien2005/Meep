# Gotcha: Firestore rules + query — phải nhớ khi làm Chat

> Rút ra từ bug friend module (2026-05-31). Chat dùng `conversations` có cùng rủi ro.

## Bug gốc (đã fix ở friend)

Rule `friendships` dùng `resource.data.members.hasAll([request.auth.uid])`.
- `hasAll` **chạy với `get`** (đọc 1 doc) nhưng **THROW với `list`/query**:
  `Function not found error: Name: [hasAll]. for 'list'`
- App query `where('members', arrayContains: uid)` → trúng nhánh `list` → `permission-denied`.
- Rules test cũ chỉ test `.get()` 1 doc → bug lọt suốt.

**Fix:** `uid in resource.data.members` (chuẩn cho cả get + list), thay cho `members.hasAll([uid])`.

## ÁP DỤNG NGAY cho Chat (conversations)

`firestore.rules` hiện có 2 chỗ NGHI NGỜ dùng pattern lỗi:
- L53: `isParticipant()` → `get(...).data.participantIds.hasAll([request.auth.uid])`
- L204: `conversations` rule → `request.resource.data.participantIds.hasAll([request.auth.uid])`

Nếu Chat query inbox kiểu `conversations.where('participantIds', arrayContains: uid)` (list)
→ sẽ dính ĐÚNG bug `permission-denied` này.

**Khi làm chat, BẮT BUỘC:**
1. Đổi rule đọc conversations sang `request.auth.uid in resource.data.participantIds`
   (không dùng `hasAll` cho nhánh `read`/`list`).
   - Lưu ý: `keys().hasAll([...])` lúc CREATE thì OK — nó validate field, không dính query.
2. Viết rules test cho cả **query** (`.where(...).get()`), KHÔNG chỉ `.get()` 1 doc.
3. Mỗi composite query (≥2 where, hoặc where+orderBy) → thêm index vào
   `firestore.indexes.json` + deploy. Kiểm field name khớp code (vụ `toUid` vs `senderId`).

## Checklist verify trước khi claim "chat xong"

- [ ] Rule đọc/list conversations dùng `in`, không `hasAll`.
- [ ] Rules test có case QUERY (list), pass trên emulator.
- [ ] Index cho mọi composite query đã add + deploy staging.
- [ ] App surface lỗi `errorMessage` ra UI (đừng nuốt) để debug nhanh.
- [ ] `firebase deploy --only firestore:rules,firestore:indexes --project staging`.

## Quy trình deploy đã dùng (friend)

```
firebase emulators:exec --only firestore "npm run test:rules -- <file>.rules" --project staging
firebase deploy --only firestore:rules --project staging
firebase deploy --only firestore:indexes --project staging
```
Port 9999 hay bị emulator zombie giữ → kill: `Get-NetTCPConnection -LocalPort 9999,9150,4400 | Stop-Process`.

## Lưu ý infra
`firestore.rules` + `firestore.indexes.json` + rules test = shared infra → branch `chore/ThienPDM/...`, KHÔNG để trong feature branch.
