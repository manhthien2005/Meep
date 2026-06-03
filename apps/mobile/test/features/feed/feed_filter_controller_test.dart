import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/feed/application/feed_filter_controller.dart';
import 'package:meep/features/space/data/space.dart';

Space _spaceFixture({
  String spaceId = 's1',
  String name = 'Family',
  String colorHex = '#00DEEE',
}) =>
    Space(
      spaceId: spaceId,
      name: name,
      iconEmoji: '👥',
      colorHex: colorHex,
      creatorId: 'creator-uid',
      memberCount: 1,
      memberIds: const ['creator-uid'],
      createdAt: DateTime(2026, 6, 1),
    );

ProviderContainer _makeContainer({String? currentUid = 'user1'}) {
  return ProviderContainer(
    overrides: [
      currentUidProvider.overrideWith((ref) => Stream.value(currentUid)),
    ],
  );
}

void main() {
  group('FeedFilterController', () {
    test('build() returns empty selection labelled "Mọi người"', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final state = container.read(feedFilterControllerProvider);
      expect(state.authorUid, isNull);
      expect(state.spaceId, isNull);
      expect(state.label, 'Mọi người');
    });

    test('selectAuthor(uid, label) sets author, clears space', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(feedFilterControllerProvider.notifier);
      notifier.selectSpace(_spaceFixture()); // pre-condition: space set
      expect(
        container.read(feedFilterControllerProvider).spaceId,
        's1',
      );

      notifier.selectAuthor('friend-uid', 'Khoa');

      final state = container.read(feedFilterControllerProvider);
      expect(state.authorUid, 'friend-uid');
      expect(state.spaceId, isNull);
      expect(state.label, 'Khoa');
    });

    test('selectAll() resets cả author và space', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(feedFilterControllerProvider.notifier);
      notifier.selectAuthor('friend-uid', 'Khoa');
      notifier.selectAll();

      final state = container.read(feedFilterControllerProvider);
      expect(state.authorUid, isNull);
      expect(state.spaceId, isNull);
      expect(state.label, 'Mọi người');
    });

    test('selectSpace(space) sets space, clears author', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(feedFilterControllerProvider.notifier);
      notifier.selectAuthor('friend-uid', 'Khoa'); // pre-condition

      notifier.selectSpace(_spaceFixture(spaceId: 's2', name: 'Roommates'));

      final state = container.read(feedFilterControllerProvider);
      expect(state.spaceId, 's2');
      expect(state.authorUid, isNull);
      expect(state.label, 'Roommates');
    });

    test(
      'seedFromRoute deeplink overrides current state regardless',
      () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        final notifier = container.read(feedFilterControllerProvider.notifier);
        notifier.selectAuthor('friend-uid', 'Khoa');

        notifier.seedFromRoute(
          spaceId: 'deeplink-space',
          label: 'Deep Space',
        );

        final state = container.read(feedFilterControllerProvider);
        expect(state.spaceId, 'deeplink-space');
        expect(state.authorUid, isNull);
        expect(state.label, 'Deep Space');
      },
    );

    test('state persists across re-reads (keepAlive)', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container
          .read(feedFilterControllerProvider.notifier)
          .selectAuthor('friend-uid', 'Khoa');

      // Re-read same provider — state must persist (keepAlive: true).
      await Future<void>.delayed(Duration.zero);
      final state = container.read(feedFilterControllerProvider);
      expect(state.authorUid, 'friend-uid');
      expect(state.label, 'Khoa');
    });

    test('state resets to empty when currentUid changes', () async {
      // Start signed in as user1, set a filter, then switch to user2.
      // build() listens to currentUidProvider — change must wipe selection.
      final uidController = StreamController<String?>();
      addTearDown(uidController.close);
      final container = ProviderContainer(
        overrides: [
          currentUidProvider.overrideWith((ref) => uidController.stream),
        ],
      );
      addTearDown(container.dispose);

      uidController.add('user1');
      await Future<void>.delayed(Duration.zero);
      // Realize provider so build() runs and listens.
      container.read(feedFilterControllerProvider);
      container
          .read(feedFilterControllerProvider.notifier)
          .selectAuthor('friend-uid', 'Khoa');
      expect(
        container.read(feedFilterControllerProvider).authorUid,
        'friend-uid',
      );

      uidController.add('user2');
      await Future<void>.delayed(Duration.zero);
      final state = container.read(feedFilterControllerProvider);
      expect(state.authorUid, isNull);
      expect(state.spaceId, isNull);
      expect(state.label, 'Mọi người');
    });
  });
}
