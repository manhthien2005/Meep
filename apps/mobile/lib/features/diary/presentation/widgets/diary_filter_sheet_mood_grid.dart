part of 'diary_filter_sheet.dart';

// Mood grid — Stack 354×155 với 5 mood ở vị trí Figma `712:4491`.

class _MoodSpec {
  const _MoodSpec({
    required this.template,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final MoodTemplate template;
  final double x, y, width, height;

  String get asset => 'assets/icons/bg_${template.name}.png';
}

/// 5 mood position từ Figma `712:4491` (Frame 1575 354×155).
const _moodSpecs = <_MoodSpec>[
  _MoodSpec(template: MoodTemplate.happy, x: 37, y: 8, width: 59, height: 59),
  _MoodSpec(template: MoodTemplate.bored, x: 146, y: 5, width: 73, height: 65),
  _MoodSpec(
    template: MoodTemplate.tired,
    x: 262,
    y: 9.5,
    width: 55,
    height: 56,
  ),
  _MoodSpec(template: MoodTemplate.shy, x: 84.5, y: 89, width: 65, height: 61),
  _MoodSpec(template: MoodTemplate.sad, x: 192.5, y: 89, width: 77, height: 61),
];

class _MoodGrid extends StatelessWidget {
  const _MoodGrid({required this.selected, required this.onToggle});

  final Set<MoodTemplate> selected;
  final ValueChanged<MoodTemplate> onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 354,
      height: 155,
      child: Stack(
        children: [
          for (final spec in _moodSpecs)
            Positioned(
              left: spec.x,
              top: spec.y,
              width: spec.width,
              height: spec.height,
              child: _MoodTile(
                spec: spec,
                isSelected: selected.contains(spec.template),
                onTap: () => onToggle(spec.template),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.spec,
    required this.isSelected,
    required this.onTap,
  });

  final _MoodSpec spec;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: spec.template.name,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Mood image — giữ shape gốc của asset
            Positioned.fill(
              child: Image.asset(spec.asset, fit: BoxFit.contain),
            ),
            // Checkbox overlay — top-right corner khi selected
            if (isSelected)
              const Positioned(
                top: -4,
                right: -4,
                child: _MoodCheckBadge(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Checkbox badge — 22×22 turquoise500 circle với check mark đen ở giữa.
/// Figma `718:4496` (Checkbox instance trong Group 44).
class _MoodCheckBadge extends StatelessWidget {
  const _MoodCheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.turquoise500,
      ),
      child: const Icon(
        Icons.check,
        size: 14,
        color: AppColors.bw900,
      ),
    );
  }
}
