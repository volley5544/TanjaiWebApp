import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// White page body with a centred spinner and an optional Thai caption — shown
/// while a page loads its initial data (API call on open). Same pattern as
/// sawadLoanUniversal's `PLoanLoadingView`: the AppBar stays so the user can
/// still go back. Actions the user triggers (search, save) keep the
/// [withLoading] overlay instead.
class PageLoadingView extends StatelessWidget {
  const PageLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.primaryBackground,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.brandOrange),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppText.style(fontWeight: FontWeight.w400, color: AppColors.secondaryText),
            ),
          ],
        ],
      ),
    );
  }
}
