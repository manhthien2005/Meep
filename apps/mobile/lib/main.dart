import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/router/app_router.dart';
import 'package:meep/core/theme/app_theme.dart';
import 'package:meep/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // TODO(T2+3/KhoaLND): override authRepositoryProvider + userRepositoryProvider
  // sau khi FirebaseAuthRepository + FirebaseUserRepository được implement.
  // Ví dụ:
  //   authRepositoryProvider.overrideWithValue(
  //     FirebaseAuthRepository(auth: FirebaseAuth.instance),
  //   ),
  //   userRepositoryProvider.overrideWithValue(
  //     FirebaseUserRepository(firestore: FirebaseFirestore.instance),
  //   ),

  // TODO(N/T2/TBD): FCM init sau khi firebase_messaging được add vào pubspec:
  //   final messaging = FirebaseMessaging.instance;
  //   await messaging.requestPermission();
  //   final token = await messaging.getToken();
  //   if (token != null) notificationController.initFcm();
  //   FirebaseMessaging.onMessage.listen(notificationController.handleForeground);
  //   FirebaseMessaging.onMessageOpenedApp.listen(notificationController.handleTap);
  runApp(const ProviderScope(child: MeepApp()));
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
