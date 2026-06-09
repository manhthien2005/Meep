import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/application/login_controller.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('auth flow signs up, creates public profile, then logs in',
      (tester) async {
    final harness = await MeepIntegrationHarness.create();
    addTearDown(harness.dispose);

    final signUp = harness.container.read(signUpControllerProvider.notifier);

    final emailAvailable =
        await signUp.checkEmailAvailable('alice@example.com');
    expect(emailAvailable, isTrue);
    signUp
      ..setPassword('pass1234')
      ..setDisplayName('Alice Nguyen');
    await signUp.checkUsername('alice');
    await signUp.createAccount();

    final profile = await harness.users.getProfile('uid-alice');
    expect(profile, isNotNull);
    expect(profile!.displayName, 'Alice Nguyen');
    expect(profile.username, 'alice');
    expect(harness.auth.currentUid, 'uid-alice');
    expect(harness.auth.verificationEmailCount, 1);

    final publicProfile = await harness.users.getPublicProfile('uid-alice');
    expect(publicProfile, isNotNull);
    expect(publicProfile!.displayName, 'Alice Nguyen');

    final watchedProfile =
        await harness.container.read(currentUserProfileProvider.future);
    expect(watchedProfile?.uid, 'uid-alice');

    await harness.auth.signOut();
    final login = harness.container.read(loginControllerProvider.notifier)
      ..setEmail('alice@example.com')
      ..setPassword('pass1234');
    await login.signIn();

    final loginState = harness.container.read(loginControllerProvider);
    expect(loginState.isSuccess, isTrue);
    expect(loginState.errorMessage, isNull);
    expect(harness.auth.currentUid, 'uid-alice');
  });
}
