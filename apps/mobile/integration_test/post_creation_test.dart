import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/feed/application/post_controller.dart';
import 'package:meep/shared/models/post.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('post creation uploads bytes and writes a feed post',
      (tester) async {
    final harness = await MeepIntegrationHarness.create(
      signedInProfile: testUserProfile(),
    );
    addTearDown(harness.dispose);

    await harness.container.read(currentUidProvider.future);
    await harness.container.read(currentUserProfileProvider.future);

    final controller = harness.container.read(postControllerProvider.notifier)
      ..setPendingImage('memory/photo.jpg')
      ..setCaption('Hello Meep')
      ..setAudience(AudienceType.select, const ['uid-friend']);

    final submitted = await controller.submit();

    expect(submitted, isTrue);
    expect(harness.posts.createdPosts, hasLength(1));

    final post = harness.posts.createdPosts.single;
    expect(post.postId, 'post-1');
    expect(post.authorId, 'uid-me');
    expect(post.authorName, 'Meep Tester');
    expect(post.caption, 'Hello Meep');
    expect(post.audienceType, AudienceType.select);
    expect(post.audienceUids, ['uid-friend']);
    expect(post.imageUrl, 'memory://posts/uid-me/post-1/photo.jpg');
    expect(
      harness.container.read(postControllerProvider).pendingImagePath,
      isNull,
    );
  });
}
