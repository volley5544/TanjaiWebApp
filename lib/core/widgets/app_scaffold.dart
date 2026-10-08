import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The FF pages' standard AppBar: white, centred navy title (Noto Sans Thai
/// 18), orange back arrow (size 30) with no splash.
PreferredSizeWidget tanjaiAppBar({
  required String title,
  VoidCallback? onBack,
  Color backgroundColor = Colors.white,
  Color titleColor = AppColors.titleNavy,
  Color backColor = AppColors.backIconOrange,
  double titleSize = 18,
  List<Widget> actions = const [],
  Widget? titleWidget,
}) {
  return AppBar(
    backgroundColor: backgroundColor,
    surfaceTintColor: Colors.transparent,
    automaticallyImplyLeading: false,
    centerTitle: true,
    elevation: 0,
    leading: onBack == null
        ? null
        : InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            onTap: onBack,
            child: Icon(Icons.arrow_back, color: backColor, size: 30),
          ),
    title: titleWidget ??
        Text(title, style: AppText.style(fontSize: titleSize, color: titleColor)),
    actions: actions,
  );
}

/// Tap-anywhere-to-unfocus wrapper used by every FF page.
class UnfocusOnTap extends StatelessWidget {
  const UnfocusOnTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      );
}

/// Caps the content width on wide screens (desktop browser testing) while
/// staying full-width on phones / the host WebView.
class MobileFrame extends StatelessWidget {
  const MobileFrame({super.key, required this.child, this.maxWidth = 600});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= maxWidth) return child;
    // Pages size things as a fraction of MediaQuery width (FF style), so
    // report the framed width, not the browser window's.
    return ColoredBox(
      color: const Color(0xFFF1F4F8),
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: MediaQuery(
            data: mq.copyWith(size: Size(maxWidth, mq.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}
