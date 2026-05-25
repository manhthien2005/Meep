import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_radii.dart';
import 'package:meep/core/theme/app_text_styles.dart';

enum AppTextInputType { email, username, name, password }

enum AppTextInputStatus { normal, active, error, success }

class AppTextInput extends StatefulWidget {
  const AppTextInput({
    super.key,
    required this.inputType,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.errorText,
    this.hint,
    this.status = AppTextInputStatus.normal,
  });

  final AppTextInputType inputType;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? hint;
  final AppTextInputStatus status;

  @override
  State<AppTextInput> createState() => _AppTextInputState();
}

class _AppTextInputState extends State<AppTextInput> {
  FocusNode? _internalFocus;
  bool _hasFocus = false;
  bool _obscure = true;

  bool get _isPassword => widget.inputType == AppTextInputType.password;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocus!;

  // Active overrides normal when focused; error/success take precedence
  AppTextInputStatus get _effectiveStatus {
    if (widget.status == AppTextInputStatus.error) {
      return AppTextInputStatus.error;
    }
    if (widget.status == AppTextInputStatus.success) {
      return AppTextInputStatus.success;
    }
    if (_hasFocus) return AppTextInputStatus.active;
    return AppTextInputStatus.normal;
  }

  Color get _borderColor {
    return switch (_effectiveStatus) {
      AppTextInputStatus.active => AppColors.turquoise500,
      AppTextInputStatus.error => AppColors.error700,
      AppTextInputStatus.success => AppColors.success700,
      AppTextInputStatus.normal => Colors.transparent,
    };
  }

  Color get _fillColor {
    return switch (_effectiveStatus) {
      AppTextInputStatus.normal => AppColors.bw600,
      _ => AppColors.bw800,
    };
  }

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocus = FocusNode();
    }
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _internalFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _fillColor,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: _borderColor,
              width: _effectiveStatus == AppTextInputStatus.normal ? 0 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            keyboardType: _keyboardType(),
            obscureText: _isPassword && _obscure,
            style: AppTextStyles.mdSemiBold.copyWith(
              color: _effectiveStatus == AppTextInputStatus.error
                  ? AppColors.error700
                  : AppColors.bw100,
            ),
            cursorColor: AppColors.bw100,
            decoration: InputDecoration(
              hintText: widget.hint ?? _defaultHint(),
              hintStyle: AppTextStyles.mdSemiBold.copyWith(
                color: AppColors.bw400,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 19,
                horizontal: 30,
              ),
              border: InputBorder.none,
              suffixIcon: _suffix(),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 21),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.xsSemiBold.copyWith(
                color: AppColors.error700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _suffix() {
    if (_isPassword) {
      return IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.bw400,
          size: 20,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    }
    if (_effectiveStatus == AppTextInputStatus.success) {
      return const Padding(
        padding: EdgeInsets.only(right: 16),
        child: Icon(
          Icons.check_circle_outline,
          color: AppColors.success700,
          size: 20,
        ),
      );
    }
    return null;
  }

  String _defaultHint() {
    return switch (widget.inputType) {
      AppTextInputType.email => 'Địa chỉ email',
      AppTextInputType.username => 'Tên người dùng',
      AppTextInputType.name => 'Họ và tên',
      AppTextInputType.password => 'Mật khẩu',
    };
  }

  TextInputType _keyboardType() {
    return switch (widget.inputType) {
      AppTextInputType.email => TextInputType.emailAddress,
      AppTextInputType.username || AppTextInputType.name => TextInputType.text,
      AppTextInputType.password => TextInputType.visiblePassword,
    };
  }
}
