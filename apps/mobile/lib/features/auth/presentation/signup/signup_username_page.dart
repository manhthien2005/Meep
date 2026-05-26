import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/validators/auth_validators.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';
import 'package:meep/features/auth/application/sign_up_state.dart';
import 'package:meep/shared/widgets/app_back_button.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';
import 'package:meep/shared/widgets/app_text_input.dart';

/// Forces input to lowercase letters. Validation of allowed characters happens
/// in [AuthValidators.isUsernameFormatValid] so users can paste full strings
/// and see a clear error rather than silently dropped characters.
class _LowerCaseFormatter extends TextInputFormatter {
  const _LowerCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lower = newValue.text.toLowerCase();
    return lower == newValue.text ? newValue : newValue.copyWith(text: lower);
  }
}

class SignUpUsernamePage extends ConsumerStatefulWidget {
  const SignUpUsernamePage({super.key});

  @override
  ConsumerState<SignUpUsernamePage> createState() => _SignUpUsernamePageState();
}

class _SignUpUsernamePageState extends ConsumerState<SignUpUsernamePage> {
  static const _debounceDuration = Duration(milliseconds: 500);

  final _usernameCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameCtrl.dispose();
    super.dispose();
  }

  bool get _hasEnoughInput =>
      _usernameCtrl.text.trim().length >= AuthValidators.usernameMinLength;

  void _onUsernameChanged(String value) {
    // Clear stale error ngay để user thấy phản hồi tức thì
    ref.read(signUpControllerProvider.notifier).clearError();
    setState(() {});

    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < AuthValidators.usernameMinLength) return;

    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      unawaited(
        ref.read(signUpControllerProvider.notifier).checkUsername(trimmed),
      );
    });
  }

  Future<void> _onContinue() async {
    _debounce?.cancel();
    final username = _usernameCtrl.text.trim();

    // Nếu chưa kịp check (user tap trước khi debounce fire) → check ngay.
    if (!ref.read(signUpControllerProvider).isUsernameAvailable ||
        ref.read(signUpControllerProvider).username != username) {
      await ref.read(signUpControllerProvider.notifier).checkUsername(username);
      if (!mounted) return;
      if (!ref.read(signUpControllerProvider).isUsernameAvailable) return;
    }

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
    final inputStatus = _inputStatusFor(state);

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
                      style: AppTextStyles.xlBold.copyWith(
                        color: AppColors.bw100,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    AppTextInput(
                      inputType: AppTextInputType.username,
                      controller: _usernameCtrl,
                      hint: 'Tên người dùng',
                      status: inputStatus,
                      errorText: _errorTextFor(state),
                      inputFormatters: const [_LowerCaseFormatter()],
                      maxLength: AuthValidators.usernameMaxLength,
                      onChanged: _onUsernameChanged,
                    ),
                    const SizedBox(height: 20),
                    _StatusPill(state: state),
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

  AppTextInputStatus _inputStatusFor(SignUpState state) {
    if (state.username.isEmpty || state.isCheckingUsername) {
      return AppTextInputStatus.normal;
    }
    if (state.errorMessage != null || !state.isUsernameAvailable) {
      return AppTextInputStatus.error;
    }
    return AppTextInputStatus.success;
  }

  /// Lỗi inline dưới input — chỉ hiện khi user đã gõ và check đã chạy xong
  /// với kết quả không khả dụng hoặc lỗi format / mạng.
  String? _errorTextFor(SignUpState state) {
    if (state.username.isEmpty || state.isCheckingUsername) return null;
    if (state.isUsernameAvailable && state.errorMessage == null) return null;
    return state.errorMessage ??
        'Tên người dùng này đã tồn tại. Vui lòng chọn tên khác.';
  }
}

/// Pill hiển thị dưới input — 3 nhánh: hint mặc định, available, error.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.state});

  final SignUpState state;

  @override
  Widget build(BuildContext context) {
    final hasChecked = state.username.isNotEmpty;
    if (!hasChecked || state.isCheckingUsername) return const _HintPill();

    if (state.isUsernameAvailable && state.errorMessage == null) {
      return const Center(child: _AvailablePill());
    }
    if (state.errorMessage != null && state.isUsernameAvailable) {
      // createAccount() failed (vd email đã dùng, mạng lỗi) — khác với "taken"
      return _ErrorPill(message: state.errorMessage!);
    }
    return const _HintPill();
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill();

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

class _ErrorPill extends StatelessWidget {
  const _ErrorPill({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.error700.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        message,
        style: AppTextStyles.smSemiBold.copyWith(color: AppColors.error400),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AvailablePill extends StatelessWidget {
  const _AvailablePill();

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
