# Meep — Feature Catalog

Catalog đầy đủ MVP scope với MoSCoW priority. Mỗi feature có scope cứng (must ship) + scope cắt (defer).

> **Tags status:** `firm` (must ship M3) · `stretch` (unlock per retro) · `won't` (defer post-capstone, fixed)
>
> Detail breakdown + day estimates: memory `mvp-tier-priority`. User stories: [`user-stories.md`](user-stories.md).

## Tổng quan tier

| Tier | Type | Số features | Days raw | Status |
|---|---|---|---|---|
| **Tier 0** | Locket parity | 8 | 34-45 | 🔒 firm |
| **Tier 0+** | Meep differentiator | 4 | 17-18 | 🔒 firm |
| **Tier 1** | Stretch goal | 3 | 9-13 | 🔓 unlock per retro |
| **Tier 2** | Won't have | 11 | — | ❌ defer |

**Total firm (Tier 0 + 0+):** 12 features, 51-63 days raw. AI boost ~1.6x → effective ~32-39 days. Fit budget 4 dev × 6 tuần.

---

## Tier 0 — Locket parity (firm, must ship M3)

Foundation tính năng tương đương Locket. Thiếu 1 feature → demo M3 broken.

### 1. Auth — `firm` · M1 · 8-10 days

**Mô tả:** Xác thực user qua email/password hoặc Google Sign-In. Multi-step signup theo Figma (5 screens).

**Trong scope:**
- Trang giới thiệu (intro với 2 button: "Tạo tài khoản mới" / "Đăng nhập")
- Signup flow 5-screen: Email → Password (≥8 ký tự) → Họ + Tên → Username (validate unique) → Tìm bạn từ danh bạ (optional skip)
- Login flow: Email → Password (có "Bạn đã quên mật khẩu?" link)
- Login với Google (Firebase Auth)
- Logout từ Settings
- Auto-login (Firebase Auth tự persist token)
- Quên mật khẩu (gửi email reset link, KHÔNG gating)

**Ngoài scope:**
- ❌ Email verification gating (gửi email verify nhưng không block login)
- ❌ Apple Sign-In (defer với iOS post-MVP)
- ❌ Đổi mật khẩu detail flow (chỉ "Quên MK" basic)
- ❌ Profile editing trong signup (defer Settings basic Tier 1)

**Acceptance criteria:**
- [ ] User signup mới qua email/password thành công, navigate đúng theo flow 5 screens
- [ ] User signup với Google → bypass password screen, vẫn vào họ tên/username
- [ ] Username validation real-time (unique check qua Firestore)
- [ ] Login với credential đúng → vào /home (camera tab); sai → inline error tiếng Việt
- [ ] Logout → clear session → redirect /intro
- [ ] Auto-login: mở app sau login → trực tiếp vào /home

**Dependencies:** Firebase project setup (M1 sprint 1).

### 2. Friends — `firm` · M2 · 6-8 days

**Mô tả:** Mời + accept lời mời kết bạn, list bạn bè. Closed graph (không public following).

**Trong scope:**
- Invite bằng username (search + send request)
- Invite bằng share-link (Meep deep link, paste vào messenger/SMS)
- List incoming friend requests (accept/decline)
- List outgoing requests (cancel)
- Friend list (name + avatar + last active)
- Unfriend (remove bạn bè 2 chiều)

**Ngoài scope:**
- ❌ Block + Report user (Tier 2, defer post-capstone)
- ❌ Tìm bạn từ danh bạ (đã optional trong signup, full implementation defer M2 nếu time)
- ❌ Friend suggestions (mạng rộng → không phù hợp closed graph)

**Acceptance criteria:**
- [ ] User search username chính xác → hiện kết quả + nút "Kết bạn"
- [ ] Send friend request → recipient thấy trong incoming list + push notification
- [ ] Accept request → cả 2 thành bạn (Firestore document `/friendships/{sortedPair}`)
- [ ] Decline → request xoá, recipient không re-send được trong 24h
- [ ] Friend list real-time update khi có thay đổi

**Dependencies:** Auth (Tier 0 #1).

### 3. Camera basic — `firm` · M2 · 4-5 days

**Mô tả:** Chụp ảnh đơn giản với camera trước/sau, chọn từ album, caption text.

**Trong scope:**
- Camera viewfinder (full-screen Trang chủ tab)
- Capture button (single tap → ảnh)
- Flip camera (back ↔ front)
- Album picker (gallery icon → chọn ảnh từ device)
- Preview ảnh sau capture (Xem trước ảnh chụp)
- Caption text plain (textfield 1-2 dòng)
- Cancel hoặc Send

**Ngoài scope:**
- ❌ Dual camera (multi-camera API, Tier 2)
- ❌ Video recording 5-10s (Tier 2)
- ❌ Memory cards from old photos (Tier 2)
- ❌ Caption stickers system (Tier 2)
- ❌ Filter / chỉnh sửa ảnh (defer post-capstone)

**Acceptance criteria:**
- [ ] App mở → camera ready trong <1.5s (Locket benchmark <500ms khó với Flutter, accept loose)
- [ ] Capture button tap → ảnh hiển thị preview
- [ ] Flip camera nút → switch back/front trong <500ms
- [ ] Album picker → chọn ảnh thành công, hiện preview
- [ ] Caption nhập tiếng Việt (Unicode) OK
- [ ] Cancel → quay về camera

**Dependencies:** Auth (Tier 0 #1). `camera` Flutter package.

### 4. Share photo — `firm` · M2 · 4-5 days

**Mô tả:** Upload ảnh + metadata, trigger push notification cho bạn bè.

**Trong scope:**
- Upload ảnh lên Firebase Storage (`posts/{uid}/{postId}/{filename}.jpg`)
- Resize ảnh server-side qua Cloud Function `onPostCreated` (max 1080p, strip EXIF location)
- Metadata Firestore (`posts` collection): authorId, caption, recipients, createdAt, storageUrl
- Send to: tất cả bạn bè (default) hoặc danh sách chọn lọc hoặc Space (Tier 0+ #10)
- Trigger Cloud Function `fanOutPost` push notification recipients

**Ngoài scope:**
- ❌ Video upload
- ❌ Multi-photo upload 1 post (Locket cũng chỉ 1 photo/post)
- ❌ Schedule post

**Acceptance criteria:**
- [ ] Upload ảnh 5MB → success trong <5s (kết nối 4G stable)
- [ ] EXIF location bị strip server-side
- [ ] Recipients nhận push notification trong <10s
- [ ] Photo xuất hiện trên feed recipient trong <15s
- [ ] Failed upload → retry button + error message tiếng Việt

**Dependencies:** Auth, Friends, Camera basic.

### 5. Feed — `firm` · M2 · 3-4 days

**Mô tả:** Hiển thị ảnh nhận được từ bạn bè/Space theo thời gian, latest first.

**Trong scope:**
- Vertical list (1 ảnh / screen như Trang chủ-2 swipe page)
- Latest first sorting
- Pull-to-refresh
- Infinite scroll pagination (20 ảnh/page)
- Cache ảnh local (cached_network_image)
- Filter theo Space (dropdown "Mọi người" / per Space)
- Empty state ("Chưa có hoạt động nào!")
- Error state (network fail → retry button)

**Ngoài scope:**
- ❌ Search trong feed
- ❌ Filter theo người gửi cụ thể
- ❌ Stories / ephemeral content

**Acceptance criteria:**
- [ ] Feed load 20 ảnh đầu trong <3s
- [ ] Scroll xuống → load thêm 20 ảnh tiếp theo
- [ ] Pull-to-refresh → load latest
- [ ] Cache hoạt động: ảnh đã xem không tải lại khi scroll lên
- [ ] Empty state hiện đúng khi user chưa có bạn / chưa nhận ảnh

**Dependencies:** Share photo (cần ảnh để hiển thị).

### 6. Push notification — `firm` · M3 · 3-4 days

**Mô tả:** Firebase Cloud Messaging cho Android. Gửi notification khi có ảnh mới, reaction, RollCall.

**Trong scope:**
- FCM token lưu trên Firestore (`users/{uid}/devices/{deviceId}`)
- Notification types: ảnh mới (`new_photo`), reaction (`new_reaction`), RollCall (`rollcall_weekly`)
- Notification body tiếng Việt: "Aldo gửi ảnh mới", "Beatrice react ❤️ ảnh của bạn"
- Tap notification → deep link mở app vào ảnh tương ứng (cần `go_router` setup)
- Cài đặt bật/tắt từng loại (defer Tier 1 Settings — M3 basic on/off all)

**Ngoài scope:**
- ❌ Notification grouping logic phức tạp (Android tự group default)
- ❌ Custom sound / vibration pattern
- ❌ iOS APNs (defer với iOS)

**Acceptance criteria:**
- [ ] FCM token registered tự động khi login
- [ ] Bạn gửi ảnh → recipient nhận notification trong <10s
- [ ] Tap notification → app mở vào đúng ảnh (deep link)
- [ ] Background/killed app vẫn nhận notification

**Dependencies:** Share photo (notification trigger từ `fanOutPost`).

### 7. Reaction — `firm` · M3 · 2-3 days

**Mô tả:** React emoji 1 lần per post.

**Trong scope:**
- Tap emoji bottom of photo (Đăng ảnh-2 design — 4 emoji default: ❤️🔥😂😍)
- 1 emoji / user / post (replace previous nếu đổi)
- Hiển thị tổng count + danh sách reactor
- Trigger push notification cho author
- Xóa reaction (tap lại = remove)

**Ngoài scope:**
- ❌ Multi-emoji react (RollCall riêng có Tier 0+ #11)
- ❌ Custom emoji picker (chỉ 4 default)
- ❌ Reaction comment (defer)

**Acceptance criteria:**
- [ ] Tap emoji → react instant (optimistic UI)
- [ ] Author nhận push trong <10s
- [ ] Count reactor real-time update
- [ ] Re-tap same emoji → unreact

**Dependencies:** Share photo, Push notification.

### 8. Widget Android — `firm` · M3 · 4-6 days · 🔧 native Kotlin

**Mô tả:** Home-screen widget Android hiển thị ảnh mới nhất từ bạn bè. Tap → mở app vào ảnh đó.

**Trong scope:**
- Android AppWidget (Kotlin native)
- Widget size: 2x2 và 4x4 cell
- Hiển thị ảnh mới nhất + tên người gửi + caption (truncate)
- Update qua FCM data message (silent push) → trigger widget refresh
- Tap widget → deep link `meep://post/{postId}` mở app
- Empty state: "Mời bạn bè để thấy ảnh"

**Ngoài scope:**
- ❌ iOS WidgetKit (defer với iOS)
- ❌ Multi-photo widget (chỉ latest)
- ❌ Customization theme/size từ user

**Acceptance criteria:**
- [ ] User add widget từ Android home screen launcher
- [ ] Widget hiển thị ảnh mới nhất sau khi user nhận
- [ ] FCM trigger update widget trong <30s
- [ ] Tap widget → app mở vào đúng ảnh
- [ ] Test trên 3 thiết bị Android khác nhau (size/launcher)

**Dependencies:** Push notification (FCM data message channel), `home_widget` Flutter plugin + native Kotlin AppWidget code.

---

## Tier 0+ — Meep differentiator (firm, must ship M3)

Đây là điểm khác biệt vs Locket. KHÔNG cắt được.

### 9. Diary basic — `firm` · M3 · 5 days

**Mô tả:** Nhật ký cá nhân lưu kỷ niệm dài hạn. Text + 1-3 ảnh attach. Private hoặc public.

**Trong scope:**
- Tab "Nhật ký" trong bottom nav (mục Message tab share)
- List entries (Nhật ký-1 design): grid 2 cột, mỗi card thumbnail + title + date
- Empty state: "Bạn chưa có nhật ký nào"
- Tạo entry mới (FAB + button góc phải dưới):
  - Title (text 1 dòng)
  - Body (textarea multi-line, plain text)
  - Attach ảnh (1-3 ảnh từ device)
  - Privacy toggle: private (chỉ user xem) hoặc public (hiện trên profile)
- Detail view: xem entry full, có nút edit/delete
- Edit entry (sửa title/body/ảnh)
- Delete entry (confirm dialog)

**Ngoài scope:**
- ❌ **Canvas editor** (text/sticker/draw/layer free positioning) — Tier 2, đây là app-in-app
- ❌ Template diary (chỉ blank text + ảnh)
- ❌ Rich text formatting (bold, italic, color)
- ❌ Search trong diary entries

**Acceptance criteria:**
- [ ] Tạo entry với 0 ảnh, 1 ảnh, 3 ảnh đều OK
- [ ] Privacy toggle hoạt động: private không hiện trên profile, public hiện
- [ ] Edit entry → reflect ngay trên list
- [ ] Delete entry → confirm dialog → remove khỏi Firestore + Storage
- [ ] List entries sorted by `createdAt` desc

**Dependencies:** Auth, Camera basic (cho ảnh attach).

### 10. Space basic — `firm` · M3 · 5 days

**Mô tả:** Tạo nhóm riêng tư (BFF, Couple, Family). Gửi ảnh chỉ trong nhóm.

**Trong scope:**
- Tab Settings → "Tiện ích" section → "Tạo Space mới"
- Form tạo: Name + Icon (chọn từ preset 6-8 icon) + invite friends (chọn từ friend list)
- List spaces user đang tham gia (hiện trong Settings + dropdown camera home)
- Send photo to Space (Camera flow: chọn "Mọi người" / "Bạn cụ thể" / "Space X" → broadcast members)
- Feed filter theo Space (Đăng ảnh-3 dropdown "Mọi người" → list spaces)
- Leave space (rời nhóm)
- Members list trong space settings

**Ngoài scope:**
- ❌ **Theme color/icon switch per Space** — Tier 2
- ❌ **Group chat trong Space** — Tier 2
- ❌ Space camera UI changes (theme apply lên camera) — Tier 2
- ❌ Admin/owner role (mọi member equal)
- ❌ Space discovery (chỉ invite-only)

**Acceptance criteria:**
- [ ] Tạo Space "Bạn thân" với 3 friends → 4 members tổng
- [ ] Send photo to Space → chỉ members nhận, không broadcast bạn bè khác
- [ ] Feed filter theo Space → chỉ hiện photos trong Space đó
- [ ] Leave Space → user không nhận photos space mới + không xem được photos cũ space
- [ ] Members list real-time update khi có người leave

**Dependencies:** Auth, Friends, Share photo.

### 11. RollCall basic — `firm` · M3 · 4 days

**Mô tả:** Weekly social challenge. Cron Cloud Function trigger weekly notification, user post ảnh đặc biệt với multi-emoji react.

**Trong scope:**
- Cloud Function cron (scheduled Sunday 8pm Vietnam timezone) → broadcast push notification "RollCall: chia sẻ khoảnh khắc tuần này"
- Tap notification → mở special post screen (UI khác camera thường, có badge "RollCall")
- Special post:
  - Chỉ chọn ảnh từ device gallery (filter ảnh chụp 7 ngày gần nhất)
  - KHÔNG caption (chỉ ảnh)
  - KHÔNG edit / filter
  - Submit → post tag `type: 'rollcall'` trên Firestore
- Display RollCall posts trong feed (badge riêng, distinct visual)
- **Multi-emoji react**: cho phép 1 user thả nhiều emoji trên cùng 1 RollCall post (khác Reaction Tier 0 #7 chỉ 1 emoji)

**Ngoài scope:**
- ❌ **168h auto-archive** (post sau 7 ngày tự ẩn khỏi feed + chuyển vào Diary) — Tier 2, background job phức tạp
- ❌ **Feed gating** ("chỉ unlock feed sau khi đăng RollCall") — anti-pattern UX, Tier 2
- ❌ Custom emoji picker (chỉ 6 default: 🔥❤️😂😍🥰😮)
- ❌ User skip / opt-out RollCall

**Acceptance criteria:**
- [ ] Cron function trigger Sunday 8pm Vietnam → tất cả users nhận push
- [ ] Special post screen filter ảnh đúng 7 ngày gần
- [ ] Submit RollCall post → hiện trên feed với badge "RollCall"
- [ ] Multi-react: user A thả 3 emoji khác nhau trên cùng post → đếm 3
- [ ] RollCall post counter visible cho author

**Dependencies:** Push notification, Reaction (concept), Cloud Function scheduler.

### 12. Profile screen — `firm` · M2 · 3-4 days

**Mô tả:** Trang profile cá nhân hiển thị avatar, username, bio, grid posts.

**Trong scope:**
- Tab Profile (icon person trong bottom nav)
- Header: avatar (circle), username, bio (text 2-3 dòng max)
- Stats: số bài viết, số bạn bè, số space
- Tab grid: 3 cột thumbnail posts (mới nhất trước)
- Tab memory (heart icon): Diary entries public của user
- Button "Chỉnh sửa" → defer Settings (Tier 1)
- Button "Chia sẻ trang cá nhân" → share Meep deep link
- View profile của bạn bè khác (giới hạn theo privacy)

**Ngoài scope:**
- ❌ Edit profile inline (defer Tier 1 Settings basic)
- ❌ Profile cover photo
- ❌ Story highlights
- ❌ Profile analytics

**Acceptance criteria:**
- [ ] Profile own load avatar, username, bio chính xác
- [ ] Grid posts hiện tất cả posts user đã đăng (không bị filter Space)
- [ ] Tab memory hiện chỉ Diary entries `privacy: public`
- [ ] View profile bạn → chỉ thấy posts đã share with this friend
- [ ] Button "Chia sẻ trang cá nhân" → copy deep link `meep://user/{username}`

**Dependencies:** Auth, Share photo, Diary basic.

---

## Tier 1 — Stretch goals (unlock per retro)

Lock cho đến khi M1/M2 retro confirm velocity ≥1.5x boost.

### 13. Settings basic — `stretch` · M3 · 2-3 days

**Mô tả:** Settings screen với edit profile + logout (theo Trang settings.png).

**Trong scope:**
- Edit avatar (upload Storage)
- Edit username (validate unique)
- Edit bio
- Notification toggle (on/off all)
- Logout button (confirm dialog)
- Help center link (link external)

**Ngoài scope:**
- ❌ Account deletion (Tier 2)
- ❌ Block user list (Tier 2)
- ❌ Privacy granular per content type
- ❌ Đổi mật khẩu (link "Quên MK" cũ)
- ❌ Trung tâm trợ giúp + Báo cáo sự cố + Gửi đề xuất (chỉ link external, không build internal)

**Acceptance criteria:** Edit thành công + reflect ngay trên Profile screen.

### 14. Streak/Kỷ niệm calendar — `stretch` · M3 · 2-3 days

**Mô tả:** Tab Calendar (icon calendar bottom nav) — hiển thị lịch tháng với highlight ngày user post + counter streak.

**Trong scope:**
- Calendar view tháng hiện tại
- Highlight ngày user đã post
- Counter streak ("2 Locket | 2d chuỗi")
- Empty state: "Gửi khoảnh khắc đầu tiên..."

**Ngoài scope:**
- ❌ Tap ngày → xem posts ngày đó (defer)
- ❌ Multi-month navigation
- ❌ Streak rewards / gamification

### 15. Chat 1-1 từ ảnh — `stretch` · M3 · 5-7 days

**Mô tả:** Reply ảnh → tạo/mở chat thread 1-1 với người gửi.

**Trong scope:**
- Bottom of photo (Đăng ảnh-2): "Gửi tin nhắn..." input
- Tap input → mở chat thread (Tin nhắn-1)
- Thread chứa text messages + photo context (thumbnail ảnh gốc + caption ở header)
- Realtime update qua Firestore listener
- List threads (Tin nhắn screen)
- Push notification cho new message

**Ngoài scope:**
- ❌ Group chat trong Space (Tier 2)
- ❌ Voice message
- ❌ Image attachment trong chat (chỉ text)
- ❌ Message reactions
- ❌ Read receipts

---

## Tier 2 — Won't have (defer post-capstone, fixed)

Cắt regardless of velocity. Lý do từng feature:

| Feature | Lý do cắt |
|---|---|
| **Diary canvas editor** | Canvas editor (text/sticker/draw/layer free positioning) = app-in-app, 4+ tuần dev. Ngoài budget. |
| **Dual camera** | Camera2 multi-camera API native phức tạp + không phải máy nào support. Risk failure cao. |
| **Video recording 5-10s** | Encoding/upload/playback complexity + storage cost. |
| **Memory cards from old photos** | Nice-to-have, không defining. |
| **Caption stickers full** | Music/weather/location/time/season/decoration tag system với composable overlay = entire feature riêng. |
| **Group chat trong Space** | Realtime listener + UI thread group phức tạp. Phase 1 chỉ chat 1-1 (Tier 1). |
| **Theme switch per Space** | UI complexity high, không phải differentiator. |
| **Block + Report user** | Moderation system = entire feature riêng. |
| **Account deletion** | GDPR cascade Firestore data cleanup phức tạp + concerns post-capstone. |
| **RollCall 168h auto-archive** | Background job logic + state transition complexity. |
| **RollCall feed gating** | Anti-pattern UX (ép user post mới được xem feed = friction cao). |

## Tài liệu liên quan

- **User stories per Tier 0+ feature:** [`user-stories.md`](user-stories.md)
- **Non-functional requirements:** [`non-functional.md`](non-functional.md)
- **Sprint allocation M1/M2/M3:** [`../roadmap/milestones.md`](../roadmap/milestones.md)
- **Demo M3 acceptance test:** [`../roadmap/demo-script.md`](../roadmap/demo-script.md)
- **Risk register:** [`../roadmap/risks.md`](../roadmap/risks.md)
- **Figma reference (26 screens):** [`../specs/figma_design/`](../specs/figma_design/)
