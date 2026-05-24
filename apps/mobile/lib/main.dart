import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/router/app_router.dart';
import 'package:meep/core/theme/app_theme.dart';
import 'package:meep/features/auth/application/auth_controller.dart';
import 'package:meep/features/auth/data/firebase_auth_repository.dart';
import 'package:meep/features/auth/data/firebase_user_repository.dart';
import 'package:meep/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FirebaseAuthRepository(auth: FirebaseAuth.instance),
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
