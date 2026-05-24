import 'package:flutter/material.dart';

class AppGoogleButton extends StatelessWidget {
  const AppGoogleButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // TODO(A/HanDHG): implement per Figma — 357×60, radius=30, bg=white, border=#EFF0F6
    // Android only — do NOT show on iOS
    return SizedBox(
      width: 357,
      height: 60,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFEFF0F6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: const _GoogleIcon(),
        label: const Text(
          'Tiếp tục với Google',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    // TODO(A/HanDHG): replace with actual Google SVG asset
    return const SizedBox(
      width: 18,
      height: 18,
      child: Placeholder(),
    );
  }
}
