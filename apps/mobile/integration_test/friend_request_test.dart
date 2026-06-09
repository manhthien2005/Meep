import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:meep/features/friend/application/friend_controller.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('friend request search sends one idempotent pending request',
      (tester) async {
    final bob = testPublicProfile(
      uid: 'uid-bob',
      displayName: 'Bob Tran',
      username: 'bob',
    );
    final harness = await MeepIntegrationHarness.create(
      signedInProfile: testUserProfile(),
      publicProfiles: [bob],
    );
    addTearDown(harness.dispose);

    final controller =
        harness.container.read(friendControllerProvider('uid-me').notifier);
    await tester.pump();

    await controller.searchUser('bob');
    await tester.pump(const Duration(milliseconds: 600));

    final searched =
        harness.container.read(friendControllerProvider('uid-me')).searchResult;
    expect(searched?.uid, 'uid-bob');

    await controller.sendFriendRequest('uid-bob');
    await tester.pump();
    await controller.sendFriendRequest('uid-bob');
    await tester.pump();

    expect(harness.friendRequests.sentFrom('uid-me'), hasLength(1));
    expect(
      harness.container
          .read(friendControllerProvider('uid-me'))
          .sentRequests
          .map((request) => request.receiverId),
      ['uid-bob'],
    );
  });
}
