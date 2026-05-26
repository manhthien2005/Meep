import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  bool get _hasEnoughInput => _usernameCtrl.text.trim().length >= 3;

  // Flow: ấn "Tiếp tục" → check → nếu available → createAccount → navigate
  Future<void> _onContinue() async {
    final username = _usernameCtrl.text.trim();
    await ref.read(signUpControllerProvider.notifier).checkUsername(username);
    if (!mounted) return;

    final state = ref.read(signUpControllerProvider);
    if (!state.isUsernameAvailable) return; // UI shows error từ state

    await ref.read(signUpControllerProvider.notifier).createAccount();
    if (!mounted) return;
    if (ref.read(signUpControllerProvider).errorMessage == null) {
      // Delay 800ms để user thấy "Hoàn tất" trước khi redirect
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpControllerProvider);
    final isBusy = state.isCheckingUsername || state.isLoading;

    // Trạng thái input: chỉ show sau khi đã check (username đã được set vào state)
    final hasChecked = state.username.isNotEmpty;
    AppTextInputStatus inputStatus = AppTextInputStatus.normal;
    if (hasChecked && !state.isCheckingUsername) {
      inputStatus = state.isUsernameAvailable
          ? AppTextInputStatus.success
          : AppTextInputStatus.error;
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
                    const SizedBox(height: 20),
                    AppTextInput(
                      inputType: AppTextInputType.username,
                      controller: _usernameCtrl,
                      hint: 'Tên người dùng',
                      status: inputStatus,
                      errorText: (hasChecked &&
                              !state.isCheckingUsername &&
                              !state.isUsernameAvailable)
                          ? (state.errorMessage ??
                              'Tên người dùng này đã tồn tại. Vui lòng chọn tên khác.')
                          : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    if (hasChecked &&
                        !state.isCheckingUsername &&
                        state.isUsernameAvailable)
                      Center(child: _AvailablePill())
                    else
                      _HintPill(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(37, 0, 37, 33),
              child: AppPrimaryButton(
                label: state.isUsernameAvailable ? 'Hoàn tất' : 'Tiếp tục',
                isLoading: isBusy,
                onPressed: (_hasEnoughInput && !isBusy) ? _onContinue : null,
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
          SvgPicture.asset(
            'assets/icons/ic_circle_check_big.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.bw100,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            'Tuyệt vời!',
            style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
          ),
        ],
      ),
    );
  }
}
