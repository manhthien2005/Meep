# /figma-to-flutter — Figma → Flutter Widget

> Solo-dev model: HanDHG + NganTNK kiêm Figma + module owner. Skill này guide chuyển 1 Figma node → 1 Flutter widget **clean, không drift design token**.

## Core principle

**3-round iteration:** Extract → Verify → Refine. Không pixel-perfect 1 lần.

## Scope (strict)

- ✅ 1 Figma frame = 1 widget Flutter class.
- ✅ Compose nhiều widget nhỏ thành page ở PR riêng sau.
- ❌ KHÔNG generate `MaterialApp`, route config, navigation logic.
- ❌ KHÔNG generate Riverpod controller / business logic — chỉ `presentation/`.

## Design token gate — STRICT

**Color / font / spacing / radius không có trong `core/theme/` → STOP.** Không inline hex, không hardcode font size.

Quy trình unblock:
1. Liệt kê token thiếu.
2. Module owner ping leader: "Cần thêm token X vào `core/theme/`".
3. Leader merge token vào `develop` qua PR riêng (chore branch).
4. Pull develop → resume.

Lý do: `core/theme/` là shared code — 1 dev tự thêm = drift design system.

## Pre-flight

- [ ] Đang trên feature branch (KHÔNG develop/deploy).
- [ ] Read `apps/mobile/lib/core/theme/`: `color_scheme.dart`, `text_theme.dart`, `spacing.dart`, `radii.dart`.
- [ ] User đã attach: **Figma node URL** + **PNG @2x hoặc SVG** (không dùng @1x / JPG).

## Phase 1 — Extract (dual source)

### 1.1 MCP extract (nếu Figma MCP active)

```
mcp.call("figma_get_node", { nodeId: "<id>", url: "<paste URL>" })
```

Output cần: layer tree, Auto-Layout config, color values (hex), text styles, constraints, variants.

### 1.2 Image "look at"

Đọc PNG/SVG attached để catch visual intent và lỗi MCP (layer ẩn, overlay missing).

### 1.3 Cross-check

MCP 5 children → image phải thấy 5 phần tử. Nếu lệch → STOP, báo user.

## Phase 2 — Map (strict table)

### Layout

| Figma | Flutter |
|---|---|
| Auto-Layout vertical | `Column` |
| Auto-Layout horizontal | `Row` |
| Stack (overlap) | `Stack` + `Positioned` |
| Auto-Layout padding | `Padding(padding: EdgeInsets.all(Spacing.md))` |
| Item spacing | `SizedBox` token hoặc `Column(spacing: Spacing.sm)` (Flutter 3.27+) |
| Constraint Stretch | `Expanded` |
| Constraint Fixed (W,H) | `SizedBox(width: X, height: Y)` |
| Constraint Hug | default (no wrapper) |

### Color

| Figma | Flutter |
|---|---|
| Hex `#1A73E8` | Tra `core/theme/color_scheme.dart` → `Theme.of(context).colorScheme.primary` |
| Token thiếu | **STOP** — ping leader |

### Typography

| Figma | Flutter |
|---|---|
| Style "Headline/Large" | `Theme.of(context).textTheme.headlineLarge` |
| Custom font size không match style | **STOP** — designer adjust Figma trước |

### Spacing & Radius

| Figma | Flutter |
|---|---|
| 4/8/16/24/32px | `Spacing.xs/sm/md/lg/xl` |
| Border radius | `Radii.xs/sm/md/lg` |
| Value không match scale | **STOP** — propose round, ping leader |

### Component variants

| Figma | Flutter |
|---|---|
| Variant "primary/secondary/ghost" | Factory: `Button.primary()`, `Button.secondary()` |
| Variant "size: sm/md/lg" | Enum: `Button.primary(size: ButtonSize.lg)` |

## Phase 3 — Validate before generate

Print summary trước khi generate:

```
Figma node: <name>
File: <feature>/presentation/widgets/<widget_name>.dart
Layout: Column / Row / Stack
Children: <count>

Tokens used:    ✅ colorScheme.primary, textTheme.headlineLarge, Spacing.md
Tokens MISSING: ❌ colorScheme.tertiary (hex #FF6B35) — STOP, ping leader

Proceed? (yes / wait for tokens)
```

## Phase 4 — Generate widget code

File: `apps/mobile/lib/features/<my-module>/presentation/widgets/<widget_name>.dart`

Naming: Figma layer `btn_primary_lg` → class `PrimaryButtonLarge`, file `primary_button_large.dart`.

```dart
import 'package:flutter/material.dart';

class <WidgetName> extends StatelessWidget {
  const <WidgetName>({super.key, /* required params */});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = theme.textTheme;

    return <root layout>;
  }
}
```

Rules:
- `const` constructors mandatory.
- KHÔNG `ref.watch(provider)` trong widget — consume via callback/parameter.
- KHÔNG async method — pass `VoidCallback onTap`.

### Component with variants — factory pattern

```dart
class MeepButton extends StatelessWidget {
  const MeepButton._({required this.label, required this.onPressed, required this._variant});

  factory MeepButton.primary({required String label, required VoidCallback onPressed}) =>
      MeepButton._(label: label, onPressed: onPressed, _variant: _Variant.primary);

  factory MeepButton.secondary({...}) => ...;

  final String label;
  final VoidCallback onPressed;
  final _Variant _variant;
}
enum _Variant { primary, secondary, ghost }
```

## Phase 5 — Generate widget test (mandatory)

File: `apps/mobile/test/features/<my-module>/presentation/widgets/<widget_name>_test.dart`

```dart
void main() {
  group('<WidgetName>', () {
    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: <WidgetName>(/* params */))),
      );
      expect(find.byType(<WidgetName>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('finds expected text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: <WidgetName>(...))),
      );
      expect(find.text('<expected text>'), findsOneWidget);
    });
  });
}
```

Mandatory test cases:
- [ ] Renders without throwing.
- [ ] No layout overflow.
- [ ] Critical text/buttons findable.
- [ ] Tap callbacks invoke (if interactive).

## Phase 6 — Verify (3-round iteration)

### Round 1 — Automated

```bash
flutter test test/features/<my-module>/presentation/widgets/<widget_name>_test.dart
flutter analyze
dart format --set-exit-if-changed lib/features/<my-module>/presentation/widgets/<widget_name>.dart
```

### Round 2 — Visual diff

User renders on emulator, screenshots Flutter widget + attaches alongside Figma image. Compare:

| Element | Figma | Flutter | Match? |
|---|---|---|---|
| Layout direction | Column | Column | ✅ |
| Title font | textTheme.headlineLarge | textTheme.titleLarge | ❌ |

Agent fixes specific items, NOT rewrite full widget.

### Round 3 — Refine

After Round 2 fixes, repeat Round 1 + Round 2.

> 3 rounds vẫn lệch → STOP. Designer review Figma — không ép code match Figma sai.

## Anti-patterns

| Anti-pattern | Vấn đề |
|---|---|
| Inline hex `Color(0xFF1A73E8)` | Drift design system, dark mode vỡ |
| Hardcode `TextStyle(fontSize: 16)` | Bypass textTheme → inconsistent |
| Generate full screen 1 lần | Risk lệch cao, khó review |
| Generate widget + Riverpod controller cùng PR | Mix concerns |
| Auto-add token vào `core/theme` tự động | `core/` là shared code, cần leader gate |
| Skip widget test | Presentation layer test is mandatory |
