import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const _family = 'Nunito';

  // text-xs — 12px
  static const xsRegular = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
  );
  static const xsSemiBold = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
  );

  // text-sm — 14px
  static const smRegular = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 18 / 14,
  );
  static const smMedium = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 18 / 14,
  );
  static const smSemiBold = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
  );

  // text-base — 18px
  static const baseBold = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 24 / 18,
  );

  // text-md — 16px
  static const mdRegular = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 22 / 16,
  );
  static const mdSemiBold = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 22 / 16,
  );
  static const mdBold = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 22 / 16,
  );

  // text-lg — 20px
  static const lgBold = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 28 / 20,
  );

  // text-xl — 24px
  static const xlRegular = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 30 / 24,
  );
  static const xlBold = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 30 / 24,
  );

  // text-2xl — 32px
  static const xl2Regular = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 42 / 32,
  );
  static const xl2Bold = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 42 / 32,
  );

  // text-3xl — 36px
  static const xl3Bold = TextStyle(
    fontFamily: _family,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 46 / 36,
  );
}
