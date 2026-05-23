# TODO Index — Meep All Modules

> Mỗi module có todo file riêng. File này là index + sprint tracking.

---

## Leader tasks (ThienPDM — ongoing)

- [ ] **TX1** — Merge contract artifacts từng module vào `develop` (theo dependency order bên dưới) trước khi giao dev
- [ ] **TX2** — Viết `firestore.rules` cuối cùng: merge tất cả helper functions + match blocks từ 12 specs
- [ ] **TX3** — Update `app_router.dart` với tất cả routes từ 12 modules
- [ ] **TX4** — Update `pubspec.yaml`: thêm packages (share_plus, camera, flutter_image_compress, gal, geolocator, cached_network_image, http, intl, image_picker, firebase_messaging, flutter_local_notifications, emoji_picker_flutter, flutter_svg, shared_preferences); confirm workmanager

---

## Leader todos (ThienPDM — làm TRƯỚC khi giao dev)

| Task | Todo | Mô tả |
|------|------|-------|
| Leader plan | [todo-leader.md](todo-leader.md) | Contract creation + shared infrastructure (LX0–LX12 + LX-RULES + LX-PUBSPEC) |

---

## Module todos (theo dependency order)

| # | Module | Todo | Tier | Milestone | Blocked by |
|---|--------|------|------|-----------|-----------|
| 1 | Auth | [todo-auth.md](todo-auth.md) | T0 | M1 | — |
| 2 | Friend | [todo-friend.md](todo-friend.md) | T0 | M2 | Auth |
| 3 | Settings | [todo-settings.md](todo-settings.md) | T0 | M2/M3 | Auth, Friend |
| 4 | Chat | [todo-chat.md](todo-chat.md) | T1/T0+ | M3 | Friend, Settings |
| 5 | Home/Camera/Feed | [todo-home-camera-feed.md](todo-home-camera-feed.md) | T0 | M2 | Friend, Settings |
| 6 | Notification | [todo-notification.md](todo-notification.md) | T0 | M3 | Feed, Friend |
| 7 | Reaction | [todo-reaction.md](todo-reaction.md) | T0 | M3 | Feed |
| 8 | Diary | [todo-diary.md](todo-diary.md) | T0+ | M3 | Auth |
| 9 | Profile | [todo-profile.md](todo-profile.md) | T0+ | M2 | Auth, Friend, Diary |
| 10 | Space | [todo-space.md](todo-space.md) | T0+ | M3 | Friend, Feed |
| 11 | Widget Android | [todo-widget-android.md](todo-widget-android.md) | T0 | M3 | Feed, Auth |
| 12 | Streak | [todo-streak.md](todo-streak.md) | T1 | Post-M3 | Feed |

---

## Global task numbering (tham khảo)

Dùng khi cần cross-reference giữa modules:

| Global range | Module | Local tasks |
|---|---|---|
| T1–T11 | Auth | A/T1–T11 |
| T12–T18 | Friend | F/T1–T7 |
| T19–T26 | Settings | SE/T1–T8 |
| T27–T33 | Chat | C/T1–T7 |
| T34–T44 | Feed/Camera | FE/T1–T11 |
| T45–T52 | Notification | N/T1–T8 |
| T53–T57 | Reaction | R/T1–T5 |
| T58–T65 | Diary | D/T1–T8 |
| T66–T74 | Profile | P/T1–T9 |
| T75–T85b | Space | SP/T1–T10b, T11 |
| T86–T91 | Widget | W/T1–T6 |
| T92–T95 | Streak | ST/T1–T4 |
