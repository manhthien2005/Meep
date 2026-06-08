import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/core/utils/pair_id.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/data/friend_repository.dart';
import 'package:meep/features/friend/data/friend_request.dart';
import 'package:meep/features/friend/data/friend_request_repository.dart';

class MockFriendRepository extends Mock implements FriendRepository {}

class MockFriendRequestRepository extends Mock
    implements FriendRequestRepository {}

void main() {
  late MockFriendRepository friendRepo;
  late MockFriendRequestRepository requestRepo;

  setUp(() {
    friendRepo = MockFriendRepository();
    requestRepo = MockFriendRequestRepository();

    // Setup default streams
    when(() => friendRepo.watchFriends(any())).thenAnswer(
      (_) => Stream.value(<PublicProfile>[]),
    );
    when(() => requestRepo.watchPendingRequests(any())).thenAnswer(
      (_) => Stream.value(<FriendRequest>[]),
    );
    when(() => requestRepo.watchSentRequests(any())).thenAnswer(
      (_) => Stream.value(<FriendRequest>[]),
    );
  });

  group('FriendController', () {
    test('searchUser debounces 500ms - only calls repo once', () async {
      // Arrange
      when(() => friendRepo.searchUser(any())).thenAnswer(
        (_) async => _publicProfile(uid: 'user1', name: 'Test User'),
      );

      final container = ProviderContainer(
        overrides: [
          friendRepositoryProvider.overrideWithValue(friendRepo),
          friendRequestRepositoryProvider.overrideWithValue(requestRepo),
          currentUidProvider.overrideWith(
            (ref) => Stream.value('currentUser'),
          ),
        ],
      );
      // Keep the autoDispose provider alive so the debounce timer survives
      // until it fires (disposal would cancel it before the 500ms elapse).
      container.listen(friendControllerProvider('user1'), (_, __) {});

      final controller =
          container.read(friendControllerProvider('user1').notifier);

      // Act: call searchUser multiple times within 500ms (fire and forget)
      unawaited(controller.searchUser('test'));
      unawaited(controller.searchUser('testu'));
      unawaited(controller.searchUser('testus'));
      unawaited(controller.searchUser('testuser'));

      // Wait for debounce
      await Future<void>.delayed(const Duration(milliseconds: 600));

      // Assert: repo.searchUser called only once with final query
      verify(() => friendRepo.searchUser('testuser')).called(1);

      container.dispose();
    });

    test('searchUser clears result when query is empty', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          friendRepositoryProvider.overrideWithValue(friendRepo),
          friendRequestRepositoryProvider.overrideWithValue(requestRepo),
          currentUidProvider.overrideWith(
            (ref) => Stream.value('currentUser'),
          ),
        ],
      );

      final controller =
          container.read(friendControllerProvider('user1').notifier);

      // Act
      await controller.searchUser('');

      // Assert
      final state = container.read(friendControllerProvider('user1'));
      expect(state.searchResult, isNull);
      expect(state.searchQuery, '');
      verifyNever(() => friendRepo.searchUser(any()));

      container.dispose();
    });

    test('acceptFriendRequest handles max 20 friends error', () async {
      // Arrange
      when(() => requestRepo.acceptFriendRequest(any())).thenThrow(
        Exception('FAILED_PRECONDITION: max 20 friends'),
      );

      final container = ProviderContainer(
        overrides: [
          friendRepositoryProvider.overrideWithValue(friendRepo),
          friendRequestRepositoryProvider.overrideWithValue(requestRepo),
          currentUidProvider.overrideWith(
            (ref) => Stream.value('currentUser'),
          ),
        ],
      );

      final controller =
          container.read(friendControllerProvider('user1').notifier);

      // Act
      await controller.acceptFriendRequest('request123');

      // Assert
      final state = container.read(friendControllerProvider('user1'));
      expect(state.errorMessage, contains('20 bạn bè'));
      expect(state.isLoading, false);

      container.dispose();
    });

    test('acceptFriendRequest handles generic error', () async {
      // Arrange
      when(() => requestRepo.acceptFriendRequest(any())).thenThrow(
        Exception('Network error'),
      );

      final container = ProviderContainer(
        overrides: [
          friendRepositoryProvider.overrideWithValue(friendRepo),
          friendRequestRepositoryProvider.overrideWithValue(requestRepo),
          currentUidProvider.overrideWith(
            (ref) => Stream.value('currentUser'),
          ),
        ],
      );

      final controller =
          container.read(friendControllerProvider('user1').notifier);

      // Act
      await controller.acceptFriendRequest('request123');

      // Assert
      final state = container.read(friendControllerProvider('user1'));
      expect(state.errorMessage, contains('Không thể chấp nhận'));
      expect(state.isLoading, false);

      container.dispose();
    });

    test('sendFriendRequest calls repository with correct params', () async {
      // Arrange
      when(
        () => requestRepo.sendFriendRequest(
          senderUid: any(named: 'senderUid'),
          receiverUid: any(named: 'receiverUid'),
        ),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          friendRepositoryProvider.overrideWithValue(friendRepo),
          friendRequestRepositoryProvider.overrideWithValue(requestRepo),
          currentUidProvider.overrideWith(
            (ref) => Stream.value('currentUser'),
          ),
        ],
      );
      // Keep alive + resolve currentUid — sendFriendRequest reads it via
      // ref.read(currentUidProvider).valueOrNull.
      container.listen(friendControllerProvider('user1'), (_, __) {});
      container.listen(currentUidProvider, (_, __) {});
      await container.read(currentUidProvider.future);

      final controller =
          container.read(friendControllerProvider('user1').notifier);

      // Act
      await controller.sendFriendRequest('receiver123');

      // Assert
      verify(
        () => requestRepo.sendFriendRequest(
          senderUid: 'currentUser',
          receiverUid: 'receiver123',
        ),
      ).called(1);

      container.dispose();
    });

    test('cancelFriendRequest calls repository', () async {
      // Arrange
      when(() => requestRepo.cancelFriendRequest(any()))
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          friendRepositoryProvider.overrideWithValue(friendRepo),
          friendRequestRepositoryProvider.overrideWithValue(requestRepo),
          currentUidProvider.overrideWith(
            (ref) => Stream.value('currentUser'),
          ),
        ],
      );

      final controller =
          container.read(friendControllerProvider('user1').notifier);

      // Act
      await controller.cancelFriendRequest('request123');

      // Assert
      verify(() => requestRepo.cancelFriendRequest('request123')).called(1);

      container.dispose();
    });

    test('declineFriendRequest calls repository', () async {
      // Arrange
      when(() => requestRepo.declineFriendRequest(any()))
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          friendRepositoryProvider.overrideWithValue(friendRepo),
          friendRequestRepositoryProvider.overrideWithValue(requestRepo),
          currentUidProvider.overrideWith(
            (ref) => Stream.value('currentUser'),
          ),
        ],
      );

      final controller =
          container.read(friendControllerProvider('user1').notifier);

      // Act
      await controller.declineFriendRequest('request123');

      // Assert
      verify(() => requestRepo.declineFriendRequest('request123')).called(1);

      container.dispose();
    });

    test(
        'unfriend deletes friendship by pairId and drops friend optimistically',
        () async {
      final friend = _publicProfile(uid: 'friendX', name: 'Friend X');
      when(() => friendRepo.watchFriends(any())).thenAnswer(
        (_) => Stream.value([friend]),
      );
      when(() => friendRepo.unfriend(any())).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          friendRepositoryProvider.overrideWithValue(friendRepo),
          friendRequestRepositoryProvider.overrideWithValue(requestRepo),
          currentUidProvider.overrideWith(
            (ref) => Stream.value('currentUser'),
          ),
        ],
      );

      // Keep the autoDispose provider alive so the watchFriends stream stays
      // subscribed (otherwise it disposes mid-test and the seed is lost).
      container.listen(friendControllerProvider('user1'), (_, __) {});
      // unfriend() reads currentUid via ref.read; keep it alive + resolve the
      // stream so it isn't AsyncLoading (valueOrNull == null) when unfriend runs.
      container.listen(currentUidProvider, (_, __) {});
      await container.read(currentUidProvider.future);
      final controller =
          container.read(friendControllerProvider('user1').notifier);
      // Let watchFriends emit the seeded friend into state.
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(friendControllerProvider('user1')).friends,
        [friend],
      );

      await controller.unfriend('friendX');

      verify(
        () => friendRepo.unfriend(pairIdOf('currentUser', 'friendX')),
      ).called(1);
      expect(
        container.read(friendControllerProvider('user1')).friends,
        isEmpty,
      );

      container.dispose();
    });

    test('unfriend reverts the friend list when the repository throws',
        () async {
      final friend = _publicProfile(uid: 'friendX', name: 'Friend X');
      when(() => friendRepo.watchFriends(any())).thenAnswer(
        (_) => Stream.value([friend]),
      );
      when(() => friendRepo.unfriend(any())).thenThrow(Exception('boom'));

      final container = ProviderContainer(
        overrides: [
          friendRepositoryProvider.overrideWithValue(friendRepo),
          friendRequestRepositoryProvider.overrideWithValue(requestRepo),
          currentUidProvider.overrideWith(
            (ref) => Stream.value('currentUser'),
          ),
        ],
      );

      // Keep the autoDispose provider alive so the watchFriends stream stays
      // subscribed (otherwise it disposes mid-test and the seed is lost).
      container.listen(friendControllerProvider('user1'), (_, __) {});
      container.listen(currentUidProvider, (_, __) {});
      await container.read(currentUidProvider.future);
      final controller =
          container.read(friendControllerProvider('user1').notifier);
      await Future<void>.delayed(Duration.zero);

      await controller.unfriend('friendX');

      final state = container.read(friendControllerProvider('user1'));
      expect(state.friends, [friend]);
      expect(state.errorMessage, contains('Không thể xóa bạn'));

      container.dispose();
    });
  });
}

PublicProfile _publicProfile({required String uid, required String name}) {
  return PublicProfile(
    uid: uid,
    displayName: name,
    username: uid.toLowerCase(),
    updatedAt: DateTime.now(),
  );
}
