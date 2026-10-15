import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../router/app_router.dart';
import '../../quotation_list/data/lead_api.dart';
import '../../quotation_list/list/quotation_list_page.dart' show NoDataBox, SearchNameBox;
import '../../search_package/quotation/pdf_frame.dart';
import '../models/fire_lead.dart';
import '../state/fire_quotation_list_state.dart';

/// Port of FF `MakeFireInsuranceListPage` as the fire list's 'ทำประกัน'
/// opens it (`checkPayment: '0'`, `checkVMI: '0'`, `checkTotal: 1`, `list` =
/// the tapped lead).
///
/// Per card: insurer image / name, customer, insurance type, plan, status,
/// 'ดูใบเสนอราคา' (FireQuotationCopy), 'ดูกรมธรรม์' when approved
/// (get-file-vmi), the premium and the main 'ทำประกัน' / 'ดูกรมธรรม์'
/// button, whose targets (InsuranceInfoPage1 / 42 / 5) aren't ported yet.
///
/// Not reachable from the list, so not ported: the `checkPayment == '1'`
/// legend / calendar buttons, the `checkVMI != '0'` (current-month policy)
/// variant, and the Firestore `insurance_request_api_url` FutureBuilder (its
/// value was never used). The hidden 'ติดตามงาน' button (`if (false)` in FF)
/// is left out. The main button's reset of ~100 `nonePackage*` FFAppState
/// fields belongs to the manual-request flow and isn't needed here.
class MakeFireInsuranceListPage extends StatefulWidget {
  const MakeFireInsuranceListPage({super.key});

  @override
  State<MakeFireInsuranceListPage> createState() => _MakeFireInsuranceListPageState();
}

class _MakeFireInsuranceListPageState extends State<MakeFireInsuranceListPage> {
  final _state = FireQuotationListState.instance;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    if (_state.detailLeads == null) {
      // Opened by refresh / deep link without the list's data.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.fireQuotationList);
      });
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
      context.go(AppRoutes.fireQuotationList);
    }
  }

  /// FF: search text in `first_name` or `last_name` (case-sensitive).
  bool _visible(FireLead lead) {
    final q = _search.text;
    return q.isEmpty || containWordinStringUrl(q, lead.text('first_name')) || containWordinStringUrl(q, lead.text('last_name'));
  }

  /// `app_detail_house[0].<field>` when set, else `leads_detail_house[0]`.
  static String _appOrLead(FireLead lead, String Function(FireLeadDetail d) field) {
    final app = field(lead.appDetail);
    return app != '' && app != 'null' ? app : field(lead.detail);
  }

  // ---- actions --------------------------------------------------------------

  Future<void> _openQuotationCopy(FireLead lead) async {
    final pdf = lead.detail.pdfQuotation;
    if (pdf == '' || pdf == 'null') {
      await showAlert(context, 'ไม่พบไฟล์ใบเสนอราคา');
      return;
    }
    if (!mounted) return;
    _state.quotationCopyUrls = [pdf];
    context.push(AppRoutes.fireQuotationCopy);
  }

  /// 'ดูกรมธรรม์' (approved). FF special-cased TNI / ชั้น 1 / auto (motor
  /// fields a fire lead doesn't have); on web every case opens a new tab.
  Future<void> _viewPolicy(FireLead lead) async {
    final r = await withLoading(context, () => LeadApi.instance.getFileVmi(lead.text('quotation_id')));
    if (!mounted) return;
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.httpStatus})');
      return;
    }
    if (r.status1 != 200) {
      await showAlert(context, r.message1 ?? '');
      return;
    }
    final url = r.data ?? '';
    if (isSafePdfUrl(url)) openUrlInNewTab(url);
  }

  /// The main button: every target is a mobile page not ported yet; the
  /// branching (which page FF opens) is kept so the hand-off is right.
  void _mainAction(FireLead lead) {
    final status = lead.text('quotation_status');
    const beforeApplication = {'เตรียมข้อมูล', 'รอตัดสินใจ', 'ส่งเรื่องขอใบเสนอราคา'};
    const toPage5 = {
      'อยู่ระหว่างตรวจสอบสภาพรถ',
      'อนุมัติ',
      'ไม่อนุมัติ',
      'ส่งเรื่องให้บริษัทประกันพิจารณา',
      'ยกเลิก',
      'ขอคืนเงิน',
      'โยกเงิน',
    };
    final String page;
    if (!beforeApplication.contains(status)) {
      page = toPage5.contains(status) ? 'InsuranceInfoPage5' : 'InsuranceInfoPage42';
    } else {
      // FF: `'auto' == quotation_type || true` → always InsuranceInfoPage1
      // (fromPage 'FireInsurance').
      page = 'InsuranceInfoPage1';
    }
    context.push(AppRoutes.notPorted(page));
  }

  // ---- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final leads = _state.detailLeads ?? const <FireLead>[];
    return PopScope(
      canPop: false,
      child: UnfocusOnTap(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: tanjaiAppBar(
            title: 'รายการ',
            titleColor: const Color(0xFF003063),
            backColor: AppColors.sheetButtonOrange,
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
                  // FF checkTotal is always 1 from the list; an empty list
                  // shows the no-data box instead of nothing.
                  child: leads.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 50),
                            itemCount: leads.length,
                            itemBuilder: (context, i) {
                              final lead = leads[i];
                              if (!_visible(lead)) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _card(lead),
                              );
                            },
                          ),
                        )
                      : const Center(child: NoDataBox()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(FireLead lead) {
    final approved = lead.text('quotation_status') == 'อนุมัติ';
    final premium = _appOrLead(lead, (d) => d.netPremiumTotal);
    final premiumText = returnNumberWithComma2Decimal(premium);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(),
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
                  child: _LeadImage(url: _appOrLead(lead, (d) => d.image)),
                ),
                Expanded(child: _details(lead, approved)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ราคาเบี้ยประกัน/ปี \n(ไม่รวมภาษีเเละอากร)', style: AppText.style(fontSize: 13)),
                        // FF valueOrDefault(..., 'net_premium_total') — kept.
                        Text(
                          '${premiumText.isEmpty ? 'net_premium_total' : premiumText} บาท',
                          style: AppText.style(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                if (lead.text('sub_product') == 'CMI') const SizedBox(width: 100, height: 40),
                _button(approved ? 'ดูกรมธรรม์' : 'ทำประกัน', const Color(0xFFDB771A), () => _mainAction(lead)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _details(FireLead lead, bool approved) {
    final label = AppText.style(fontSize: 13);
    Widget row(String l, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l, style: label),
              Flexible(child: Text(v, textAlign: TextAlign.end, style: label)),
            ],
          ),
        );
    final insurerStatus = checkNullValueAndReturn(lead.detail.insurerStatus);
    final status = insurerStatus != 'ปฏิเสธ' ? lead.text('quotation_status') : insurerStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _appOrLead(lead, (d) => d.insurerName),
            style: AppText.style(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1D4774)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('ชื่อ', style: label)),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${lead.text('first_name')} ${lead.text('last_name')}',
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    style: label,
                  ),
                ),
              ),
            ],
          ),
        ),
        row('ประเภทประกัน', lead.text('insurance_type')),
        row('เเผนประกัน', _appOrLead(lead, (d) => d.packageName)),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text('สถานะการดำเนินงาน', style: AppText.style(fontSize: 13))),
              Expanded(
                child: Text(status, textAlign: TextAlign.end, maxLines: 2, style: AppText.style(fontSize: 13)),
              ),
            ],
          ),
        ),
        _buttonRow('ใบเสนอราคา', 'ดูใบเสนอราคา', const Color(0xFF5D78FF), () => _openQuotationCopy(lead)),
        if (approved)
          _buttonRow('กรมธรรม์', 'ดูกรมธรรม์', const Color(0xFFA75194), () => _viewPolicy(lead), top: 8),
      ],
    );
  }

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
  Widget _button(String text, Color color, VoidCallback onPressed) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      width: 115,
      height: 40,
      color: color,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      radius: 15,
      borderColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

/// 50×50 image; FF fell back to `assets/images/error_image.png`.
class _LeadImage extends StatelessWidget {
  const _LeadImage({required this.url});

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
