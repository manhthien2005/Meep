import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/core/utils/pair_id.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/friend/application/friend_controller.dart';

part 'friend_posts_provider.g.dart';

/// Posts của một friend, đã filter theo audience để chỉ hiển thị ảnh
/// chia sẻ với current user (spec Q OQ5 — không thêm field mới, dùng
/// `audienceType` + `audienceUids` đã có trong Post model).
///
/// Filter rule:
/// - `audienceType == 'all'` → all friends thấy
/// - `audienceType == 'select' && audienceUids.contains(currentUid)` → chỉ
///   user được chỉ định thấy
///
/// Trả `null` khi current user chưa login. Caller phải gate UI bằng
/// `isFriendProvider` trước khi watch.
@riverpod
Future<List<Post>?> friendPosts(Ref ref, String friendUid) async {
  final currentUid = ref.watch(currentUidProvider).valueOrNull;
  if (currentUid == null) return null;

  final all =
      await ref.read(postRepositoryProvider).getPostsByAuthor(friendUid);
  final visible = all.where((p) {
    if (p.audienceType == AudienceType.all) return true;
    if (p.audienceType == AudienceType.select) {
      return p.audienceUids.contains(currentUid);
    }
    return false;
  }).toList();

  // Defensive sort — repo orders by createdAt desc.
  visible.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return visible;
}

/// True nếu [friendUid] là bạn bè của current user, kiểm tra qua FriendRepository
/// (Firestore `/friendships/{pairId}` doc). False khi pair doc không tồn tại
/// hoặc current user chưa login.
@riverpod
Future<bool> isFriendOfCurrent(Ref ref, String friendUid) async {
  final currentUid = ref.watch(currentUidProvider).valueOrNull;
  if (currentUid == null || currentUid == friendUid) return false;

  final friendUids =
      await ref.read(friendRepositoryProvider).getFriendUids(currentUid);
  return friendUids.contains(friendUid);
}

/// Helper để compute pairId từ current user + friend uid — dùng cho unfriend
/// action trong FriendSheet.
String? pairIdWithCurrent(WidgetRef ref, String friendUid) {
  final currentUid = ref.read(currentUidProvider).valueOrNull;
  if (currentUid == null) return null;
  return pairIdOf(currentUid, friendUid);
}
