# Meep — Demo Script (M3 Capstone Final)

E2E acceptance test cho M3 demo (9/6/2026). Story 3 nhân vật Aldo + Beatrice + Charlie chạy qua tất cả Tier 0 + Tier 0+ features.

> **Mục đích:** Khi story này chạy mượt 15 phút trước giảng viên = capstone success. Đây là **single source of truth** cho M3 acceptance.

## Demo setup

### Pre-demo (1 ngày trước, 8/6)

| Action | Owner | Time |
|---|---|---|
| Pre-create 3 accounts trên `meep-prod`: Aldo, Beatrice, Charlie | Anh | 15ph |
| Set avatar + bio + 2-3 posts cũ cho mỗi account | Anh | 30ph |
| Test full story trên 3 thiết bị Android riêng | All dev | 1h |
| Record backup video full demo (10-15ph) | Anh + 1 dev | 1.5h |
| Kiểm tra Firebase quota + billing alert | Anh | 15ph |
| Charge 3 thiết bị 100% pin + screen brightness max | Anh | — |
| Setup Wi-Fi backup (mobile hotspot phòng) | Anh | — |

### Demo equipment

- **3 thiết bị Android** (1 cho mỗi nhân vật)
  - Tốt nhất: 3 phone khác model + screen size để show responsive
  - Aldo: phone chính anh
  - Beatrice: phone dev FS-2
  - Charlie: phone dev module owner UI
- **Projector / TV screencast**: cast 1 phone screen lên (Aldo) chính, 2 phone còn lại physical hold up theo turn
- **Backup laptop**: APK + recording video sẵn sàng
- **Wi-Fi office + mobile hotspot backup**

## Demo story (15 phút)

### Part 1: Auth & Friends (3 phút) — Tier 0

**Aldo download Meep và signup mới**
1. Aldo mở app lần đầu trên thiết bị mới (uninstall + reinstall)
2. **[SCREEN: Trang giới thiệu]** Logo Meep + tagline + 2 button
3. Tap "Tạo tài khoản mới"
4. **[SCREEN: Đăng ký_Nhập email]** Nhập `aldo.demo@meep.app` → "Tiếp tục"
5. **[SCREEN: Đăng ký_Nhập MK]** Nhập password ≥8 ký tự → "Tiếp tục"
6. **[SCREEN: Đăng ký_Nhập họ tên]** Họ "Nguyễn Aldo" + Tên → "Tiếp tục"
7. **[SCREEN: Đăng ký_Nhập username]** Nhập `aldo_meep` → real-time validate unique → "Tuyệt vời!" → "Tiếp tục"
8. **[SCREEN: Tìm bạn từ danh bạ]** "Để sau" (skip — không demo contact discovery vì optional)
9. **[SCREEN: Trang chủ]** Camera viewfinder home tab → demo M3 backbone

> **Talking point:** "Signup multi-step UX flow theo Figma design — 5 screens dẫn user qua từng bước, validate real-time, không overwhelm."

**Aldo mời Beatrice qua share-link**
10. Aldo navigate Settings (icon person bottom nav) → Profile → "Chia sẻ trang cá nhân"
11. Native share sheet hiện ra → tap "Sao chép link" → link `meep://invite/{aldo-uid}` copied
12. Aldo paste link Messenger gửi cho Beatrice (giả lập — anh đã chuẩn bị bạn dev)

**Beatrice tap link và signup**
13. **[SWITCH DEVICE: Beatrice phone]** Tap link Messenger → Meep app mở (deep link)
14. Signup tương tự (rút gọn — chỉ show 2 screens cuối: username + skip contacts)
15. Sau signup → friend request **tự động** sent từ Aldo
16. **[SCREEN: Notification]** Beatrice nhận push "Aldo đã mời bạn kết bạn"
17. Beatrice Settings → Friends → tab Incoming → tap "Đồng ý"

> **Talking point:** "Deep link signup với pre-friend mechanism — giảm friction onboarding cho user mới."

**Aldo nhận confirmation**
18. **[SWITCH DEVICE: Aldo phone]** Push "Bạn và Beatrice đã trở thành bạn bè!"
19. Friends list show Beatrice với avatar + tên

### Part 2: Camera + Share + Feed + Reaction (3 phút) — Tier 0

**Aldo chụp ảnh và gửi**
20. Camera home tab → chụp 1 ảnh (anything visible — book, table, hand)
21. **[SCREEN: Xem trước ảnh chụp]** Preview ảnh + caption input
22. Caption: "Buổi sáng cà phê ☕"
23. Recipient default "Mọi người" → tap send button (paper plane)
24. Loading indicator → "Đã gửi!" toast → quay về camera

> **Talking point:** "Upload qua Cloud Function `onPostCreated` — resize ảnh 1080p, strip EXIF location (bảo vệ privacy), fan-out đến recipients trong <10s."

**Beatrice nhận push + xem feed**
25. **[SWITCH DEVICE: Beatrice phone]** Push "Aldo gửi ảnh mới"
26. Tap notification → **[deep link]** app mở vào /post/{postId}
27. Hoặc Beatrice swipe sang Feed page → vertical list
28. Beatrice xem ảnh full → caption "Buổi sáng cà phê ☕" + author Aldo + thời gian "vừa xong"

**Beatrice react**
29. Tap emoji ❤️ bottom of photo → react instant (optimistic UI)
30. Counter ❤️ tăng 1

> **Talking point:** "React qua Firestore subcollection + Cloud Function `onReactionCreated` denormalize count trên post document. Push notification cho author."

**Aldo nhận reaction notification**
31. **[SWITCH DEVICE: Aldo phone]** Push "Beatrice react ❤️ ảnh của bạn"
32. Tap → mở post → see reactor list

### Part 3: Profile (1 phút) — Tier 0+

**Beatrice xem profile của Aldo**
33. Beatrice tap avatar Aldo trên feed → mở Profile của Aldo
34. **[SCREEN: Trang Profile]** Avatar + username `aldo_meep` + bio + stats (1 bài viết, 1 bạn, 0 space) + grid 1 thumbnail post mới
35. Beatrice swipe lên xem grid history (chỉ 1 post)

> **Talking point:** "Profile public fields visible cho friends. Posts grid filtered theo recipient — Beatrice chỉ thấy posts đã share với mình."

### Part 4: Space (3 phút) — Tier 0+

**Aldo + Beatrice + Charlie tạo Space "Cà phê chiều"**
36. **[SWITCH DEVICE: Aldo phone]** Settings → Tiện ích → "Tạo Space mới"
37. Form: name "Cà phê chiều" + icon "☕" + invite friends (chọn Beatrice)
38. Submit → Beatrice nhận push "Aldo mời bạn vào Space 'Cà phê chiều'"

**Beatrice accept Space**
39. **[SWITCH DEVICE: Beatrice phone]** Push tap → Space invite screen → "Tham gia"
40. **[SWITCH DEVICE: Charlie phone]** Charlie pre-friended với Aldo (setup pre-demo) → Aldo invite Charlie vào Space tương tự
41. Charlie accept

**Aldo gửi photo vào Space**
42. **[SWITCH DEVICE: Aldo phone]** Camera → chụp ảnh "đồ uống"
43. Preview screen → recipient dropdown "Mọi người" → tap → list Spaces hiện ra
44. Chọn "Cà phê chiều" → recipient = members space (Beatrice + Charlie)
45. Caption "Latte hôm nay" → send

**Beatrice + Charlie nhận**
46. **[SWITCH DEVICE: Beatrice phone]** Push "Aldo gửi ảnh trong 'Cà phê chiều'"
47. Beatrice mở Feed → dropdown "Mọi người" → tap → chọn "Cà phê chiều" → feed filtered chỉ photos space
48. **[SWITCH DEVICE: Charlie phone]** Cùng tương tự — Charlie thấy ảnh

> **Talking point:** "Spaces = closed groups. Photo broadcast chỉ tới members, không public. Feed filter theo space cho organize content."

### Part 5: Diary (2 phút) — Tier 0+

**Aldo viết Diary entry**
49. **[SWITCH DEVICE: Aldo phone]** Bottom nav tab Message icon → swipe sang Nhật ký
50. **[SCREEN: Nhật ký]** Empty state "Bạn chưa có nhật ký nào" → tap FAB +
51. Form: title "Buổi đi chơi cuối tuần"
52. Body (textarea): "Hôm nay đi cà phê với Beatrice và Charlie. Vui ghê 🥰"
53. Attach 2 ảnh từ device gallery (chọn 2 ảnh demo)
54. Privacy toggle: "public" (để show trên Profile)
55. Submit → entry tạo

**Aldo + Beatrice xem Diary**
56. **[SCREEN: Nhật ký-1]** Grid 2 cột → 1 card thumbnail
57. Tap card → detail view → see full body + 2 ảnh
58. **[SWITCH DEVICE: Beatrice phone]** Mở Profile của Aldo → tab Memory (heart icon) → thấy entry public của Aldo
59. Tap entry → xem detail (read-only — Beatrice không edit/delete được)

> **Talking point:** "Diary = không gian chậm lưu kỷ niệm dài hạn. Privacy toggle: private chỉ owner xem, public hiện trên profile cho bạn bè. Đây là khác biệt vs Locket — Locket không có concept Diary."

### Part 6: RollCall (2 phút) — Tier 0+

**Trigger RollCall (manual cho demo)**

> **Note:** RollCall scheduler cron Sunday 8pm. Cho demo, anh manual trigger qua Firebase Cloud Functions Console hoặc qua admin endpoint.

60. Anh trigger `rollcallScheduler` từ Cloud Functions Console (giải thích: "Bình thường cron Sunday 8pm, demo manual cho time")
61. **[SWITCH DEVICE: Beatrice phone]** Push "RollCall hôm nay 📸 — Chia sẻ khoảnh khắc tuần này"
62. Tap notification → mở special post screen
63. **[SCREEN: RollCall special post]** Album picker filter ảnh 7 ngày gần nhất
64. Beatrice chọn 1 ảnh → preview → submit (KHÔNG caption, KHÔNG edit)
65. Post tag `type: 'rollcall'` lưu Firestore

**Aldo + Charlie multi-react**
66. **[SWITCH DEVICE: Aldo phone]** Push "Beatrice posted RollCall" → mở
67. RollCall post hiện trên feed với badge distinct "RollCall"
68. Aldo react 🔥 → counter 🔥 = 1
69. Aldo react thêm ❤️ → counter ❤️ = 1 (multi-react cho phép)
70. Aldo react thêm 😍 → counter 😍 = 1 (3 emoji khác nhau cùng 1 user)
71. **[SWITCH DEVICE: Charlie phone]** Charlie react 🔥 → counter 🔥 = 2

> **Talking point:** "RollCall = weekly social challenge. Khác post thường ở 2 điểm: (1) album picker filter chỉ 7 ngày gần (force chia sẻ moment recent), (2) multi-emoji react (express nhiều cảm xúc trên 1 post). Đây là defining feature Meep."

### Part 7: Widget Android (1 phút) — Tier 0

**Aldo add widget**
72. **[SWITCH DEVICE: Aldo phone]** Press home button → about app → long-press home screen → widget picker
73. Scroll find Meep → drag widget Meep size 4x4 vào home screen
74. Widget render ảnh mới nhất từ Beatrice (RollCall post hoặc latest photo)

**Beatrice gửi ảnh mới → widget update**
75. **[SWITCH DEVICE: Beatrice phone]** Camera → chụp ảnh nhanh + caption "Cuối ngày 🌙" → send to all friends
76. **[SWITCH DEVICE: Aldo phone]** Trong vòng 30s, widget tự update với ảnh mới
77. Tap widget → app mở deep link `meep://post/{postId}` → vào ảnh đó

> **Talking point:** "Widget Android — headline differentiator của Meep (lý do user install app). FCM data message silent push trigger widget refresh, không cần app foreground. Tap → deep link mở app vào đúng ảnh."

## Tổng kết demo (1 phút)

**Recap features đã show:**
- Tier 0: Auth, Friends, Camera, Share, Feed, Push, Reaction, Widget (8/8)
- Tier 0+: Profile, Space, Diary, RollCall (4/4)
- Total: 12/12 firm features ship

**Talking point closing:** "Meep MVP ship được tất cả 12 firm features trong 6 tuần với team 4 dev. Stack: Flutter + Firebase + native Kotlin widget. AI-augmented workflow với Cascade boost ~1.6x velocity, disciplined với TDD + verification + glob-scoped rules."

## Backup plan

### Mức độ fail và mitigation

| Step fail | Mức độ | Backup |
|---|---|---|
| Push notification chậm/miss | Med | Skip wait, manual refresh feed. Talking point: "Trên prod thật <10s, demo có lag mạng" |
| Widget không update | High | Show recorded video segment widget update. "Widget có FCM trigger, demo có thể bị Wi-Fi flaky" |
| Photo upload fail | High | Retry 1 lần. Nếu fail → switch sang pre-uploaded photo (demo account đã có sẵn 2-3 posts) |
| Auth/signup fail | Critical | Use pre-created account (Aldo+Beatrice+Charlie đã signup). Skip signup demo, jump to Part 2. Pre-recorded video signup show riêng. |
| App crash | Critical | Restart app. 1 lần OK acceptable. >1 lần → switch sang backup video full demo. |
| Cloud Function fail | Critical | Skip feature đó. Talking point: "Logic tested unit test 100%, prod issue có thể do quota/Firebase region" |
| Internet outage | Critical | Mobile hotspot backup. Nếu cũng fail → backup video full. |

### Backup video record (8/6 chuẩn bị)

- Format: MP4 1080p, 12-15 phút
- Cover toàn bộ 7 parts demo
- Voice over tiếng Việt (anh narrate)
- Subtitle Vietnamese
- Save 3 nơi: laptop demo + Google Drive backup + 1 dev's USB

## Q&A prep — talking points thường gặp

### Q1: "Tại sao chọn Flutter mà không React Native / native?"

**Trả lời:**
- Cross-platform ready cho post-MVP iOS (codebase reuse 80%)
- Single team Dart skillset (mọi dev đều full-stack module → tham gia dễ)
- Material 3 default UI tốt, ít boilerplate
- Performance gần native (especially scrolling)
- Hot reload boost dev velocity 2-3x
- Reference: ADR-0001 (chưa viết — có thể add nếu giảng viên hỏi sâu)

### Q2: "Tại sao Firebase mà không self-host BE?"

**Trả lời:**
- 4 dev student → operational simplicity ưu tiên
- Firebase free tier đủ cho 100-500 users (target capstone)
- Auth + Firestore + Storage + Functions + FCM trong 1 SDK
- Nếu logic phức tạp → vẫn có thể add Node BE riêng (planned `services/api/` defer)
- Reference: ADR-0001 firebase-first

### Q3: "Tại sao Android only mà không iOS cùng lúc?"

**Trả lời:**
- Capstone scope (6 tuần × 4 dev) không đủ cho cả 2 platform
- VN market 70% Android share → Android first hợp lý
- Flutter codebase giữ cross-platform-ready, switch iOS sau capstone không phải rewrite
- Reference: ADR-0002

### Q4: "Tại sao không có canvas editor cho Diary?"

**Trả lời:**
- Canvas editor (text/sticker/draw/layer) = app-in-app, 4+ tuần dev đơn lẻ
- MVP focus simple text + ảnh attach → ship được + value đủ
- Defer Tier 2 post-capstone — khi user feedback validate need

### Q5: "Tại sao không có dual camera như BeReal?"

**Trả lời:**
- Camera2 multi-camera API native phức tạp + không phải máy nào support
- Risk failure cao, không impressive value
- Single + flip front đủ cover use case 90%
- Defer Tier 2

### Q6: "Sao không có chat group, chỉ chat 1-1?"

**Trả lời:**
- Chat 1-1 đã defer Tier 1 (stretch) — chỉ ship nếu velocity cao
- Group chat thêm complexity realtime listener + thread UI
- MVP focus: chat = photo-anchored context (diff với generic messenger), không phải chat tự do
- Tier 2 post-capstone

### Q7: "Privacy/Security thế nào?"

**Trả lời:**
- Firestore rules default deny + per-collection helpers
- Owner check + Friend check + Space member check
- EXIF location strip server-side
- HTTPS only, password Firebase Auth hash
- Phone hash SHA-256 trước khi transmit
- Reference: `docs/architecture/security-model.md`

### Q8: "Tại sao không có account deletion?"

**Trả lời:**
- GDPR cascade Firestore data cleanup phức tạp
- Defer Tier 2 — khi compliance requirements rõ post-capstone
- MVP: user có thể logout, không ship feature delete

### Q9: "AI agent đóng vai trò gì trong dev?"

**Trả lời:**
- Cascade + Sonnet 4.6 backing assist:
  - Boilerplate code (CRUD, theme): boost 3-5x
  - Tests + documentation: boost 2-3x
  - Architecture / business logic: boost 1.2-1.5x (human judgment vẫn primary)
- Disciplined workflow:
  - Test-driven (TDD)
  - Verification before completion
  - PR review chặt ≤200 lines
  - Glob-scoped rules `.windsurf/rules/`
- Average velocity boost ~1.6x → fit 6-tuần timeline

### Q10: "Có gì khác biệt với Locket?"

**Trả lời:**
- 4 differentiator features (Tier 0+):
  1. **Diary** — không gian chậm lưu kỷ niệm dài hạn
  2. **Space** — nhóm riêng tư (BFF, family, couple)
  3. **RollCall** — weekly social challenge với multi-react
  4. **Camera enhanced** — flip + caption (foundation cho dual + video Tier 2)
- Locket = chỉ widget + photo share. Meep = widget + photo share + 4 layers engagement.

### Q11: "Future plan post-capstone?"

**Trả lời:**
- Phase 1: ship Tier 1 stretch goals (Settings full + Streak + Chat 1-1)
- Phase 2: ship Tier 2 nếu user traction tốt (Diary canvas, Dual camera, Video, Space chat)
- Phase 3: iOS port (Flutter codebase ready, ~2 tuần effort)
- Phase 4: Monetization (premium Spaces, custom themes, ad-free) — nếu user >5K

## Demo Day checklist

### 30 phút trước demo

- [ ] 3 thiết bị Android pin 100%, screen brightness max
- [ ] Cast 1 phone (Aldo) lên projector test
- [ ] Cài backup APK trên cả 3 phone (latest deploy build)
- [ ] Test Wi-Fi office stable
- [ ] Mobile hotspot backup ready
- [ ] Backup video MP4 trên laptop + USB + Google Drive
- [ ] Pre-created accounts logged in trên 3 phone
- [ ] Pre-friended setup (Aldo ↔ Beatrice ↔ Charlie)
- [ ] Reset state: clear cache, no test posts cũ trong feed (start clean)

### 5 phút trước demo

- [ ] Anh deep breath. Confidence.
- [ ] Open camera tab trên cả 3 phone (start position)
- [ ] Tab notifications opened + sound on
- [ ] Demo script này print 1 trang (cheat sheet) hoặc trên iPad

## Liên quan

- **Acceptance criteria full:** [`milestones.md`](milestones.md)
- **Risk register (backup plans):** [`risks.md`](risks.md)
- **Feature catalog:** [`../product/features.md`](../product/features.md)
- **User stories (granular AC):** [`../product/user-stories.md`](../product/user-stories.md)
