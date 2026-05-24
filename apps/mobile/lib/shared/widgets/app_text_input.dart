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
  bool _obscure = true;
  bool get _isPassword => widget.inputType == AppTextInputType.password;

  Color get _borderColor {
    return switch (widget.status) {
      AppTextInputStatus.active => AppColors.turquoise500,
      AppTextInputStatus.error => AppColors.error700,
      AppTextInputStatus.success => AppColors.success700,
      AppTextInputStatus.normal => Colors.transparent,
    };
  }

  Color get _fillColor {
    return switch (widget.status) {
      AppTextInputStatus.normal => AppColors.bw600,
      _ => AppColors.bw800,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _fillColor,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: _borderColor),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            onChanged: widget.onChanged,
            keyboardType: _keyboardType(),
            obscureText: _isPassword && _obscure,
            style: AppTextStyles.mdSemiBold.copyWith(
              color: widget.status == AppTextInputStatus.error
                  ? AppColors.error700
                  : AppColors.bw100,
            ),
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
            padding: const EdgeInsets.only(left: 20),
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
    if (widget.status == AppTextInputStatus.success) {
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
