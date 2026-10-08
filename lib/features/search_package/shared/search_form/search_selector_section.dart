import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/selector_tile.dart';

/// One labelled selector field of the search form (FF section template 6.1):
/// label + red required note, then a 60px tile with the value and a chevron.
///
/// [provinceStyle] = the จังหวัดที่จดทะเบียน variant (5px top gap, label
/// padding 20, default label colour, radius 8, #B3B3B3 1px border).
class SearchSelectorSection extends StatelessWidget {
  const SearchSelectorSection({
    super.key,
    required this.label,
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
    this.note = '(บังคับเลือก)',
    this.labelColor = AppColors.labelGrey,
    this.provinceStyle = false,
  });

  final String label;
  final String note;
  final String value;
  final bool isPlaceholder;
  final VoidCallback? onTap;
  final Color labelColor;
  final bool provinceStyle;

  @override
  Widget build(BuildContext context) {
    if (provinceStyle) {
      return Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FieldLabel(
              label: label,
              note: note,
              labelColor: AppColors.primaryText,
              noteColor: const Color(0xFFFB0606),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            SelectorTile(
              value: value,
              isPlaceholder: isPlaceholder,
              onTap: onTap,
              radius: 8,
              borderColor: AppColors.secondaryText,
              borderWidth: 1,
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, note: note, labelColor: labelColor),
        SelectorTile(value: value, isPlaceholder: isPlaceholder, onTap: onTap),
      ],
    );
  }
}

/// FF `containerOnPageLoadAnimation`: fade 0→1 + move (0,-20)→(0,0), 500 ms
/// easeInOut — played when the child (the รุ่นรถ section) first appears.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, -20 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

/// Centred 50×50 spinner (FF FutureBuilder loading state).
class SectionSpinner extends StatelessWidget {
  const SectionSpinner({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 50,
      height: 50,
      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
    ),
  );
}
