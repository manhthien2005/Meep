import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quay lại',
      button: true,
      child: GestureDetector(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        child: SvgPicture.asset(
          'assets/icons/ic_back.svg',
          width: 40,
          height: 40,
        ),
      ),
    );
  }
}
