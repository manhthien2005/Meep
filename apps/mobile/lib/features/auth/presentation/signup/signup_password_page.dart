import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';
import 'package:meep/shared/widgets/app_back_button.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';
import 'package:meep/shared/widgets/app_text_input.dart';

class SignUpPasswordPage extends ConsumerStatefulWidget {
  const SignUpPasswordPage({super.key});

  @override
  ConsumerState<SignUpPasswordPage> createState() => _SignUpPasswordPageState();
}

class _SignUpPasswordPageState extends ConsumerState<SignUpPasswordPage> {
  final _pwCtrl = TextEditingController();
  final _pwFocus = FocusNode();
  bool _hasBlurred = false;

  void _onFocusChange() {
    if (!_pwFocus.hasFocus && mounted) {
      setState(() => _hasBlurred = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _pwFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _pwFocus.removeListener(_onFocusChange);
    _pwFocus.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue => _pwCtrl.text.length >= 8;

  bool get _showError =>
      _hasBlurred && _pwCtrl.text.isNotEmpty && !_canContinue;

  void _onContinue() {
    ref.read(signUpControllerProvider.notifier).setPassword(_pwCtrl.text);
    context.push('/signup/name');
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
                      'Chọn một mật khẩu',
                      style:
                          AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppTextInput(
                      inputType: AppTextInputType.password,
                      controller: _pwCtrl,
                      focusNode: _pwFocus,
                      hint: 'Mật khẩu',
                      errorText:
                          _showError ? 'Mật khẩu tối thiểu 8 ký tự.' : null,
                      status: _showError
                          ? AppTextInputStatus.error
                          : _canContinue
                              ? AppTextInputStatus.success
                              : AppTextInputStatus.normal,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    const _InfoPill(
                      text: 'Mật khẩu của bạn phải dài tối thiểu 8 ký tự',
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.bw800,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        text,
        style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
      ),
    );
  }
}
