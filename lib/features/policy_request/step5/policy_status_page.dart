import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../../router/app_router.dart';
import '../../search_package/quotation/pdf_frame.dart';
import '../data/policy_request_api.dart';
import '../models/application_detail.dart';
import '../shared/request_widgets.dart';
import '../state/policy_request_state.dart';
import 'document_download_sheet.dart';
import 'step5_data.dart';
import 'step5_rules.dart';

const _title = '5.ส่งเรื่องให้บริษัทประกันพิจารณา';
const _blockBg = Color(0xFFFAFAFA);
const _copyGreen = Color(0xFF39D2C0);
const _approved = 'อนุมัติ';
const _inspecting = 'อยู่ระหว่างตรวจสอบสภาพรถ';

/// FF InsuranceInfoPage5 — read-only status of a quotation sent to the
/// insurer: status / dates / policy numbers / payment, documents sheet,
/// policy / coverage / พ.ร.บ. links, cancel, 'ทำรายการใหม่'.
///
/// Opened after 'ยืนยันทำประกัน' (step 4.2), from the cancel page, or directly
/// from the quotation list (only the ids are set) — so it always loads
/// server date + detail + policy itself on open.
///
/// Exit: FF had no back arrow (the mobile bottom nav bar was the way out);
/// user decision 2026-10-16 — the AppBar back leaves the flow
/// ([leaveRequestFlow], quotation list).
///
/// Not ported: 'บันทึก พ.ร.บ.' (CMI only, gated by Firestore `role_menu`,
/// SaveContractCMI sheet) — so `role_menu` is not read and the page doesn't
/// wait for it; CMI / House customer cards; the dead ShowPolicy page.
class PolicyStatusPage extends StatefulWidget {
  const PolicyStatusPage({super.key});

  @override
  State<PolicyStatusPage> createState() => _PolicyStatusPageState();
}

class _PolicyStatusPageState extends State<PolicyStatusPage> {
  final _state = PolicyRequestState.instance;
  final _api = PolicyRequestApi.instance;
  bool _loading = true;

  /// FF `isProcessing` — refresh throttle (hides the refresh icon).
  bool _processing = false;
  Timer? _processingTimer;

  Step5Data get _d => _state.step5;
  Step5Rules get _rules => Step5Rules.of(_state.variant);

  @override
  void initState() {
    super.initState();
    if (redirectIfNoFlow(context)) return;
    _load();
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    super.dispose();
  }

  /// FF on-load (§3). FF left its loading sheet open (stuck) when the detail
  /// or policy call failed; the port shows the page after the alert.
  Future<void> _load() async {
    Future<void> fail(String message) async {
      setState(() => _loading = false);
      await showAlert(context, message);
    }

    final t = await _api.getServerDateTime();
    if (!mounted) return;
    // FF: HTTP error → the bare status code as the message (kept).
    if (!t.isHttpOk) return fail('${t.statusCode}');
    if (t.localStatus != 200) return fail(t.message ?? '');
    _d.dateNow = '${t.at('info.DateYMD') ?? ''}';

    final r = await _api.getApplicationDetail(_state.quotationId);
    if (!mounted) return;
    if (!r.isHttpOk) return fail('พบข้อผิดพลาดConnection (${r.statusCode})');
    if (r.code != 200) return fail(r.message ?? '');
    _state.applyDetail(ApplicationDetail(r.json, leadDtlId: _state.leadDtlId));

    final p = await _api.getPolicy(_state.quotationId);
    if (!mounted) return;
    if (!p.isHttpOk) return fail('พบข้อผิดพลาดConnection (${p.statusCode})');
    if (p.code != 200) return fail(p.message ?? '');
    setState(() {
      _d.applyPolicy(p.json, refresh: false);
      _loading = false;
    });
  }

  /// Refresh icon (§6). FF left `isProcessing` true (icon gone for good) and
  /// the loading sheet open on errors; the port resets both.
  Future<void> _refresh() async {
    if (_processing) {
      await showAlert(context, 'กรุณากดรีเฟรชใหม่ในอีก 10 วินาที');
      return;
    }
    setState(() => _processing = true);
    void end() {
      if (mounted) setState(() => _processing = false);
    }

    final t = await withLoading(context, () => _api.getServerDateTime());
    if (!mounted) return;
    if (!t.isHttpOk) {
      end();
      await showAlert(context, 'พบข้อผิดพลาด (${t.statusCode})');
      return;
    }
    _d.dateNow = '${t.at('info.DateYMD') ?? ''}';

    final p = await withLoading(context, () => _api.getPolicy(_state.quotationId));
    if (!mounted) return;
    if (!p.isHttpOk || p.code != 200) {
      end();
      await showAlert(
          context, !p.isHttpOk ? 'พบข้อผิดพลาดConnection (${p.statusCode})' : 'พบข้อผิดพลาด (${p.code})');
      return;
    }
    setState(() => _d.applyPolicy(p.json, refresh: true));
    // FF: icon hidden for 10 s after a refresh (kept).
    _processingTimer?.cancel();
    _processingTimer = Timer(const Duration(seconds: 10), end);
  }

  // ---- links -----------------------------------------------------------------

  /// FF `launchURL` / Chrome intent / iOS copy dialog → web: new tab, https only.
  void _open(String url) {
    if (isSafePdfUrl(url)) openUrlInNewTab(url);
  }

  void _snack(String text, {Color bg = const Color(0xCB101213), Color fg = Colors.white}) {
    final m = ScaffoldMessenger.of(context);
    m.clearSnackBars();
    m.showSnackBar(SnackBar(
      content: Text(text, style: AppText.style(fontWeight: FontWeight.normal, color: fg)),
      backgroundColor: bg,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _copy(String text) => Clipboard.setData(ClipboardData(text: text));

  /// get-file-vmi; null on error (alert shown).
  Future<String?> _fetchVmi() async {
    final r = await withLoading(context, () => _api.getFileVmi(_state.quotationId));
    if (!mounted) return null;
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.statusCode})');
      return null;
    }
    if (r.fileStatus != 200) {
      await showAlert(context, r.fileMessage ?? '');
      return null;
    }
    final url = r.at('VMI_documentUrl');
    setState(() => _d.vmiDocUrl = url == null ? '' : '$url');
    return _d.vmiDocUrl;
  }

  /// get-file-cmi; [copy] = the 'คัดลอก' button, whose layer-1 error showed
  /// the numeric statusCode instead of the message (FF quirk, kept).
  Future<String?> _fetchCmi({required bool copy}) async {
    final r = await withLoading(context, () => _api.getFileCmi(_state.quotationId));
    if (!mounted) return null;
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาด (${r.statusCode})');
      return null;
    }
    if (r.fileStatus != 200) {
      await showAlert(context, copy ? '${r.at('statusCode')}' : '${r.at('statusMessage')}');
      return null;
    }
    final url = r.at('CMI_documentUrl');
    setState(() => _d.cmiDocUrl = url == null ? '' : '$url');
    return _d.cmiDocUrl;
  }

  /// 'ดูกรมธรรม์'. FF's TNI / ชั้น 1 / auto "Chrome only" handling is
  /// mobile-only; on web every case opens a new tab.
  Future<void> _viewPolicy() async {
    final url = await _fetchVmi();
    if (url != null) _open(url);
  }

  Future<void> _copyPolicy() async {
    final url = await _fetchVmi();
    if (url == null || !mounted) return;
    await _copy(url);
    if (mounted) _snack('คัดลอดลิ้งค์กรมธรรม์เรียบร้อย'); // FF typo 'คัดลอด' kept
  }

  Future<void> _viewCmi() async {
    final url = await _fetchCmi(copy: false);
    if (url != null) _open(url);
  }

  Future<void> _copyCmi() async {
    final url = await _fetchCmi(copy: true);
    if (url == null || !mounted) return;
    await _copy(url);
    if (mounted) _snack('คัดลอดลิ้งค์ พ.ร.บ เรียบร้อย', bg: _copyGreen, fg: AppColors.primaryText);
  }

  Future<void> _copyCoverage() async {
    await _copy(_d.vmiDocUrl);
    if (mounted) _snack('คัดลอดลิ้งค์กรมธรรม์เรียบร้อย');
  }

  // ---- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: requestAppBar(
          title: _title,
          onBack: () => leaveRequestFlow(context),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download_outlined, color: AppColors.brandOrange, size: 30),
              onPressed: _loading ? null : () => showStep5DocumentDownload(context, _d, _rules),
            ),
          ],
        ),
        body: _loading
            ? const PageLoadingView()
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: _content(context),
                ),
              ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final d = _d;
    final rules = _rules;
    final approved = d.status == _approved;
    final installment = d.paymentType == 'ผ่อนชำระ';
    final statusColor = switch (d.status) {
      'อนุมัติ' => AppColors.success,
      'ไม่อนุมัติ' => AppColors.error,
      _ => AppColors.brandOrange,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Step5SummaryCard(data: d),
        const RequestStepIndicator(current: 5),
        _block(
          'สถานะการดำเนินงาน',
          Row(
            children: [
              Expanded(child: Text(d.status, style: AppText.style(fontSize: 15, color: statusColor))),
              if (!_processing)
                InkWell(onTap: _refresh, child: const Icon(Icons.refresh, color: AppColors.secondaryText, size: 24)),
            ],
          ),
          bg: AppColors.secondaryBackground,
        ),
        _block('วันที่สถานะการดำเนินงาน', _text(d.createdDate)),
        _block('วันที่-เวลา ที่พิจารณาเสร็จ', _text(d.completedDate)),
        if (approved) _block('เลขที่รับแจ้ง', _text(d.contractId)),
        if (approved) _block('เลขกรมธรรม์', _text(d.vmiPolicyNo)),
        if (d.status != 'ขอคืนเงิน') _block('เหตุผล', _text(d.reason), autoHeight: true),
        if (d.status == 'ขอคืนเงิน') _block('เหตุผลขอคืนเงิน', _text(d.refundRemark), autoHeight: true),
        if (approved) ...[
          _block('สถานะการชำระเงิน', _text(d.paymentStatus)),
          _block('ประเภทการชำระเงิน', _text(d.paymentType)),
          _block('ช่องการชำระเงิน', _text(d.paymentChannel)),
          if (rules.showsPremiumBlocks) ...[
            _block('ราคาเบี้ย', _text(showNumberWithComma(d.netPremium))),
            _block('ราคาเบี้ยจ่ายล่วงหน้า (รวม พ.ร.บ. ถ้ามี)', _text(showNumberWithComma(d.amount))),
          ],
          if (rules.showsActBlock) _block('ราคา พ.ร.บ. (ถ้ามี)', _text(showNumberWithComma(d.actPrice))),
          _block('ราคาทั้งหมด', _text(showNumberWithComma(d.grossTotalNet))),
          if (installment)
            _block('ระบุงวด', _text(d.tenor, weight: FontWeight.w600, color: Colors.black)),
          // FF checks page5PaymentStatus (not PaymentType like its siblings),
          // so this block practically never shows — FF behaviour kept.
          if (d.paymentStatus == 'ผ่อนชำระ') _block('ผ่อนงวดละ', _text(showNumberWithComma(d.firstDue))),
          if (installment) _block('ผ่อนงวดสุดท้าย', _text(showNumberWithComma(d.lastDue))),
        ],
        if (approved && installment) _loanCard(d),
        if (approved &&
            installment &&
            d.vloanContNo != '' &&
            d.vloanContNo != '-' &&
            isSafePdfUrl(step5InstalmentCardUrl(d.vloanContNo)))
          // FF URLs are http → hidden on web until an https URL exists
          // (see step5InstalmentCardUrl).
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: AppButton(
              text: 'การ์ดค่างวด',
              onPressed: () => _open(step5InstalmentCardUrl(d.vloanContNo)),
              color: const Color(0xFF1A73E7),
              borderColor: const Color(0xFF204A77),
              icon: const Icon(Icons.qr_code, size: 15, color: Colors.white),
            ),
          ),
        if (step5ShowsNewRequest(d))
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AppButton(
              text: 'ทำรายการใหม่',
              // FF → SearchInsurancePage(fromIcon 'page5'); web → the
              // quotation's own product search page (Step5Rules).
              onPressed: () => context.go(AppRoutes.search(rules.newRequestProduct)),
              color: kRequestLightOrange,
              textColor: kRequestOrange,
              borderColor: kRequestLightOrange,
            ),
          ),
        _actions(d),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _actions(Step5Data d) {
    final approved = d.status == _approved;
    Widget pair(Widget a, Widget b) => Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
          child: Row(children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]),
        );
    Widget copyBtn(String text, VoidCallback onTap) => AppButton(
          text: text,
          onPressed: onTap,
          color: _copyGreen,
          fontSize: 13,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          icon: const Icon(Icons.content_copy, size: 15, color: Colors.white),
        );
    Widget mainBtn(String text, Color color, VoidCallback onTap, {double fontSize = 15}) => AppButton(
          text: text,
          onPressed: onTap,
          color: color,
          fontSize: fontSize,
          borderColor: kRequestLightOrange,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          if (step5CanCancel(d))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AppButton(
                text: 'ยกเลิก',
                onPressed: () => context.go(AppRoutes.requestCancel),
                color: AppColors.primaryBackground,
                textColor: const Color(0xFF204A77),
                borderColor: const Color(0xFF204A77),
              ),
            ),
          // Not ported: 'บันทึก พ.ร.บ.' row (CMI only, role_menu-gated).
          if (d.status == _inspecting && d.vmiDocUrl != '-')
            pair(
              mainBtn('ดูความคุ้มครอง', const Color(0xFFF39C96), () => _open(d.vmiDocUrl)),
              copyBtn('คัดลอกความคุ้มครอง', _copyCoverage),
            ),
          if (approved && d.vmiDocUrl != '-')
            pair(
              mainBtn('ดูกรมธรรม์', kRequestOrange, _viewPolicy),
              copyBtn('คัดลอกลิ้งค์กรมธรรม์', _copyPolicy),
            ),
          if (approved && d.cmiDocUrl != '-')
            pair(
              mainBtn('ดู พ.ร.บ', const Color(0xFF5D78FF), _viewCmi, fontSize: 14),
              copyBtn('คัดลอกลิ้งค์ พ.ร.บ', _copyCmi),
            ),
        ],
      ),
    );
  }

  Widget _loanCard(Step5Data d) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RequestFieldLabel('สัญญาเป้า ง'),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kRequestBorder),
              boxShadow: const [BoxShadow(blurRadius: 1, color: Color(0x33000000))],
            ),
            child: Column(
              children: [
                _infoRow('รหัสสัญญา', d.vloanContNo),
                _infoRow('รหัสลูกค้า', d.cusIdCardNo),
                _infoRow('จำนวนงวด', d.tenor),
                _infoRow('ผ่อนงวดละ', showNumberWithComma(d.firstDue)),
                _infoRow('ผ่อนงวดสุดท้าย', showNumberWithComma(d.lastDue), bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    final width = MediaQuery.sizeOf(context).width;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: width * 0.30, child: Text(label, style: AppText.style(fontSize: 15, fontWeight: FontWeight.normal))),
        const SizedBox(width: 10, child: Text(':')),
        Expanded(
          child: Text(value,
              style: AppText.style(fontSize: 15, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        ),
      ],
    );
  }

  Widget _text(String value, {FontWeight weight = FontWeight.normal, Color color = AppColors.primaryText}) =>
      Text(value, style: AppText.style(fontSize: 15, fontWeight: weight, color: color));

  /// FF status block: #FAFAFA, title 15 w500, then a 60-px box (radius 8,
  /// border #B3B3B3, padding h10) filled [bg] (default lineColor #E0E3E7).
  Widget _block(String label, Widget child, {Color bg = AppColors.lineColor, bool autoHeight = false}) {
    final box = Container(
      width: double.infinity,
      constraints: autoHeight ? const BoxConstraints(minHeight: 60) : null,
      height: autoHeight ? null : 60,
      alignment: Alignment.centerLeft,
      padding: autoHeight ? const EdgeInsets.all(10) : const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kRequestGrey),
      ),
      child: child,
    );
    return Container(
      color: _blockBg,
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RequestFieldLabel(label),
          Padding(padding: const EdgeInsets.only(top: 5), child: box),
        ],
      ),
    );
  }
}

/// P5's own summary card (FF inline copy of InfomationCustomer, spec
/// shared §1.1.4): adds 'App No.' and 'วันหมดอายุ', prices from get/policy.
class Step5SummaryCard extends StatelessWidget {
  const Step5SummaryCard({super.key, required this.data});

  final Step5Data data;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final width = MediaQuery.sizeOf(context).width;
    final base = AppText.style(fontSize: 15, fontWeight: FontWeight.normal);
    final strong = AppText.style(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryText);
    Widget row(String label, String value, {bool bold = false}) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: width * 0.20, child: Text(label, style: base)),
            SizedBox(width: 10, child: Text(':', style: AppText.style(fontWeight: FontWeight.normal))),
            Expanded(child: Text(value, style: bold ? strong : base)),
          ],
        );
    String baht(String v) => '${showNumberWithComma(v)} บาท';
    final premium = step5PremiumRounds(d) ? returnNumberWithComma2Decimal(d.netPremium) : showNumberWithComma(d.netPremium);
    final logo = d.insurerLogo.isNotEmpty ? d.insurerLogo : kRequestNoImageUrl;
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kRequestBorder),
        ),
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: width * 0.65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  row('ใบเสนอราคา', PolicyRequestState.instance.quotationId),
                  row('App No.', d.applicationNo),
                  row('ชื่อลูกค้า', '${d.firstName}  ${d.lastName}'),
                  row('เบอร์โทร', d.phone),
                  row('การซ่อม', d.garageType),
                  row('ประกัน', d.coverType),
                  if (d.oldVmiExpDate != '') row('วันหมดอายุ', d.oldVmiExpDateText),
                  row('ราคาเบี้ย', '$premium บาท', bold: true),
                  if (d.actFlag == '1') row('ราคา พ.ร.บ', baht(d.actPrice), bold: true),
                  if (d.discountFlg == '1') row('เปอร์เซ็นต์ส่วนลด', '${showNumberWithComma(d.discountPercent)}%', bold: true),
                  if (d.discountFlg == '1') row('ราคาที่ลด', baht(d.discountOther), bold: true),
                  if (d.actFlag == '1' || d.discountFlg == '1') row('ราคารวม', baht(d.grossTotalNet), bold: true),
                  row('ขอเบี้ย', d.quotationTypeBakName, bold: true),
                  row('แจ้งงาน', d.quotationTypeName, bold: true),
                  row('ผลิตภัณฑ์', d.subProductName, bold: true),
                ],
              ),
            ),
            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: SizedBox(height: 75, child: RequestNetworkImage(url: logo, width: 300, height: 200)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
