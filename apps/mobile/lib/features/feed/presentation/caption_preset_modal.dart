import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/feed/data/post.dart';

class CaptionPresetModal extends StatelessWidget {
  const CaptionPresetModal({super.key, required this.onSelect});

  final ValueChanged<CaptionType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F20),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.bw600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chú thích',
            style: TextStyle(
              color: AppColors.bw100,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Chung',
            items: const [
              _CaptionItem(
                type: CaptionType.text,
                label: 'Văn bản',
                icon: 'Aa',
              ),
              _CaptionItem(
                type: CaptionType.star,
                label: 'Review',
                emoji: '⭐',
              ),
              _CaptionItem(
                type: CaptionType.music,
                label: 'Đang phát',
                emoji: '♪',
              ),
              _CaptionItem(
                type: CaptionType.location,
                label: 'Vị trí',
                emoji: '📍',
              ),
              _CaptionItem(
                type: CaptionType.weather,
                label: 'Thời tiết',
                emoji: '🌤️',
              ),
              _CaptionItem(
                type: CaptionType.time,
                label: 'Thời gian',
                emoji: '🕐',
              ),
            ],
            onSelect: onSelect,
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Trang trí',
            items: const [
              _CaptionItem(
                type: CaptionType.streak,
                label: 'Streak',
                emoji: '🔥',
              ),
            ],
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.onSelect,
  });

  final String title;
  final List<_CaptionItem> items;
  final ValueChanged<CaptionType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.bw500,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) =>
                    _CaptionChip(item: item, onTap: () => onSelect(item.type)),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _CaptionItem {
  const _CaptionItem({
    required this.type,
    required this.label,
    this.emoji,
    this.icon,
  });

  final CaptionType type;
  final String label;
  final String? emoji;
  final String? icon;
}

class _CaptionChip extends StatelessWidget {
  const _CaptionChip({required this.item, required this.onTap});

  final _CaptionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bw800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.emoji != null)
              Text(item.emoji!, style: const TextStyle(fontSize: 16))
            else if (item.icon != null)
              Text(
                item.icon!,
                style: const TextStyle(
                  color: AppColors.bw100,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: const TextStyle(
                color: AppColors.bw100,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
