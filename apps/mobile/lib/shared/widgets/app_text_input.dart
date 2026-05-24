import 'package:flutter/material.dart';

enum AppTextInputType { email, username, name, password }

class AppTextInput extends StatefulWidget {
  const AppTextInput({
    super.key,
    required this.inputType,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.errorText,
    this.label,
    this.hint,
  });

  final AppTextInputType inputType;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? label;
  final String? hint;

  @override
  State<AppTextInput> createState() => _AppTextInputState();
}

class _AppTextInputState extends State<AppTextInput> {
  bool _obscure = true;

  bool get _isPassword => widget.inputType == AppTextInputType.password;

  @override
  Widget build(BuildContext context) {
    // TODO(A/NganTNK): implement per Figma — Default/Active/Error states
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      keyboardType: _keyboardType(),
      obscureText: _isPassword && _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        suffixIcon: _isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  TextInputType _keyboardType() {
    switch (widget.inputType) {
      case AppTextInputType.email:
        return TextInputType.emailAddress;
      case AppTextInputType.username:
        return TextInputType.text;
      case AppTextInputType.name:
        return TextInputType.name;
      case AppTextInputType.password:
        return TextInputType.visiblePassword;
    }
  }
}
