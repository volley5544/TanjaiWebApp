import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_scaffold.dart';

/// Stand-in for a mobile-app page that isn't part of the web port yet (e.g.
/// InsuranceInfoPage1, InsuranceListPage, SelectReasonPage). Shows which page
/// the flow would continue to, so testers can confirm the hand-off point.
class NotPortedPage extends StatelessWidget {
  const NotPortedPage({super.key, required this.pageName, this.details = const {}});

  final String pageName;

  /// Non-sensitive identifiers the next page would receive (e.g. quotation id).
  final Map<String, String> details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: tanjaiAppBar(
        title: 'ประกันทันใจ',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, color: AppColors.brandOrange, size: 48),
              const SizedBox(height: 16),
              Text('หน้านี้ยังไม่เปิดให้ใช้งานบนเว็บ',
                  style: AppText.style(fontSize: 18, color: AppColors.titleNavy)),
              const SizedBox(height: 8),
              Text(pageName, style: AppText.style(fontSize: 14, color: AppColors.textGrey)),
              for (final e in details.entries)
                Text('${e.key}: ${e.value}',
                    style: AppText.style(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textGrey)),
            ],
          ),
        ),
      ),
    );
  }
}
