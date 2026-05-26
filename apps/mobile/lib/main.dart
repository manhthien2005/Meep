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
import 'package:meep/features/auth/application/orphan_auth_check.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';
import 'package:meep/features/auth/data/firebase_auth_repository.dart';
import 'package:meep/features/auth/data/firebase_user_repository.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authRepo = FirebaseAuthRepository(
    auth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(
      serverClientId: AppConfig.googleServerClientId,
    ),
  );
  // Đồng bộ cached session với server — phát hiện account đã delete/disable
  // trên Firebase Console (token cached vẫn valid ~1h sau khi xoá nếu không
  // force reload). Network errors swallow để app vẫn launch được offline.
  await authRepo.revalidateSession();

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
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
    // Nếu app mở lại mà uid tồn tại nhưng Firestore không có profile VÀ không
    // đang trong active signup/login flow → orphan → sign out về /intro.
    //
    // Decision logic ở [checkOrphanAuth] (pure function, test riêng) — listener
    // chỉ wire ref state vào và execute action.
    ref.listen<AsyncValue<UserProfile?>>(currentUserProfileProvider, (_, next) {
      final login = ref.read(loginControllerProvider);
      final signUp = ref.read(signUpControllerProvider);
      final result = checkOrphanAuth(
        profileState: next,
        uid: ref.read(currentUidProvider).valueOrNull,
        isLoginLoading: login.isLoading,
        needsProfile: login.needsProfile,
        isSignUpGoogle: signUp.isGoogleSignIn,
        isSignUpLoading: signUp.isLoading,
      );
      if (result == OrphanCheckResult.signOut) {
        ref.read(authRepositoryProvider).signOut();
      }
    });

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
