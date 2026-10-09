import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../state/quotation_list_state.dart';

/// Port of FF `InsuranceTypeColorWidget` — the quotation list's colour legend,
/// which doubles as its filter: ticking a row sets `searchList1` (`'manual'`
/// / `'auto'`) and closes; the red ✕ resets it to `'0'` (all) and closes.
/// Opened with `isDismissible: false`, so only those two close it.
class InsuranceTypeColorSheet extends StatefulWidget {
  const InsuranceTypeColorSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: const InsuranceTypeColorSheet(),
        ),
      );

  @override
  State<InsuranceTypeColorSheet> createState() => _InsuranceTypeColorSheetState();
}

class _InsuranceTypeColorSheetState extends State<InsuranceTypeColorSheet> {
  final _state = QuotationListState.instance;

  void _select(String value) {
    _state
      ..searchList1 = value
      ..notify();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.secondaryBackground,
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text('สถานะทั้งหมด', style: AppText.headlineSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, color: Color(0xFFFF0000), size: 30),
                        onPressed: () => _select('0'),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 0, 8),
                child: Text('เเถบสีเเสดงสถานะดังนี้', style: AppText.bodySmall),
              ),
              _row(
                fill: const Color(0xFFD9D9D9),
                border: const Color(0xFF95A1AC), // grayIcon
                label: 'งานนอกเรท',
                value: 'manual',
              ),
              _row(
                fill: const Color(0xFFF9DCC3),
                border: const Color(0xFFD9761A),
                label: 'งานในเรท',
                value: 'auto',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row({
    required Color fill,
    required Color border,
    required String label,
    required String value,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: border),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: AppText.style(color: Colors.black)),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Checkbox(
                        value: _state.searchList1 == value,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const CircleBorder(),
                        side: const BorderSide(width: 2, color: AppColors.secondaryText),
                        activeColor: const Color(0xFF39EF4E),
                        checkColor: AppColors.primaryBackground,
                        // FF only acted on ticking; unticking did nothing.
                        onChanged: (v) {
                          if (v == true) _select(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
