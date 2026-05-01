# Meep — Tổng quan sản phẩm

> *"Bắt trọn từng khoảnh khắc, lưu giữ ký ức cùng những người thân yêu."*

## Meep là gì?

Meep là ứng dụng chia sẻ ảnh **riêng tư, thân mật** giữa nhóm bạn bè thân thiết. Mobile-first, Android MVP. Khác với mạng xã hội đại chúng (Instagram, Facebook), Meep tập trung vào **vòng kết nối nhỏ** (close graph) — chỉ bạn bè đã được mời mới thấy nội dung của bạn.

Điểm khác biệt cốt lõi: **home-screen widget** trên Android hiển thị ảnh mới nhất của bạn bè, biến mỗi lần unlock điện thoại thành 1 khoảnh khắc kết nối.

## Target user

| Đặc điểm | Mô tả |
|---|---|
| Độ tuổi | 18-25 (Gen Z, sinh viên, người mới đi làm) |
| Vòng quan hệ | Bạn thân, người yêu, gia đình nhỏ (5-30 người) |
| Hành vi | Chia sẻ khoảnh khắc đời thường (selfie, đồ ăn, cảnh đẹp), không phải content marketing |
| Pain point | Ngại post Instagram/Facebook vì "audience quá lớn" → muốn không gian riêng tư hơn |
| Platform | Android primary (Việt Nam ~70% Android share) |

## Khác biệt vs competitor

| App | Điểm mạnh | Meep khác biệt thế nào |
|---|---|---|
| **Locket** | Widget ảnh mới nhất | Meep có widget + Diary + Space + RollCall — nhiều layer engagement hơn |
| **BeReal** | Daily prompt "be real" | Meep có RollCall (weekly challenge) + flexible timing — không ép user |
| **Instagram Close Friends** | Story riêng tư | Meep là app riêng cho close circle, không bị lẫn với public content |
| **Snapchat** | Ephemeral, ảnh gửi 1-1 | Meep persistent (lưu lại trong Diary, profile) — ký ức dài hạn |

### 4 differentiator chính của Meep (Tier 0+ — must ship M3)

1. **Diary cá nhân** — không gian "chậm" lưu kỷ niệm dài hạn (text + ảnh attach), private/public toggle.
2. **Space (nhóm riêng tư)** — tạo nhóm BFF / Couple / Family, gửi ảnh chỉ trong nhóm.
3. **RollCall** — weekly social challenge: chia sẻ khoảnh khắc tuần, multi-emoji react.
4. **Camera + Widget** — chụp nhanh, widget Android cập nhật ảnh mới nhất bạn bè.

## MVP scope (tóm tắt)

3 tier theo MoSCoW priority:

- **Tier 0 — Locket parity (firm, 8 features):** Auth, Friends, Camera basic, Share photo, Feed, Push, Reaction, Widget Android
- **Tier 0+ — Meep differentiator (firm, 4 features):** Diary basic, Space basic, RollCall basic, Profile screen
- **Tier 1 — Stretch (unlock per retro):** Settings, Streak calendar, Chat 1-1
- **Tier 2 — Won't have (defer post-capstone):** Diary canvas editor, dual camera, video, stickers, group chat, block/report, account deletion, RollCall 168h archive

Detail: [`docs/product/features.md`](features.md). Day estimates: memory `mvp-tier-priority`.

## Platform & scope

- **Mobile:** Flutter, Android-only MVP (iOS deferred — xem `docs/adr/0002-android-first-defer-ios.md`)
- **Backend:** Firebase first (Auth, Firestore, Storage, Cloud Functions, FCM) — xem `docs/adr/0001-firebase-first-backend.md`
- **Region:** asia-southeast1 (Singapore)
- **Auth methods:** Email/password + Google Sign-In (Apple deferred với iOS)
- **Native widget:** Android AppWidget (Kotlin) — không có iOS WidgetKit

## Team & timeline

- **Team:** 4 dev student capstone (anh là leader). 2 FS dev (Flutter + Cloud Functions + Firestore rules + native Kotlin) + 2 FE-bridge (Figma → Flutter UI).
- **Timeline:** 6 tuần hard deadline, 30/4 → 9/6/2026.
- **3 milestones:** M1 (Setup + Auth) → M2 (Social core) → M3 (Differentiator + Demo).

Detail: [`docs/team-workflow.md`](../team-workflow.md), [`docs/adr/0003-task-management-process.md`](../adr/0003-task-management-process.md), [`docs/roadmap/milestones.md`](../roadmap/milestones.md).

## Tài liệu liên quan

- **Vision đầy đủ + feature catalog:** [`features.md`](features.md)
- **User stories per feature:** [`user-stories.md`](user-stories.md)
- **Non-functional requirements:** [`non-functional.md`](non-functional.md)
- **Architecture overview:** [`../architecture/system-overview.md`](../architecture/system-overview.md)
- **Roadmap M1/M2/M3:** [`../roadmap/milestones.md`](../roadmap/milestones.md)
- **Demo M3 script:** [`../roadmap/demo-script.md`](../roadmap/demo-script.md)
- **Figma reference (26 screens):** [`../specs/figma_design/`](../specs/figma_design/)
