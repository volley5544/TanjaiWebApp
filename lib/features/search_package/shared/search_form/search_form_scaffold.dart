import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';

/// Page frame of the FF SearchInsurancePage: white AppBar with back arrow,
/// scrollable form (flex 10) and the bottom 'ค้นหา' bar (flex 2).
///
/// Purely presentational — each product page passes its own sections and
/// callbacks. System back is disabled like FF (`PopScope(canPop: false)`);
/// only the AppBar arrow leaves the page.
class SearchFormScaffold extends StatelessWidget {
  const SearchFormScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.onSearch,
    required this.sections,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onSearch;

  /// Form sections, shown with 8px gaps (20 above, 36 below).
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return UnfocusOnTap(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.secondaryBackground,
          appBar: tanjaiAppBar(title: title, onBack: onBack),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  flex: 10,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        for (var i = 0; i < sections.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          sections[i],
                        ],
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    color: AppColors.secondaryBackground,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AppButton(text: 'ค้นหา', onPressed: onSearch),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
