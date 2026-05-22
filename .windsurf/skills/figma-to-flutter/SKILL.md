---
name: figma-to-flutter
description: Convert Figma frame/node → Flutter widget với strict design token mapping + dual-source verification (MCP data + PNG image). Use when user pastes a Figma node URL or attaches a Figma screenshot and asks to generate a Flutter widget. Scope: 1 frame = 1 widget (compose multiple widgets sau). Strict gate: KHÔNG inline hex/font — token thiếu → ping leader.
---

# Figma → Flutter Widget — Strict Mapping Skill

> Solo-dev model: HanDHG + NganTNK kiêm Figma + module owner. Skill này guide họ (và mọi dev khác đụng UI) chuyển 1 Figma node → 1 Flutter widget **clean, không drift design token**.

## Core principle

**KHÔNG có Figma → Flutter pixel-perfect.** Mỗi Figma node convert qua 3 round:
1. Extract (MCP + image cross-check) → widget v1.
2. Verify (test + visual diff) → list lệch điểm.
3. Refine (specific fix) → widget final.

Sau 3 round vẫn lệch → designer review Figma (overflow / missing constraint).

## Scope (strict)

- ✅ **1 frame Figma = 1 widget Flutter class.** Không attempt full screen 1 lần.
- ✅ **Compose nhiều widget nhỏ thành page** ở 1 PR riêng, sau khi từng widget đã merge.
- ❌ KHÔNG generate `MaterialApp`, route config, navigation logic — đây là responsibility của leader (`core/router/`).
- ❌ KHÔNG generate Riverpod controller / business logic — chỉ presentation layer.

## Strict gate — Design token

**Color / font / spacing / radius KHÔNG có trong `core/theme/` → STOP.** KHÔNG inline hex, KHÔNG hardcode font size. Quy trình unblock:

1. Skill liệt kê token thiếu trong output.
2. Module owner ping leader: "Cần thêm token X vào `core/theme/`".
3. Leader đánh giá → nếu OK → merge token vào `develop` qua PR riêng (chore branch).
4. Module owner pull develop → resume widget generation.

Lý do strict: `core/theme/` là shared code (rule 25 §Cross-module touch). 1 dev tự thêm token = drift design system.

## Pre-flight

Trước khi extract:

- [ ] Verify Figma MCP active (`figma-mcp-go` trong `.windsurf/mcp_config.example.json`).
- [ ] Verify đang trên feature branch `feature/<DevName>/<short-desc>` (KHÔNG develop/deploy).
- [ ] Read `core/theme/`:
  - `core/theme/color_scheme.dart` — color tokens
  - `core/theme/text_theme.dart` — typography tokens
  - `core/theme/spacing.dart` — spacing tokens
  - `core/theme/radii.dart` — border radius tokens
- [ ] User đã attach 2 nguồn:
  1. **Figma node URL** (cho MCP extract).
  2. **PNG @2x hoặc SVG** của node (cho agent "nhìn"). PNG @1x quá nhỏ, JPG có compression artifacts → KHÔNG dùng.

## Phase 1 — Extract (dual source)

### 1.1. MCP extract (số liệu)

```
mcp.call("figma_get_node", { nodeId: "<id>", url: "<paste URL>" })
```

Output expected:
- Layer tree (frame → child → child).
- Auto-Layout config (direction, spacing, padding, alignment).
- Color values (hex format).
- Text styles (font family, size, weight, line height).
- Constraints (stretch / fixed / hug).
- Component variants nếu có.

### 1.2. Image "look at" (intent)

Agent đọc PNG/SVG attached:
- Visual layout intent (whitespace, alignment "feel").
- Catch lỗi MCP (layer ẩn, overlay missing).
- Confirm component hierarchy match MCP tree.

### 1.3. Cross-check

- MCP nói có 5 children → image phải thấy 5 phần tử.
- MCP nói color `#1A73E8` → image phải xuất hiện màu xanh đó ở vị trí khớp.
- **Nếu lệch → STOP**, báo user: "MCP data và image không khớp — Figma có overlay ẩn hoặc layer hidden?"

## Phase 2 — Map (strict rules table)

Bảng quy đổi cố định. Agent KHÔNG tự đoán. Có rule → follow. Không có → STOP.

### Layout

| Figma | Flutter |
|---|---|
| Frame Auto-Layout vertical | `Column` |
| Frame Auto-Layout horizontal | `Row` |
| Stack (overlap) | `Stack` + `Positioned` |
| Auto-Layout padding | `Padding(padding: EdgeInsets.all(Spacing.md))` |
| Item spacing | `SizedBox(height: Spacing.sm)` between children, hoặc `Column(spacing: Spacing.sm)` (Flutter 3.27+) |
| Constraint Stretch | `Expanded` |
| Constraint Fixed (W,H) | `SizedBox(width: X, height: Y)` |
| Constraint Hug | default (no wrapper) |

### Color

| Figma | Flutter |
|---|---|
| Hex `#1A73E8` | **Tra `core/theme/color_scheme.dart`** → `Theme.of(context).colorScheme.primary` (hoặc token đúng tên) |
| Token thiếu | **STOP** — ping leader thêm token |

### Typography

| Figma | Flutter |
|---|---|
| Style "Headline/Large" | `Theme.of(context).textTheme.headlineLarge` |
| Custom font size không match style | **STOP** — Figma có style chưa? Nếu chưa → designer adjust Figma trước |

### Spacing & Radius

| Figma | Flutter |
|---|---|
| Spacing 4/8/16/24/32px | `Spacing.xs/sm/md/lg/xl` token |
| Border radius 4/8/12/16px | `Radii.xs/sm/md/lg` token |
| Value không match scale | **STOP** — propose round to nearest token, ping leader |

### Component variants

| Figma | Flutter |
|---|---|
| Component variant "primary/secondary/ghost" | Factory constructor: `Button.primary()`, `Button.secondary()`, `Button.ghost()` |
| Component variant "size: sm/md/lg" | Enum + named constructor: `Button.primary(size: ButtonSize.lg)` |

## Phase 3 — Validate before generate

Trước khi generate code, agent print summary:

```
Figma node: <name>
File: <feature>/presentation/widgets/<widget_name>.dart
Layout: Column / Row / Stack
Children: <count>

Tokens used:
  ✅ colorScheme.primary
  ✅ textTheme.headlineLarge
  ✅ Spacing.md, Spacing.sm
  ✅ Radii.md

Tokens MISSING (must add to core/theme first):
  ❌ <none> — proceed
  
  HOẶC
  
  ❌ colorScheme.tertiary (hex #FF6B35) — STOP, ping leader
  ❌ textTheme.labelXLarge (custom 20px bold) — STOP, ping leader

Proceed? (yes / wait for tokens)
```

Nếu có MISSING → KHÔNG continue Phase 4. Output instructions cho user ping leader.

## Phase 4 — Generate widget code

### File location

`apps/mobile/lib/features/<my-module>/presentation/widgets/<widget_name>.dart`

Naming rule:
- Figma layer name `btn_primary_lg` → class `PrimaryButtonLarge`, file `primary_button_large.dart`.
- snake_case file, UpperCamelCase class.

### Widget template

```dart
import 'package:flutter/material.dart';

/// <Brief description from Figma layer comment>
///
/// Generated from Figma node: <node-name>
/// Module: <module-name>
class <WidgetName> extends StatelessWidget {
  const <WidgetName>({
    super.key,
    // required params
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = theme.textTheme;

    return <root layout>;
  }
}
```

### Const constructors mandatory

Mọi widget tĩnh → `const` constructor. Linter check sẽ catch nếu miss.

### No business logic

- KHÔNG `ref.watch(provider)` trong widget — consume controller có sẵn qua callback hoặc parameter.
- KHÔNG `async` method trong widget — pass callback `VoidCallback onTap`.
- KHÔNG hardcoded text strings — hoặc pass via param, hoặc dùng `AppLocalizations` (nếu i18n đã setup).

### Component with variants — factory pattern

```dart
class MeepButton extends StatelessWidget {
  const MeepButton._({
    required this.label,
    required this.onPressed,
    required this._variant,
  });

  factory MeepButton.primary({
    required String label,
    required VoidCallback onPressed,
  }) =>
      MeepButton._(label: label, onPressed: onPressed, _variant: _Variant.primary);

  factory MeepButton.secondary({...}) => ...;

  final String label;
  final VoidCallback onPressed;
  final _Variant _variant;

  @override
  Widget build(BuildContext context) {...}
}

enum _Variant { primary, secondary, ghost }
```

## Phase 5 — Generate widget test (mandatory)

Test file: `apps/mobile/test/features/<my-module>/presentation/widgets/<widget_name>_test.dart`

### Test template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/<my-module>/presentation/widgets/<widget_name>.dart';

void main() {
  group('<WidgetName>', () {
    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: <WidgetName>(/* test params */),
          ),
        ),
      );
      expect(find.byType(<WidgetName>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('finds expected text/elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: <WidgetName>(...))),
      );
      expect(find.text('<expected text from Figma>'), findsOneWidget);
    });

    testWidgets('respects design tokens (no hardcoded colors)', (tester) async {
      // Verify widget uses Theme.of(context) — not hex literals.
      // Spot check via finder: widget with key X has colorScheme.primary background.
    });
  });
}
```

### Mandatory test cases per widget

- [ ] Renders without throwing.
- [ ] No layout overflow (RenderFlex error).
- [ ] Critical text/buttons findable.
- [ ] Tap callbacks invoke (if interactive).

Optional (for component widget):
- [ ] Variant rendering (primary/secondary).
- [ ] Disabled state.
- [ ] Loading state.

## Phase 6 — Verify (3-round iteration)

### Round 1 — Automated check

```bash
flutter test test/features/<my-module>/presentation/widgets/<widget_name>_test.dart
flutter analyze
dart format --set-exit-if-changed lib/features/<my-module>/presentation/widgets/<widget_name>.dart
```

Tất cả pass → Round 2. Fail → fix lỗi cụ thể, repeat Round 1.

### Round 2 — Visual diff (manual)

User render trên emulator + so sánh:

```bash
cd apps/mobile
flutter run -d android
```

User chụp screenshot Flutter widget → attach lại vào chat cùng Figma image. Agent compare:

| Element | Figma | Flutter | Match? |
|---|---|---|---|
| Layout direction | Column | Column | ✅ |
| Primary button color | colorScheme.primary | colorScheme.primary | ✅ |
| Vertical spacing | Spacing.md (16px) | Spacing.md | ✅ |
| Title font | textTheme.headlineLarge | textTheme.titleLarge | ❌ MISMATCH |

Output diff list cho user. Agent fix specific items, KHÔNG rewrite full widget.

### Round 3 — Refine

Sau Round 2 fix, repeat Round 1 + Round 2. Nếu vẫn lệch:

- < 3 round: agent fix tiếp.
- = 3 round vẫn lệch: STOP. Designer review Figma xem có overflow / missing constraint / sai style không. KHÔNG ép code match Figma sai.

## Output format

Sau khi skill chạy xong, output structured:

```markdown
## Figma → Flutter: <WidgetName>

### Files generated
- `apps/mobile/lib/features/<m>/presentation/widgets/<w>.dart` (XX lines)
- `apps/mobile/test/features/<m>/presentation/widgets/<w>_test.dart` (XX lines)

### Tokens used
- colorScheme.primary, textTheme.headlineLarge, Spacing.md, Radii.md

### Tokens MISSING (PR riêng cần thiết)
- <none — proceed>
  HOẶC
- ❌ colorScheme.tertiary (hex #FF6B35) — leader chưa thêm. Wait.

### Verification
- ✅ flutter test passed (3/3)
- ✅ flutter analyze clean
- ✅ Round 1 automated done
- ⏸ Round 2 visual diff — user chụp screenshot trên emulator + attach

### Next steps
1. `flutter run -d android` → render widget
2. Screenshot widget Flutter
3. Attach + ping agent: "compare với Figma"
```

## Anti-patterns

| Anti-pattern | Vấn đề |
|---|---|
| Inline hex `Color(0xFF1A73E8)` vì `core/theme` chưa có token | Drift design system, dark mode vỡ |
| Hardcode `TextStyle(fontSize: 16)` | Bypass textTheme → inconsistent |
| Generate full screen 1 lần | Risk lệch cao, khó review |
| Generate widget + Riverpod controller cùng PR | Mix concerns, vi phạm solo-dev contract |
| Force code match Figma sai (overflow, missing constraint) | Designer phải fix Figma trước, không ép code |
| Skip widget test | Solo-dev model: presentation layer test là mandatory |
| Auto-add token vào `core/theme` tự động | `core/` là shared code, cần leader gate |
| Skip image, chỉ dùng MCP | Miss visual intent, layer ẩn không catch |
| Generate vượt scope (vd touch `data/` hoặc `application/`) | Skill chỉ generate `presentation/` |

## Quick reference card

```
Trigger: user paste Figma node URL + image PNG/SVG @2x

Pre-flight:
  [ ] MCP active (figma-mcp-go)
  [ ] Feature branch
  [ ] Read core/theme/* tokens
  [ ] Image quality check (PNG @2x hoặc SVG)

Phase 1 Extract:
  - MCP figma_get_node → layer tree + values
  - "Look at" image → layout intent
  - Cross-check, STOP nếu lệch

Phase 2 Map:
  - Strict table (layout / color / typography / spacing / radius / variants)
  - Token thiếu → STOP

Phase 3 Validate:
  - Print summary tokens used + missing
  - Wait approval nếu missing

Phase 4 Generate:
  - Widget class theo Figma layer naming
  - Const constructor mandatory
  - No business logic

Phase 5 Test:
  - Widget test mandatory (renders, no overflow, find elements)
  - Variant test nếu có

Phase 6 Verify:
  - Round 1: flutter test + analyze + format
  - Round 2: user screenshot + visual diff
  - Round 3: refine specific items
  - >3 round lệch → escalate designer
```

## Related skills/rules

- `24-flutter-ui-patterns.md` (rule, glob-scoped) — design token rules + accessibility checklist khi edit `presentation/`.
- `25-dev-code-standards.md` (rule, alwaysApply) — cross-module gate + shared code rule.
- `flutter-firebase-patterns` (skill) — Riverpod + Firestore patterns (consume từ widget).
- `code-review-five-axis` (skill) — 5-axis review trước PR (bao gồm no-hardcoded-color check).
