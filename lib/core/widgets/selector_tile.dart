import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Label row above a field: `<label>` + red `<required note>` — the FF
/// search form's section header (Noto Sans Thai w500 15 / w600 12).
class FieldLabel extends StatelessWidget {
  const FieldLabel({
    super.key,
    required this.label,
    this.note = '',
    this.labelColor = AppColors.labelGrey,
    this.noteColor = AppColors.requiredRed,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 4),
  });

  final String label;
  final String note;
  final Color labelColor;
  final Color noteColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(label, style: AppText.style(fontSize: 15, fontWeight: FontWeight.w500, color: labelColor)),
          if (note.isNotEmpty)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(note, style: AppText.style(fontSize: 12, color: noteColor)),
              ),
            ),
        ],
      ),
    );
  }
}

/// The FF "selector tile": 60px bordered box with the current value (grey when
/// it's still a placeholder) and a trailing chevron. Tapping opens a picker.
class SelectorTile extends StatelessWidget {
  const SelectorTile({
    super.key,
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
    this.radius = 10,
    this.borderColor = Colors.black,
    this.borderWidth = 0.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final String value;
  final bool isPlaceholder;
  final VoidCallback? onTap;
  final double radius;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          padding: const EdgeInsets.only(left: 20, right: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.style(
                    fontSize: 15,
                    color: isPlaceholder ? AppColors.placeholderGrey : Colors.black,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppColors.chevronGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
