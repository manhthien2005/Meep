# Meep — User Stories

User stories cho MVP Tier 0 + Tier 0+ (12 firm features). Format chuẩn:

> **As a** \<persona\>, **I want** \<action\>, **so that** \<benefit\>.

ID format: `US-<FEATURE>-NN` (vd `US-AUTH-01`).

## Personas

| ID | Persona | Mô tả |
|---|---|---|
| **P1** | Sinh viên 18-25 | Vòng kết nối ~10-30 bạn thân, học/làm cùng nhau. Thường xuyên chia sẻ khoảnh khắc đời thường. |
| **P2** | Cặp đôi yêu xa | Muốn không gian riêng để chia sẻ ảnh hằng ngày, không cần public. |
| **P3** | Nhóm gia đình nhỏ | Chia sẻ ảnh con cái, hoạt động cuối tuần với gia đình thân. |

---

## Tier 0 — Locket parity

### 1. Auth

**US-AUTH-01: Đăng ký tài khoản mới qua email**
- As a P1 (new user), I want signup mới với email + password và Google, so that tạo account Meep và bắt đầu chia sẻ ảnh.
- AC:
  - [ ] Flow 5 screens (Email → Password → Họ Tên → Username → Tìm bạn từ danh bạ)
  - [ ] Username validate unique real-time qua Firestore
  - [ ] Password ≥8 ký tự
  - [ ] Submit thành công → vào /home (camera tab)

**US-AUTH-02: Đăng nhập với credential có sẵn**
- As a returning user, I want login với email/Google, so that truy cập account đã tạo.
- AC:
  - [ ] Login email + password sai → inline error tiếng Việt ("Email hoặc mật khẩu không đúng")
  - [ ] Login Google → bypass password screen
  - [ ] "Bạn đã quên mật khẩu?" → nhập email → gửi reset link

**US-AUTH-03: Auto-login khi mở app**
- As a logged-in user, I want app nhớ session, so that không phải nhập credential mỗi lần mở.
- AC:
  - [ ] Mở app sau khi đã login → trực tiếp /home, không qua /intro
  - [ ] Logout từ Settings → clear session → next mở app vào /intro

### 2. Friends

**US-FRIEND-01: Gửi lời mời kết bạn qua username**
- As a P1, I want search username của bạn và gửi friend request, so that kết nối với bạn bè đã có account.
- AC:
  - [ ] Search → kết quả real-time
  - [ ] Tap "Kết bạn" → request sent + recipient nhận push
  - [ ] Hủy request đang gửi (cancel outgoing)

**US-FRIEND-02: Mời bạn qua share-link**
- As a P1, I want gửi link Meep qua Messenger/SMS, so that bạn chưa có account vẫn install + connect.
- AC:
  - [ ] Generate deep link `meep://invite/{senderUid}` từ Settings hoặc Trang chủ-1
  - [ ] Share link qua Messenger/SMS native intent
  - [ ] Recipient install app + accept link → tự động pre-friend với sender

**US-FRIEND-03: Accept/decline lời mời**
- As a P1, I want xem incoming requests và accept/decline, so that kiểm soát ai vào friend graph.
- AC:
  - [ ] List incoming requests với avatar + name + button accept/decline
  - [ ] Accept → tạo `friendships/{sortedPair}` doc + push notification cả 2
  - [ ] Decline → request xoá, sender không re-send 24h

**US-FRIEND-04: Unfriend**
- As a P1, I want xóa bạn nếu không muốn tiếp tục, so that giữ vòng quan hệ chất lượng.
- AC:
  - [ ] Long-press friend trong friend list → confirm dialog "Hủy kết bạn?"
  - [ ] Confirm → xoá friendship doc + cả 2 không nhận photo của nhau nữa

### 3. Camera basic

**US-CAMERA-01: Chụp ảnh nhanh khi mở app**
- As a P1, I want camera ready ngay khi mở app, so that bắt khoảnh khắc không lỡ.
- AC:
  - [ ] Mở app → /home tab Camera default
  - [ ] Camera viewfinder ready trong <1.5s (Flutter `camera` package)
  - [ ] Capture button tap → ảnh preview ngay

**US-CAMERA-02: Flip camera trước/sau**
- As a P1, I want chuyển back/front camera, so that selfie hoặc chụp scene tùy chọn.
- AC:
  - [ ] Nút flip trên camera screen (right of capture)
  - [ ] Switch <500ms

**US-CAMERA-03: Chọn ảnh từ album**
- As a P1, I want post ảnh đã có trong device, so that share ký ức cũ.
- AC:
  - [ ] Gallery icon left of capture
  - [ ] Mở native album picker
  - [ ] Chọn ảnh → vào preview screen như chụp mới

### 4. Share photo

**US-SHARE-01: Gửi ảnh cho tất cả bạn bè**
- As a P1, I want chia sẻ khoảnh khắc với cả friend graph, so that mọi người thấy.
- AC:
  - [ ] Sau preview ảnh + caption → tap send → upload Storage
  - [ ] Default recipient = "Mọi người" (tất cả friends)
  - [ ] Friends nhận push trong <10s

**US-SHARE-02: Gửi ảnh cho bạn cụ thể**
- As a P2 (cặp yêu xa), I want gửi ảnh chỉ cho người yêu, so that giữ moments riêng.
- AC:
  - [ ] Trong Xem trước ảnh chụp screen → chọn recipients từ avatar row
  - [ ] Chỉ recipients được chọn nhận push + thấy ảnh trên feed

**US-SHARE-03: Caption text cho ảnh**
- As a P1, I want viết caption ngắn cho ảnh, so that thêm context.
- AC:
  - [ ] Textfield 1-2 dòng trên preview
  - [ ] Caption tiếng Việt (Unicode) lưu chính xác Firestore
  - [ ] Caption hiện trên feed dưới ảnh

### 5. Feed

**US-FEED-01: Xem ảnh từ bạn bè**
- As a P1, I want xem ảnh bạn gửi theo thứ tự thời gian, so that catch up moments.
- AC:
  - [ ] Swipe sang trái từ Camera tab → Feed page
  - [ ] List vertical 1 ảnh / screen, latest first
  - [ ] Mỗi ảnh có author name + caption + thời gian (relative: "2h trước")

**US-FEED-02: Pull-to-refresh**
- As a P1, I want refresh feed manually, so that thấy ảnh mới ngay.
- AC:
  - [ ] Pull down từ top → loading indicator → load latest
  - [ ] Hoàn tất → release indicator

**US-FEED-03: Infinite scroll pagination**
- As a P1, I want load thêm khi scroll xuống, so that xem ảnh cũ.
- AC:
  - [ ] Scroll near bottom → auto load thêm 20 photos
  - [ ] Loading indicator trong khi fetch
  - [ ] Cache local: scroll lên không tải lại

### 6. Push notification

**US-PUSH-01: Nhận notification ảnh mới**
- As a P1, I want biết ngay khi bạn gửi ảnh, so that engage timely.
- AC:
  - [ ] Push body: "Aldo gửi ảnh mới"
  - [ ] Tap notification → app mở vào ảnh đó (deep link)
  - [ ] Background/killed app vẫn nhận

**US-PUSH-02: Nhận notification reaction**
- As a P1, I want biết khi bạn react ảnh của tôi, so that cảm thấy được kết nối.
- AC:
  - [ ] Push body: "Beatrice react ❤️ ảnh của bạn"
  - [ ] Tap → mở ảnh + show reactor list

### 7. Reaction

**US-REACT-01: React emoji ảnh bạn**
- As a P1, I want react quick ảnh bạn gửi, so that engage không cần text.
- AC:
  - [ ] Bottom photo có 4 emoji default (❤️🔥😂😍)
  - [ ] Tap emoji → react instant (optimistic UI)
  - [ ] Re-tap same emoji → unreact
  - [ ] Khác emoji → replace

**US-REACT-02: Xem ai đã react**
- As a P1, I want biết ai react ảnh của mình, so that respond appropriately.
- AC:
  - [ ] Tap counter reaction → modal hiện list reactor + emoji họ react

### 8. Widget Android

**US-WIDGET-01: Add widget vào home screen**
- As a P1, I want có widget Meep trên Android home, so that thấy ảnh bạn ngay khi unlock.
- AC:
  - [ ] User long-press home → widget picker → Meep widget
  - [ ] Drag widget vào home screen (size 2x2 hoặc 4x4)
  - [ ] Widget hiển thị ảnh mới nhất + sender + caption truncate

**US-WIDGET-02: Widget tự update khi có ảnh mới**
- As a P1, I want widget cập nhật real-time, so that không miss moments.
- AC:
  - [ ] Bạn gửi ảnh → widget update trong <30s (qua FCM data message)
  - [ ] Widget không cần app foreground để update

**US-WIDGET-03: Tap widget mở app**
- As a P1, I want tap widget mở app, so that xem ảnh full + react.
- AC:
  - [ ] Tap widget → app mở deep link `meep://post/{postId}`
  - [ ] App navigate trực tiếp vào ảnh đó

---

## Tier 0+ — Meep differentiator

### 9. Diary basic

**US-DIARY-01: Tạo nhật ký mới**
- As a P1, I want viết nhật ký với text + ảnh, so that lưu kỷ niệm dài hạn.
- AC:
  - [ ] FAB "+" trong Nhật ký tab
  - [ ] Form: title + body (textarea) + attach 1-3 ảnh
  - [ ] Privacy toggle: private (default) / public
  - [ ] Submit → entry hiện ngay trong list

**US-DIARY-02: Xem list entries**
- As a P1, I want xem tất cả nhật ký đã viết, so that ôn lại kỷ niệm.
- AC:
  - [ ] Grid 2 cột (Nhật ký-1 design)
  - [ ] Mỗi card: thumbnail + title + date
  - [ ] Empty state: "Bạn chưa có nhật ký nào"
  - [ ] Sorted by `createdAt` desc

**US-DIARY-03: Edit/delete entry**
- As a P1, I want sửa hoặc xóa nhật ký cũ, so that update ký ức.
- AC:
  - [ ] Tap entry → detail view → button edit + delete
  - [ ] Edit → reuse form tạo, prefill data
  - [ ] Delete → confirm dialog → remove Firestore + Storage

**US-DIARY-04: Public diary hiện trên profile**
- As a P1, I want share nhật ký với bạn, so that họ thấy được hành trình của tôi.
- AC:
  - [ ] Privacy toggle public → entry hiện trên Profile tab Memory
  - [ ] Bạn bè view profile thấy được public entries
  - [ ] Private entries chỉ owner thấy

### 10. Space basic

**US-SPACE-01: Tạo space mới**
- As a P3 (gia đình), I want tạo group "Family" với 5 thành viên, so that chia sẻ ảnh chỉ trong gia đình.
- AC:
  - [ ] Settings → "Tiện ích" → "Tạo Space mới" hoặc add icon trong section
  - [ ] Form: name + chọn icon từ preset 6-8 icon + invite friends từ list
  - [ ] Submit → space tạo, members nhận push "Bạn được mời vào Space X"

**US-SPACE-02: Send photo to space**
- As a P3, I want gửi ảnh chỉ cho members space, so that giữ riêng.
- AC:
  - [ ] Camera screen → recipient dropdown "Mọi người" → list spaces
  - [ ] Chọn Space → photo broadcast chỉ members
  - [ ] Friends ngoài space KHÔNG thấy

**US-SPACE-03: Filter feed theo space**
- As a P3, I want xem feed riêng của space "Family", so that focus moments với gia đình.
- AC:
  - [ ] Feed top dropdown "Mọi người" → list spaces
  - [ ] Chọn space → feed filter chỉ photos trong space đó

**US-SPACE-04: Leave space**
- As a P1, I want rời space nếu không quan tâm nữa, so that clean up.
- AC:
  - [ ] Space settings → button "Rời space"
  - [ ] Confirm → user removed from members + không thấy photos space cũ/mới

### 11. RollCall basic

**US-ROLLCALL-01: Nhận RollCall weekly**
- As a P1, I want được nhắc weekly chia sẻ moment, so that engage đều đặn.
- AC:
  - [ ] Cron Cloud Function trigger Sunday 8pm Vietnam timezone
  - [ ] Tất cả users active nhận push: "RollCall: chia sẻ khoảnh khắc tuần này"
  - [ ] Push tap → mở special post screen

**US-ROLLCALL-02: Post RollCall photo**
- As a P1, I want chia sẻ ảnh tuần qua, so that bạn bè thấy hành trình.
- AC:
  - [ ] Special post screen có badge "RollCall" distinct
  - [ ] Album picker filter chỉ ảnh chụp 7 ngày gần nhất
  - [ ] KHÔNG caption, KHÔNG edit
  - [ ] Submit → post tag `type: 'rollcall'` lưu Firestore

**US-ROLLCALL-03: Multi-emoji react RollCall**
- As a P1, I want react nhiều emoji trên RollCall post (khác post thường), so that express nhiều cảm xúc.
- AC:
  - [ ] RollCall post hiện trên feed với badge
  - [ ] User có thể thả 6 emoji default (🔥❤️😂😍🥰😮)
  - [ ] User cùng có thể thả nhiều emoji khác nhau (multi)
  - [ ] Counter mỗi emoji visible

### 12. Profile screen

**US-PROFILE-01: Xem profile của mình**
- As a P1, I want xem trang cá nhân, so that quản lý content và identity.
- AC:
  - [ ] Tab Profile (icon person bottom nav)
  - [ ] Header: avatar + username + bio
  - [ ] Stats: số bài viết + số bạn bè + số space
  - [ ] Tab grid: 3-col thumbnails posts

**US-PROFILE-02: Xem memory tab (Diary public)**
- As a P1, I want xem Diary entries public của mình ở Profile, so that chia sẻ hành trình.
- AC:
  - [ ] Tab thứ 2 (icon heart) hiện Diary entries `privacy: public`
  - [ ] Visitor (bạn bè) thấy được tab này

**US-PROFILE-03: Xem profile bạn bè**
- As a P1, I want xem profile bạn để biết họ post gì, so that connect.
- AC:
  - [ ] Tap avatar bạn (trong feed/friend list) → mở Profile họ
  - [ ] Chỉ thấy posts đã share with me
  - [ ] Memory tab thấy public Diary

**US-PROFILE-04: Share Meep deep link**
- As a P1, I want share trang cá nhân, so that mời người ngoài app vào Meep.
- AC:
  - [ ] Button "Chia sẻ trang cá nhân" → copy link `meep://user/{username}`
  - [ ] Share qua native intent (Messenger, SMS, etc.)

---

## Tier 1 — Stretch (brief)

### 13. Settings basic
- US-SETTINGS-01: Edit avatar/username/bio
- US-SETTINGS-02: Toggle notification
- US-SETTINGS-03: Logout với confirm dialog

### 14. Streak/Kỷ niệm calendar
- US-STREAK-01: Xem calendar tháng hiện tại với highlight ngày post
- US-STREAK-02: Xem counter streak ("2 chuỗi ngày")

### 15. Chat 1-1 từ ảnh
- US-CHAT-01: Reply ảnh → tạo/mở chat thread 1-1
- US-CHAT-02: Send text message trong thread
- US-CHAT-03: Realtime update qua Firestore listener
- US-CHAT-04: Push notification new message

---

## Acceptance test E2E

Demo M3 acceptance test = chạy được full Aldo+Beatrice+Charlie story trong [`../roadmap/demo-script.md`](../roadmap/demo-script.md).

## Liên quan

- **Feature catalog:** [`features.md`](features.md)
- **NFR:** [`non-functional.md`](non-functional.md)
- **Demo script:** [`../roadmap/demo-script.md`](../roadmap/demo-script.md)
