import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/settings/application/blocked_user_view.dart';
import 'package:meep/features/settings/application/settings_controller.dart';

part 'blocked_users_provider.g.dart';

/// Stream danh sách `BlockedUserView` cho BlockedAccountsPage.
/// Join `BlockRepository.watchBlockedUsers` với `UserRepository.getProfile`
/// để có username + avatar (Block chỉ chứa UIDs).
///
/// N+1 reads chấp nhận được vì blocked list thường < 10. Nếu list lớn lên,
/// xem xét denormalize username/avatar vào doc /blocks/.
@riverpod
Stream<List<BlockedUserView>> blockedUsers(Ref ref) {
  final uid = ref.watch(authRepositoryProvider).currentUid;
  if (uid == null) return Stream.value(const []);

  final blockRepo = ref.watch(blockRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);

  return blockRepo.watchBlockedUsers(uid).asyncMap((blocks) async {
    if (blocks.isEmpty) return <BlockedUserView>[];
    final profiles = await Future.wait(
      blocks.map((b) => userRepo.getProfile(b.blockedUid)),
    );
    return [
      for (var i = 0; i < blocks.length; i++)
        BlockedUserView(
          uid: blocks[i].blockedUid,
          username: profiles[i]?.username ?? blocks[i].blockedUid,
          avatarUrl: profiles[i]?.avatarUrl,
        ),
    ];
  });
}
