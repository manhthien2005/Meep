import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/firebase_auth_repository.dart';
import 'package:meep/features/auth/data/firebase_user_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

ProviderContainer makeContainer({
  MockFirebaseAuth? auth,
}) {
  final mockAuth = auth ?? MockFirebaseAuth();
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FirebaseAuthRepository(auth: mockAuth),
      ),
      userRepositoryProvider.overrideWithValue(
        FirebaseUserRepository(firestore: FakeFirebaseFirestore()),
      ),
    ],
  );
}

void main() {
  group('currentUidProvider', () {
    test('emits null khi chưa sign in', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final uid = await container.read(currentUidProvider.future);
      expect(uid, isNull);
    });

    test('emits uid khi đã sign in', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-alice'),
        signedIn: true,
      );
      final container = makeContainer(auth: auth);
      addTearDown(container.dispose);

      final uid = await container.read(currentUidProvider.future);
      expect(uid, 'uid-alice');
    });
  });

  group('isSignedInProvider', () {
    test('false khi chưa sign in', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      // Đợi stream resolve trước
      await container.read(currentUidProvider.future);
      expect(container.read(isSignedInProvider), false);
    });

    test('true khi đã sign in', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-bob'),
        signedIn: true,
      );
      final container = makeContainer(auth: auth);
      addTearDown(container.dispose);

      await container.read(currentUidProvider.future);
      expect(container.read(isSignedInProvider), true);
    });
  });
}
