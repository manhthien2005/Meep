import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/application/login_controller.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';
import 'package:meep/features/auth/presentation/intro_page.dart';
import 'package:meep/features/auth/presentation/login/login_email_page.dart';
import 'package:meep/features/auth/presentation/login/login_password_page.dart';
import 'package:meep/features/auth/presentation/login/reset_password_page.dart';
import 'package:meep/features/auth/presentation/signup/signup_email_page.dart';
import 'package:meep/features/auth/presentation/signup/signup_name_page.dart';
import 'package:meep/features/auth/presentation/signup/signup_password_page.dart';
import 'package:meep/features/auth/presentation/signup/signup_username_page.dart';
import 'package:meep/features/chat/presentation/chat_screen.dart';
import 'package:meep/features/chat/presentation/group_chat_screen.dart';
import 'package:meep/features/chat/presentation/inbox_screen.dart';
import 'package:meep/dev/widget_catalog_page.dart';
import 'package:meep/features/diary/presentation/diary_canvas_screen.dart';
import 'package:meep/features/diary/presentation/diary_create_screen.dart';
import 'package:meep/features/diary/presentation/diary_list_screen.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/feed/presentation/capture_preview_args.dart';
import 'package:meep/features/feed/presentation/capture_preview_screen.dart';
import 'package:meep/features/feed/presentation/home_screen.dart';
import 'package:meep/features/home/presentation/home_page.dart';
import 'package:meep/features/profile/presentation/edit_profile_screen.dart';
import 'package:meep/features/profile/presentation/friend_profile_screen.dart';
import 'package:meep/features/profile/presentation/photo_detail_screen.dart';
import 'package:meep/features/profile/presentation/profile_screen.dart';
import 'package:meep/features/space/presentation/space_create_sheet.dart';
import 'package:meep/features/streak/presentation/streak_photo_detail_screen.dart';
import 'package:meep/features/streak/presentation/streak_screen.dart';

part 'app_router.g.dart';

/// Pure redirect logic — testable không cần GoRouter.
///
/// 5-state machine:
///   uid = null                                          → /intro
///   uid != null, profileExists = null (loading)        → wait
///   uid != null, profileExists = false, needsProfile   → /signup/name
///     (đang ở /signup/name hoặc /signup/username → giữ nguyên)
///   uid != null, profileExists = false, !needsProfile  → /intro (orphaned)
///     (đang trong /signup/* → giữ nguyên cho email signup)
///   uid != null, profileExists = true                  → /home
///
/// Special case: /login/reset-password và /__/auth/* luôn được phép truy cập
/// bất kể auth state — user có thể có bất kỳ session nào khi reset mật khẩu.
String? authRedirect({
  required bool isLoading,
  required String? uid,
  required bool? profileExists,
  required bool needsProfile,
  required String location,
}) {
  if (isLoading) return null;

  // Password reset deep link: bypass toàn bộ auth guard
  if (location == '/login/reset-password' || location.startsWith('/__/auth/')) {
    return null;
  }

  // DEV(C/#142): cho phép test luồng Chat FE không cần login (bypass cả 2 chiều
  // — uid null không bị đá về /intro, uid có không bị đá về /home). Bỏ khi auth
  // wire xong + có home-shell điều hướng Inbox sau đăng nhập.
  if (location.startsWith('/inbox') ||
      location.startsWith('/chat') ||
      location.startsWith('/group-chat')) {
    return null;
  }

  final onAuthRoute = location.startsWith('/login') ||
      location.startsWith('/signup') ||
      location.startsWith('/dev') ||
      location == '/intro';

  if (uid == null) return onAuthRoute ? null : '/intro';

  // uid != null — chờ profile resolve
  if (profileExists == null) return null;

  if (!profileExists) {
    if (needsProfile) {
      // Google Sign-In vừa hoàn tất, cần setup profile
      if (location == '/signup/name' || location == '/signup/username') {
        return null;
      }
      return '/signup/name';
    }
    // Orphaned auth → về /intro; MeepApp cleanup sẽ signOut
    if (location.startsWith('/signup')) return null;
    return '/intro';
  }

  // uid != null, profile exists — không redirect user khỏi reset page
  if (location == '/login/reset-password') return null;
  return onAuthRoute ? '/home' : null;
}

/// ChangeNotifier kích hoạt GoRouter redirect re-evaluation khi auth state thay đổi.
/// Không recreate GoRouter (tránh navigation stack reset).
///
/// Phụ chức năng: giữ `signUpControllerProvider` alive xuyên route transitions.
/// `@riverpod` codegen mặc định là autoDispose → khi `SignUpEmailPage` dispose
/// và `SignUpNamePage` chưa kịp watch, controller bị tháo → mất state
/// `isGoogleSignIn`, `displayName` đã prefill từ Google → bước cuối
/// `createAccount` chạy nhầm nhánh email signup với creds trống → Firebase
/// throw Pigeon channel error leak ra UI. Listen với callback rỗng đủ để
/// Riverpod giữ provider sống trong suốt vòng đời router (keepAlive).
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(currentUidProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProfileProvider, (_, __) => notifyListeners());
    ref.listen(
      loginControllerProvider.select((s) => s.needsProfile),
      (_, __) => notifyListeners(),
    );
    // No-op listen — chỉ để keepAlive, không trigger redirect re-eval.
    ref.listen(signUpControllerProvider, (_, __) {});
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // ── Cold start: process deep link TRƯỚC khi tạo GoRouter ─────────────────
  // Cold start mặc định vào /intro để chạy luồng auth thật → /home (feed).
  // Deep link (nếu có) sẽ override bên dưới.
  String initialLocation = '/intro';
  try {
    final rawRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;

    if (rawRoute.isNotEmpty && rawRoute != '/') {
      final uri = Uri.tryParse(rawRoute);
      if (uri != null && uri.host.isNotEmpty) {
        final path = uri.path;
        final query = uri.hasQuery ? '?${uri.query}' : '';
        if (path.isNotEmpty && path != '/') {
          initialLocation = '$path$query';
        }
      } else if (rawRoute.startsWith('/')) {
        initialLocation = rawRoute;
      }
    }
  } catch (_) {/* giữ initialLocation mặc định */}

  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: initialLocation,
    refreshListenable: notifier,
    onException: (context, state, router) {
      final uri = state.uri;

      String? target;
      if (uri.host.isNotEmpty) {
        // Warm start: full URL → strip host
        final path = uri.path;
        final query = uri.hasQuery ? '?${uri.query}' : '';
        if (path.isNotEmpty && path != '/') target = '$path$query';
      } else if (uri.path.startsWith('/__/auth/')) {
        // Cold start: host đã stripped nhưng chưa có route match
        // (xảy ra khi refreshListenable trigger trước route được register)
        final path = uri.path;
        final query = uri.hasQuery ? '?${uri.query}' : '';
        target = '$path$query';
      }

      WidgetsBinding.instance.addPostFrameCallback(
        (_) => router.go(target ?? '/intro'),
      );
    },
    redirect: (context, state) {
      // Dùng ref.read (không watch) vì redirect chạy ngoài provider build
      final uidState = ref.read(currentUidProvider);
      final profileState = ref.read(currentUserProfileProvider);
      final needsProfile = ref.read(loginControllerProvider).needsProfile;
      final uid = uidState.valueOrNull;
      final isLoading =
          uidState.isLoading || (uid != null && profileState.isLoading);
      final bool? profileExists = switch (profileState) {
        AsyncData(:final value) => value != null,
        _ => null,
      };

      // Strip scheme+host nếu GoRouter nhận full URL từ Android deep link
      // VD: https://meep-staging.firebaseapp.com/__/auth/action?... → /__/auth/action?...
      final rawUri = state.uri;
      if (rawUri.host.isNotEmpty) {
        final path = rawUri.path;
        final query = rawUri.hasQuery ? '?${rawUri.query}' : '';
        return '$path$query';
      }

      return authRedirect(
        isLoading: isLoading,
        uid: uid,
        profileExists: profileExists,
        needsProfile: needsProfile,
        location: state.matchedLocation,
      );
    },
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
      GoRoute(
        path: '/login/reset-password',
        builder: (context, state) => ResetPasswordPage(
          oobCode: state.uri.queryParameters['oobCode'] ?? '',
        ),
      ),
      // Firebase email action deep link (/__/auth/links wrapper)
      // URL: /__/auth/links?link=https://.../__/auth/action?...&mode=resetPassword&oobCode=xxx
      GoRoute(
        path: '/__/auth/links',
        redirect: (context, state) {
          final linkParam = state.uri.queryParameters['link'] ?? '';
          if (linkParam.isEmpty) return '/intro';

          // URI.queryParameters đã URL-decode linkParam
          final innerUri = Uri.tryParse(linkParam);
          if (innerUri == null) return '/intro';

          final mode = innerUri.queryParameters['mode'];
          final oobCode = innerUri.queryParameters['oobCode'] ?? '';

          if (mode == 'resetPassword' && oobCode.isNotEmpty) {
            return '/login/reset-password?oobCode=$oobCode';
          }
          return '/intro';
        },
        builder: (_, __) => const SizedBox.shrink(),
      ),
      // Fallback cho direct action link (không qua links wrapper)
      GoRoute(
        path: '/__/auth/action',
        redirect: (context, state) {
          final mode = state.uri.queryParameters['mode'];
          final oobCode = state.uri.queryParameters['oobCode'] ?? '';
          if (mode == 'resetPassword' && oobCode.isNotEmpty) {
            return '/login/reset-password?oobCode=$oobCode';
          }
          return '/intro';
        },
        builder: (_, __) => const SizedBox.shrink(),
      ),
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
      GoRoute(
        path: '/invite/:uid',
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: '/capture-preview',
        builder: (_, state) =>
            CapturePreviewScreen(args: state.extra as CapturePreviewArgs),
      ),
      GoRoute(
        path: '/caption-modal',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(path: '/grid-view', builder: (_, __) => const HomeScreen()),
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
        builder: (_, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            // ProfileScreen / FriendProfileScreen passes
            // { 'posts': List<Post>, 'index': int }
            final posts = extra['posts'];
            return PhotoDetailScreen(
              postId: state.pathParameters['postId'] ?? '',
              initialIndex: (extra['index'] as int?) ?? 0,
              posts: posts is List<Post> ? posts : null,
            );
          }
          return PhotoDetailScreen(
            postId: state.pathParameters['postId'] ?? '',
            initialIndex: (extra as int?) ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/friend-profile/:uid',
        builder: (_, state) =>
            FriendProfileScreen(uid: state.pathParameters['uid'] ?? ''),
      ),
      GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (_, state) => ChatScreen(
          conversationId: state.pathParameters['conversationId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/group-chat/:conversationId',
        builder: (_, state) => GroupChatScreen(
          conversationId: state.pathParameters['conversationId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/space/create',
        builder: (_, __) => const SpaceCreateSheet(),
      ),
      // Deeplink target — vd: tap Widget Android sẽ deeplink `/space/:spaceId`
      // để mở Home với Space context active. SpaceContextBottomSheet KHÔNG
      // map sang route (chỉ mở qua showModalBottomSheet từ long-press
      // FriendsButton).
      GoRoute(
        path: '/space/:spaceId',
        builder: (_, state) => HomeScreen(
          spaceId: state.pathParameters['spaceId'] ?? '',
        ),
      ),
      GoRoute(path: '/streak', builder: (_, __) => const StreakScreen()),
      GoRoute(
        path: '/streak/photo/:postId',
        builder: (_, state) => StreakPhotoDetailScreen(
          postId: state.pathParameters['postId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/dev/widgets',
        builder: (_, __) => const WidgetCatalogPage(),
      ),
    ],
  );

  ref.onDispose(notifier.dispose);
  return router;
}
