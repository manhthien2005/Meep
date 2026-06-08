import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/auth_providers.dart';

part 'email_verification_gate.g.dart';

/// True khi user hiện tại CẦN xác minh email trước khi vào app: đăng nhập bằng
/// email/password (provider `password`) VÀ chưa verify. Google/social provider
/// luôn false (email pre-verified). Signed-out → false.
///
/// Seed đồng bộ trong [build] từ [authRepositoryProvider]; vì `revalidateSession`
/// đã `user.reload()` trước `runApp`, giá trị cold-start đã fresh. [refresh]
/// reload lại từ server (poll / nút "Tôi đã xác minh") rồi re-eval — khi verify
/// xong state đổi true→false → router rời `/verify-email` về `/home`.
@riverpod
class EmailVerificationGate extends _$EmailVerificationGate {
  @override
  bool build() {
    // Rebuild khi uid đổi (login / logout / cold-start).
    ref.watch(currentUidProvider);
    return _computeRequiresVerification();
  }

  bool _computeRequiresVerification() {
    final repo = ref.read(authRepositoryProvider);
    if (repo.currentUid == null) return false;
    // Chỉ gate email/password — Google email đã pre-verified.
    if (repo.currentProviderId != 'password') return false;
    return !repo.isEmailVerified;
  }

  /// Reload user từ server rồi re-đọc `emailVerified`. Gọi từ poll Timer + nút
  /// "Tôi đã xác minh" trên `/verify-email`. State đổi → `_RouterNotifier` được
  /// notify → GoRouter re-eval redirect.
  Future<void> refresh() async {
    await ref.read(authRepositoryProvider).reloadUser();
    final next = _computeRequiresVerification();
    if (next != state) state = next;
  }
}
