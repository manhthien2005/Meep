part of 'diary_filter_sheet.dart';

// Date row — 3 dropdown pill (day / month / year).

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.day,
    required this.month,
    required this.year,
    required this.onDayChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  final int? day, month, year;
  final ValueChanged<int> onDayChanged, onMonthChanged, onYearChanged;

  @override
  Widget build(BuildContext context) {
    // Year range: 2020 → năm hiện tại. Descending để năm gần nhất lên trên.
    final currentYear = DateTime.now().year;
    final years = [
      for (var y = currentYear; y >= 2020; y--) y,
    ];

    return SizedBox(
      width: 355,
      height: 60,
      child: Row(
        children: [
          _PillDropdown<int>(
            width: 98,
            value: day,
            placeholder: '--',
            options: [for (var d = 1; d <= 31; d++) d],
            optionLabel: (d) => '$d',
            valueLabel: (d) => '$d',
            onSelected: onDayChanged,
          ),
          const SizedBox(width: 11),
          _PillDropdown<int>(
            width: 128,
            value: month,
            placeholder: 'tháng --',
            options: [for (var m = 1; m <= 12; m++) m],
            optionLabel: (m) => 'tháng $m',
            valueLabel: (m) => 'tháng $m',
            onSelected: onMonthChanged,
          ),
          const SizedBox(width: 11),
          _PillDropdown<int>(
            width: 107,
            value: year,
            placeholder: '----',
            options: years,
            optionLabel: (y) => '$y',
            valueLabel: (y) => '$y',
            onSelected: onYearChanged,
          ),
        ],
      ),
    );
  }
}

/// Pill dropdown — 1 ô date input.
/// Figma frame 1538/1539/1540: bg #050F10 alpha 20%, cornerRadius 30.
/// Tap → showMenu anchored bên trên ô (đổ ngược), scrollable nếu nhiều item.
class _PillDropdown<T> extends StatelessWidget {
  const _PillDropdown({
    required this.width,
    required this.value,
    required this.placeholder,
    required this.options,
    required this.optionLabel,
    required this.valueLabel,
    required this.onSelected,
  });

  final double width;
  final T? value;
  final String placeholder;
  final List<T> options;
  final String Function(T) optionLabel;
  final String Function(T) valueLabel;
  final ValueChanged<T> onSelected;

  /// Hiện tối đa ~10 item rồi cuộn. `kItemHeight × 10 + chrome ≈ 380`.
  static const double _kItemHeight = 36;
  static const double _kMenuChrome = 16; // padding trên/dưới của _PopupMenu
  static const double _kMenuMaxHeight = 380;

  Future<void> _openMenu(BuildContext context) async {
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) return;
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;

    final origin = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final size = renderBox.size;
    final overlaySize = overlay.size;

    // Menu MỞ LÊN trên pill (đổ ngược). Ước tính chiều cao THỰC của menu
    // theo số option — nếu pin theo maxHeight, dropdown ít item sẽ float
    // cao quá pill (tạo gap lớn). Clamp ở `_kMenuMaxHeight` để scroll.
    final estimatedMenuHeight = math.min(
      options.length * _kItemHeight + _kMenuChrome,
      _kMenuMaxHeight,
    );
    final menuTop =
        (origin.dy - estimatedMenuHeight - 4).clamp(0.0, double.infinity);
    final menuBottom = overlaySize.height - origin.dy + 4;

    final position = RelativeRect.fromLTRB(
      origin.dx,
      menuTop,
      overlaySize.width - origin.dx - size.width,
      menuBottom,
    );

    final picked = await showMenu<T>(
      context: context,
      position: position,
      color: AppColors.bw700,
      // maxHeight giới hạn vùng menu → SingleChildScrollView nội bộ của
      // showMenu sẽ kích hoạt scroll khi items vượt quá.
      constraints: BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
        maxHeight: _kMenuMaxHeight,
      ),
      items: [
        for (final opt in options)
          PopupMenuItem<T>(
            value: opt,
            height: _kItemHeight,
            child: Text(
              optionLabel(opt),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.bw100,
              ),
            ),
          ),
      ],
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 60,
      child: Material(
        color: AppColors.bw900.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _openMenu(context),
          child: Center(
            child: Text(
              value == null ? placeholder : valueLabel(value as T),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.bw300,
                height: 24 / 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
