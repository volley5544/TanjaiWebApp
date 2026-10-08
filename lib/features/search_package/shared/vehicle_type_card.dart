import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';

/// Card of the vehicle-type pickers (FF SearchableCarListPage /
/// SearchablePickUpListPage): label on the left, car image on the right,
/// 65px bordered box with a light divider under the row.
class VehicleTypeCard extends StatelessWidget {
  const VehicleTypeCard({
    super.key,
    required this.label,
    required this.image,
    required this.imageWidth,
    required this.imageRightPadding,
    required this.onTap,
  });

  final String label;
  final String image;
  final double imageWidth;
  final double imageRightPadding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 65,
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 0.5),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(label, style: AppText.bodyMedium),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: imageRightPadding),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(image, width: imageWidth, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
              ),
              // FF used a default 16px Divider (overflowing the 65px box);
              // a 4px one keeps the same line without overflow.
              const Divider(height: 4, thickness: 1, color: AppColors.accent4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scaffold of the vehicle-type pickers: #FAFAFA page, 16px navy title, list
/// of [cards] with 12px top / 24px bottom gaps. System back disabled (FF).
class VehicleTypePickerScaffold extends StatelessWidget {
  const VehicleTypePickerScaffold({super.key, required this.title, required this.cards});

  final String title;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: tanjaiAppBar(title: title, titleSize: 16, onBack: () => Navigator.of(context).pop()),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(padding: EdgeInsets.zero, children: cards),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
