import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/profile/data/firebase_profile_repository.dart';

void main() {
  const uid = 'uid-alice';
  const otherUid = 'uid-other';

  late FakeFirebaseFirestore firestore;
  late _StubStorageClient storage;
  late _StubCompressor compressor;
  late FirebaseProfileRepository repo;

  final initialProfile = <String, Object?>{
    'uid': uid,
    'email': 'alice@example.com',
    'displayName': 'Alice Nguyen',
    'username': 'alice',
    'avatarUrl': null,
    'bio': null,
    'dateOfBirth': null,
    'phoneNumber': null,
    'gender': null,
    'postCount': 5,
    'friendCount': 3,
    'spaceCount': 1,
    'isSearchable': true,
    'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
    'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
  };

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    storage = _StubStorageClient();
    compressor = _StubCompressor(Uint8List(1024));
    repo = FirebaseProfileRepository(
      firestore: firestore,
      storageClient: storage,
      compressor: compressor,
    );
    await firestore.doc('users/$uid').set(initialProfile);
  });

  group('getUserProfile', () {
    test('returns UserProfile khi doc tồn tại', () async {
      final result = await repo.getUserProfile(uid);

      expect(result, isNotNull);
      expect(result!.uid, uid);
      expect(result.displayName, 'Alice Nguyen');
      expect(result.postCount, 5);
      expect(result.friendCount, 3);
      expect(result.spaceCount, 1);
    });

    test('returns null khi doc không tồn tại', () async {
      final result = await repo.getUserProfile(otherUid);
      expect(result, isNull);
    });
  });

  group('watchUserProfile', () {
    test('emits profile khi doc tồn tại', () async {
      final first = await repo.watchUserProfile(uid).first;
      expect(first?.uid, uid);
    });

    test('emits null khi doc không tồn tại', () async {
      final first = await repo.watchUserProfile(otherUid).first;
      expect(first, isNull);
    });

    test('emits update mới khi profile thay đổi', () async {
      final values = <String?>[];
      final sub =
          repo.watchUserProfile(uid).listen((p) => values.add(p?.displayName));

      await Future<void>.delayed(Duration.zero);
      await firestore.doc('users/$uid').update({'displayName': 'Updated'});
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(values, contains('Updated'));
    });
  });

  group('updateProfile — allowlist enforcement', () {
    test('throws ValidationError khi fields rỗng', () async {
      expect(
        () => repo.updateProfile(uid, const {}),
        throwsA(
          isA<ValidationError>()
              .having((e) => e.code, 'code', 'profile/empty-update'),
        ),
      );
    });

    test('throws ValidationError khi field ngoài allowlist (uid)', () async {
      expect(
        () => repo.updateProfile(uid, {'uid': 'hacker'}),
        throwsA(
          isA<ValidationError>()
              .having((e) => e.code, 'code', 'profile/field-not-allowed'),
        ),
      );
    });

    test('throws khi cố update server-only counter (postCount)', () async {
      expect(
        () => repo.updateProfile(uid, {'postCount': 999}),
        throwsA(isA<ValidationError>()),
      );
    });

    test('throws khi cố update username (server-only — dùng transaction)',
        () async {
      expect(
        () => repo.updateProfile(uid, {'username': 'newname'}),
        throwsA(isA<ValidationError>()),
      );
    });

    test('throws khi mix allowed + disallowed', () async {
      expect(
        () => repo.updateProfile(uid, {
          'displayName': 'OK',
          'email': 'new@x.com',
        }),
        throwsA(isA<ValidationError>()),
      );
    });

    test('cập nhật khi tất cả fields trong allowlist', () async {
      await repo.updateProfile(uid, {
        'displayName': 'Bob',
        'bio': 'New bio',
        'gender': 'other',
      });

      final updated = (await firestore.doc('users/$uid').get()).data()!;
      expect(updated['displayName'], 'Bob');
      expect(updated['bio'], 'New bio');
      expect(updated['gender'], 'other');
    });

    test('luôn set updatedAt khi update', () async {
      await repo.updateProfile(uid, {'displayName': 'Bob'});
      final updated = (await firestore.doc('users/$uid').get()).data()!;
      expect(updated['updatedAt'], isNotNull);
    });
  });

  group('updateAvatar', () {
    Future<File> createTempFile() async {
      final tmp = File(
        '${Directory.systemTemp.path}/avatar_${uid}_${DateTime.now().microsecondsSinceEpoch}.bin',
      );
      await tmp.writeAsBytes(const [1, 2, 3]);
      addTearDown(() async {
        if (await tmp.exists()) await tmp.delete();
      });
      return tmp;
    }

    test('throws ValidationError khi compressed > 5MB', () async {
      final file = await createTempFile();
      compressor.output = Uint8List(5 * 1024 * 1024 + 1);

      await expectLater(
        repo.updateAvatar(uid, file),
        throwsA(
          isA<ValidationError>()
              .having((e) => e.code, 'code', 'profile/avatar-too-large'),
        ),
      );
      expect(
        storage.uploadCount,
        0,
        reason: 'không được upload khi vượt size cap',
      );
    });

    test('cho phép exactly 5MB', () async {
      final file = await createTempFile();
      compressor.output = Uint8List(5 * 1024 * 1024);
      storage.urlToReturn = 'https://cdn/avatar.jpg';

      await repo.updateAvatar(uid, file);

      expect(storage.uploadCount, 1);
      expect(storage.lastBytes?.lengthInBytes, 5 * 1024 * 1024);
    });

    test('compress → upload → cập nhật avatarUrl khi compressed <= 5MB',
        () async {
      final file = await createTempFile();
      compressor.output = Uint8List.fromList(List.filled(2048, 0xAB));
      storage.urlToReturn = 'https://cdn/avatars/$uid/avatar.jpg';

      await repo.updateAvatar(uid, file);

      expect(compressor.calledWith?.path, file.path);
      expect(storage.lastUid, uid);
      expect(storage.lastBytes?.lengthInBytes, 2048);

      final updated = (await firestore.doc('users/$uid').get()).data()!;
      expect(updated['avatarUrl'], 'https://cdn/avatars/$uid/avatar.jpg');
      expect(updated['updatedAt'], isNotNull);
    });

    test('FirebaseException từ Storage → ForbiddenError khi unauthorized',
        () async {
      final file = await createTempFile();
      compressor.output = Uint8List(100);
      storage.exceptionToThrow =
          FirebaseException(plugin: 'storage', code: 'unauthorized');

      await expectLater(
        repo.updateAvatar(uid, file),
        throwsA(isA<ForbiddenError>()),
      );

      // Firestore KHÔNG được update khi upload fail
      final unchanged = (await firestore.doc('users/$uid').get()).data()!;
      expect(unchanged['avatarUrl'], isNull);
    });

    test('FirebaseException unavailable từ Storage → NetworkError', () async {
      final file = await createTempFile();
      compressor.output = Uint8List(100);
      storage.exceptionToThrow =
          FirebaseException(plugin: 'storage', code: 'unavailable');

      await expectLater(
        repo.updateAvatar(uid, file),
        throwsA(isA<NetworkError>()),
      );
    });
  });

  group('removeAvatar', () {
    test('set avatarUrl = null + updatedAt', () async {
      // Pre-set một avatarUrl
      await firestore.doc('users/$uid').update({
        'avatarUrl': 'https://cdn/old.jpg',
      });

      await repo.removeAvatar(uid);

      final updated = (await firestore.doc('users/$uid').get()).data()!;
      expect(updated['avatarUrl'], isNull);
      expect(updated['updatedAt'], isNotNull);
    });

    test('không xóa Storage file (orphan acceptable)', () async {
      await repo.removeAvatar(uid);
      // removeAvatar không gọi storageClient → storage.uploadCount remains 0
      expect(storage.uploadCount, 0);
    });
  });
}

class _StubStorageClient implements AvatarStorageClient {
  int uploadCount = 0;
  String? lastUid;
  Uint8List? lastBytes;
  String urlToReturn = 'https://stub/avatar.jpg';
  FirebaseException? exceptionToThrow;

  @override
  Future<String> upload({
    required String uid,
    required Uint8List bytes,
  }) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    uploadCount++;
    lastUid = uid;
    lastBytes = bytes;
    return urlToReturn;
  }
}

class _StubCompressor implements AvatarCompressor {
  _StubCompressor(this.output);

  Uint8List output;
  File? calledWith;

  @override
  Future<Uint8List> compress(File file) async {
    calledWith = file;
    return output;
  }
}
