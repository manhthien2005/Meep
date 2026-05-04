import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/auth_controller.dart';
import 'package:meep/features/auth/presentation/intro_page.dart';
import 'package:meep/features/auth/presentation/login/login_email_page.dart';
import 'package:meep/features/auth/presentation/login/login_password_page.dart';
import 'package:meep/features/auth/presentation/signup/signup_email_page.dart';
import 'package:meep/features/auth/presentation/signup/signup_name_page.dart';
import 'package:meep/features/auth/presentation/signup/signup_password_page.dart';
import 'package:meep/features/auth/presentation/signup/signup_username_page.dart';
import 'package:meep/features/home/presentation/home_page.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(currentUidProvider);

  return GoRouter(
    initialLocation: '/intro',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isSignedIn = authState.valueOrNull != null;
      final onAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation == '/intro';

      if (isSignedIn && onAuthRoute) return '/home';
      if (!isSignedIn && !onAuthRoute) return '/intro';
      return null;
    },
    routes: [
      GoRoute(path: '/intro', builder: (_, __) => const IntroPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(
        path: '/signup/email',
        builder: (_, __) => const SignUpEmailPage(),
      ),
      GoRoute(
        path: '/signup/password',
        builder: (_, __) => const SignUpPasswordPage(),
      ),
      GoRoute(
        path: '/signup/name',
        builder: (_, __) => const SignUpNamePage(),
      ),
      GoRoute(
        path: '/signup/username',
        builder: (_, __) => const SignUpUsernamePage(),
      ),
      GoRoute(
        path: '/login/email',
        builder: (_, __) => const LoginEmailPage(),
      ),
      GoRoute(
        path: '/login/password',
        builder: (context, state) =>
            LoginPasswordPage(email: state.extra as String? ?? ''),
      ),
    ],
  );
}
