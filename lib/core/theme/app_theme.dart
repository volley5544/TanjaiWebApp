import 'package:flutter/material.dart';

/// Colours of the Tanjai mobile app.
///
/// The `theme*` tokens are FlutterFlowTheme's light-mode values (the FF pages
/// reference them as `FlutterFlowTheme.of(context).xxx`); the rest are the
/// hard-coded colours the FF pages use most. Light mode only — the FF pages
/// hard-code most colours, so dark mode was never really supported.
abstract final class AppColors {
  // FlutterFlowTheme tokens (light).
  static const primary = Color(0xFF4B39EF);
  static const secondary = Color(0xFF39D2C0);
  static const tertiary = Color(0xFFEE8B60);
  static const alternate = Color(0xFFFF5963);
  static const primaryText = Color(0xFF101213);
  static const secondaryText = Color(0xFFB3B3B3);
  static const primaryBackground = Color(0xFFFFFFFF);
  static const secondaryBackground = Color(0xFFFFFFFF);
  static const accent1 = Color(0xFF616161);
  static const accent2 = Color(0xFF757575);
  static const accent3 = Color(0xFFE0E0E0);
  static const accent4 = Color(0xFFEEEEEE);
  static const success = Color(0xFF04A24C);
  static const warning = Color(0xFFFCDC0C);
  static const error = Color(0xFFE21C3D);
  static const info = Color(0xFF1C4494);
  static const primaryBtnText = Color(0xFFFFFFFF);
  static const lineColor = Color(0xFFE0E3E7);

  // Brand + frequently hard-coded colours.
  static const brandOrange = Color(0xFFDB771A); // icons, accents
  static const buttonOrange = Color(0xFFDB771B); // primary buttons
  static const backIconOrange = Color(0xFFDB7619);
  static const sheetButtonOrange = Color(0xFFD9761A);
  static const lightOrange = Color(0xFFFCEFE4);
  static const sliderOverlay = Color(0xFFFFBB7C);
  static const navy = Color(0xFF002D5E);
  static const titleNavy = Color(0xFF123063);
  static const requiredRed = Color(0xFFF40606);
  static const labelGrey = Color(0xFF404040);
  static const placeholderGrey = Color(0xFF9F9F9F);
  static const chevronGrey = Color(0xFF474747);
  static const textGrey = Color(0xFF646464);
  static const textDark = Color(0xFF222424);
  static const borderGrey = Color(0xFFCBD8D8);
  static const borderLight = Color(0xFFB9B9B9);
}

/// Typography: every FF page renders Noto Sans Thai (bundled, see pubspec),
/// default weight w600 from FF's `bodyMedium`.
abstract final class AppText {
  static const fontFamily = 'NotoSansThai';
  static const fallback = ['NotoSans'];

  /// The FF pattern `bodyMedium.override(font: notoSansThai(...), ...)`.
  static TextStyle style({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.primaryText,
    double? height,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: 0,
        height: height,
        decoration: decoration,
      );

  // FlutterFlowTheme typography (sizes/weights/colours as in the FF theme).
  static TextStyle get bodyMedium => style();
  static TextStyle get bodySmall => style(color: AppColors.secondaryText);
  static TextStyle get titleSmall => style(fontSize: 16, color: AppColors.secondaryText);
  static TextStyle get titleMedium => style(fontSize: 18);
  static TextStyle get titleLarge => style(fontSize: 22, fontWeight: FontWeight.w500);
  static TextStyle get headlineMedium => style(fontSize: 22, color: AppColors.secondaryText);
  static TextStyle get headlineSmall => style(fontSize: 20);
  static TextStyle get labelMedium => style(fontSize: 12, fontWeight: FontWeight.w500);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: AppText.fontFamily,
    fontFamilyFallback: AppText.fallback,
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.secondaryBackground,
    textTheme: base.textTheme.apply(fontFamily: AppText.fontFamily),
  );
}
