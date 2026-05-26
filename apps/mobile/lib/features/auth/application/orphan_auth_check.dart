import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/features/auth/data/user_profile.dart';

/// Decision của orphan-auth listener trong `MeepApp`.
enum OrphanCheckResult {
  /// Profile state đang loading hoặc có flow signup/login active → để yên.
  skip,

  /// `uid != null` nhưng profile resolved về null + không có flow active →
  /// gọi `authRepository.signOut()` để dọn orphan auth user.
  signOut,
}

/// Pure decision logic cho orphan auth cleanup listener.
///
/// Tách khỏi `MeepApp` để testable không cần boot toàn bộ app + Riverpod
/// container. Chỉ trả về [OrphanCheckResult.signOut] khi profile stream đã
/// thực sự resolve với value null, có uid, và không có signup/login flow active.
///
/// **Lưu ý kỹ thuật:** Riverpod 2.5+ giữ `previousValue` xuyên qua refresh →
/// `currentUserProfileProvider` (StreamProvider) khi uid đổi sẽ trả về
/// `AsyncData(null, isLoading: true)` thay vì `AsyncLoading` mới. Vì vậy:
/// - Check `isLoading` để skip cả `AsyncLoading` thuần lẫn refresh-from-data.
/// - Trước fix: dùng `hasValue` / `is AsyncData` đều bị false-positive trong
///   cửa sổ uid vừa đổi (previousValue=null từ state cũ) → trigger signOut
///   sai sau khi login thành công, đẩy user về `/intro`.
OrphanCheckResult checkOrphanAuth({
  required AsyncValue<UserProfile?> profileState,
  required String? uid,
  required bool isLoginLoading,
  required bool needsProfile,
  required bool isSignUpGoogle,
  required bool isSignUpLoading,
}) {
  // Đang load / refresh sau khi uid đổi → chờ stream emit lần đầu.
  if (profileState.isLoading) return OrphanCheckResult.skip;
  // Stream error tạm thời → đừng đột ngột signOut user.
  if (profileState.hasError) return OrphanCheckResult.skip;
  // Profile tồn tại — không phải orphan.
  if (profileState.valueOrNull != null) return OrphanCheckResult.skip;
  // Chưa có uid — không phải orphan.
  if (uid == null) return OrphanCheckResult.skip;

  final isActiveFlow =
      isLoginLoading || needsProfile || isSignUpGoogle || isSignUpLoading;
  if (isActiveFlow) return OrphanCheckResult.skip;

  return OrphanCheckResult.signOut;
}
