# Meep — Roadmap Milestones

3 milestones × 2 tuần = 6 tuần hard deadline (30/4 → 9/6/2026).

> **Strategy:** Plan firm = Tier 0 + Tier 0+ (12 features). Stretch goal = Tier 1 (3 features), unlock per retro nếu velocity ≥1.5x boost.
>
> Sprint conventions: ADR-0003 + `docs/team-workflow.md` §8.

## Timeline tổng quan

```
30/4         13/5         27/5         9/6
  │           │            │            │
  M1          M2           M3           DEMO
Foundation  Social Core  Differentiator
  Auth      Friends       Push + Widget
  Setup     Camera        Diary + Space
            Share + Feed  RollCall
            Profile       Polish + Demo
```

## Team allocation

- **2 FS dev (anh + 1):** Cloud Functions + Firestore rules + native Kotlin widget + data layer + complex business logic
- **2 FE-bridge:** Figma → Flutter UI (presentation layer + theme + reusable widgets)
- Cross-lane PR review: FE-bridge PR → anh review default

## Velocity baseline

- **Raw:** 4 dev × 14 days × 6h × 0.7 efficiency = ~39 dev-days/sprint (M1, M2). M3 12 days = ~33 dev-days
- **AI-boosted (1.6x avg):** ~62 effective dev-days/sprint (M1, M2). M3 ~53.

---

# M1 — Foundation + Auth (1/5 → 13/5)

> 14 ngày. Sprint 1.

## Mục tiêu

End of M1: 4 dev signup được + login được + có CI/CD chạy stage deploy APK + có Firestore rules cho users collection.

## Deliverables (must ship)

### 1. CI/CD + Firebase setup ✅
- Firebase project `meep-dev` (Auth + Firestore + Storage + Functions emulator)
- `flutterfire configure` wire `google-services.json`
- GitHub Actions workflows chạy commitlint + lint + test trên mọi PR
- Husky hooks bind sau `npm install`
- Branch protection `develop` + `deploy`

### 2. Auth feature (Tier 0 #1) ✅
- Signup 5-screen email/Google + login + logout + auto-login
- AuthRepository + AuthController + 5 screens UI placeholder Material 3 baseline
- Riverpod controllers (multi-step state machine)
- Firestore `users` schema + rules cơ bản
- Tests: unit (controller, repository) + widget (signup form) + 1 integration (login flow)

### 3. Profile screen scaffold (Tier 0+ #12, partial) ✅
- Profile screen UI placeholder
- Read user data từ Firestore
- Edit avatar/bio defer M2

### 4. Phase 0 docs maintenance ✅
- Update `docs/specs/` với spec auth M1
- Update `docs/plans/` với plan auth M1

## Acceptance criteria

- [ ] User signup mới qua email/password thành công, đi đúng 5 screens
- [ ] User signup với Google → bypass password
- [ ] Username validation real-time unique check
- [ ] Login → vào /home (camera tab placeholder)
- [ ] Logout → clear session → /intro
- [ ] Auto-login: mở app sau login → trực tiếp /home
- [ ] CI/CD pass cho mọi PR
- [ ] Staging APK build được + deploy thành công Firebase Hosting / App Distribution
- [ ] 4 dev đã signup được trên app
- [ ] Test coverage controllers + repos ≥ 80%

## Sprint breakdown M1

### Tuần 1 (1/5 → 6/5)

| Day | Lane | Task | Owner | Effort |
|---|---|---|---|---|
| 1-2 | BE/Native | Setup Firebase project + flutterfire wire + emulator | FS-1 (anh) | M |
| 1-2 | BE/Native | GitHub Actions CI/CD workflows + husky hooks | FS-2 | M |
| 3-4 | BE/Native | `users` Firestore schema + rules + tests | FS-1 | M |
| 3-4 | BE/Native | `AuthRepository` Firebase implementation + tests | FS-2 | M |
| 5-6 | BE/Native | Riverpod controllers (signup multi-step state machine) | FS-1 + FS-2 (pair) | L |
| 4-5 | UI/Design | Setup `core/theme/` Material 3 baseline | FE-1 | S |
| 4-5 | UI/Design | Setup `core/routing/` go_router config + auth guard | FE-2 (anh advise) | M |

### Tuần 2 (7/5 → 13/5)

| Day | Lane | Task | Owner | Effort |
|---|---|---|---|---|
| 8-9 | UI/Design | UI placeholder Login screen | FE-1 | M |
| 8-9 | UI/Design | UI placeholder Signup 5-screen flow | FE-2 | L |
| 10 | UI/Design | UI placeholder Profile screen scaffold | FE-1 | S |
| 10 | UI/Design | UI placeholder Home placeholder + AuthGate | FE-2 | S |
| 11-12 | All | Widget tests + integration test login flow | FE-bridge + FS | M |
| 12 | All | M1 demo prep (run through scenario, fix critical bug) | All | S |
| 13 | All | M1 demo + retro (giảng viên review) | All | — |

## Demo M1 (13/5)

**Story 5 phút:**
1. Open app → Trang giới thiệu
2. Tap "Tạo tài khoản mới" → Signup flow 5 screens
3. Submit username → Profile screen với avatar default + username
4. Logout → Trang giới thiệu
5. Login lại → Profile

**Backup nếu signup fail demo:** Show pre-recorded video + commit history giải thích.

## Velocity tracking M1

End of M1 retro:
- [ ] Đo task done / task planned
- [ ] Compare estimate vs actual
- [ ] Decide unlock Tier 1 cho M2 (nếu boost ≥1.5x)
- [ ] Update memory `mvp-tier-priority` với learnings

Milestone report: `docs/milestones/M1-foundation-auth.md`.

---

# M2 — Social Core (14/5 → 27/5)

> 14 ngày. Sprint 2.

## Mục tiêu

End of M2: 4 dev kết bạn nhau + gửi ảnh cho nhau + xem feed + có Profile full với grid posts.

## Deliverables (must ship)

### 1. Friends (Tier 0 #2) ✅
- Invite by username + share-link
- Accept/decline incoming requests
- Friend list real-time
- `friend_requests` + `friendships` Firestore schema + rules
- `onFriendRequestAccepted` Cloud Function

### 2. Camera basic (Tier 0 #3) ✅
- `camera` Flutter package wire
- Capture + flip + album picker + caption text
- Spike: test trên 3 thiết bị Android khác nhau

### 3. Share photo (Tier 0 #4) ✅
- Upload Storage + post metadata Firestore
- `onPostCreated` Cloud Function (resize + fan-out + push trigger)
- `posts` schema + Storage rules

### 4. Feed (Tier 0 #5) ✅
- Vertical list từ `users/{uid}/feed_items`
- Pull-to-refresh + infinite scroll pagination
- Cache với `cached_network_image`
- 4 trạng thái loading/error/empty/data

### 5. Profile screen full (Tier 0+ #12) ✅
- Avatar + Username + Bio + Stats + Grid posts
- View own profile + view friend profile

### 6. M3 prep (Pre-build foundation) 🔧
Cuối M2 (day 13-14):
- Tạo `features/diary/`, `features/space/`, `features/rollcall/` skeleton (data layer + Firestore schema scaffold)
- KHÔNG UI yet — UI vào M3
- → Move 3-5 days work từ M3 lên M2 → giảm M3 overflow risk

## Acceptance criteria

- [ ] User invite bạn qua username, recipient nhận push + accept/decline
- [ ] User chụp ảnh + upload thành công trong <5s (4G)
- [ ] Recipient nhận push + thấy ảnh trên feed trong <15s
- [ ] EXIF location bị strip (verify metadata)
- [ ] Feed load 20 photos đầu trong <3s
- [ ] Pull-to-refresh + scroll pagination hoạt động
- [ ] Profile own load avatar + username + bio + grid posts đúng
- [ ] View friend profile chỉ hiện posts đã share with current user
- [ ] 4 dev đã friend nhau + chia sẻ ảnh thành công

## Sprint breakdown M2

### Tuần 1 (14/5 → 20/5)

| Day | Lane | Task | Owner | Effort |
|---|---|---|---|---|
| 1-2 | BE/Native | Friends data layer (`friend_requests`, `friendships` schema + rules + tests) | FS-1 | M |
| 1-2 | BE/Native | `onFriendRequestAccepted` Cloud Function + tests | FS-2 | M |
| 3-5 | BE/Native | Camera spike + Camera basic data layer (gallery picker integration) | FS-1 | L |
| 3-5 | BE/Native | Share photo data layer (Storage upload + post metadata) | FS-2 | L |
| 1-3 | UI/Design | Friends screens (invite, list, accept/decline UI) | FE-1 | L |
| 4-5 | UI/Design | Camera home screen UI (Trang chủ + viewfinder + capture button + bottom nav) | FE-2 | L |

### Tuần 2 (21/5 → 27/5)

| Day | Lane | Task | Owner | Effort |
|---|---|---|---|---|
| 6-7 | BE/Native | `onPostCreated` Cloud Function (resize + fan-out + push trigger) | FS-1 | L |
| 6-7 | BE/Native | Feed data layer (paginate `feed_items`) | FS-2 | M |
| 8-9 | UI/Design | Preview ảnh + send screen (Xem trước ảnh chụp) | FE-1 | M |
| 8-9 | UI/Design | Feed screen (vertical list + states) | FE-2 | L |
| 10-11 | UI/Design | Profile screen full (header + grid + tabs) | FE-1 | M |
| 10-12 | BE/Native | M3 prep: skeleton diary + space + rollcall data layer | FS-1 + FS-2 | M |
| 12-13 | All | Tests integration + bug fix | All | — |
| 13 | All | M2 demo prep | All | — |
| 14 | All | M2 demo + retro | All | — |

## Demo M2 (27/5)

**Story 8 phút:**
1. Aldo invite Beatrice qua username
2. Beatrice accept → cả 2 thành bạn
3. Aldo chụp ảnh + caption "Cuối tuần ☕" → send to Beatrice
4. Beatrice nhận push trên screen → mở app
5. Beatrice swipe sang Feed → xem ảnh
6. Aldo mở Profile của mình → grid hiện ảnh vừa post
7. Aldo mở Profile của Beatrice → empty grid (chưa post)

## Velocity tracking M2

End of M2 retro:
- Decide unlock thêm Tier 1 cho M3
- M3 lock scope: chỉ Tier 0 + 0+ (firm) + Tier 1 nếu unlock

Milestone report: `docs/milestones/M2-social-core.md`.

---

# M3 — Differentiator + Polish + Demo (28/5 → 9/6)

> 12 ngày (NGẮN HƠN 2 ngày so M1/M2). Sprint 3.

## Mục tiêu

End of M3: Demo M3 story Aldo+Beatrice+Charlie chạy mượt trước giảng viên. Tier 0 + 0+ tất cả ship.

## Deliverables (must ship)

### 1. Push notification (Tier 0 #6) ✅
- FCM Android setup + token storage
- Notification types: `new_photo`, `new_reaction`, `rollcall_weekly`, `widget_update`
- Deep link mở đúng ảnh/post

### 2. Reaction (Tier 0 #7) ✅
- React emoji single trên photo
- `onReactionCreated` Cloud Function (count + push)

### 3. Widget Android (Tier 0 #8) 🔧 native Kotlin
- AppWidget scaffold (size 2x2 + 4x4)
- `home_widget` Flutter plugin wire
- FCM data message → widget refresh
- Tap widget → deep link

### 4. Diary basic (Tier 0+ #9) ✅
- Tab Nhật ký với list + create/edit/delete entry
- Privacy private/public toggle
- Public diary hiện trên Profile tab Memory

### 5. Space basic (Tier 0+ #10) ✅
- Create space + invite members
- Send photo to space + space feed filter
- Members list + leave space

### 6. RollCall basic (Tier 0+ #11) ✅
- `rollcallScheduler` cron Cloud Function (Sunday 8pm)
- Special post screen (album picker filter 7 days)
- Multi-emoji react

### 7. Polish + Demo prep ✅
- Bug fix critical from M2
- Loading/error/empty states across all screens
- Re-skin với design tokens (FE-bridge)
- Demo rehearsal 3+ lần
- Backup video record

## Acceptance criteria

- [ ] FCM push delivery <10s từ trigger
- [ ] React emoji → author push trong <10s
- [ ] Widget hiển thị ảnh mới nhất + update sau push <30s
- [ ] Tap widget → app mở đúng ảnh
- [ ] Diary entry tạo/edit/delete đúng
- [ ] Space gửi photo, chỉ members nhận, ngoài space không thấy
- [ ] RollCall trigger Sunday 8pm → all active users nhận push
- [ ] Multi-react RollCall: user thả 3 emoji → đếm 3
- [ ] Demo M3 story Aldo+Beatrice+Charlie chạy mượt 11 steps
- [ ] App stable, crash rate <2%

## Sprint breakdown M3

### Tuần 1 (28/5 → 3/6)

| Day | Lane | Task | Owner | Effort |
|---|---|---|---|---|
| 1-2 | BE/Native | FCM setup + token storage + push notification handler | FS-1 | M |
| 1-2 | BE/Native | Reaction Cloud Function + push trigger | FS-2 | M |
| 3-5 | BE/Native | Widget Android Kotlin (AppWidgetProvider + layout + FCM trigger) | FS-1 | L |
| 3-5 | BE/Native | Diary data layer + Cloud Functions (resize attached images) | FS-2 | M |
| 1-3 | UI/Design | Reaction UI (emoji bar + counter) | FE-1 | M |
| 4-5 | UI/Design | Diary screens (list + create + edit) | FE-2 | M |

### Tuần 2 (4/6 → 9/6)

| Day | Lane | Task | Owner | Effort |
|---|---|---|---|---|
| 6-7 | BE/Native | Space data layer + `onSpaceCreated` + photo broadcasting logic | FS-1 | M |
| 6-7 | BE/Native | RollCall scheduler + special post backend logic | FS-2 | M |
| 6-7 | UI/Design | Space screens (create + members + filter feed dropdown) | FE-1 | M |
| 8 | UI/Design | RollCall special post screen + multi-react UI | FE-2 | M |
| 8-9 | UI/Design | Re-skin theme tokens (Figma colors → Material 3) | FE-1 + FE-2 | M |
| 9-10 | All | Bug fix critical + polish | All | — |
| 10-11 | All | Demo rehearsal 3x + record backup video | All | — |
| 12 | All | M3 demo + retro (final capstone presentation) | All | — |

## Demo M3 (9/6) — capstone final

**Story 15 phút:** Aldo + Beatrice + Charlie. Xem [`demo-script.md`](demo-script.md).

**Demo deliverable cho giảng viên:**
- Live demo working
- Walk through GitHub commits highlight (5-10 PRs ấn tượng)
- Q&A
- Documentation review (`docs/`, ADR, milestones reports)

## Velocity tracking M3

End of M3 retro:
- Decide nếu unlock được Tier 1 (chỉ nếu Tier 0+0+ ship sớm 2-3 ngày)
- Capstone deliverable cuối: milestone report tổng hợp + SRS compiled

Milestone report: `docs/milestones/M3-differentiator-demo.md` + final report.

---

## M3 risk overflow alert ⚠️

M3 12 ngày × 4 dev × 0.7 = 33 dev-days budget. Tasks raw: ~49 dev-days.

### Mitigation chính

1. **Pre-build M2 cuối (day 13-14):** Move 3-5 days skeleton diary/space/rollcall lên M2 → M3 chỉ implement.
2. **Cut Tier 1 hoàn toàn nếu velocity <1.5x:** M3 chỉ Tier 0 + 0+.
3. **Streamline differentiator nếu cần:**
   - Diary: chỉ create + list + view (skip edit/delete cycle 1)
   - Space: chỉ create + send (skip invite friends list — manual add by username)
   - RollCall: chỉ multi-react UI (skip cron scheduler — manual trigger admin Cloud Function Console)
4. **Accept M3 dài hơn:** Nếu giảng viên cho phép, demo 12-15/6 thay vì 9/6.

## Liên quan

- **Risk register:** [`risks.md`](risks.md)
- **Demo script E2E:** [`demo-script.md`](demo-script.md)
- **Sprint conventions:** `docs/adr/0003-task-management-process.md`
- **Team workflow:** `docs/team-workflow.md`
- **Milestone reports template:** `docs/milestones/README.md`
