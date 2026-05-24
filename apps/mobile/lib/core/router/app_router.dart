import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/dev/widget_catalog_page.dart';
import 'package:meep/features/auth/application/auth_controller.dart';
import 'package:meep/features/auth/presentation/intro_page.dart';
import 'package:meep/features/auth/presentation/login/login_email_page.dart';
import 'package:meep/features/auth/presentation/login/login_password_page.dart';
import 'package:meep/features/auth/presentation/signup/signup_email_page.dart';
import 'package:meep/features/auth/presentation/signup/signup_name_page.dart';
import 'package:meep/features/auth/presentation/signup/signup_password_page.dart';
import 'package:meep/features/auth/presentation/signup/signup_username_page.dart';
import 'package:meep/features/chat/presentation/chat_screen.dart';
import 'package:meep/features/chat/presentation/inbox_screen.dart';
import 'package:meep/features/diary/presentation/diary_canvas_screen.dart';
import 'package:meep/features/diary/presentation/diary_create_screen.dart';
import 'package:meep/features/diary/presentation/diary_list_screen.dart';
import 'package:meep/features/feed/presentation/home_screen.dart';
import 'package:meep/features/home/presentation/home_page.dart';
import 'package:meep/features/profile/presentation/edit_profile_screen.dart';
import 'package:meep/features/profile/presentation/photo_detail_screen.dart';
import 'package:meep/features/profile/presentation/profile_screen.dart';
import 'package:meep/features/space/presentation/space_context_bottom_sheet.dart';
import 'package:meep/features/space/presentation/space_create_sheet.dart';
import 'package:meep/features/streak/presentation/streak_photo_detail_screen.dart';
import 'package:meep/features/streak/presentation/streak_screen.dart';

part 'app_router.g.dart';

/// Pure redirect logic — testable without GoRouter.
///
/// 3-state machine:
///   uid = null                           → /intro
///   uid != null, profileExists = null    → wait (still resolving)
///   uid != null, profileExists = false   → /signup/name (Google Sign-In incomplete)
///   uid != null, profileExists = true    → /home
String? authRedirect({
  required bool isLoading,
  required String? uid,
  required bool? profileExists,
  required String location,
}) {
  if (isLoading) return null;

  final onAuthRoute = location.startsWith('/login') ||
      location.startsWith('/signup') ||
      location.startsWith('/dev') ||
      location == '/intro';

  if (uid == null) return onAuthRoute ? null : '/intro';

  // uid != null — wait until profile state is resolved
  if (profileExists == null) return null;

  if (!profileExists) {
    // Google Sign-In first time or incomplete signup — resume from name step
    return location.startsWith('/signup') ? null : '/signup/name';
  }

  // uid != null, profile exists
  return onAuthRoute ? '/home' : null;
}

// NOTE: mỗi khi currentUidProvider emit giá trị mới, provider này rebuild và tạo
// GoRouter mới → navigation stack reset. Cho MVP M1 chấp nhận được (chỉ xảy ra
// lúc login/logout). Post-MVP nên refactor sang RouterNotifier + refreshListenable.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final uidState = ref.watch(currentUidProvider);
  final profileState = ref.watch(currentUserProfileProvider);

  final uid = uidState.valueOrNull;
  // isLoading: uid resolving OR (uid exists but profile still loading)
  final isLoading =
      uidState.isLoading || (uid != null && profileState.isLoading);
  // profileExists: null when error/loading (unknown), else whether profile doc exists
  final bool? profileExists = switch (profileState) {
    AsyncData(:final value) => value != null,
    _ => null,
  };

  return GoRouter(
    initialLocation: '/intro',
    redirect: (context, state) => authRedirect(
      isLoading: isLoading,
      uid: uid,
      profileExists: profileExists,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: '/intro', builder: (_, __) => const IntroPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
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
      // DEV ONLY — xóa trước khi merge
      GoRoute(
        path: '/dev/widgets',
        builder: (_, __) => const WidgetCatalogPage(),
      ),
      // TODO(D/T13/TBD): wire diary routes — DiaryListScreen/CreateScreen/CanvasScreen
      GoRoute(path: '/diary', builder: (_, __) => const DiaryListScreen()),
      GoRoute(
        path: '/diary/create',
        builder: (_, __) => const DiaryCreateScreen(),
      ),
      GoRoute(
        path: '/diary/:entryId',
        builder: (_, state) => DiaryCanvasScreen(
          mode: DiaryCanvasMode.read,
          entryId: state.pathParameters['entryId'],
        ),
      ),
      // TODO(F/T11/KhoaLND): implement InvitePage — profile invite link landing
      GoRoute(
        path: '/invite/:uid',
        builder: (_, __) => const HomePage(),
      ),
      // TODO(FE/T20/KhoaLND): wire Feed routes
      GoRoute(
        path: '/capture-preview',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/caption-modal',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(path: '/grid-view', builder: (_, __) => const HomeScreen()),
      // TODO(P/T10/TBD): wire Profile routes
      GoRoute(
        path: '/profile',
        builder: (_, state) => ProfileScreen(uid: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/photo/:postId',
        builder: (_, state) =>
            PhotoDetailScreen(postId: state.pathParameters['postId'] ?? ''),
      ),
      GoRoute(
        path: '/friend-profile/:uid',
        builder: (_, state) =>
            ProfileScreen(uid: state.pathParameters['uid'] ?? ''),
      ),
      // TODO(C/T8/TBD): wire Chat routes
      GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (_, state) => ChatScreen(
          conversationId: state.pathParameters['conversationId'] ?? '',
        ),
      ),
      // TODO(SP/T10/TBD): wire Space routes
      GoRoute(
        path: '/space/create',
        builder: (_, __) => const SpaceCreateSheet(),
      ),
      GoRoute(
        path: '/space/:spaceId',
        builder: (_, state) => SpaceContextBottomSheet(
          spaceId: state.pathParameters['spaceId'] ?? '',
        ),
      ),
      // TODO(ST/T5/TBD): wire Streak routes
      GoRoute(path: '/streak', builder: (_, __) => const StreakScreen()),
      GoRoute(
        path: '/streak/photo/:postId',
        builder: (_, state) => StreakPhotoDetailScreen(
          postId: state.pathParameters['postId'] ?? '',
        ),
      ),
    ],
  );
}
