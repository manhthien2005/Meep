import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';
import 'package:meep/features/auth/application/sign_up_state.dart';
import 'package:meep/shared/widgets/app_back_button.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';
import 'package:meep/shared/widgets/app_text_input.dart';

class SignUpNamePage extends ConsumerStatefulWidget {
  const SignUpNamePage({super.key});

  @override
  ConsumerState<SignUpNamePage> createState() => _SignUpNamePageState();
}

class _SignUpNamePageState extends ConsumerState<SignUpNamePage> {
  final _hoCtrl = TextEditingController();
  final _tenCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill khi là Google Sign-In (displayName được tách thành Họ + Tên)
    final displayName = ref.read(signUpControllerProvider).displayName;
    if (displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        _hoCtrl.text = parts.first;
        _tenCtrl.text = parts.skip(1).join(' ');
      } else {
        _tenCtrl.text = displayName;
      }
    }
  }

  @override
  void dispose() {
    _hoCtrl.dispose();
    _tenCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _hoCtrl.text.trim().isNotEmpty && _tenCtrl.text.trim().isNotEmpty;

  void _onContinue() {
    final displayName = '${_hoCtrl.text.trim()} ${_tenCtrl.text.trim()}'.trim();
    ref.read(signUpControllerProvider.notifier).setDisplayName(displayName);
    if (!mounted) return;
    final state = ref.read(signUpControllerProvider);
    if (state.step == SignUpStep.username) {
      context.push('/signup/username');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(27, 49, 27, 0),
              child: AppBackButton(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 27),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tên bạn là gì?',
                      style:
                          AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppTextInput(
                      inputType: AppTextInputType.name,
                      controller: _hoCtrl,
                      hint: 'Họ',
                      status: AppTextInputStatus.normal,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    AppTextInput(
                      inputType: AppTextInputType.name,
                      controller: _tenCtrl,
                      hint: 'Tên',
                      errorText: state.errorMessage,
                      status: state.errorMessage != null
                          ? AppTextInputStatus.error
                          : AppTextInputStatus.normal,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 0, 27, 33),
              child: AppPrimaryButton(
                label: 'Tiếp tục',
                isLoading: state.isLoading,
                onPressed: _canContinue ? _onContinue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
