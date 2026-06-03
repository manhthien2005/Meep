import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/reaction/application/reaction_controller.dart';
import 'package:meep/features/reaction/data/reaction.dart';
import 'package:meep/shared/widgets/app_avatar.dart';

/// Bottom sheet hiển thị danh sách ai đã react vào post của mình.
/// Figma 769:6014 — "Phản ứng" title + [avatar][name][emoji] rows.
/// Sort newest first (createdAt DESC). Row inert — không nav profile (MVP).
class ReactionListSheet extends ConsumerWidget {
  const ReactionListSheet({super.key, required this.postId});

  final String postId;

  static Future<void> show(BuildContext context, String postId) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bw800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReactionListSheet(postId: postId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reactionControllerProvider(postId));
    final reactions = state.reactions;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 55,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.bw700,
                borderRadius: BorderRadius.circular(6.5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Phản ứng',
              style: TextStyle(
                color: AppColors.bw100,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: reactions.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có phản ứng nào',
                        style: TextStyle(color: AppColors.bw400),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: reactions.length,
                      itemBuilder: (context, index) {
                        final r = reactions[index];
                        return _ReactionRow(reaction: r);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({required this.reaction});

  final Reaction reaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Row(
        children: [
          AppAvatar(
            fallbackText: reaction.reactorName,
            size: 50,
          ),
          const SizedBox(width: 16),
          Text(
            reaction.reactorName,
            style: const TextStyle(
              color: AppColors.bw100,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
          const Spacer(),
          Text(
            reaction.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
}
