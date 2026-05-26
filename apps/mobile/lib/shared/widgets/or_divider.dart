import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// Horizontal divider với label "hoặc" ở giữa.
/// Dùng cho auth forms (email/Google) hoặc bất kỳ chỗ nào cần OR-separator.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'hoặc'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.bw600, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw600),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.bw600, thickness: 1)),
      ],
    );
  }
}
