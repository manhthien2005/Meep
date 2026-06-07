# Meep Adapter — flutter-fix-layout-issues

> Áp dụng official skill cho codebase Meep. Đọc sau `SKILL.md`.

## Meep-specific layout issues hay gặp

### 1. Camera capture preview
- `CameraPreview` widget cần `AspectRatio` wrap để không gây overflow ở phone notch / cutout.
- Overlay caption pill (≤ 30 chars per CLAUDE.md domain) trong `Stack` — tránh `Positioned.fill` để không overflow camera frame.

### 2. Feed grid (Locket-parity)
- `GridView.builder` 3-column trên 360dp width — item width = 120dp, đủ cho avatar (40) + caption (single line truncate).
- Caption text overflow: dùng `Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis)` — KHÔNG `Expanded` trong `Row` nếu không cần.

### 3. Bottom sheet form (share, settings, reaction)
- `app_bottom_sheet.dart` use `DraggableScrollableSheet` — cần `Builder` để có constraint trước khi nest `Column`.
- Form trong sheet: wrap `SingleChildScrollView` + `MediaQuery.viewInsets.bottom` để tránh keyboard cover input.

### 4. Hero animation cross-route (photo detail)
- `Hero` tag conflict khi 2 widget cùng tag trong tree đồng thời — dùng `postId` cho `tag` đảm bảo unique.

### 5. SafeArea + status bar
- `Scaffold` với background image (auth/onboarding) cần `SafeArea(top: false)` để image extend dưới status bar nhưng content trong safe area.

## Common error → Meep code mapping

| Error | Suspect file pattern |
|---|---|
| `Vertical viewport was given unbounded height` | `lib/features/*/presentation/**/list_*.dart` — ListView trong Column thiếu Expanded |
| `RenderFlex overflowed` (Row) | `lib/features/feed/presentation/post_*.dart` — caption Text không Expanded |
| `An InputDecorator cannot have an unbounded width` | `lib/shared/widgets/app_text_input.dart` usage trong Row thiếu Flexible |
| `RenderBox was not laid out` | Cascade — trace upward |

## Workflow (Meep)

1. Reproduce trên Android emulator (chính, không iOS).
2. Read exception trong `flutter run` output (NOT Crashlytics — local repro).
3. Identify root error theo SKILL.md guide.
4. Fix trong widget — KHÔNG sửa cross-module (solo-dev ADR-0004).
5. Hot reload via `mcp__dart__hot_reload` nếu Dart MCP đang connect.
6. Verify visually + write widget test catch regression (cite `dart-add-unit-test` adapter).

## Cite as authority

- `.claude/skills/flutter-fix-layout-issues/SKILL.md` (official patterns)
- `apps/mobile/CLAUDE.md` §Widget split thresholds (split nếu > 150 lines body)
