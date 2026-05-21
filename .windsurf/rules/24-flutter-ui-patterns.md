---
trigger: glob
globs: apps/mobile/lib/features/**/presentation/**/*.dart,apps/mobile/lib/core/theme/**/*.dart,apps/mobile/lib/shared/widgets/**/*.dart
---

# Flutter UI Patterns — Presentation Layer

Loaded when editing `presentation/`, `core/theme/`, or `shared/widgets/`. Supplements `21-flutter-rules.md` (general mobile rules) — this file focuses on **UI patterns** áp dụng cho mọi solo-dev khi implement screen (đặc biệt important cho HanDHG + NganTNK khi map Figma → Flutter).

**General rules for splitting widgets / functions / classes** (size threshold, reuse threshold, file length) — see `21-flutter-rules.md` §Code organization & widget split. This file does NOT duplicate those; it only covers FE-specific patterns below.

## Design tokens — NO hardcoding

**Required** (dark/light mode + text scaling breaks if hardcoded):

- Hardcoded color: `Color(0xFF1A73E8)` → use `Theme.of(context).colorScheme.primary`.
- Hardcoded font size/family: `TextStyle(fontSize: 16)` → use `Theme.of(context).textTheme.bodyMedium`.

**Encouraged** (use tokens when they carry semantic meaning; one-off inline OK):

- Spacing: `SizedBox(height: 12)` → prefer `Spacing.md` tokens for semantic spacing (card padding, section gap). One-off `SizedBox(height: 4)` or `EdgeInsets.all(16)` acceptable.
- Radius: `BorderRadius.circular(8)` → prefer `Radii.md`. Inline OK if used only once.

If Figma has a new color/font not yet in theme → **add to `core/theme/` first**, then use it. Never inline.

## Layering — solo-dev module owner

Module Owner own full-stack module → được touch tất cả layer trong module mình:

- ✅ `apps/mobile/lib/features/<my-module>/data/` — repositories, mappers.
- ✅ `apps/mobile/lib/features/<my-module>/application/` — controllers, services.
- ✅ `apps/mobile/lib/features/<my-module>/presentation/` — widgets, pages.
- ✅ `firebase/functions/src/<my-module>/` — Cloud Functions của module mình.
- ✅ `apps/mobile/android/app/src/main/kotlin/<my-module>/` — native code của module mình.

**Khoá lại + ping leader** khi cần touch:

- ❌ `apps/mobile/lib/core/theme/` — design token shared cho cả app.
- ❌ `apps/mobile/lib/shared/widgets/` — widget reuse cross-module.
- ❌ `apps/mobile/lib/core/error/`, `core/router/`, `core/di/` — shared infra.
- ❌ `firebase/firestore.rules`, `storage.rules`, `firestore.indexes.json` — security rules + indexes.
- ❌ `features/<other-module>/**` — module dev khác (xem `25-dev-code-standards.md` §Cross-module touch).

If Cascade suggests code outside ✅ scope → flag user: "outside my module scope, should I ping leader?".

## Accessibility — minimum required

- **Semantics:** every `IconButton`, `GestureDetector`, custom tap area must have `Semantics(label: '...')` or `tooltip`.
- **Touch target:** tap area ≥ 48x48 logical pixels (Material guideline). Use `InkWell` + padding or `IconButton` (defaults to 48).
- **Contrast:** use theme tokens — light/dark mode automatically meets WCAG AA. DO NOT manually override colors breaking contrast.
- **Text scaling:** never set `fixedFontSize` on `Text`. Let Flutter scale with system settings.

## Figma → Flutter mapping convention

When converting Figma frames to Flutter widgets:

1. **1 Figma frame = 1 widget class** (top-level page or shared widget).
2. **Layer name → variable/widget name:** Figma `btn_primary_lg` → Flutter `PrimaryButtonLarge`. Layer `header_avatar` → field `_headerAvatar` or widget `HeaderAvatar`.
3. **Frame Auto-Layout → Flutter `Column`/`Row`** with `spacing` (Flutter 3.27+) or `SizedBox` token.
4. **Constraints (Stretch/Fix/Hug) → Flutter equivalents:**
   - Stretch → `Expanded` or `SizedBox.expand`.
   - Fix → `SizedBox(width: X, height: Y)`.
   - Hug → let widget self-size (default).
5. **Component variants (Figma) → enum + factory constructor.** E.g. `Button.primary()`, `Button.secondary()` instead of 2 separate widgets.

## Widget state — minimal

- **`StatelessWidget`** preferred. UI-local state (`setState`, `ValueNotifier`, `AnimationController`) OK for toggles, animations, expanded flags.
- **Business state** (auth, posts, friends) → consume from Riverpod controller. DO NOT use `setState` to call APIs.
- **Form state** → use Flutter’s `Form` + `FormState`. DO NOT write custom `setState` per field.

## Loading / error / empty — 4 required states

Every screen consuming async data must handle:

```dart
ref.watch(provider).when(
  loading: () => LoadingIndicator(),
  error: (e, _) => ErrorView(error: e),
  data: (items) => items.isEmpty
      ? EmptyState(message: 'Chưa có gì ở đây')
      : ItemList(items: items),
);
```

Empty state must have a **Vietnamese CTA** (e.g. "Mời bạn bè", "Đăng bài đầu tiên") — never leave the screen blank.

## When unsure

Ask the leader before:

- Adding a new UI dependency (`flutter_animate`, `gap`, `flutter_svg`...).
- Overriding the `MaterialApp` global theme.
- Changing `core/theme/` shared tokens.
- Touching `application/` to fix a bug — report to FS dev instead.
