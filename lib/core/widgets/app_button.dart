import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Port of FlutterFlow's `FFButtonWidget` as the FF pages configure it:
/// filled, elevation 3, rounded corners, optional border and leading icon.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 60,
    this.color = AppColors.buttonOrange,
    this.textColor = Colors.white,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w600,
    this.radius = 16,
    this.elevation = 3,
    this.borderColor = Colors.transparent,
    this.borderWidth = 1,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  final String text;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final Color color;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double radius;
  final double elevation;
  final Color borderColor;
  final double borderWidth;
  final Widget? icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      textAlign: TextAlign.center,
      style: AppText.style(fontSize: fontSize, fontWeight: fontWeight, color: textColor),
    );
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          elevation: elevation,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: borderColor, width: borderWidth),
          ),
        ),
        child: icon == null
            ? label
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [icon!, const SizedBox(width: 8), Flexible(child: label)],
              ),
      ),
    );
  }
}
