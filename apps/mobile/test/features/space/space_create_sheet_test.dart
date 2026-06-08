import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/data/friend_repository.dart';
import 'package:meep/features/space/presentation/space_create_sheet.dart';

class _FakeFriendRepository implements FriendRepository {
  final List<PublicProfile> _friends;

  _FakeFriendRepository(this._friends);

  @override
  Stream<List<PublicProfile>> watchFriends(String uid) =>
      Stream.value(_friends);

  @override
  Future<PublicProfile?> searchUser(String username) async =>
      _friends.where((f) => f.username == username).firstOrNull;

  @override
  Future<List<String>> getFriendUids(String uid) async =>
      _friends.map((f) => f.uid).toList();

  @override
  Future<void> unfriend(String pairId) async {}
}

void main() {
  group('SpaceCreateSheet scaffold', () {
    final mockFriends = List.generate(
      3,
      (i) => PublicProfile(
        uid: 'uid-$i',
        displayName: 'User $i',
        username: 'user$i',
        updatedAt: DateTime.now(),
      ),
    );

    Widget buildSheet() {
      return ProviderScope(
        overrides: [
          friendRepositoryProvider.overrideWithValue(
            _FakeFriendRepository(mockFriends),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SpaceCreateSheet()),
        ),
      );
    }

    testWidgets('renders with 3 steps', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      // Sheet hiện
      expect(find.byType(SpaceCreateSheet), findsOneWidget);

      // Step 1 title
      expect(find.text('Thêm Space mới'), findsOneWidget);
    });

    testWidgets('shows continue button on step 1', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      // Step 1 hiện
      expect(find.text('Thêm Space mới'), findsOneWidget);

      // Nút "Tiếp tục" hiện (AppPrimaryButton)
      expect(find.text('Tiếp tục'), findsOneWidget);
    });
  });
}
