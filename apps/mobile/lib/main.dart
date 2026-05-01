import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_theme.dart';
import 'package:meep/features/auth/presentation/login_page.dart';

void main() {
  // TODO(setup): wire Firebase before runApp once flutterfire configure has been run.
  // import 'package:firebase_core/firebase_core.dart';
  // import 'firebase_options.dart';
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MeepApp()));
}

class MeepApp extends StatelessWidget {
  const MeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meep',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const LoginPage(),
    );
  }
}
