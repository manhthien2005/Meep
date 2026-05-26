import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/application/orphan_auth_check.dart';
import 'package:meep/features/auth/data/user_profile.dart';

void main() {
  final aliceProfile = UserProfile(
    uid: 'uid-alice',
    email: 'alice@example.com',
    displayName: 'Alice',
    username: 'alice',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  OrphanCheckResult run({
    required AsyncValue<UserProfile?> profileState,
    String? uid = 'uid-alice',
    bool isLoginLoading = false,
    bool needsProfile = false,
    bool isSignUpGoogle = false,
    bool isSignUpLoading = false,
  }) {
    return checkOrphanAuth(
      profileState: profileState,
      uid: uid,
      isLoginLoading: isLoginLoading,
      needsProfile: needsProfile,
      isSignUpGoogle: isSignUpGoogle,
      isSignUpLoading: isSignUpLoading,
    );
  }

  group(
      'checkOrphanAuth — loading transitions (regression: false-positive signOut)',
      () {
    test('AsyncLoading → skip (chưa emit lần đầu)', () {
      expect(
        run(profileState: const AsyncLoading<UserProfile?>()),
        OrphanCheckResult.skip,
      );
    });

    test('AsyncLoading với previousValue=null → skip', () {
      // Trước fix: dùng `hasValue` ở đây trả về true → fire signOut sai.
      final state = const AsyncLoading<UserProfile?>().copyWithPrevious(
        const AsyncData<UserProfile?>(null),
      );
      expect(run(profileState: state), OrphanCheckResult.skip);
    });

    test('AsyncError → skip', () {
      expect(
        run(
          profileState: AsyncError<UserProfile?>(
            Exception('network'),
            StackTrace.empty,
          ),
        ),
        OrphanCheckResult.skip,
      );
    });
  });

  group('checkOrphanAuth — resolved state', () {
    test('AsyncData(profile) → skip — user đã có profile', () {
      expect(
        run(profileState: AsyncData<UserProfile?>(aliceProfile)),
        OrphanCheckResult.skip,
      );
    });

    test('AsyncData(null), uid=null → skip — không phải orphan', () {
      expect(
        run(
          profileState: const AsyncData<UserProfile?>(null),
          uid: null,
        ),
        OrphanCheckResult.skip,
      );
    });

    test('AsyncData(null), uid set, không có flow active → signOut', () {
      expect(
        run(profileState: const AsyncData<UserProfile?>(null)),
        OrphanCheckResult.signOut,
      );
    });
  });

  group('checkOrphanAuth — active flow guards', () {
    const orphanProfile = AsyncData<UserProfile?>(null);

    test('isLoginLoading=true → skip', () {
      expect(
        run(profileState: orphanProfile, isLoginLoading: true),
        OrphanCheckResult.skip,
      );
    });

    test('needsProfile=true (Google new user) → skip', () {
      expect(
        run(profileState: orphanProfile, needsProfile: true),
        OrphanCheckResult.skip,
      );
    });

    test('isSignUpGoogle=true → skip', () {
      expect(
        run(profileState: orphanProfile, isSignUpGoogle: true),
        OrphanCheckResult.skip,
      );
    });

    test('isSignUpLoading=true (createAccount đang chạy) → skip', () {
      expect(
        run(profileState: orphanProfile, isSignUpLoading: true),
        OrphanCheckResult.skip,
      );
    });
  });
}
