# /figma-to-flutter — Figma → Flutter Widget

> Solo-dev model: HanDHG + NganTNK kiêm Figma + module owner. Skill này guide chuyển 1 Figma node → 1 Flutter widget **clean, match codebase reality, không drift design token**.

## Core principle

**Iterative refinement.** Simple widget (button, text input) → 1-2 rounds. Complex visual (gradient beam, custom painter, multi-layer animation) → có thể 5+ rounds. Đừng ép pixel-perfect 1 lần, cũng đừng stop ép buộc sau 3 rounds.

**Compare with codebase first.** Trước khi generate widget mới, **đọc** `apps/mobile/lib/shared/widgets/` xem widget tương tự đã tồn tại chưa. Vd Figma có "primary button" → kiểm tra `app_primary_button.dart` đã có chưa, dùng/extend thay vì viết mới.

## Scope (strict)

- ✅ 1 Figma frame = 1 widget Flutter class.
- ✅ Extract sub-widget vào `presentation/widgets/` khi dùng ≥ 2 lần trong feature.
- ✅ Custom visual (gradient, beam, glass effect) → `CustomPainter` nếu SVG quá phức tạp.
- ❌ KHÔNG generate `MaterialApp`, route config, navigation logic.
- ❌ KHÔNG generate Riverpod controller / business logic — chỉ `presentation/`.
- ❌ KHÔNG duplicate widget đã có trong `shared/widgets/` — extend hoặc compose.

## Codebase reality — Meep design system

Meep KHÔNG dùng `Theme.of(context).colorScheme.primary` style đầy đủ Material 3. Codebase dùng **abstract final class tokens** trực tiếp:

```dart
import 'package:meep/core/theme/app_colors.dart';        // AppColors.bw900, turquoise300, error700
import 'package:meep/core/theme/app_text_styles.dart';   // AppTextStyles.mdBold, xlBold
import 'package:meep/core/theme/app_radii.dart';         // AppRadii.pill, circle
import 'package:meep/core/theme/app_spacing.dart';       // AppSpacing.md (nếu có)
```

**Reference files:**
- [`app_colors.dart`](../../apps/mobile/lib/core/theme/app_colors.dart) — turquoise / bw / success / error / warning / info palettes
- [`app_text_styles.dart`](../../apps/mobile/lib/core/theme/app_text_styles.dart) — xs/sm/md/lg/xl/xl2/xl3 với Regular/SemiBold/Bold variants
- [`app_radii.dart`](../../apps/mobile/lib/core/theme/app_radii.dart) — sm/md/circle/pill

`Theme.of(context)` chỉ dùng cho `colorScheme.surface`, `appBarTheme` ở `AppBarTheme` config — NOT cho widget styling.

## Design token gate — STRICT

**Color / font / spacing / radius không có trong `core/theme/` → STOP.** Không inline hex, không hardcode font size.

Quy trình unblock:
1. Liệt kê token thiếu (vd `#1A73E8` không match palette nào trong `app_colors.dart`).
2. Module owner ping leader: "Cần thêm token X vào `core/theme/`".
3. Leader merge token vào `develop` qua **chore branch** PR riêng.
4. Pull develop → resume.

Lý do: `core/theme/` là shared code — 1 dev tự thêm = drift design system.

## Pre-flight

- [ ] Đang trên feature branch `<type>/<DevName>/<short-desc>` (KHÔNG `develop`/`deploy`).
- [ ] Read các file theme: `app_colors.dart`, `app_text_styles.dart`, `app_radii.dart`.
- [ ] Read `shared/widgets/` — có widget similar đã tồn tại chưa?
- [ ] User đã attach: **Figma node URL** + **PNG @2x hoặc SVG** (không dùng @1x / JPG).

## Phase 1 — Extract (dual source)

### 1.1 MCP extract (nếu Figma MCP active)

```
mcp.call("figma_get_node", { nodeId: "<id>", url: "<paste URL>" })
```

Output cần: layer tree, Auto-Layout config, color values (hex), text styles, constraints, variants.

### 1.2 Image "look at"

Đọc PNG/SVG attached để catch visual intent và lỗi MCP (layer ẩn, overlay missing, gradient direction).

### 1.3 Cross-check

MCP 5 children → image phải thấy 5 phần tử. Nếu lệch → STOP, báo user.

## Phase 2 — Map (strict table)

### Layout

| Figma | Flutter |
|---|---|
| Auto-Layout vertical | `Column` |
| Auto-Layout horizontal | `Row` |
| Stack (overlap) | `Stack` + `Positioned` |
| Auto-Layout padding | `Padding(padding: EdgeInsets.all(...))` |
| Item spacing | `SizedBox(height/width: ...)` |
| Constraint Stretch | `Expanded` |
| Constraint Fixed (W,H) | `SizedBox(width: X, height: Y)` |
| Constraint Hug | default (no wrapper) |
| Safe-area aware | `SafeArea(child: ...)` |

### Color

| Figma | Flutter |
|---|---|
| Hex `#050F10` (bw900) | `AppColors.bw900` |
| Hex `#C7F7FB` (turquoise300) | `AppColors.turquoise300` |
| Hex `#FF3D00` (error700) | `AppColors.error700` |
| Token thiếu | **STOP** — ping leader |

Tra cứu palette trong `app_colors.dart`. KHÔNG dùng `Color(0xFF050F10)` inline.

### Typography

| Figma style | Flutter |
|---|---|
| `Nunito Bold 16 / line-height 22` | `AppTextStyles.mdBold` |
| `Nunito SemiBold 14 / line-height 18` | `AppTextStyles.smSemiBold` |
| `Nunito Bold 24 / line-height 30` | `AppTextStyles.xlBold` |
| Override color | `AppTextStyles.mdBold.copyWith(color: AppColors.bw100)` |
| Font size không match style | **STOP** — designer adjust Figma trước |

### Spacing & Radius

| Figma | Flutter |
|---|---|
| Border radius 30 (pill) | `BorderRadius.circular(AppRadii.pill)` |
| Border radius 22.5 (circle) | `BorderRadius.circular(AppRadii.circle)` |
| Pixel spacing (16/24/32) | Hardcode pixel OK nếu chưa có `AppSpacing` token (codebase hiện tại) |

### Component variants

| Figma | Flutter |
|---|---|
| Variant "primary/secondary/ghost" | Enum + state-based styling trong widget class |
| Variant "size: sm/md/lg" | Constructor params |
| State Default/Active/Error/Success | Enum như `AppTextInputStatus` |

**Reference variant pattern:** [`app_text_input.dart`](../../apps/mobile/lib/shared/widgets/app_text_input.dart) có 4 enum types + 4 status states.

## Phase 3 — Validate before generate

Print summary trước khi generate:

```
Figma node: <name>
File: <feature>/presentation/<page>.dart hoặc <feature>/presentation/widgets/<widget>.dart
Layout: Column / Row / Stack
Children: <count>

Existing widgets reused:
  ✅ AppPrimaryButton (label, onPressed, isLoading)
  ✅ AppTextInput (inputType, status, errorText)
  ✅ AppBackButton

Tokens used:
  ✅ AppColors.bw900, turquoise300, error700
  ✅ AppTextStyles.xlBold, mdSemiBold
  ✅ AppRadii.pill

Tokens MISSING:
  ❌ Color #1A73E8 — không match palette nào → STOP, ping leader

Custom paint needed:
  ⚠️ Beam gradient overlay — CustomPainter required (xem IntroBeam pattern)

Animations:
  ⚠️ Entry stagger + breathing pulse — AnimationController pattern

Proceed? (yes / wait for tokens / discuss with leader)
```

## Phase 4 — Generate widget code

### Widget file path

| Scope | Path |
|---|---|
| Page (1 Figma frame = full screen) | `apps/mobile/lib/features/<module>/presentation/<name>_page.dart` |
| Feature widget (reused ≥ 2 lần trong feature) | `apps/mobile/lib/features/<module>/presentation/widgets/<name>.dart` |
| Cross-feature widget (reused ≥ 3 lần ở module khác) | `apps/mobile/lib/shared/widgets/<name>.dart` |

### Naming

| Figma layer | File | Class |
|---|---|---|
| `btn_primary_lg` | `app_primary_button.dart` (nếu đặt shared) | `AppPrimaryButton` |
| `intro_page` | `intro_page.dart` | `IntroPage` |
| `dialog_forgot_pw` | `forgot_password_dialog.dart` | `ForgotPasswordDialog` |

**Meep convention:** shared widgets prefix `App`, dialogs suffix `Dialog`, pages suffix `Page`.

### Stateless widget skeleton

```dart
import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_radii.dart';
import 'package:meep/core/theme/app_text_styles.dart';

class <WidgetName> extends StatelessWidget {
  const <WidgetName>({super.key, /* required params */});

  @override
  Widget build(BuildContext context) {
    return <root layout>;
  }
}
```

### Stateful widget skeleton (interactive / animated)

```dart
class <WidgetName> extends StatefulWidget {
  const <WidgetName>({super.key});

  @override
  State<<WidgetName>> createState() => _<WidgetName>State();
}

class _<WidgetName>State extends State<<WidgetName>> with TickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
    // ❌ KHÔNG `ref.read()` trong dispose nếu widget là ConsumerStatefulWidget
    //    — race với router teardown. Xem AUTH §7.
  }

  @override
  Widget build(BuildContext context) { ... }
}
```

### ConsumerStatefulWidget (cần state từ Riverpod)

> Full pattern: [AUTH reference §7](../reference-architectures/auth.md) — dispose-safe + clear-on-keystroke
> File mẫu: [`login_password_page.dart`](../../apps/mobile/lib/features/auth/presentation/login/login_password_page.dart)

```dart
class XxxPage extends ConsumerStatefulWidget { ... }

class _XxxPageState extends ConsumerState<XxxPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();   // ❌ KHÔNG ref.read trong dispose
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(xxxControllerProvider);
    return AppTextInput(
      onChanged: (_) {
        if (ref.read(xxxControllerProvider).errorMessage != null) {
          ref.read(xxxControllerProvider.notifier).clearError();
        }
        setState(() {});
      },
      // ...
    );
  }
}
```

### Component with variants — enum + factory

Reference: [`app_text_input.dart`](../../apps/mobile/lib/shared/widgets/app_text_input.dart)

```dart
enum AppTextInputType { email, username, name, password }
enum AppTextInputStatus { normal, active, error, success }

class AppTextInput extends StatefulWidget {
  const AppTextInput({
    super.key,
    required this.inputType,
    this.status = AppTextInputStatus.normal,
    // ...
  });

  final AppTextInputType inputType;
  final AppTextInputStatus status;
}
```

Rules:
- `const` constructors mandatory.
- KHÔNG `ref.watch(provider)` trong StatelessWidget — pass via param hoặc callback.
- KHÔNG async method — pass `VoidCallback onTap`.
- `Semantics(button: true, label: '...')` cho mọi tap target.
- Touch target ≥ 48x48 logical pixels (CLAUDE.md a11y rule).

## Phase 4.5 — Custom visual patterns (cho complex Figma)

### CustomPainter cho SVG path / gradient overlay

> Khi nào dùng: Figma có path/shape phức tạp, gradient direction custom, blur layer mà SVG asset không cover hết. Vd: animated background, overlay beam, particle.
> Reference: [`intro_beam.dart`](../../apps/mobile/lib/features/auth/presentation/widgets/intro_beam.dart)

```dart
class XxxPainter extends CustomPainter {
  const XxxPainter({required this.opacity});

  final double opacity;

  Shader _gradient(Size size) {
    return const LinearGradient(
      begin: Alignment(1.16, -0.90),
      end: Alignment(-0.001, 0.41),
      colors: [Color(0xFF85E9FF), Color(0x3385E9FF)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Scale theo viewport — Figma node thường 412x841
    final sx = size.width / 412;
    final sy = size.height / 841;

    final path = Path()
      ..moveTo(400.0 * sx, -85.0 * sy)
      ..lineTo(513.0 * sx, -44.0 * sy)
      // ... coords từ Figma SVG export
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = _gradient(size)
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;  // hoặc compare props
}
```

**Khi nào KHÔNG dùng CustomPainter:**
- Shape đơn giản (rectangle, circle) → `Container(decoration: BoxDecoration(...))`
- SVG asset có sẵn → `SvgPicture.asset('assets/icons/xxx.svg')`
- Static image → `Image.asset` / `Image.network`

### Animation patterns

> Reference: [`intro_page.dart`](../../apps/mobile/lib/features/auth/presentation/intro_page.dart) — 3 animation types trong cùng widget

**1. Entry stagger (fade + slide-up cho từng phần tử)**

```dart
late final AnimationController _entryCtrl;

@override
void initState() {
  super.initState();
  _entryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  _entryCtrl.forward();
}

Widget _stagger({required double start, required double end, required Widget child}) {
  final anim = CurvedAnimation(
    parent: _entryCtrl,
    curve: Interval(start, end, curve: Curves.easeOut),
  );
  return FadeTransition(
    opacity: anim,
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(anim),
      child: child,
    ),
  );
}

// Usage:
_stagger(start: 0.10, end: 0.60, child: const Logo()),     // Logo: 100ms-600ms
_stagger(start: 0.25, end: 0.70, child: const Title()),    // Title: 250ms-700ms
_stagger(start: 0.50, end: 0.90, child: const Button1()),  // Button1: 500ms-900ms
```

**2. Breathing pulse (loop forever, vd background beam)**

```dart
late final AnimationController _breathCtrl;

@override
void initState() {
  super.initState();
  _breathCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  )..repeat(reverse: true);
}

// Usage:
AnimatedBuilder(
  animation: _breathCtrl,
  builder: (_, __) => IntroBeam(opacity: 0.85 + 0.15 * _breathCtrl.value),
),
```

**3. Press feedback (scale + haptic)**

```dart
class _GlassButtonState extends State<_GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.lightImpact();   // tactile feedback
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: Duration(milliseconds: _pressed ? 80 : 220),
        curve: _pressed ? Curves.easeIn : Curves.easeOutBack,
        child: ...,
      ),
    );
  }
}
```

**Dispose mandatory** cho mọi `AnimationController`:
```dart
@override
void dispose() {
  _entryCtrl.dispose();
  _breathCtrl.dispose();
  super.dispose();
}
```

## Phase 5 — Generate widget test (mandatory)

> Reference: [`app_text_input_test.dart`](../../apps/mobile/test/shared/widgets/app_text_input_test.dart) — 10 cases trên 1 widget

File: `apps/mobile/test/features/<my-module>/presentation/widgets/<widget_name>_test.dart` hoặc `apps/mobile/test/shared/widgets/<widget_name>_test.dart`

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

    testWidgets('shows expected text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: <WidgetName>(...))),
      );
      expect(find.text('<expected text>'), findsOneWidget);
    });

    // Cho variant
    testWidgets('renders error state correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: <WidgetName>(
        status: <WidgetName>Status.error,
        errorText: 'Test error',
      ))));
      expect(find.text('Test error'), findsOneWidget);
    });
  });
}
```

Mandatory test cases:
- [ ] Renders without throwing.
- [ ] No layout overflow.
- [ ] Critical text/buttons findable.
- [ ] Tap callbacks invoke (nếu interactive).
- [ ] Variant states render correctly (nếu có enum status).

## Phase 6 — Verify (iterative)

### Round 1 — Automated (mandatory mỗi round)

```bash
flutter test test/features/<my-module>/presentation/widgets/<widget_name>_test.dart
flutter analyze
dart format --set-exit-if-changed lib/features/<my-module>/presentation/widgets/<widget_name>.dart
```

3 lệnh exit 0 → next round. Có warning → fix trước khi proceed.

### Round 2 — Visual diff

User renders trên emulator / device, screenshot widget + attach alongside Figma image. Compare:

| Element | Figma | Flutter | Match? |
|---|---|---|---|
| Layout direction | Column | Column | ✅ |
| Title font | xl Bold | xl Bold | ✅ |
| Beam gradient angle | -45° from top-right | -50° | ❌ — adjust Alignment |
| Button press scale | 0.96 | 1.0 (no anim) | ❌ — add AnimatedScale |

Agent fixes specific items, NOT rewrite full widget.

### Round 3+ — Refine for complex visuals

Đối với simple widget (button, input) → 1-2 rounds đủ.
Đối với complex visual (CustomPainter gradient, multi-layer animation) → 5+ rounds OK. Vd IntroPage cần ~28 commits iteration để pixel-perfect.

**STOP rules:**
- 3 rounds vẫn lệch ở element SIMPLE (text/layout/color) → designer review Figma, không ép code match Figma sai.
- 5 rounds vẫn lệch ở element COMPLEX (gradient/painter/animation) → discuss với leader, có thể accept "close enough" với note trong PR.

## Anti-patterns

| Anti-pattern | Vấn đề |
|---|---|
| Inline hex `Color(0xFF1A73E8)` | Drift design system, dark mode vỡ |
| `Theme.of(context).colorScheme.primary` cho widget styling | Codebase Meep dùng `AppColors` direct |
| Hardcode `TextStyle(fontSize: 16)` | Bypass `AppTextStyles` → inconsistent |
| Generate full screen 1 lần | Risk lệch cao, khó review |
| Generate widget + Riverpod controller cùng PR | Mix concerns |
| Auto-add token vào `core/theme` tự động | Shared code cần leader gate |
| Duplicate widget có sẵn trong `shared/widgets/` | DRY vỡ, drift behavior |
| Skip widget test | Presentation layer test mandatory |
| `ref.read()` trong `dispose()` | Race với router teardown — Cannot use ref after disposed |
| Stop sau 3 rounds khi gradient/painter chưa khớp | Complex visuals cần iterations |
| Generate `MeepButton` mới khi đã có `AppPrimaryButton` | Naming inconsistency, drift |

## Quick reference — Meep shared widgets có sẵn

| Widget | File | Use case |
|---|---|---|
| `AppPrimaryButton` | [`app_primary_button.dart`](../../apps/mobile/lib/shared/widgets/app_primary_button.dart) | CTA button với loading + disabled state |
| `AppTextInput` | [`app_text_input.dart`](../../apps/mobile/lib/shared/widgets/app_text_input.dart) | Email/username/name/password input với 4 status |
| `AppGoogleButton` | [`app_google_button.dart`](../../apps/mobile/lib/shared/widgets/app_google_button.dart) | Google Sign-In button (Android only) |
| `AppBackButton` | [`app_back_button.dart`](../../apps/mobile/lib/shared/widgets/app_back_button.dart) | 40x40 circle back button |
| `OrDivider` | [`or_divider.dart`](../../apps/mobile/lib/shared/widgets/or_divider.dart) | Horizontal divider với "hoặc" label |

Trước khi tạo widget mới, **đọc file shared widgets đầy đủ** xem có thể reuse / extend không.
