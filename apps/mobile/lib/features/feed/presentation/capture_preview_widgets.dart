part of 'capture_preview_screen.dart';

class _Header extends StatelessWidget {
  const _Header({required this.onDownload, required this.savedToGallery});

  final VoidCallback onDownload;
  final bool savedToGallery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const Spacer(),
          const Text(
            'Gửi đến...',
            style: TextStyle(
              color: AppColors.bw100,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onDownload,
            child: Icon(
              savedToGallery ? Icons.check : Icons.download_outlined,
              color: savedToGallery ? AppColors.turquoise500 : AppColors.bw100,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceRow extends ConsumerWidget {
  const _AudienceRow({
    required this.screenW,
    required this.audienceType,
    required this.selectedUids,
    required this.selectedSpaceIds,
    required this.onAudienceChanged,
    required this.onSpaceToggled,
  });

  final double screenW;
  final AudienceType audienceType;
  final List<String> selectedUids;
  final List<String> selectedSpaceIds;
  final void Function(AudienceType, List<String>) onAudienceChanged;
  final void Function(String spaceId) onSpaceToggled;

  static const double _tileGap = 12.0;

  void _onAllTap(String currentUid) {
    if (audienceType == AudienceType.all) {
      // Đang "Tất cả" → bỏ, tự chọn "Bạn" (bản thân)
      onAudienceChanged(AudienceType.select, [currentUid]);
    } else {
      // Chọn "Tất cả" → unselect hết friend đã pick lẻ
      onAudienceChanged(AudienceType.all, const []);
    }
  }

  void _onSelfTap(String currentUid) {
    onAudienceChanged(AudienceType.select, [currentUid]);
  }

  void _onFriendTap(String currentUid, String friendUid) {
    if (audienceType == AudienceType.all) {
      // Từ "Tất cả" → chọn riêng friend này
      onAudienceChanged(AudienceType.select, [friendUid]);
      return;
    }
    final next = selectedUids.contains(friendUid)
        ? selectedUids.where((u) => u != friendUid).toList()
        : [...selectedUids, friendUid];
    if (next.isEmpty && selectedSpaceIds.isEmpty) {
      onAudienceChanged(AudienceType.all, const []);
    } else {
      onAudienceChanged(AudienceType.select, next);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarSize = AppProportions.audienceAvatarSize(screenW);
    final labelSize = avatarSize * 0.45;
    final isAll = audienceType == AudienceType.all;

    final currentUid = ref.watch(currentUidProvider).valueOrNull ?? '';
    final friends = currentUid.isEmpty
        ? const <UserProfile>[]
        : ref.watch(
            friendControllerProvider(currentUid).select((s) => s.friends),
          );
    final spaces = currentUid.isEmpty
        ? const <Space>[]
        : ref.watch(
            spaceControllerProvider(currentUid).select((s) => s.spaces),
          );
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    // Build ordered tile list: Spaces → Tất cả → Bạn → Friends
    final tileWidgets = <Widget>[];
    for (final space in spaces) {
      tileWidgets.add(
        _SpaceAudienceTile(
          space: space,
          isSelected: selectedSpaceIds.contains(space.spaceId),
          avatarSize: avatarSize,
          labelSize: labelSize,
          onTap: () => onSpaceToggled(space.spaceId),
        ),
      );
      tileWidgets.add(const SizedBox(width: _tileGap));
    }
    // Tất cả tile
    tileWidgets.add(
      _AllAudienceTile(
        isSelected: isAll,
        avatarSize: avatarSize,
        labelSize: labelSize,
        onTap: () => _onAllTap(currentUid),
      ),
    );
    tileWidgets.add(const SizedBox(width: _tileGap));
    // Bạn tile (author/self)
    if (profile != null) {
      tileWidgets.add(
        _SelfAudienceTile(
          profile: profile,
          isSelected: audienceType == AudienceType.select &&
              selectedUids.length == 1 &&
              selectedUids.first == currentUid,
          avatarSize: avatarSize,
          labelSize: labelSize,
          onTap: () => _onSelfTap(currentUid),
        ),
      );
      tileWidgets.add(const SizedBox(width: _tileGap));
    }
    // Friends
    for (final friend in friends) {
      tileWidgets.add(
        _FriendAudienceTile(
          friend: friend,
          isSelected: selectedUids.contains(friend.uid),
          avatarSize: avatarSize,
          labelSize: labelSize,
          onTap: () => _onFriendTap(currentUid, friend.uid),
        ),
      );
      tileWidgets.add(const SizedBox(width: _tileGap));
    }
    // Remove trailing gap
    if (tileWidgets.isNotEmpty) tileWidgets.removeLast();

    final tileCount = tileWidgets.length;
    if (tileCount == 0) return const SizedBox.shrink();

    // Estimate total width để quyết định có cycle scroll không
    final estTileWidth = avatarSize + 8; // avatar + label padding
    final estTotalWidth = tileCount * estTileWidth + (tileCount - 1) * _tileGap;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: avatarSize + 4 + labelSize * 1.35 + 2,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final needsScroll = estTotalWidth > constraints.maxWidth;

            if (!needsScroll) {
              // List vừa màn hình → căn giữa
              return Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: tileWidgets,
                  ),
                ),
              );
            }

            // Cycle scroll: duplicate list 101 lần, start ở giữa
            const repeats = 101;
            final totalItems = tileCount * repeats;
            final startIndex = totalItems ~/ 2;

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: ScrollController(initialScrollOffset: 0),
              itemCount: totalItems,
              itemBuilder: (context, index) {
                final tile = tileWidgets[(index + startIndex) % tileCount];
                // Re-wrap với key duy nhất để Flutter diff đúng
                return SizedBox(
                  key: ValueKey('aud_$index'),
                  child: tile,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// "Tất cả" tile — selected by default, picks AudienceType.all.
class _AllAudienceTile extends StatelessWidget {
  const _AllAudienceTile({
    required this.isSelected,
    required this.avatarSize,
    required this.labelSize,
    required this.onTap,
  });

  final bool isSelected;
  final double avatarSize;
  final double labelSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected ? AppColors.turquoise500 : AppColors.bw100;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.turquoise500 : AppColors.bw600,
                width: 1.5,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF394041),
              ),
              child: Icon(
                Icons.group_outlined,
                color: accent,
                size: avatarSize * 0.45,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tất cả',
            style: TextStyle(
              color: accent,
              fontSize: labelSize,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Bạn" tile — author/self. Selected khi audienceType=select và chỉ có
/// mỗi currentUid trong selectedUids.
class _SelfAudienceTile extends StatelessWidget {
  const _SelfAudienceTile({
    required this.profile,
    required this.isSelected,
    required this.avatarSize,
    required this.labelSize,
    required this.onTap,
  });

  final UserProfile profile;
  final bool isSelected;
  final double avatarSize;
  final double labelSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected ? AppColors.turquoise500 : AppColors.bw100;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.turquoise500 : AppColors.bw600,
                width: 1.5,
              ),
            ),
            child: AppAvatar(
              imageUrl: profile.avatarUrl,
              size: avatarSize,
              fallbackText: profile.displayName.isNotEmpty
                  ? profile.displayName[0].toUpperCase()
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: avatarSize + 8,
            child: Text(
              'Bạn',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent,
                fontSize: labelSize,
                fontWeight: FontWeight.w900,
                fontFamily: 'Nunito',
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Friend avatar tile — tap to add/remove this uid from the recipient list.
class _FriendAudienceTile extends StatelessWidget {
  const _FriendAudienceTile({
    required this.friend,
    required this.isSelected,
    required this.avatarSize,
    required this.labelSize,
    required this.onTap,
  });

  final UserProfile friend;
  final bool isSelected;
  final double avatarSize;
  final double labelSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected ? AppColors.turquoise500 : AppColors.bw100;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAvatar(
            imageUrl: friend.avatarUrl,
            size: avatarSize,
            ringColor: isSelected ? AppColors.turquoise500 : null,
            fallbackText: friend.displayName.isNotEmpty
                ? friend.displayName[0].toUpperCase()
                : null,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: avatarSize + 8,
            child: Text(
              friend.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent,
                fontSize: labelSize,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Space tile — circle với colorHex bg + iconEmoji centered. Layout like
/// `_FriendAudienceTile` nhưng nền dùng màu Space thay vì avatar ảnh.
class _SpaceAudienceTile extends StatelessWidget {
  const _SpaceAudienceTile({
    required this.space,
    required this.isSelected,
    required this.avatarSize,
    required this.labelSize,
    required this.onTap,
  });

  final Space space;
  final bool isSelected;
  final double avatarSize;
  final double labelSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected ? AppColors.turquoise500 : AppColors.bw100;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hexToColor(space.colorHex),
              border: Border.all(
                color: isSelected ? AppColors.turquoise500 : AppColors.bw600,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              space.iconEmoji,
              style: TextStyle(fontSize: avatarSize * 0.4),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: avatarSize + 8,
            child: Text(
              space.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent,
                fontSize: labelSize,
                fontWeight: FontWeight.w900,
                fontFamily: 'Nunito',
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DualPreviewImage extends StatelessWidget {
  const _DualPreviewImage({
    required this.frontPath,
    required this.backPath,
    required this.primaryIsFront,
  });

  final String frontPath;
  final String backPath;
  final bool primaryIsFront;

  @override
  Widget build(BuildContext context) {
    final primary = primaryIsFront ? frontPath : backPath;
    final secondary = primaryIsFront ? backPath : frontPath;

    return LayoutBuilder(
      builder: (context, constraints) {
        final frameSize = constraints.maxWidth;
        final pipSize = AppProportions.pipSize(frameSize);
        final pipMargin = AppProportions.pipMargin(frameSize);

        return Stack(
          children: [
            // Primary (back camera by default) — full frame
            Positioned.fill(
              child: Image.file(
                File(primary),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            // Secondary (front camera by default) — PiP top-right
            Positioned(
              top: pipMargin,
              right: pipMargin,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppProportions.pipCornerRadius),
                child: SizedBox(
                  width: pipSize,
                  height: pipSize,
                  child: Image.file(
                    File(secondary),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
