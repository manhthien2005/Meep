import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/core/config/app_config.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/auth/data/user_repository.dart';
import 'package:meep/features/profile/application/profile_controller.dart';
import 'package:meep/features/profile/data/profile_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _FakeFile extends Fake implements File {}

void main() {
  const uid = 'uid-alice';

  final profile = UserProfile(
    uid: uid,
    email: 'alice@example.com',
    displayName: 'Alice',
    username: 'alice',
    avatarUrl: 'https://cdn/old.jpg',
    bio: 'old bio',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  late _MockProfileRepository profileRepo;
  late _MockUserRepository userRepo;
  late StreamController<UserProfile?> profileStreamCtrl;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(_FakeFile());
  });

  setUp(() {
    profileRepo = _MockProfileRepository();
    userRepo = _MockUserRepository();
    profileStreamCtrl = StreamController<UserProfile?>.broadcast();
    when(() => profileRepo.watchUserProfile(uid))
        .thenAnswer((_) => profileStreamCtrl.stream);
  });

  tearDown(() async {
    await profileStreamCtrl.close();
  });

  /// Keep provider alive across `c.read` calls — without an active listener,
  /// autoDispose providers tear down between reads and lose the stream sub.
  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(profileRepo),
        userRepositoryProvider.overrideWithValue(userRepo),
      ],
    );
    final sub = c.listen(profileControllerProvider(uid), (_, __) {});
    addTearDown(sub.close);
    addTearDown(c.dispose);
    return c;
  }

  group('build + watchUserProfile', () {
    test('initial state: isLoading=true', () {
      final c = makeContainer();
      final state = c.read(profileControllerProvider(uid));
      expect(state.isLoading, isTrue);
      expect(state.profile, isNull);
    });

    test('stream emit → state.profile updated, isLoading=false', () async {
      final c = makeContainer();
      c.read(profileControllerProvider(uid)); // trigger build + subscribe
      await Future<void>.delayed(Duration.zero); // let listen() resolve

      profileStreamCtrl.add(profile);
      await Future<void>.delayed(Duration.zero);

      final state = c.read(profileControllerProvider(uid));
      expect(state.isLoading, isFalse);
      expect(state.profile?.uid, uid);
      expect(state.profile?.displayName, 'Alice');
    });

    test('stream emit lần 2 → state cập nhật theo update mới', () async {
      final c = makeContainer();
      c.read(profileControllerProvider(uid));
      await Future<void>.delayed(Duration.zero);

      profileStreamCtrl.add(profile);
      await Future<void>.delayed(Duration.zero);
      profileStreamCtrl.add(profile.copyWith(displayName: 'Alice Updated'));
      await Future<void>.delayed(Duration.zero);

      final state = c.read(profileControllerProvider(uid));
      expect(state.profile?.displayName, 'Alice Updated');
    });

    test('stream error → errorMessage set', () async {
      final c = makeContainer();
      c.read(profileControllerProvider(uid));
      await Future<void>.delayed(Duration.zero);

      profileStreamCtrl.addError(
        const NetworkError(message: 'Mất mạng'),
      );
      await Future<void>.delayed(Duration.zero);

      final state = c.read(profileControllerProvider(uid));
      expect(state.errorMessage, 'Mất mạng');
      expect(state.isLoading, isFalse);
    });
  });

  group('clearError', () {
    test('xóa errorMessage', () async {
      final c = makeContainer();
      c.read(profileControllerProvider(uid));
      profileStreamCtrl.addError(const NetworkError(message: 'err'));
      await Future<void>.delayed(Duration.zero);

      c.read(profileControllerProvider(uid).notifier).clearError();
      expect(
        c.read(profileControllerProvider(uid)).errorMessage,
        isNull,
      );
    });
  });

  group('updateField — bio validation', () {
    test('bio > 150 chars → errorMessage, KHÔNG gọi repository', () async {
      final c = makeContainer();
      c.read(profileControllerProvider(uid));

      await c
          .read(profileControllerProvider(uid).notifier)
          .updateField('bio', 'x' * 151);

      expect(
        c.read(profileControllerProvider(uid)).errorMessage,
        contains('150'),
      );
      verifyNever(() => profileRepo.updateProfile(any(), any()));
    });

    test('bio = exactly 150 → repository được gọi', () async {
      when(() => profileRepo.updateProfile(uid, any()))
          .thenAnswer((_) async {});
      final c = makeContainer();
      c.read(profileControllerProvider(uid));

      await c
          .read(profileControllerProvider(uid).notifier)
          .updateField('bio', 'x' * 150);

      verify(() => profileRepo.updateProfile(uid, {'bio': 'x' * 150}))
          .called(1);
    });

    test('field khác bio → bypass length check', () async {
      when(() => profileRepo.updateProfile(uid, any()))
          .thenAnswer((_) async {});
      final c = makeContainer();
      c.read(profileControllerProvider(uid));

      await c
          .read(profileControllerProvider(uid).notifier)
          .updateField('displayName', 'A very long name ' * 20);

      verify(() => profileRepo.updateProfile(uid, any())).called(1);
    });
  });

  group('updateProfile', () {
    test('success → isSaving=false, no error', () async {
      when(() => profileRepo.updateProfile(uid, any()))
          .thenAnswer((_) async {});
      final c = makeContainer();
      c.read(profileControllerProvider(uid));

      await c
          .read(profileControllerProvider(uid).notifier)
          .updateProfile({'displayName': 'Bob'});

      final state = c.read(profileControllerProvider(uid));
      expect(state.isSaving, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('AppError → errorMessage set, isSaving=false', () async {
      when(() => profileRepo.updateProfile(uid, any())).thenThrow(
        const ValidationError(message: 'Field không hợp lệ'),
      );
      final c = makeContainer();
      c.read(profileControllerProvider(uid));

      await c
          .read(profileControllerProvider(uid).notifier)
          .updateProfile({'bio': 'x'});

      final state = c.read(profileControllerProvider(uid));
      expect(state.errorMessage, 'Field không hợp lệ');
      expect(state.isSaving, isFalse);
    });
  });

  group('updateAvatar', () {
    test('success → isSaving=false', () async {
      when(() => profileRepo.updateAvatar(uid, any())).thenAnswer((_) async {});
      final c = makeContainer();
      c.read(profileControllerProvider(uid));
      await Future<void>.delayed(Duration.zero);
      profileStreamCtrl.add(profile);
      await Future<void>.delayed(Duration.zero);

      await c
          .read(profileControllerProvider(uid).notifier)
          .updateAvatar(_FakeFile());

      final state = c.read(profileControllerProvider(uid));
      expect(state.isSaving, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('fail → giữ avatarUrl cũ + errorMessage', () async {
      // Acceptance: avatar upload fail → rollback state.profile.avatarUrl.
      // Controller không optimistic-update trước upload — state.profile
      // mirror Firestore qua watch stream. Khi upload throw, errorMessage
      // set và avatarUrl giữ giá trị cũ ('https://cdn/old.jpg').
      when(() => profileRepo.updateAvatar(uid, any())).thenThrow(
        const NetworkError(message: 'Mạng yếu'),
      );
      final c = makeContainer();
      c.read(profileControllerProvider(uid));
      await Future<void>.delayed(Duration.zero);
      profileStreamCtrl.add(profile);
      await Future<void>.delayed(Duration.zero);

      await c
          .read(profileControllerProvider(uid).notifier)
          .updateAvatar(_FakeFile());

      final state = c.read(profileControllerProvider(uid));
      expect(state.errorMessage, 'Mạng yếu');
      expect(
        state.profile?.avatarUrl,
        'https://cdn/old.jpg',
        reason: 'phải giữ URL cũ',
      );
    });
  });

  group('removeAvatar', () {
    test('success', () async {
      when(() => profileRepo.removeAvatar(uid)).thenAnswer((_) async {});
      final c = makeContainer();
      c.read(profileControllerProvider(uid));

      await c.read(profileControllerProvider(uid).notifier).removeAvatar();

      verify(() => profileRepo.removeAvatar(uid)).called(1);
      expect(c.read(profileControllerProvider(uid)).errorMessage, isNull);
    });

    test('fail → errorMessage', () async {
      when(() => profileRepo.removeAvatar(uid)).thenThrow(
        const NetworkError(message: 'Mạng yếu'),
      );
      final c = makeContainer();
      c.read(profileControllerProvider(uid));

      await c.read(profileControllerProvider(uid).notifier).removeAvatar();

      expect(c.read(profileControllerProvider(uid)).errorMessage, 'Mạng yếu');
    });
  });

  group('isUsernameAvailable — delegate UserRepository', () {
    test('returns true khi UserRepository trả true', () async {
      when(() => userRepo.isUsernameAvailable('newname'))
          .thenAnswer((_) async => true);
      final c = makeContainer();
      c.read(profileControllerProvider(uid));

      final available = await c
          .read(profileControllerProvider(uid).notifier)
          .isUsernameAvailable('newname');

      expect(available, isTrue);
      verify(() => userRepo.isUsernameAvailable('newname')).called(1);
      verifyNever(() => profileRepo.updateProfile(any(), any()));
    });

    test('returns false khi UserRepository trả false', () async {
      when(() => userRepo.isUsernameAvailable('taken'))
          .thenAnswer((_) async => false);
      final c = makeContainer();
      c.read(profileControllerProvider(uid));

      final available = await c
          .read(profileControllerProvider(uid).notifier)
          .isUsernameAvailable('taken');

      expect(available, isFalse);
    });

    test('UserRepository throw → returns false + errorMessage', () async {
      when(() => userRepo.isUsernameAvailable(any())).thenThrow(
        const NetworkError(message: 'Mạng yếu'),
      );
      final c = makeContainer();
      c.read(profileControllerProvider(uid));

      final available = await c
          .read(profileControllerProvider(uid).notifier)
          .isUsernameAvailable('anything');

      expect(available, isFalse);
      expect(
        c.read(profileControllerProvider(uid)).errorMessage,
        'Mạng yếu',
      );
    });
  });

  group('shareProfileUrl', () {
    test('= AppConfig.shareBaseUrl/{username}', () {
      final c = makeContainer();
      final url = c
          .read(profileControllerProvider(uid).notifier)
          .shareProfileUrl('alice');
      expect(url, '${AppConfig.shareBaseUrl}/alice');
    });
  });
}
