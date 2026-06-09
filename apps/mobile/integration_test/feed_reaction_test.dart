import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/reaction/application/reaction_controller.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('feed emits friend post and reaction toggles optimistically',
      (tester) async {
    final harness = await MeepIntegrationHarness.create(
      signedInProfile: testUserProfile(),
    );
    addTearDown(harness.dispose);

    harness.posts.seedPost(
      testPost(
        postId: 'post-friend',
        authorId: 'uid-friend',
        authorName: 'Bob Tran',
      ),
    );

    final feedState = await harness.container.read(
      feedControllerProvider(filter: FeedFilter.all).future,
    );
    expect(feedState.posts.map((post) => post.postId), ['post-friend']);

    final reactionController = harness.container.read(
      reactionControllerProvider('post-friend').notifier,
    );
    await reactionController.toggleReact(
      uid: 'uid-me',
      displayName: 'Meep Tester',
      emoji: '❤️',
    );

    expect(harness.reactions.forPost('post-friend'), hasLength(1));
    expect(harness.reactions.forPost('post-friend').single.emoji, '❤️');
    expect(
      harness.container.read(reactionControllerProvider('post-friend')).myEmoji,
      '❤️',
    );

    await reactionController.toggleReact(
      uid: 'uid-me',
      displayName: 'Meep Tester',
      emoji: '❤️',
    );
    expect(harness.reactions.forPost('post-friend'), isEmpty);
  });
}
