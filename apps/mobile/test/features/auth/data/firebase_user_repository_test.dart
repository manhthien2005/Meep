import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/data/firebase_user_repository.dart';
import 'package:meep/features/auth/data/user_profile.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseUserRepository repo;

  final alice = UserProfile(
    uid: 'uid-alice',
    email: 'alice@example.com',
    displayName: 'Alice Nguyen',
    username: 'alice',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = FirebaseUserRepository(firestore: fakeFirestore);
  });

  group('createProfile', () {
    test('tạo /users/{uid} + /usernames/{username} trong cùng batch', () async {
      await repo.createProfile(alice);

      final userDoc = await fakeFirestore.doc('users/${alice.uid}').get();
      final usernameDoc =
          await fakeFirestore.doc('usernames/${alice.username}').get();

      expect(userDoc.exists, isTrue);
      expect(usernameDoc.exists, isTrue);
      expect(usernameDoc.data()?['uid'], alice.uid);
    });

    test('username stored lowercase', () async {
      final profile = alice.copyWith(username: 'Alice');
      await repo.createProfile(profile);

      final usernameDoc = await fakeFirestore.doc('usernames/alice').get();
      expect(usernameDoc.exists, isTrue);
    });

    test('user doc có đầy đủ required fields', () async {
      await repo.createProfile(alice);
      final data =
          (await fakeFirestore.doc('users/${alice.uid}').get()).data()!;
      expect(data['uid'], alice.uid);
      expect(data['email'], alice.email);
      expect(data['displayName'], alice.displayName);
      expect(data['username'], alice.username);
    });
  });

  group('getProfile', () {
    test('trả null khi uid không tồn tại', () async {
      final result = await repo.getProfile('nonexistent');
      expect(result, isNull);
    });

    test('trả UserProfile đúng khi tồn tại', () async {
      await repo.createProfile(alice);
      final result = await repo.getProfile(alice.uid);
      expect(result, isNotNull);
      expect(result!.uid, alice.uid);
      expect(result.email, alice.email);
      expect(result.displayName, alice.displayName);
      expect(result.username, alice.username);
    });
  });

  group('getPublicProfile', () {
    test('trả null khi public profile chưa tồn tại', () async {
      final result = await repo.getPublicProfile('nonexistent');
      expect(result, isNull);
    });

    test('trả PublicProfile đúng khi tồn tại', () async {
      await fakeFirestore.doc('users/${alice.uid}/public/profile').set({
        'uid': alice.uid,
        'displayName': alice.displayName,
        'username': alice.username,
        'avatarUrl': null,
        'bio': null,
        'isSearchable': true,
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      final result = await repo.getPublicProfile(alice.uid);

      expect(result, isNotNull);
      expect(result!.uid, alice.uid);
      expect(result.displayName, alice.displayName);
      expect(result.username, alice.username);
    });
  });

  group('isUsernameAvailable', () {
    test('trả true khi username chưa có', () async {
      final available = await repo.isUsernameAvailable('newuser');
      expect(available, isTrue);
    });

    test('trả false khi username đã được dùng', () async {
      await repo.createProfile(alice); // username = 'alice'
      final available = await repo.isUsernameAvailable('alice');
      expect(available, isFalse);
    });

    test('case-insensitive — alice và Alice là cùng username', () async {
      await repo.createProfile(alice);
      final available = await repo.isUsernameAvailable('Alice');
      expect(available, isFalse);
    });
  });

  group('watchProfile', () {
    test('emits null khi uid không tồn tại', () async {
      final profile = await repo.watchProfile('nonexistent').first;
      expect(profile, isNull);
    });

    test('emits profile sau khi tạo', () async {
      await repo.createProfile(alice);
      final profile = await repo.watchProfile(alice.uid).first;
      expect(profile?.uid, alice.uid);
    });
  });

  group('watchPublicProfile', () {
    test('emits null khi public profile không tồn tại', () async {
      final profile = await repo.watchPublicProfile('nonexistent').first;
      expect(profile, isNull);
    });

    test('emits public profile sau khi tạo', () async {
      await fakeFirestore.doc('users/${alice.uid}/public/profile').set({
        'uid': alice.uid,
        'displayName': alice.displayName,
        'username': alice.username,
        'avatarUrl': null,
        'bio': null,
        'isSearchable': true,
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      final profile = await repo.watchPublicProfile(alice.uid).first;

      expect(profile?.uid, alice.uid);
      expect(profile?.displayName, alice.displayName);
    });
  });
}
