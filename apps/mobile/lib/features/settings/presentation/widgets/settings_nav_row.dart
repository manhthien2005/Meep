import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// Một dòng điều hướng trong SettingsSheet: icon + nhãn + mũi tên phải.
/// [isDestructive] tô đỏ cho hành động nguy hiểm (Xoá tài khoản).
class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error800 : Colors.white;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.mdRegular.copyWith(color: color),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDestructive ? AppColors.error800 : AppColors.bw500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
