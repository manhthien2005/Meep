import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/settings/application/settings_controller.dart';

/// Skeleton HomePage — module owner sẽ implement Feed/Camera/Grid scaffold
/// theo Figma (FE/T15/KhoaLND). Tạm giữ profile preview + dev sign-out button
/// (chỉ trong debug build) để leader test auth flow end-to-end.
///
/// Contract-first: KHÔNG dùng `FirebaseAuth.instance` trực tiếp — chỉ qua
/// `currentUserProfileProvider` + `authRepositoryProvider`. Đảm bảo test
/// có thể override repository bằng fake.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Home — TODO'),
            const SizedBox(height: 8),
            profileAsync.maybeWhen(
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                return Text(
                  profile.email,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            // Dev affordance — `kDebugMode` strips this from release builds
            // so prod users không nhìn thấy sign-out shortcut.
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await ref.read(settingsControllerProvider.notifier).logout();
                  if (context.mounted) context.go('/intro');
                },
                child: const Text('Sign out (dev)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
