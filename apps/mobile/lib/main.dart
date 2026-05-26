import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:meep/core/config/app_config.dart';
import 'package:meep/core/router/app_router.dart';
import 'package:meep/core/theme/app_theme.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/application/login_controller.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';
import 'package:meep/features/auth/data/firebase_auth_repository.dart';
import 'package:meep/features/auth/data/firebase_user_repository.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FirebaseAuthRepository(
            auth: FirebaseAuth.instance,
            googleSignIn: GoogleSignIn(
              serverClientId: AppConfig.googleServerClientId,
            ),
          ),
        ),
        userRepositoryProvider.overrideWithValue(
          FirebaseUserRepository(firestore: FirebaseFirestore.instance),
        ),
      ],
      child: const MeepApp(),
    ),
  );
}

class MeepApp extends ConsumerWidget {
  const MeepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Orphaned Google auth cleanup:
    // Nếu app mở lại mà uid tồn tại nhưng chưa có profile VÀ không đang
    // trong active signup flow → user đã bỏ giữa chừng → sign out về /intro.
    ref.listen<AsyncValue<UserProfile?>>(
      currentUserProfileProvider,
      (_, next) {
        final uid = ref.read(currentUidProvider).valueOrNull;
        if (uid == null) return;
        if (!next.hasValue) return; // còn loading
        if (next.value != null) return; // profile exists — OK

        // Profile null: kiểm tra có đang trong active signup/login flow không
        final login = ref.read(loginControllerProvider);
        final signUp = ref.read(signUpControllerProvider);

        final isActiveFlow = login.isLoading ||
            login.needsProfile ||
            signUp.isGoogleSignIn ||
            signUp.isLoading;

        if (isActiveFlow) return;

        // Orphaned auth — sign out silently
        ref.read(authRepositoryProvider).signOut();
      },
    );

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Meep',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
