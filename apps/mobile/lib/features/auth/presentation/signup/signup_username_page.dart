import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';
import 'package:meep/shared/widgets/app_back_button.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';
import 'package:meep/shared/widgets/app_text_input.dart';

class SignUpUsernamePage extends ConsumerStatefulWidget {
  const SignUpUsernamePage({super.key});

  @override
  ConsumerState<SignUpUsernamePage> createState() => _SignUpUsernamePageState();
}

class _SignUpUsernamePageState extends ConsumerState<SignUpUsernamePage> {
  final _usernameCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue {
    final state = ref.read(signUpControllerProvider);
    return state.isUsernameAvailable && !state.isCheckingUsername;
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(signUpControllerProvider.notifier).checkUsername(value.trim());
      }
    });
  }

  Future<void> _onContinue() async {
    await ref.read(signUpControllerProvider.notifier).createAccount();
    if (!mounted) return;
    final state = ref.read(signUpControllerProvider);
    if (state.errorMessage == null && !state.isLoading) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpControllerProvider);
    final isAvailable = state.isUsernameAvailable;
    final isChecking = state.isCheckingUsername;
    final hasInput = _usernameCtrl.text.trim().length >= 3;

    AppTextInputStatus inputStatus = AppTextInputStatus.normal;
    if (hasInput && !isChecking) {
      inputStatus =
          isAvailable ? AppTextInputStatus.success : AppTextInputStatus.error;
    }

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
                      'Chọn tên người dùng của bạn',
                      style:
                          AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppTextInput(
                      inputType: AppTextInputType.username,
                      controller: _usernameCtrl,
                      hint: 'Tên người dùng',
                      status: inputStatus,
                      errorText: (hasInput && !isChecking && !isAvailable)
                          ? 'Tên người dùng đã được sử dụng'
                          : null,
                      onChanged: (v) {
                        setState(() {});
                        _onUsernameChanged(v);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (hasInput && !isChecking && isAvailable)
                      _AvailablePill()
                    else
                      _HintPill(),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage!,
                        style: AppTextStyles.smSemiBold
                            .copyWith(color: AppColors.error700),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 0, 27, 33),
              child: AppPrimaryButton(
                label: 'Tiếp tục',
                isLoading: state.isLoading || isChecking,
                onPressed: _canContinue ? _onContinue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.bw700,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        'Việc này sẽ giúp bạn kết nối bạn bè nhanh chóng.',
        style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
      ),
    );
  }
}

class _AvailablePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.bw700,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tuyệt vời!',
            style:
                AppTextStyles.smSemiBold.copyWith(color: AppColors.success700),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.check, size: 14, color: AppColors.success700),
        ],
      ),
    );
  }
}
