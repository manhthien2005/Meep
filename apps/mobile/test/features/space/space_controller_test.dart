import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_repository.dart';

class MockSpaceRepository extends Mock implements SpaceRepository {}

Space _spaceFixture({
  required String spaceId,
  required String creatorId,
  List<String>? memberIds,
  String name = 'Space',
}) {
  return Space(
    spaceId: spaceId,
    name: name,
    iconEmoji: '👥',
    colorHex: '#00DEEE',
    creatorId: creatorId,
    memberCount: memberIds?.length ?? 1,
    memberIds: memberIds ?? [creatorId],
    createdAt: DateTime(2026, 6, 1),
  );
}

ProviderContainer _makeContainer({
  required SpaceRepository repo,
  String? currentUid,
}) {
  return ProviderContainer(
    overrides: [
      spaceRepositoryProvider.overrideWithValue(repo),
      currentUidProvider.overrideWith(
        (ref) => Stream.value(currentUid),
      ),
    ],
  );
}

void main() {
  late MockSpaceRepository repo;

  setUp(() {
    repo = MockSpaceRepository();
    // Default stream: empty list, no error
    when(() => repo.watchMySpaces(any())).thenAnswer(
      (_) => Stream.value(<Space>[]),
    );
  });

  group('build(uid) — stream subscription', () {
    test('subscribes watchMySpaces and updates state.spaces', () async {
      final spaces = [
        _spaceFixture(spaceId: 's1', creatorId: 'user1', name: 'Family'),
      ];
      when(() => repo.watchMySpaces('user1')).thenAnswer(
        (_) => Stream.value(spaces),
      );

      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});

      // Wait for stream emit
      await Future<void>.delayed(Duration.zero);

      final state = container.read(spaceControllerProvider('user1'));
      expect(state.spaces, hasLength(1));
      expect(state.spaces.first.spaceId, 's1');
      expect(state.errorMessage, isNull);
    });

    test('sets errorMessage when stream errors', () async {
      when(() => repo.watchMySpaces('user1')).thenAnswer(
        (_) => Stream.error(Exception('permission-denied')),
      );

      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});

      await Future<void>.delayed(Duration.zero);

      final state = container.read(spaceControllerProvider('user1'));
      expect(state.errorMessage, contains('Không thể tải danh sách Space'));
    });
  });

  group('createSpace — client-side validation', () {
    test('sets errorMessage when name is empty (trimmed)', () async {
      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});

      await container
          .read(spaceControllerProvider('user1').notifier)
          .createSpace(
        name: '   ',
        iconEmoji: '👥',
        colorHex: '#00DEEE',
        friendUids: ['friend1'],
      );

      expect(
        container.read(spaceControllerProvider('user1')).errorMessage,
        'Tên Space không được trống',
      );
      verifyNever(
        () => repo.createSpace(
          name: any(named: 'name'),
          iconEmoji: any(named: 'iconEmoji'),
          colorHex: any(named: 'colorHex'),
          friendUids: any(named: 'friendUids'),
        ),
      );
    });

    test('sets errorMessage when name exceeds 30 chars', () async {
      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});

      await container
          .read(spaceControllerProvider('user1').notifier)
          .createSpace(
        name: 'a' * 31,
        iconEmoji: '👥',
        colorHex: '#00DEEE',
        friendUids: ['friend1'],
      );

      expect(
        container.read(spaceControllerProvider('user1')).errorMessage,
        'Tên Space tối đa 30 ký tự',
      );
      verifyNever(
        () => repo.createSpace(
          name: any(named: 'name'),
          iconEmoji: any(named: 'iconEmoji'),
          colorHex: any(named: 'colorHex'),
          friendUids: any(named: 'friendUids'),
        ),
      );
    });

    test('sets errorMessage when friendUids < 2 (min 3 thành viên)', () async {
      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});

      await container
          .read(spaceControllerProvider('user1').notifier)
          .createSpace(
        name: 'Family',
        iconEmoji: '👥',
        colorHex: '#00DEEE',
        friendUids: ['friend1'], // 1 friend → 2 thành viên < 3
      );

      expect(
        container.read(spaceControllerProvider('user1')).errorMessage,
        contains('tối thiểu 3 thành viên'),
      );
      verifyNever(
        () => repo.createSpace(
          name: any(named: 'name'),
          iconEmoji: any(named: 'iconEmoji'),
          colorHex: any(named: 'colorHex'),
          friendUids: any(named: 'friendUids'),
        ),
      );
    });

    test('sets errorMessage when friendUids exceeds 9', () async {
      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});

      await container
          .read(spaceControllerProvider('user1').notifier)
          .createSpace(
            name: 'Family',
            iconEmoji: '👥',
            colorHex: '#00DEEE',
            friendUids: List.generate(10, (i) => 'friend$i'),
          );

      expect(
        container.read(spaceControllerProvider('user1')).errorMessage,
        contains('tối đa 10 người'),
      );
      verifyNever(
        () => repo.createSpace(
          name: any(named: 'name'),
          iconEmoji: any(named: 'iconEmoji'),
          colorHex: any(named: 'colorHex'),
          friendUids: any(named: 'friendUids'),
        ),
      );
    });

    test('delegates to repository with trimmed name on success', () async {
      when(
        () => repo.createSpace(
          name: any(named: 'name'),
          iconEmoji: any(named: 'iconEmoji'),
          colorHex: any(named: 'colorHex'),
          friendUids: any(named: 'friendUids'),
        ),
      ).thenAnswer((_) async => 'new-space-id');

      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});

      await container
          .read(spaceControllerProvider('user1').notifier)
          .createSpace(
        name: '  Family  ',
        iconEmoji: '👨‍👩‍👧‍👦',
        colorHex: '#BFD5FF',
        friendUids: ['friend1', 'friend2'],
      );

      verify(
        () => repo.createSpace(
          name: 'Family',
          iconEmoji: '👨‍👩‍👧‍👦',
          colorHex: '#BFD5FF',
          friendUids: ['friend1', 'friend2'],
        ),
      ).called(1);
      final state = container.read(spaceControllerProvider('user1'));
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('sets errorMessage when repo throws AppError', () async {
      when(
        () => repo.createSpace(
          name: any(named: 'name'),
          iconEmoji: any(named: 'iconEmoji'),
          colorHex: any(named: 'colorHex'),
          friendUids: any(named: 'friendUids'),
        ),
      ).thenThrow(const ValidationError(message: 'Server: friendUids invalid'));

      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});

      await container
          .read(spaceControllerProvider('user1').notifier)
          .createSpace(
        name: 'Family',
        iconEmoji: '👥',
        colorHex: '#00DEEE',
        // min 2 friends để pass client guard → trigger repo throw path.
        friendUids: ['friend1', 'friend2'],
      );

      final state = container.read(spaceControllerProvider('user1'));
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Server: friendUids invalid');
    });
  });

  group('leaveSpace — client-side guard', () {
    test('sets errorMessage when not signed in', () async {
      final container = _makeContainer(repo: repo, currentUid: null);
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});

      await container
          .read(spaceControllerProvider('user1').notifier)
          .leaveSpace('s1');

      expect(
        container.read(spaceControllerProvider('user1')).errorMessage,
        'Chưa đăng nhập',
      );
      verifyNever(() => repo.leaveSpace(any()));
    });

    test('blocks when current user is creator', () async {
      when(() => repo.watchMySpaces('user1')).thenAnswer(
        (_) => Stream.value([
          _spaceFixture(spaceId: 's1', creatorId: 'user1'),
        ]),
      );

      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});
      container.listen(currentUidProvider, (_, __) {});
      await container.read(currentUidProvider.future);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(spaceControllerProvider('user1').notifier)
          .leaveSpace('s1');

      expect(
        container.read(spaceControllerProvider('user1')).errorMessage,
        contains('Chọn người quản trị mới'),
      );
      verifyNever(() => repo.leaveSpace(any()));
    });

    test('delegates to repo when current user is non-creator', () async {
      when(() => repo.watchMySpaces('user2')).thenAnswer(
        (_) => Stream.value([
          _spaceFixture(
            spaceId: 's1',
            creatorId: 'user1',
            memberIds: ['user1', 'user2'],
          ),
        ]),
      );
      when(() => repo.leaveSpace(any())).thenAnswer((_) async {});

      final container = _makeContainer(repo: repo, currentUid: 'user2');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user2'), (_, __) {});
      container.listen(currentUidProvider, (_, __) {});
      await container.read(currentUidProvider.future);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(spaceControllerProvider('user2').notifier)
          .leaveSpace('s1');

      verify(() => repo.leaveSpace('s1')).called(1);
      expect(
        container.read(spaceControllerProvider('user2')).errorMessage,
        isNull,
      );
    });
  });

  group('deleteSpace — client-side guard', () {
    test('blocks non-creator with ForbiddenError message', () async {
      when(() => repo.watchMySpaces('user2')).thenAnswer(
        (_) => Stream.value([
          _spaceFixture(
            spaceId: 's1',
            creatorId: 'user1',
            memberIds: ['user1', 'user2'],
          ),
        ]),
      );

      final container = _makeContainer(repo: repo, currentUid: 'user2');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user2'), (_, __) {});
      container.listen(currentUidProvider, (_, __) {});
      await container.read(currentUidProvider.future);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(spaceControllerProvider('user2').notifier)
          .deleteSpace('s1');

      expect(
        container.read(spaceControllerProvider('user2')).errorMessage,
        contains('Chỉ creator'),
      );
      verifyNever(() => repo.deleteSpace(any()));
    });

    test('delegates to repo when current user is creator', () async {
      when(() => repo.watchMySpaces('user1')).thenAnswer(
        (_) => Stream.value([
          _spaceFixture(spaceId: 's1', creatorId: 'user1'),
        ]),
      );
      when(() => repo.deleteSpace(any())).thenAnswer((_) async {});

      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});
      container.listen(currentUidProvider, (_, __) {});
      await container.read(currentUidProvider.future);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(spaceControllerProvider('user1').notifier)
          .deleteSpace('s1');

      verify(() => repo.deleteSpace('s1')).called(1);
    });
  });

  group('kickMember', () {
    test('delegates to repo with named args', () async {
      when(
        () => repo.kickMember(
          spaceId: any(named: 'spaceId'),
          targetUid: any(named: 'targetUid'),
        ),
      ).thenAnswer((_) async {});

      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});

      await container
          .read(spaceControllerProvider('user1').notifier)
          .kickMember('s1', 'user2');

      verify(
        () => repo.kickMember(spaceId: 's1', targetUid: 'user2'),
      ).called(1);
    });

    test('sets errorMessage on repo failure', () async {
      when(
        () => repo.kickMember(
          spaceId: any(named: 'spaceId'),
          targetUid: any(named: 'targetUid'),
        ),
      ).thenThrow(ForbiddenError('xoá thành viên'));

      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});

      await container
          .read(spaceControllerProvider('user1').notifier)
          .kickMember('s1', 'user2');

      expect(
        container.read(spaceControllerProvider('user1')).errorMessage,
        contains('Not allowed to xoá thành viên'),
      );
    });
  });

  group('transferOwnership', () {
    test('delegates to repo with named args', () async {
      when(
        () => repo.transferOwnership(
          spaceId: any(named: 'spaceId'),
          newCreatorUid: any(named: 'newCreatorUid'),
        ),
      ).thenAnswer((_) async {});

      final container = _makeContainer(repo: repo, currentUid: 'user1');
      addTearDown(container.dispose);
      container.listen(spaceControllerProvider('user1'), (_, __) {});

      await container
          .read(spaceControllerProvider('user1').notifier)
          .transferOwnership('s1', 'user2');

      verify(
        () => repo.transferOwnership(spaceId: 's1', newCreatorUid: 'user2'),
      ).called(1);
    });
  });
}
