import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../../router/app_router.dart';
import '../data/lead_api.dart';
import '../models/lead_detail_item.dart';
import '../state/quotation_list_state.dart';

const _navy = Color(0xFF204A77);

/// Port of FF `LeadFollowUpPage` (ติดตามประกันรถ): request-status counts from
/// `get-lead-list` (`list: 'list'`); each status tile opens
/// MakeInsuranceListPage with that status's list (FF `goNamed`, stack
/// replaced, `fromPage: 'FollowUpPage'` so its back returns here). From
/// 'เตรียมข้อมูล' → 'ทำประกัน' the user reaches request step 1.
///
/// Not ported: the mobile build-version gate. FontAwesome icons (no FA package
/// on web) → closest Material icons.
class LeadFollowUpPage extends StatefulWidget {
  const LeadFollowUpPage({super.key});

  @override
  State<LeadFollowUpPage> createState() => _LeadFollowUpPageState();
}

class _LeadFollowUpPageState extends State<LeadFollowUpPage> {
  bool _loading = true;
  LeadFollowUpResult? _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final r = await LeadApi.instance.getLeadFollowUp();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _data = r.data;
    });
    // FF: layer 1 (`$.statusCode`) ≠ 200 → 'พบข้อผิดพลาดConnection (<statusMessage>)';
    // layer 2 not 200 / 404 → 'พบข้อผิดพลาด (<results.statusMessage>)'.
    if (!r.isHttpOk || r.status1 != 200) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.message1 ?? r.httpStatus})');
    } else if (r.status2 != 200 && r.status2 != 404) {
      await showAlert(context, 'พบข้อผิดพลาด (${r.message2})');
    }
  }

  void _back() {
    // FF: loading overlay 500 ms, then goNamed(SuperAppPage).
    // TODO(bridge): hand control back to the host app instead of the web menu.
    context.go(AppRoutes.home);
  }

  /// FF `goNamed(MakeInsuranceListPage, checkTotal, list, checkPayment,
  /// fromPage: 'FollowUpPage')`.
  void _open(String countKey, String listKey, String checkPayment) {
    final d = _data;
    QuotationListState.instance.openDetail(
      items: d?.list(listKey) ?? const [],
      checkTotal: d?.count(countKey),
      checkPayment: checkPayment,
      fromPage: 'FollowUpPage',
    );
    context.go(AppRoutes.quotationDetail);
  }

  /// FF `count!.toString()` crashed when the key was missing → '0'
  /// (the last two tiles already used `valueOrDefault(…, '0')`).
  String _n(String key) => '${_data?.count(key) ?? 0}';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width * 0.4;
    Widget tile(Color color, IconData icon, String count, String label, {VoidCallback? onTap, double? width}) {
      final box = Container(
        width: width ?? w,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: AppColors.lineColor, offset: Offset(0, 1))],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(width: 1.5),
              ),
              child: Icon(icon, color: _navy, size: 30),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(count, style: AppText.style(fontSize: 15, fontWeight: FontWeight.w800, color: _navy)),
            ),
            Text(label, textAlign: TextAlign.center, style: AppText.style(fontWeight: FontWeight.bold, color: _navy)),
          ],
        ),
      );
      if (onTap == null) return box;
      return InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: box,
      );
    }

    Widget row(List<Widget> tiles) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: tiles),
        );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: tanjaiAppBar(
          title: 'ติดตามประกันรถ',
          titleColor: const Color(0xFF003063),
          backColor: AppColors.brandOrange,
          onBack: _back,
        ),
        body: SafeArea(
          child: _loading
              ? const PageLoadingView()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: tile(const Color(0xFFF6BD67), Icons.person_outline_sharp,
                            '${_data?.total ?? 0}', 'จำนวนงานทั้งหมด',
                            width: double.infinity),
                      ),
                      row([
                        tile(const Color(0xFFF9DCC3), Icons.directions_car_outlined, _n('auto'), 'งานในเรท'),
                        tile(const Color(0xFFD9D9D9), Icons.directions_car_outlined, _n('manual'), 'งานนอกเรท'),
                      ]),
                      row([
                        tile(const Color(0xFFF6EFB4), Icons.assignment_outlined, _n('status_waiting_info'),
                            'เตรียมข้อมูล',
                            onTap: () => _open('status_waiting_info', 'watingInfo', '0')),
                        tile(const Color(0xFFB6BFE3), Icons.directions_car_outlined, _n('status_waiting_car'),
                            'ตรวจสอบสภาพรถ',
                            onTap: () => _open('status_waiting_car', 'waitingCar', '0')),
                      ]),
                      row([
                        tile(const Color(0xFF8DEEA7), Icons.how_to_reg_outlined, _n('status_approve'), 'อนุมัติ',
                            onTap: () => _open('status_approve', 'approve', '0')),
                        tile(const Color(0xFFE5B2C3), Icons.highlight_off_outlined, _n('status_not_approve'),
                            'ไม่อนุมัติ',
                            onTap: () => _open('status_not_approve', 'notApprove', '0')),
                      ]),
                      row([
                        tile(const Color(0xFFC3F9D2), Icons.attach_money_sharp, _n('status_payment'),
                            'รายการลูกค้าชำระเงิน',
                            onTap: () => _open('status_payment', 'payments', '1')),
                        tile(const Color(0xFFE5B2C3), Icons.block, _n('status_cancle'), 'ยกเลิก',
                            onTap: () => _open('status_cancle', 'cancle', 'cancle')),
                      ]),
                      row([
                        tile(const Color(0xFFFFCC99), Icons.reply_all_sharp, _n('status_refund'), 'คืนเงิน',
                            onTap: () => _open('status_refund', 'refund', 'cancle')),
                        tile(const Color(0xFF99FFCC), Icons.payments_outlined, _n('status_transfer'), 'โยกเงิน',
                            onTap: () => _open('status_transfer', 'transfer', 'cancle')),
                      ]),
                      row([
                        tile(const Color(0xFFE9FFEA), Icons.schedule, _n('status_approve_installment'),
                            'รอ ภาค/สาขา อนุมัติ',
                            onTap: () => _open('status_approve_installment', 'approve_installment', '0')),
                        SizedBox(width: w),
                      ]),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
