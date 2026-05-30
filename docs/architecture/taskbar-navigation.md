# AppTaskbar — Navigation Contract

> Shared widget: [apps/mobile/lib/shared/widgets/app_taskbar.dart](../../apps/mobile/lib/shared/widgets/app_taskbar.dart)
> Đối tượng: mọi dev wire bottom navigation. Đọc trước khi dùng để không code sai mapping.

## Mục đích

`AppTaskbar` là bottom navigation dùng chung, 2 biến thể (`TaskbarVariant`):

- **`floating`** (mặc định): pill nổi, hug content, có active state (pill xám trượt theo tab đang chọn). Dùng cho các màn hình chính điều hướng giữa 5 tab.
- **`embedded`**: chìm full-width, có 2 nút phụ (grid trái / upload phải) nằm ngoài pill. **KHÔNG có active state** — ring + đĩa trắng cố định ở giữa (vị trí home), icon home bị ẩn. Dùng cho 1 màn hình cố định (vd camera/capture); khi điều hướng sang trang khác sẽ chuyển sang `floating`.

## Mapping tab → route

5 tab cố định theo thứ tự trái → phải. Route lấy từ [app_router.dart](../../apps/mobile/lib/core/router/app_router.dart):

| `TaskbarTab` | Label | Route | Lưu ý |
|---|---|---|---|
| `streak` | Kỷ niệm | `/streak` | |
| `diary` | Nhật ký | `/diary` | |
| `home` | Trang chủ | `/home` | |
| `chat` | Tin nhắn | `/inbox` | **KHÔNG phải `/chat`** — `/chat/:conversationId` là màn chat cụ thể |
| `profile` | Hồ sơ | `/profile` | Cần truyền `uid` user hiện tại qua `extra` |

Nút phụ embedded (không thuộc 5 tab, qua callback riêng):

| Nút | Label | Route gợi ý | Callback |
|---|---|---|---|
| Grid (leading) | Lưới ảnh | `/grid-view` | `onGridTap` |
| Upload (trailing) | Tải ảnh lên | (tùy luồng capture) | `onUploadTap` |

## Cách wire (floating)

Helper map tab → route — đặt ở nơi wire navigation, KHÔNG sửa trong widget:

```dart
String _routeFor(TaskbarTab tab) => switch (tab) {
      TaskbarTab.streak => '/streak',
      TaskbarTab.diary => '/diary',
      TaskbarTab.home => '/home',
      TaskbarTab.chat => '/inbox',
      TaskbarTab.profile => '/profile',
    };

TaskbarTab? _tabFor(String location) {
  if (location.startsWith('/streak')) return TaskbarTab.streak;
  if (location.startsWith('/diary')) return TaskbarTab.diary;
  if (location.startsWith('/home')) return TaskbarTab.home;
  if (location.startsWith('/inbox')) return TaskbarTab.chat;
  if (location.startsWith('/profile')) return TaskbarTab.profile;
  return null; // không tab nào active → ẩn pill
}
```

Dùng trong shell:

```dart
AppTaskbar(
  activeTab: _tabFor(GoRouterState.of(context).matchedLocation),
  chatBadgeCount: unreadCount, // từ provider chat
  onTabSelected: (tab) {
    if (tab == TaskbarTab.profile) {
      context.go('/profile', extra: currentUid); // profile cần uid
    } else {
      context.go(_routeFor(tab));
    }
  },
)
```

## Cách wire (embedded)

```dart
AppTaskbar(
  variant: TaskbarVariant.embedded,
  activeTab: TaskbarTab.home, // bị bỏ qua — embedded không có active state
  onTabSelected: (tab) => context.go(_routeFor(tab)),
  onGridTap: () => context.go('/grid-view'),
  onUploadTap: () => _startCapture(),
)
```

## Giới hạn cần biết

- **Embedded bỏ qua `activeTab`** — mọi icon luôn ở trạng thái inactive, ring giữa là tĩnh. Nếu cần highlight tab đang chọn, dùng `floating`.
- **Không tự navigate** — widget chỉ phát `onTabSelected`/`onGridTap`/`onUploadTap`. Việc điều hướng do caller quyết (giữ widget thuần presentation, đúng layering CLAUDE.md).
- **`chatBadgeCount`** chỉ hiện trên tab chat, `0` = ẩn. Badge là vòng turquoise có số.
- **Không có tab Space** trên taskbar. Module Space truy cập qua luồng khác (`/space/:spaceId`).

## Verify

```bash
flutter test test/shared/widgets/app_taskbar_test.dart
flutter analyze lib/shared/widgets
```
