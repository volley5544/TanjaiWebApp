import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/firebase/firestore_rest.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/utils/tel_link.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../../router/app_router.dart';
import '../data/lead_api.dart';
import '../models/quotation_lead.dart';
import '../state/quotation_list_state.dart';
import 'insurance_type_color_sheet.dart';

/// FlutterFlow's `black600` theme colour (card text).
const _black600 = Color(0xFF090F13);

/// Port of FF `InsuranceListPage` (`insuranceListPage`) — the quotation list,
/// AppBar 'จำนวนลูกค้าทั้งหมด'.
///
/// * On open: `get-lead-list` (`mode: 'arunsawad'`, `list: 'quotation'`).
///   HTTP≠200 → 'พบข้อผิดพลาดConnection (<code>)'; `results.statusCode` not
///   200/404 → 'พบข้อผิดพลาด (<code>)'; 404 → 'ไม่พบข้อมูลในระบบ'.
/// * Search box filters on `first_name` (case-sensitive contains, as FF);
///   the ⚠ icon opens the colour legend, which also filters on
///   `quotation_type` (`searchList1`). Refresh reloads the page.
/// * Card buttons: 'แก้ไข' / 'คัดลอก' (none-package flow, not ported) and
///   'ทำประกัน' → confirm → `get-lead-by-id` → MakeInsuranceListPage.
///
/// Mobile-only parts left out: the build-version gate and the reset of ~100
/// `nonePackage*` / search-form FFAppState fields (they belong to flows that
/// aren't on web).
class QuotationListPage extends StatefulWidget {
  const QuotationListPage({super.key});

  @override
  State<QuotationListPage> createState() => _QuotationListPageState();
}

class _QuotationListPageState extends State<QuotationListPage> {
  final _state = QuotationListState.instance;
  final _search = TextEditingController();
  final _api = LeadApi.instance;

  bool _loading = true;
  LeadApiResult<QuotationLeadList>? _result;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _state.searchList1 = '0';
    setState(() {
      _loading = true;
      _result = null;
    });
    final r = await _api.getLeadList();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = r;
    });
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.httpStatus})');
    } else if (r.status2 != 200 && r.status2 != 404) {
      await showAlert(context, 'พบข้อผิดพลาด (${r.status2})');
    }
  }

  /// FF refresh icon: `goNamed(insuranceListPage)` → page rebuilt from scratch.
  void _refresh() {
    _search.clear();
    _load();
  }

  void _back() {
    // FF: resets the nonePackage* state, waits 500 ms, goes to SuperAppPage.
    // TODO(bridge): hand control back to the host app instead of the web menu.
    context.go(AppRoutes.home);
  }

  bool _visible(QuotationLead lead) {
    final q = _search.text;
    final nameMatch = q.isEmpty || containWordinStringUrl(q, lead.firstName ?? '');
    final filter = _state.searchList1;
    return nameMatch && (filter == '0' || filter == lead.quotationType);
  }

  // ---- card actions -------------------------------------------------------

  /// 'แก้ไข' / 'คัดลอก': FF loads InsuranceRequestDetailAPI into ~100
  /// nonePackage* fields, then opens the none-package edit flow — not on web.
  void _openNonePackage(String pageName) => context.push(AppRoutes.notPorted(pageName));

  /// 'ทำประกัน'.
  Future<void> _makeInsurance(QuotationLead lead) async {
    final ok = await showConfirm(context, 'ต้องการจะบันทึกเตรียมข้อมูลใช่หรือไม่?');
    if (!ok || !mounted) return;

    final (r, videoCallShown) = await withLoading(context, () async {
      final r = await _api.getLeadById(leadId: lead.leadId?.toString() ?? '');
      if (!r.isHttpOk || r.status2 != 200) return (r, false);
      // Firestore hideInAppContent 'video_call'.isShowContent — needs Firebase
      // auth, so on web it reads as missing → false (it is false in prod too).
      final doc = await FirestoreRest.instance
          .firstWhere('hideInAppContent', field: 'content_name', equals: 'video_call');
      return (r, doc?['isShowContent'] == true);
    });
    if (!mounted) return;

    if (!r.isHttpOk) {
      await showAlert(context, '${r.message1}(${r.httpStatus})', title: 'connection');
      return;
    }
    if (r.status2 != 200) {
      await showAlert(context, '${r.message2}(${r.status2})');
      return;
    }
    final data = r.data;
    // FF: video_call shown ? (profileIsHaveInsuranceCard || first
    // video_url != '') : true. profileIsHaveInsuranceCard isn't handed to the
    // web app yet → FF default false.
    const haveInsuranceCard = false;
    final firstVideoUrl = (data?.videoUrls.isNotEmpty ?? false) ? data!.videoUrls.first : null;
    final allowed = videoCallShown ? (haveInsuranceCard || firstVideoUrl != '') : true;
    if (allowed) {
      _state.openDetail(
        items: data?.waitingInfo ?? const [],
        checkTotal: data?.waitingInfoCount,
        checkPayment: '0',
      );
      context.push(AppRoutes.quotationDetail);
    } else {
      // FF: LicenseSelectComponent sheet ('กรุณากรอกเลขผู้มีบัตรนายหน้าประกัน'),
      // which saves / cancels a broker licence — writes data, not ported.
      context.push(AppRoutes.notPorted('LicenseSelectComponent'));
    }
  }

  // ---- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) => UnfocusOnTap(
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: tanjaiAppBar(
            title: 'จำนวนลูกค้าทั้งหมด',
            titleColor: const Color(0xFF003063),
            backColor: const Color(0xFFD9761A),
            onBack: _back,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  icon: const Icon(Icons.warning_rounded, color: AppColors.brandOrange, size: 30),
                  onPressed: () => InsuranceTypeColorSheet.show(context),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchRow(),
                Expanded(child: _loading ? const PageLoadingView() : _body()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 15, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: SearchNameBox(controller: _search),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onTap: _refresh,
              child: Icon(
                Icons.refresh_sharp,
                color: _search.text.isEmpty ? const Color(0xFFB3B3B3) : Colors.black,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final r = _result;
    if (r == null || !r.isHttpOk) return const SizedBox.shrink();
    if (r.status2 == 404) return const NoDataBox();
    if (r.status2 != 200) return const SizedBox.shrink();
    final leads = r.data?.leads ?? const <QuotationLead>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: SlideUpOnLoad(
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 50),
          itemCount: leads.length,
          itemBuilder: (context, i) {
            final lead = leads[i];
            if (!_visible(lead)) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _QuotationCard(
                lead: lead,
                onEdit: () => _openNonePackage('NonePackageEditPage1'),
                onCopy: () => _openNonePackage('NonePackageBasicPage'),
                onMakeInsurance: () => _makeInsurance(lead),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The FF lists' search box: h50, white, radius 8, hairline black border,
/// grey search icon, hint 'ค้นหาชื่อลูกค้า', input 15 w600.
class SearchNameBox extends StatelessWidget {
  const SearchNameBox({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 0.1),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Icon(Icons.search, color: Color(0xFF878787), size: 24),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0.5),
              child: TextField(
                controller: controller,
                style: AppText.style(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'ค้นหาชื่อลูกค้า',
                  hintStyle: AppText.style(fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// FF empty state: 'ไม่พบข้อมูลในระบบ' centred in a 100-high box.
class NoDataBox extends StatelessWidget {
  const NoDataBox({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: w * 0.9, maxWidth: w * 0.95, minHeight: 100, maxHeight: 100),
          child: Center(child: Text('ไม่พบข้อมูลในระบบ', style: AppText.bodyMedium)),
        ),
      ),
    );
  }
}

/// FF `listViewOnPageLoadAnimation`: slide up 100 px → 0, 600 ms easeInOut.
class SlideUpOnLoad extends StatelessWidget {
  const SlideUpOnLoad({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 100, end: 0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        builder: (context, dy, child) => Transform.translate(offset: Offset(0, dy), child: child),
        child: child,
      );
}

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({
    required this.lead,
    required this.onEdit,
    required this.onCopy,
    required this.onMakeInsurance,
  });

  final QuotationLead lead;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onMakeInsurance;

  static final _text = AppText.style(fontSize: 15, color: _black600);

  @override
  Widget build(BuildContext context) {
    final inRate = lead.quotationTypeBak != 'manual';
    final status = checkNullValueAndReturn(lead.quotationStatus);
    final phone = lead.phoneNumber;
    // FF responsiveVisibility(tablet: false): hidden for 479 ≤ width < 767.
    final width = MediaQuery.sizeOf(context).width;
    final showPhone = phone != null && phone.isNotEmpty && !(width >= 479 && width < 767);
    final showEdit = lead.quotationType == 'manual' && status != 'ประกันปฏิเสธ';
    final showCopy = lead.quotationType == 'manual' && lead.flagRenew != '1' && lead.refRenewId == '';
    final showMake = lead.flagExpired == 0;

    return Container(
      decoration: BoxDecoration(
        color: inRate ? const Color(0xFFF9DCC3) : const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: inRate ? const Color(0xFFD9761A) : const Color(0xFF95A1AC)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(
                      'ชื่อลูกค้า',
                      '${checkNullValueAndReturn(lead.firstName)} ${checkNullValueAndReturn(lead.lastName)}',
                      maxLines: 2,
                      rightPadding: 50,
                    ),
                    _row('เบอร์โทร', checkNullValueAndReturn(phone)),
                    _row('ขอเบี้ย', _orDash(lead.quotationTypeBakName)),
                    _row('แจ้งงาน', _orDash(lead.quotationTypeName)),
                    _row('ผลิตภัณฑ์', _orDash(lead.subProductName)),
                    _row('วันที่บันทึก', checkNullValueAndReturn(lead.quotationDate)),
                    _row('ใบเสนอราคามีผลใช้ถึง', checkNullValueAndReturn(lead.expireDate)),
                    _row(
                      'สถานะ',
                      status,
                      valueStyle: AppText.style(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: status == 'ประกันปฏิเสธ' ? AppColors.error : _black600,
                      ),
                    ),
                    _row(
                      'เลขที่ใบคำขอ',
                      checkNullValueAndReturn(lead.quotationNo),
                      valueStyle: AppText.style(fontSize: 15, fontWeight: FontWeight.bold, color: _black600),
                    ),
                  ].expand((w) => [w, const SizedBox(height: 4)]).toList()..removeLast(),
                ),
              ),
              if (showPhone)
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, right: 10),
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _black600),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              onTap: () => launchTel(phone),
                              child: const Icon(Icons.phone_in_talk_outlined, color: _black600, size: 30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showEdit)
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: _button('แก้ไข', onEdit,
                        color: Colors.white, textColor: _black600, border: const Color(0xFFA19AAC)),
                  ),
                if (showCopy)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _button('คัดลอก', onCopy,
                        color: const Color(0xFFF3C5A2), textColor: _black600, border: const Color(0xFFD9761A)),
                  ),
                if (showMake)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: _button('ทำประกัน', onMakeInsurance,
                        color: const Color(0xFFD9761A), textColor: Colors.white, border: Colors.transparent),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// FF `valueOrDefault<String>(x, '-')`: null or '' → '-'.
  static String _orDash(String? v) => v == null || v.isEmpty ? '-' : v;

  Widget _row(String label, String value, {int? maxLines, double rightPadding = 0, TextStyle? valueStyle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: Text(label, style: _text)),
        SizedBox(width: 10, child: Text(':', style: _text)),
        Expanded(
          flex: 6,
          child: Padding(
            padding: EdgeInsets.only(right: rightPadding),
            child: Text(value, maxLines: maxLines, style: valueStyle ?? _text),
          ),
        ),
      ],
    );
  }

  Widget _button(String text, VoidCallback onPressed,
      {required Color color, required Color textColor, required Color border}) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      width: 110,
      height: 35,
      color: color,
      textColor: textColor,
      fontSize: 15,
      radius: 10,
      borderColor: border,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
