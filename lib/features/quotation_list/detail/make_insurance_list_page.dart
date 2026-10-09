import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../router/app_router.dart';
import '../../search_package/quotation/pdf_frame.dart';
import '../data/lead_api.dart';
import '../list/quotation_list_page.dart';
import '../models/lead_detail_item.dart';
import '../state/quotation_list_state.dart';
import 'history_sheet.dart';

/// Port of FF `MakeInsuranceListPage` as the quotation list's 'ทำประกัน'
/// opens it: `list` = `get-lead-by-id` `watingInfo`, `checkTotal` =
/// `status_waiting_info`, `checkPayment: '0'`, `checkVMI: '0'`.
///
/// Per card: insurer logo / name, customer, cover, sum insured, garage,
/// statuses, and the buttons 'ดูใบเสนอราคา' (QuotationCopy), 'ดูกรมธรรม์'
/// (get-file-vmi), 'ดู พ.ร.บ' (get-file-cmi), 'ติดตามงาน' (get-history sheet),
/// 'เงื่อนไข บ.ประกัน' (insurer remark) and the main 'ทำประกัน' /
/// 'ดูรายละเอียด' button, whose targets (InsuranceInfoPage1 / 42 / 5,
/// NonePackageSelectedInsurerPage) aren't ported yet.
///
/// Not reachable from the list, so not ported: the `checkPayment == '1'`
/// filter / legend (MakeInsuranceTypeColor), the `fromPage: 'FollowUpPage'`
/// back target, and the FutureBuilder on Firestore `disable_work_weekend`
/// (its value was only read by an empty `if`).
class MakeInsuranceListPage extends StatefulWidget {
  const MakeInsuranceListPage({super.key});

  @override
  State<MakeInsuranceListPage> createState() => _MakeInsuranceListPageState();
}

class _MakeInsuranceListPageState extends State<MakeInsuranceListPage> {
  final _state = QuotationListState.instance;
  final _api = LeadApi.instance;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    if (_state.detailItems == null) {
      // Opened by refresh / deep link without the list's data.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.quotationList);
      });
    } else {
      _state.searchQuotationStatus = '0';
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.quotationList);
    }
  }

  bool _visible(LeadDetailItem item) {
    final q = _search.text;
    final nameMatch = q.isEmpty || containWordinStringUrl(q, item.firstName);
    final status = _state.searchQuotationStatus;
    return nameMatch && (status == '0' || status == item.paymentStatus);
  }

  // ---- actions --------------------------------------------------------------

  void _openQuotationCopy(LeadDetailItem item) {
    _state.quotationCopyUrls = item.pdfQuotationList;
    context.push(AppRoutes.quotationCopy);
  }

  /// FF `launchURL` → new tab; https only.
  void _openUrl(String url) {
    if (isSafePdfUrl(url)) openUrlInNewTab(url);
  }

  /// 'ดูกรมธรรม์'. FF special-cased TNI / ชั้น 1 / auto (iOS: copy-link
  /// dialog, Android: external browser) because the in-app viewer couldn't
  /// open those files; on web every case opens a new tab.
  Future<void> _viewPolicy(LeadDetailItem item) async {
    final r = await withLoading(context, () => _api.getFileVmi(item.quotationId));
    if (!mounted) return;
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.httpStatus})');
      return;
    }
    if (r.status1 != 200) {
      await showAlert(context, r.message1 ?? '');
      return;
    }
    _openUrl(r.data ?? '');
  }

  /// 'ดู พ.ร.บ'.
  Future<void> _viewAct(LeadDetailItem item) async {
    final r = await withLoading(context, () => _api.getFileCmi(item.quotationId));
    if (!mounted) return;
    if (!r.isHttpOk) {
      await showAlert(context, httpErrorText(r.httpStatus));
      return;
    }
    if (r.status1 != 200) {
      await showAlert(context, '${r.message1}');
      return;
    }
    _openUrl(r.data ?? '');
  }

  /// 'ติดตามงาน'.
  Future<void> _followUp(LeadDetailItem item) async {
    final r = await withLoading(context, () => _api.getHistory(item.quotationId));
    if (!mounted) return;
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.httpStatus})');
      return;
    }
    if (r.status1 != 200) {
      await showAlert(context, r.message1 ?? '');
      return;
    }
    await HistorySheet.show(context, r.data ?? const []);
  }

  /// The main button. Every target is a mobile page not ported yet; the
  /// branching (which page FF opens) is kept so the hand-off is right.
  Future<void> _mainAction(LeadDetailItem item) async {
    final status = item.quotationStatus;
    if (_state.checkVmi == '0') {
      if (status != 'เตรียมข้อมูล' && status != 'รอตัดสินใจ' && status != 'ส่งเรื่องขอใบเสนอราคา') {
        const toPage5 = {
          'อยู่ระหว่างตรวจสอบสภาพรถ',
          'อนุมัติ',
          'ไม่อนุมัติ',
          'ส่งเรื่องให้บริษัทประกันพิจารณา',
          'ยกเลิก',
          'ขอคืนเงิน',
          'โยกเงิน',
        };
        _notPorted(toPage5.contains(status) ? 'InsuranceInfoPage5' : 'InsuranceInfoPage42');
      } else if (item.quotationType == 'auto') {
        _notPorted('InsuranceInfoPage1');
      } else if (status == 'รอตัดสินใจ') {
        // FF also cleared insuranceInfoPage1/2/3SaveDataCheckBool here.
        _notPorted('NonePackageSelectedInsurerPage');
      } else {
        _notPorted('InsuranceInfoPage1');
      }
      return;
    }
    // checkVMI ≠ '0' (current-month policy list; not reachable from the list).
    if (item.isCmi) {
      _notPorted('InsuranceInfoPage5');
    } else if (item.vmiDocumentUrl != '') {
      await _viewPolicy(item);
    } else {
      await showAlert(context, 'กรุณารอทางทีมประกันเพิ่มข้อมูลในระบบ', title: 'ไม่พบไฟล์ในระบบ');
    }
  }

  void _notPorted(String page) => context.push(AppRoutes.notPorted(page));

  // ---- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final items = _state.detailItems ?? const <LeadDetailItem>[];
    return UnfocusOnTap(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: tanjaiAppBar(
          title: _state.checkVmi == '0' ? 'รายการ' : 'รายการกรมธรรม์เดือนปัจจุบัน',
          titleColor: const Color(0xFF003063),
          backColor: const Color(0xFFD9761A),
          onBack: _back,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 12, 5),
                      child: Text('ค้นหาชื่อลูกค้า', style: AppText.style(fontSize: 15)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SearchNameBox(controller: _search),
                    ),
                  ],
                ),
              ),
              Expanded(
                // FF: `checkTotal != 0` (null counts as non-zero) → list.
                child: _state.checkTotal != 0
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 50),
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final item = items[i];
                              if (!_visible(item)) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _card(item),
                              );
                            },
                          ),
                        ),
                      )
                    : const Center(child: NoDataBox()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(LeadDetailItem item) {
    final payment = _state.checkPayment == '1';
    final Color fill;
    final Color border;
    if (item.paymentStatusCheck && payment) {
      fill = const Color(0xFFFFE090);
      border = AppColors.warning;
    } else if (item.paymentStatusCheckSec && payment) {
      fill = const Color(0xFFCCEBE2);
      border = AppColors.success;
    } else {
      fill = AppColors.secondaryBackground;
      border = AppColors.primaryText;
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _InsurerImage(url: item.image),
                ),
                Expanded(child: _details(item)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!item.isCmi)
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ราคาเบี้ย (ไม่รวม พรบ.)', style: AppText.style(fontSize: 13)),
                        Text(
                          item.grossTotalNet != '' ? _orDash(showNumberWithComma(item.grossTotalNet)) : '-',
                          style: AppText.style(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (item.isCmi) const SizedBox(width: 100, height: 40),
                if (_showMainButton(item))
                  _button(_mainButtonText(item), const Color(0xFFDB771A), () => _mainAction(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _details(LeadDetailItem item) {
    final label = AppText.style(fontSize: 13);
    Widget row(String l, String v, {double bottom = 0}) => Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l, style: label),
              Flexible(child: Text(v, textAlign: TextAlign.end, style: label)),
            ],
          ),
        );
    final rejected = checkNullValueAndReturn(item.insurerStatus) == 'ปฏิเสธ';
    final remark = checkNullValueAndReturn(item.insurerRemark);
    final insurerRejected = item.isManual && rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.insurerName,
            style: AppText.style(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1D4774))),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ชื่อ', style: label),
            Flexible(
              child: Text('${item.firstName} ${item.lastName}',
                  maxLines: 2, textAlign: TextAlign.end, style: label),
            ),
          ],
        ),
        if (!item.isCmi) row('ประเภทประกัน', item.coverTypeName),
        if (!(item.quotationTypeName == 'งานนอกเรท' || item.isCmi))
          row('ทุนประกัน', item.sumInsured != '' ? item.sumInsured : '-'),
        if (item.isCmi)
          row('ราคาเบี้ยอากรและภาษีรวมเงิน',
              item.actTotal != '' ? _orDash(showNumberWithComma(item.actTotal)) : '-'),
        if (!item.isCmi) row('ประเภทซ่อม', item.garageTypeName),
        Row(
          children: [
            Expanded(child: Text('สถานะการดำเนินงาน', style: label)),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  rejected ? checkNullValueAndReturn(item.insurerStatus) : item.quotationStatus,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  style: AppText.style(fontSize: 13, color: rejected ? AppColors.error : AppColors.primaryText),
                ),
              ),
            ),
          ],
        ),
        if (_state.checkPayment == '1' || item.quotationStatus == 'ขอคืนเงิน')
          row('สถานะการชำระเงิน', item.paymentStatus),
        row('ขอเบี้ย', item.quotationTypeBakName, bottom: 5),
        row('ประเภทงาน', item.quotationTypeName, bottom: 5),
        row('ผลิตภัณฑ์', item.subProductName, bottom: 5),
        // FF: pdf_quotation.toString() != '' — a null field ('null') counts.
        if (item.pdfQuotationText != '' && !insurerRejected && !item.isCmi)
          _buttonRow('ใบเสนอราคา', 'ดูใบเสนอราคา', const Color(0xFF5D78FF), () => _openQuotationCopy(item)),
        if (item.quotationStatus == 'อนุมัติ' && !item.isCmi)
          _buttonRow('กรมธรรม์', 'ดูกรมธรรม์', const Color(0xFFA75194), () => _viewPolicy(item), top: 8),
        if (item.quotationStatus == 'อนุมัติ' && item.flgAct == '1')
          _buttonRow('พ.ร.บ', 'ดู พ.ร.บ', const Color(0xFFA3933D), () => _viewAct(item), top: 8),
        if (item.isManual)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_button('ติดตามงาน', AppColors.secondary, () => _followUp(item))],
            ),
          ),
        if (item.isManual && remark != '-' && remark != '')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _button('เงื่อนไข บ.ประกัน', const Color(0xFFCC0000), () => showAlert(context, remark),
                    fontSize: 15, borderColor: Colors.transparent),
              ],
            ),
          ),
      ],
    );
  }

  /// FF: (pdf_quotation present and not '-') and (manual → insurer not
  /// rejected) and is_active == '1'; or any CMI item. (FF's ternary on
  /// 'ส่งเรื่องขอใบเสนอราคา' had the same check on both branches.)
  bool _showMainButton(LeadDetailItem item) {
    final pdf = item.pdfQuotationText;
    final hasPdf = pdf != '' && checkNullValueAndReturn(pdf) != '-';
    final notRejected = !item.isManual || checkNullValueAndReturn(item.insurerStatus) != 'ปฏิเสธ';
    return (hasPdf && notRejected && item.isActive == '1') || item.isCmi;
  }

  String _mainButtonText(LeadDetailItem item) {
    if (_state.checkVmi == '0') {
      const viewOnly = {'ยกเลิก', 'โยกเงิน', 'ขอคืนเงิน', 'ไม่อนุมัติ'};
      return viewOnly.contains(item.quotationStatus) ? 'ดูรายละเอียด' : 'ทำประกัน';
    }
    return item.isCmi ? 'ทำ พ.ร.บ' : 'ดูกรมธรรม์';
  }

  static String _orDash(String v) => v.isEmpty ? '-' : v;

  Widget _buttonRow(String label, String text, Color color, VoidCallback onPressed, {double top = 0}) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.style(fontSize: 13)),
          _button(text, color, onPressed),
        ],
      ),
    );
  }

  /// FF h40 w115 radius-15 buttons, white 13 w500 text.
  Widget _button(String text, Color color, VoidCallback onPressed,
      {double fontSize = 13, Color? borderColor}) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      width: 115,
      height: 40,
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      radius: 15,
      borderColor: borderColor ?? color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

/// 50×50 insurer logo; FF fell back to `assets/images/error_image.png`.
class _InsurerImage extends StatelessWidget {
  const _InsurerImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const fallback = Image(
      image: AssetImage('assets/images/error_image.png'),
      width: 50,
      height: 50,
      fit: BoxFit.cover,
    );
    final uri = Uri.tryParse(url);
    final usable = uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
    return Container(
      width: 50,
      height: 50,
      color: AppColors.secondaryBackground,
      child: usable
          ? Image.network(
              url,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (_, _, _) => fallback,
            )
          : fallback,
    );
  }
}
