import 'package:flutter/material.dart';

// TODO(T11/NganTNK): implement LoginPasswordPage theo Figma — Đăng nhập_Nhập MK + Thành công
class LoginPasswordPage extends StatelessWidget {
  const LoginPasswordPage({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Login Password ($email) — TODO')),
    );
  }
}
