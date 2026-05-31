import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/features/settings/presentation/settings_sheet.dart';

/// Test page để xem Settings UI — bypass auth
class SettingsTestPage extends StatelessWidget {
  const SettingsTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings UI Test',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.bw800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const SettingsSheet(),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bw200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tap avatar button ở góc phải →',
              style: TextStyle(fontSize: 16, color: AppColors.bw600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const SettingsSheet(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.turquoise500,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Mở Settings Sheet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
