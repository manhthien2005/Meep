import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// Hàng cuộn ngang quick-access các Space trong SettingsSheet.
/// Pre-M3: nhận danh sách tên Space (mock); logic tạo/sửa thuộc Space module.
class SpaceQuickRow extends StatelessWidget {
  const SpaceQuickRow({
    super.key,
    required this.spaceNames,
    this.onEditSpace,
    this.onCreateSpace,
  });

  final List<String> spaceNames;
  final ValueChanged<String>? onEditSpace;
  final VoidCallback? onCreateSpace;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_border, size: 20, color: Colors.white),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Space',
              style: AppTextStyles.baseBold.copyWith(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 115,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final name in spaceNames) ...[
                _SpaceCard(
                  name: name,
                  onEdit: () => onEditSpace?.call(name),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              _CreateSpaceCard(onTap: onCreateSpace),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({required this.name, required this.onEdit});

  final String name;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 115,
      height: 115,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bw700,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.bw600.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.bw600,
              borderRadius: BorderRadius.circular(21.5),
              border: Border.all(color: AppColors.bw500, width: 2),
            ),
          ),
          Text(
            name,
            style: AppTextStyles.xsSemiBold.copyWith(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Semantics(
            button: true,
            label: 'Sửa',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bw600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Sửa',
                  style: AppTextStyles.xsSemiBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateSpaceCard extends StatelessWidget {
  const _CreateSpaceCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tạo Space',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 115,
          height: 115,
          decoration: BoxDecoration(
            color: AppColors.bw700,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.bw600.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.turquoise500.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.turquoise500, width: 2),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.turquoise500,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tạo',
                style: AppTextStyles.xsSemiBold.copyWith(
                  color: AppColors.turquoise500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
