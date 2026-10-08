import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ff_functions.dart';
import '../../../../core/widgets/selector_tile.dart';

/// วันที่หมดอายุของประกันเดิม — optional old-policy expiry date tile (FF
/// section 9). Shows the date as `dd/MM/<BE year>` or the grey placeholder.
class ExpiryDateSection extends StatelessWidget {
  const ExpiryDateSection({super.key, required this.date, required this.onChanged});

  final DateTime? date;
  final ValueChanged<DateTime> onChanged;

  /// FF date picker: initial today, range 1900-01-01 … 2050-01-01. (The FF
  /// "cancel resets the date to today" quirk is intentionally dropped.)
  Future<void> _pick(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2050),
      locale: const Locale('th'),
    );
    if (picked != null) onChanged(DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final d = date;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel(label: 'วันที่หมดอายุของประกันเดิม', labelColor: Color(0xFF424242)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            onTap: () => _pick(context),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        d != null ? showDateBE(d.toString()) : 'กรุณาเลือกวันที่หมดอายุประกันเดิม',
                        style: AppText.style(fontSize: 15, color: d != null ? Colors.black : AppColors.secondaryText),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.edit_calendar_outlined, color: AppColors.chevronGrey, size: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
