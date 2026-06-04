import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/reaction/application/reaction_controller.dart';
import 'package:meep/features/reaction/data/firebase_reaction_repository.dart';
import 'package:meep/features/chat/data/firebase_conversation_repository.dart';
import 'package:meep/features/diary/application/diary_controller.dart';
import 'package:meep/features/diary/data/firebase_diary_repository.dart';
import 'package:meep/features/diary/data/image_picker_service.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/data/firebase_friend_repository.dart';
import 'package:meep/features/friend/data/firebase_friend_request_repository.dart';
import 'package:meep/features/profile/application/profile_controller.dart';
import 'package:meep/features/profile/data/firebase_profile_repository.dart';
import 'package:meep/features/settings/application/settings_controller.dart';
import 'package:meep/features/settings/data/firebase_block_repository.dart';
import 'package:meep/features/notification/application/notification_controller.dart';
import 'package:meep/features/notification/application/notification_state.dart';
import 'package:meep/features/notification/data/firebase_notification_repository.dart';
import 'package:meep/features/notification/data/notification_preferences.dart';
import 'package:meep/features/notification/presentation/widgets/notification_banner.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/firebase_space_repository.dart';
import 'package:meep/features/streak/application/streak_controller.dart';
import 'package:meep/features/streak/data/firebase_streak_repository.dart';
import 'package:meep/features/widget/application/widget_data_service.dart';
import 'package:meep/firebase_options.dart';

// Pass --dart-define=USE_EMULATOR=true khi dev local để trỏ vào Firebase Emulator Suite.
const _useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);
// Android emulator truy cập host machine qua 10.0.2.2 (không phải 127.0.0.1)
const _emulatorHost = '10.0.2.2';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (_useEmulator) {
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 9999);
    await FirebaseStorage.instance.useStorageEmulator(_emulatorHost, 9199);
  }

  final prefs = await SharedPreferences.getInstance();

  final authRepo = FirebaseAuthRepository(
    auth: FirebaseAuth.instance,
    functions: FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
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
        friendRepositoryProvider.overrideWithValue(
          FirebaseFriendRepository(FirebaseFirestore.instance),
        ),
        friendRequestRepositoryProvider.overrideWithValue(
          FirebaseFriendRequestRepository(
            FirebaseFirestore.instance,
            FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
          ),
        ),
        spaceRepositoryProvider.overrideWithValue(
          FirebaseSpaceRepository(
            FirebaseFirestore.instance,
            FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
          ),
        ),
        blockRepositoryProvider.overrideWithValue(
          FirebaseBlockRepository(
            FirebaseFirestore.instance,
            FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
          ),
        ),
        conversationRepositoryProvider.overrideWithValue(
          FirebaseConversationRepository(FirebaseFirestore.instance),
        ),
        profileRepositoryProvider.overrideWithValue(
          FirebaseProfileRepository.firebase(
            firestore: FirebaseFirestore.instance,
            storage: FirebaseStorage.instance,
          ),
        ),
        widgetDataServiceProvider.overrideWithValue(
          WidgetDataService(prefs: prefs),
        ),
        reactionRepositoryProvider.overrideWithValue(
          FirebaseReactionRepository(FirebaseFirestore.instance),
        ),
        notificationRepositoryProvider.overrideWithValue(
          FirebaseNotificationRepository(firestore: FirebaseFirestore.instance),
        ),
        notificationPreferencesProvider.overrideWithValue(
          NotificationPreferences(prefs: prefs),
        ),
        diaryRepositoryProvider.overrideWithValue(
          FirebaseDiaryRepository.firebase(
            firestore: FirebaseFirestore.instance,
            storage: FirebaseStorage.instance,
          ),
        ),
        diaryStorageClientProvider.overrideWithValue(
          FirebaseDiaryStorageClient(FirebaseStorage.instance),
        ),
        imagePickerServiceProvider.overrideWithValue(
          const FlutterImagePickerService(),
        ),
        streakRepositoryProvider.overrideWithValue(
          FirebaseStreakRepository(FirebaseFirestore.instance),
        ),
      ],
      child: const MeepApp(),
    ),
  );
}

class MeepApp extends ConsumerStatefulWidget {
  const MeepApp({super.key});

  @override
  ConsumerState<MeepApp> createState() => _MeepAppState();
}

class _MeepAppState extends ConsumerState<MeepApp> with WidgetsBindingObserver {
  OverlayEntry? _bannerOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _bannerOverlay?.remove();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(widgetDataServiceProvider).recordLastViewedAt();
    }
  }

  @override
  Widget build(BuildContext context) {
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

    // ── Notification: init FCM when user logs in ───────────────────────
    ref.listen(currentUidProvider, (prevUid, nextUid) {
      final uid = nextUid.valueOrNull;
      if (uid != null && prevUid?.valueOrNull == null) {
        ref.read(notificationControllerProvider.notifier).initFcm();
      }
    });

    // ── Notification: foreground banner overlay ─────────────────────────
    // The first `ref.listen` fire can happen before `MaterialApp.router`
    // has mounted its `Navigator`/`Overlay`. Deferring via post-frame +
    // `Overlay.maybeOf` keeps cold-start FCM from throwing
    // `'No Overlay widget exists above this context'`.
    ref.listen<NotificationState>(
      notificationControllerProvider,
      (prev, next) {
        _bannerOverlay?.remove();
        _bannerOverlay = null;

        final payload = next.currentBanner;
        if (payload == null) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final overlay = Overlay.maybeOf(context, rootOverlay: true);
          if (overlay == null) return;
          // Bail if controller state moved on (suppress/timer) between the
          // listener fire and post-frame.
          if (ref.read(notificationControllerProvider).currentBanner !=
              payload) {
            return;
          }
          final entry = OverlayEntry(
            builder: (_) => Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: (MediaQuery.of(context).size.width - 364) / 2,
              child: NotificationBanner(
                payload: payload,
                onTap: () {
                  ref
                      .read(notificationControllerProvider.notifier)
                      .openBannerAsTap();
                },
                onSuppress: () {
                  ref
                      .read(notificationControllerProvider.notifier)
                      .suppressBanner();
                },
              ),
            ),
          );
          overlay.insert(entry);
          _bannerOverlay = entry;
        });
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
