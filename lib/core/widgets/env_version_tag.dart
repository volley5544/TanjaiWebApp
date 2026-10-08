import 'package:flutter/material.dart';

import '../config/app_environment.dart';
import '../theme/app_theme.dart';

/// Small "(UAT ver12)" tag in every page's AppBar `actions` (same as
/// sawadLoanUniversal's `EnvVersionTag`), so testers can see which environment
/// and build (`WEB_VERSION` = the CI run number) the WebView is running.
/// Hidden on prod; local builds show "(UAT ver0)".
class EnvVersionTag extends StatelessWidget {
  const EnvVersionTag({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppEnvironment.current.isProduction) return const SizedBox.shrink();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          '(UAT ver$kWebVersion)',
          style: AppText.style(fontSize: 11, color: AppColors.secondaryText),
        ),
      ),
    );
  }
}
