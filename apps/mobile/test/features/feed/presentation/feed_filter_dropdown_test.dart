import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/feed/presentation/feed_filter_dropdown.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/application/friend_state.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';

UserProfile _profile({
  String uid = 'me',
  String displayName = 'Khoa',
  String? avatarUrl,
}) =>
    UserProfile(
      uid: uid,
      email: '$uid@meep.io',
      displayName: displayName,
      username: displayName.toLowerCase(),
      avatarUrl: avatarUrl,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

PublicProfile _publicProfile({
  String uid = 'friend',
  String displayName = 'Han',
  String? avatarUrl,
}) =>
    PublicProfile(
      uid: uid,
      displayName: displayName,
      username: displayName.toLowerCase(),
      avatarUrl: avatarUrl,
      updatedAt: DateTime(2026),
    );

Space _space({
  required String spaceId,
  required String name,
  String colorHex = '#FF5733',
}) =>
    Space(
      spaceId: spaceId,
      name: name,
      iconEmoji: '🏠',
      colorHex: colorHex,
      creatorId: 'me',
      memberCount: 3,
      memberIds: const ['me', 'f1', 'f2'],
      createdAt: DateTime(2026),
    );

Future<void> _pump(
  WidgetTester tester, {
  required String currentUid,
  required String selectedLabel,
  required void Function(String?, String) onFilterSelected,
  required void Function(Space) onSpaceFilterSelected,
  List<PublicProfile> friends = const [],
  List<Space> spaces = const [],
  UserProfile? currentProfile,
}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUidProvider.overrideWith((ref) => Stream.value(currentUid)),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(currentProfile),
        ),
        friendControllerProvider(currentUid).overrideWith(
          () => _FakeFriendController(FriendState(friends: friends)),
        ),
        spaceControllerProvider(currentUid).overrideWith(
          () => _FakeSpaceController(SpaceState(spaces: spaces)),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: FeedFilterDropdown(
            currentUid: currentUid,
            selectedLabel: selectedLabel,
            onFilterSelected: onFilterSelected,
            onSpaceFilterSelected: onSpaceFilterSelected,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeFriendController extends FriendController {
  _FakeFriendController(this._state);
  final FriendState _state;
  @override
  FriendState build(String uid) => _state;
}

class _FakeSpaceController extends SpaceController {
  _FakeSpaceController(this._state);
  final SpaceState _state;
  @override
  SpaceState build(String uid) => _state;
}

void main() {
  group('FeedFilterDropdown', () {
    testWidgets('renders "Mọi người" và "Bạn" rows mặc định', (tester) async {
      await _pump(
        tester,
        currentUid: 'me',
        selectedLabel: 'Mọi người',
        onFilterSelected: (_, __) {},
        onSpaceFilterSelected: (_) {},
        currentProfile: _profile(),
      );
      expect(find.text('Mọi người'), findsOneWidget);
      expect(find.text('Bạn'), findsOneWidget);
      expect(find.text('SPACES'), findsNothing);
    });

    testWidgets('renders friend rows khi friendController có friends',
        (tester) async {
      await _pump(
        tester,
        currentUid: 'me',
        selectedLabel: 'Mọi người',
        onFilterSelected: (_, __) {},
        onSpaceFilterSelected: (_) {},
        currentProfile: _profile(),
        friends: [_publicProfile(uid: 'f1', displayName: 'Han')],
      );
      expect(find.text('Han'), findsOneWidget);
    });

    testWidgets('renders SPACES header + rows khi user có spaces',
        (tester) async {
      await _pump(
        tester,
        currentUid: 'me',
        selectedLabel: 'Mọi người',
        onFilterSelected: (_, __) {},
        onSpaceFilterSelected: (_) {},
        currentProfile: _profile(),
        spaces: [_space(spaceId: 's1', name: 'Family')],
      );
      expect(find.text('SPACES'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
    });

    testWidgets('tap "Mọi người" gọi onFilterSelected(null, "Mọi người")',
        (tester) async {
      String? capturedUid = 'unset';
      String? capturedLabel;
      await _pump(
        tester,
        currentUid: 'me',
        selectedLabel: 'Khoa',
        onFilterSelected: (uid, label) {
          capturedUid = uid;
          capturedLabel = label;
        },
        onSpaceFilterSelected: (_) {},
        currentProfile: _profile(),
      );
      await tester.tap(find.text('Mọi người'));
      await tester.pumpAndSettle();
      expect(capturedUid, isNull);
      expect(capturedLabel, 'Mọi người');
    });

    testWidgets('tap "Bạn" gọi onFilterSelected(currentUid, "Bạn")',
        (tester) async {
      String? capturedUid;
      String? capturedLabel;
      await _pump(
        tester,
        currentUid: 'me',
        selectedLabel: 'Mọi người',
        onFilterSelected: (uid, label) {
          capturedUid = uid;
          capturedLabel = label;
        },
        onSpaceFilterSelected: (_) {},
        currentProfile: _profile(),
      );
      await tester.tap(find.text('Bạn'));
      await tester.pumpAndSettle();
      expect(capturedUid, 'me');
      expect(capturedLabel, 'Bạn');
    });

    testWidgets('tap space row gọi onSpaceFilterSelected(space)',
        (tester) async {
      Space? captured;
      await _pump(
        tester,
        currentUid: 'me',
        selectedLabel: 'Mọi người',
        onFilterSelected: (_, __) {},
        onSpaceFilterSelected: (s) => captured = s,
        currentProfile: _profile(),
        spaces: [_space(spaceId: 's1', name: 'Family')],
      );
      await tester.tap(find.text('Family'));
      await tester.pumpAndSettle();
      expect(captured?.spaceId, 's1');
    });
  });
}
