import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// SmoothPageIndicator(axisDirection vertical, ExpandingDotsEffect(
/// expansionFactor 2, spacing 8, radius 16, dotWidth 16, dotHeight 8,
/// dotColor lineColor, activeDotColor tertiary)). Vertical rotates the dots,
/// so each is 8 wide and 16 (active up to 32) tall. Tap → animate to page.
class VerticalExpandingDots extends StatelessWidget {
  const VerticalExpandingDots({super.key, required this.controller, required this.count});

  final PageController controller;
  final int count;

  static const _dotLength = 16.0;
  static const _dotThickness = 8.0;
  static const _expansion = 2.0;
  static const _spacing = 8.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.hasClients && controller.position.haveDimensions
            ? (controller.page ?? 0)
            : controller.initialPage.toDouble();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              _dot(i, (1 - (page - i).abs()).clamp(0.0, 1.0)),
          ],
        );
      },
    );
  }

  Widget _dot(int i, double t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _spacing / 2),
      child: GestureDetector(
        onTap: () => controller.animateToPage(i,
            duration: const Duration(milliseconds: 500), curve: Curves.ease),
        child: Container(
          width: _dotThickness,
          height: _dotLength + _dotLength * (_expansion - 1) * t,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.lineColor, AppColors.tertiary, t),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
