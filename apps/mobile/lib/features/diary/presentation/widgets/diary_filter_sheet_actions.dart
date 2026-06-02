part of 'diary_filter_sheet.dart';

// Action row — "Bỏ lọc" (BW700) + "Lọc" (turquoise500) equal width.

/// 2 button cùng hàng, equal width.
/// - "Bỏ lọc" (left): BW700 bg, clear all filters nhanh (pop empty value).
/// - "Lọc" (right): turquoise500 bg, apply current state.
/// Style theo Figma: cornerRadius 30, height 57, Nunito Bold 16.
class _FilterActions extends StatelessWidget {
  const _FilterActions({required this.onClear, required this.onApply});

  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            label: 'Bỏ lọc',
            background: AppColors.bw700,
            foreground: AppColors.bw100,
            onTap: onClear,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PillButton(
            label: 'Lọc',
            background: AppColors.turquoise500,
            foreground: AppColors.bw800,
            onTap: onApply,
          ),
        ),
      ],
    );
  }
}

/// Pill button — height 57, cornerRadius 30, Nunito Bold 16.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 57,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: foreground,
              height: 22 / 16,
            ),
          ),
        ),
      ),
    );
  }
}
