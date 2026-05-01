import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/features/auth/application/auth_controller.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meep')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_camera_outlined, size: 80),
              const SizedBox(height: 16),
              Text(
                'Welcome to Meep',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to share photos with close friends.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (isSignedIn)
                const Text('Signed in — TODO: navigate to feed')
              else
                FilledButton.icon(
                  onPressed: () {
                    // TODO(auth): wire SignInController and call signInWithGoogle.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'TODO: implement sign-in via auth controller',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
