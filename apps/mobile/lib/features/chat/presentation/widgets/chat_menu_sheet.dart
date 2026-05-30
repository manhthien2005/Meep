import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// A single row inside a [SettingMenuCard]: icon + label, optionally destructive
/// (red icon + text, Figma `Error/800`).
class SettingMenuItem {
  const SettingMenuItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final Object value;
  final bool isDestructive;
}

/// Floating "Setting" popup anchored to the top-right (under the ⋯ button),
/// Figma `564:7079` / `564:8779`: bw800 fill, radius 30, hairline bw600 border,
/// rows of md/Regular(16) with a divider between groups. Returns the tapped
/// item's value, or null when dismissed.
Future<T?> showSettingMenu<T>(
  BuildContext context,
  List<SettingMenuItem> items,
) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (_) => Stack(
      children: [
        Positioned(
          top: 64,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: _SettingMenuCard(items: items),
          ),
        ),
      ],
    ),
  );
}

class _SettingMenuCard extends StatelessWidget {
  const _SettingMenuCard({required this.items});

  final List<SettingMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bw800,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.bw600),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) _MenuRow(item: items[i]),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final SettingMenuItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isDestructive ? AppColors.error800 : AppColors.bw100;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context, item.value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            item.label,
            style: AppTextStyles.mdRegular.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
