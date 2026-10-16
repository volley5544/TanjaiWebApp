import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../state/quotation_list_state.dart';

/// Port of FF `MakeInsuranceTypeColor` (ค้นหาสถานะ) — the payment-status
/// filter of MakeInsuranceListPage when opened from the follow-up page's
/// 'รายการลูกค้าชำระเงิน' (`checkPayment == '1'`). Writes
/// `QuotationListState.searchQuotationStatus` (cards show when it is '0' or
/// equals their `payment_status`).
///
/// FF quirks kept: opening the sheet sets the filter to '' (only cards with an
/// empty payment_status match) until a row or ✕ is chosen; the sheet can't be
/// dismissed by tapping outside; the 'ชำระแล้ว' box shows ticked for
/// 'ชำระเงินแล้ว' but selecting it sets 'ชำระแล้ว'.
class PaymentStatusFilterSheet extends StatelessWidget {
  const PaymentStatusFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    final state = QuotationListState.instance;
    state.searchQuotationStatus = '';
    state.notify();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SizedBox(height: MediaQuery.sizeOf(ctx).height * 0.7, child: const PaymentStatusFilterSheet()),
    );
  }

  void _set(BuildContext context, String value) {
    final state = QuotationListState.instance;
    state.searchQuotationStatus = value;
    state.notify();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final current = QuotationListState.instance.searchQuotationStatus;
    Widget row(Color fill, Color border, String label, bool checked, String value) => SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: fill, shape: BoxShape.circle, border: Border.all(color: border)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(label, style: AppText.style(color: Colors.black)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: checked,
                    shape: const CircleBorder(),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(width: 2, color: AppColors.secondaryText),
                    activeColor: const Color(0xFF39EF4E),
                    checkColor: AppColors.primaryBackground,
                    onChanged: (v) {
                      if (v == true) _set(context, value);
                    },
                  ),
                ),
              ],
            ),
          ),
        );

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
                    child: Text('ค้นหาสถานะ', style: AppText.headlineSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFFFF0000), size: 30),
                      onPressed: () => _set(context, '0'),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 0, 8),
                child: Text('เเถบสีเเสดงสถานะดังนี้', style: AppText.bodySmall),
              ),
              row(const Color(0xFFFAE187), const Color(0xFFFFDA00), 'รอชำระเงิน', current == 'รอชำระเงิน',
                  'รอชำระเงิน'),
              row(const Color(0xFF81FEC4), AppColors.success, 'ชำระแล้ว', current == 'ชำระเงินแล้ว', 'ชำระแล้ว'),
            ],
          ),
        ),
      ],
    );
  }
}
