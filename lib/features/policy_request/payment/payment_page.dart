import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/user_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../../router/app_router.dart';
import '../../search_package/shared/searchable_list_page.dart';
import '../data/policy_request_api.dart';
import '../models/application_detail.dart';
import '../shared/request_widgets.dart';
import '../state/policy_request_state.dart';
import 'effective_date_picker.dart';
import 'payment_data.dart';
import 'payment_rules.dart';

const _title = '4. ดำเนินงาน/ชำระเงิน';
const _blockBg = Color(0xFFFAFAFA);
const _waitAdvanceApproval = 'รออนุมัติค่างวดล่วงหน้า';
const _waitBranchConfirm = 'รอสาขายืนยันลูกค้า';

/// FF InsuranceInfoPage42 — '4. ดำเนินงาน/ชำระเงิน'.
///
/// Shows the payment plan saved in step 4 (HR41), lets the user pick the
/// instalment plan, opens the payment QR, and — once the server reports
/// 'ชำระแล้ว' (user taps refresh; no polling, as FF) — sends the
/// application to the insurer ('ยืนยันทำประกัน') and opens step 5.
///
/// Can be opened directly from the quotation list (only the ids are set),
/// so it always loads the detail itself on open. FF also loaded the insurer
/// master list on open (result unused on this page) — not ported.
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _state = PolicyRequestState.instance;
  final _api = PolicyRequestApi.instance;
  bool _loading = true;

  /// FF `isProcessing` (double-submit guard).
  bool _processing = false;
  Timer? _processingTimer;

  PaymentData get _p => _state.payment;
  PaymentRules get _rules => PaymentRules.of(_state.variant);

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

  // ---- load ----------------------------------------------------------------

  Future<void> _load() async {
    final r = await _api.getApplicationDetail(_state.quotationId);
    if (!mounted) return;
    if (!r.isHttpOk || r.code != 200) {
      setState(() => _loading = false);
      await showAlert(context, !r.isHttpOk ? 'พบข้อผิดพลาด (${r.statusCode})' : (r.message ?? ''));
      return;
    }
    final step4Save = _state.step4.lastSave;
    _state.applyDetail(ApplicationDetail(r.json, leadDtlId: _state.leadDtlId));
    // FF: 'เตรียมข้อมูล' stops here and shows the 4.1 save result.
    if (_p.isPreparing && step4Save != null) _p.applyStep4Save(step4Save);

    // Full payment needs no calculation. FF never calculated in
    // 'เตรียมข้อมูล'; the port also does when an instalment plan has no
    // tenor list (page opened without coming from 4.1), else the picker
    // would be empty.
    final needsCalc = _p.isPreparing ? _p.isInstallment && _p.installments.isEmpty : !_p.isFullPayment;
    if (needsCalc) {
      final c = await _api.calculateInstallment(
        workType: _p.workType,
        actFlg: _p.actFlag,
        insurerCode2: _p.insurerShortName,
        coverTypeCode: _p.coverTypeCode,
        grossTotalNet: _p.grossTotal,
        vehicleCode: _p.vehicleCode,
        actTotal: _p.actTotal,
        subProduct: _p.subProduct,
      );
      if (!mounted) return;
      if (!c.isHttpOk || c.code != 200) {
        setState(() => _loading = false);
        // FF showed the numeric `$.code`, not the message (kept).
        await showAlert(context, 'พบข้อผิดพลาด (${!c.isHttpOk ? c.statusCode : c.code})');
        return;
      }
      _p.applyInstallments(InstallmentOption.listFrom(c.json));
    }
    setState(() => _loading = false);
  }

  /// FF pull-to-refresh (§6.1). FF returned in 'เตรียมข้อมูล' without
  /// closing its loading sheet (stuck) — here it just does nothing.
  Future<void> _pullRefresh() async {
    if (_p.isPreparing) return;
    final r = await _api.getApplicationDetail(_state.quotationId);
    if (!mounted) return;
    await _applyRefresh(r, successAlert: false);
  }

  /// Refresh icon (§6.2) — the only way payment completion is detected.
  Future<void> _refresh() async {
    final r = await withLoading(context, () => _api.getApplicationDetail(_state.quotationId));
    if (!mounted) return;
    await _applyRefresh(r, successAlert: true);
  }

  Future<void> _applyRefresh(PrResponse r, {required bool successAlert}) async {
    if (!r.isHttpOk || r.code != 200) {
      await showAlert(context, 'พบข้อผิดพลาด (${!r.isHttpOk ? r.statusCode : r.code})');
      return;
    }
    // FF did not refresh the read-only text fields nor recalculate the
    // instalments here; the port's fields show the current values.
    setState(() => _p.applyRefresh(ApplicationDetail(r.json, leadDtlId: _state.leadDtlId)));
    if (successAlert) await showAlert(context, 'รีเฟรชสำเร็จ');
  }

  // ---- actions -------------------------------------------------------------

  /// QR icons (§6.3): a fresh code on every tap, then the QR page.
  Future<void> _openQr() async {
    final r = await withLoading(context, () => _api.regeneratePaymentCode(_state.quotationId));
    if (!mounted) return;
    if (!r.isHttpOk || r.code != 200) {
      await showAlert(context, 'พบข้อผิดพลาด (${!r.isHttpOk ? r.statusCode : r.code})');
      return;
    }
    _p.applyQr(r.json);
    context.push(AppRoutes.requestPaymentQr);
  }

  Future<void> _pickTenor() async {
    if (_p.status == _waitAdvanceApproval) return;
    final picked = await SearchableListPage.open(
      context,
      titleText: 'จำนวนงวด',
      searchLabel: 'เลือกงวดชำระ',
      items: [for (final o in _p.installments) o.tenor],
    );
    if (!mounted || picked == null || picked.isEmpty) return;
    setState(() => _p.selectInstallment(picked.first));
  }

  /// FF pre-checked the current choice in this list; the shared
  /// `SearchableListPage` has no pre-selection in single mode.
  Future<void> _pickTenorOver() async {
    if (_p.status == _waitAdvanceApproval) return;
    final picked = await SearchableListPage.open(
      context,
      titleText: 'จำนวนงวดชำระล่วงหน้า',
      searchLabel: 'เลือกงวดชำระล่วงหน้า',
      items: _p.tenorOverList,
      labels: [for (final n in _p.tenorOverList) _p.tenorOverLabel(n)],
    );
    if (!mounted || picked == null || picked.isEmpty) return;
    setState(() => _p.selectTenorOver(picked.first));
  }

  void _holdProcessing(Duration d) {
    _processingTimer?.cancel();
    _processingTimer = Timer(d, () {
      if (mounted) setState(() => _processing = false);
    });
  }

  void _endProcessing() {
    _processingTimer?.cancel();
    if (mounted) setState(() => _processing = false);
  }

  /// 'บันทึก' (§6.6) — saves the payment plan.
  Future<void> _save() async {
    if (!_p.isFullPayment) {
      if (_p.selectTenor.isEmpty) {
        await showAlert(context, 'บังคับเลือกงวด');
        return;
      }
      if (_p.tenorOverSelect.isEmpty) {
        await showAlert(context, 'บังคับเลือกจำนวนงวดที่ต้องการจ่ายล่วงหน้า');
        return;
      }
      await UserProfile.instance.ensureLoaded();
      if (!mounted) return;
      if (UserProfile.instance.level == 'ภาค' && _p.tenorOverBelowDefault) {
        final go = await showConfirm(
            context, 'จำนวนงวดจ่ายล่วงหน้าที่คุณเลือก น้อยกว่าจำนวนงวดล่วงหน้าปกติ คุณต้องการยืนยันหรือไม่?');
        if (!go || !mounted) return;
      }
    }
    if (!await showConfirm(context, 'คุณต้องการบันทึกใช่หรือไม่') || !mounted) return;
    if (_processing) {
      await showAlert(context, 'กรุณารอ 10 วินาที');
      return;
    }
    setState(() => _processing = true);

    final leadDtlId = _state.leadDtlId != null ? '${_state.leadDtlId}' : _state.summary.leadDetailId;
    final f = _p.savePaymentFields(quotationId: _state.quotationId, leadDtlId: leadDtlId);
    final s = await withLoading(
      context,
      () => _api.savePayment(
        tenorFirstDue: f['tenor_first_due']!,
        quotationId: f['quotation_id']!,
        leadDtlId: f['lead_dtl_id']!,
        paymentType: f['payment_type']!,
        paymentChannel: f['payment_channel']!,
        tenor: f['tenor']!,
        netPremiumTotal: f['net_premium_total']!,
        actTotal: f['act_total']!,
        installmentFirstDue: f['installment_first_due']!,
        installmentLastDue: f['installment_last_due']!,
      ),
    );
    if (!mounted) return;
    if (!s.isHttpOk) {
      _endProcessing();
      await showAlert(context, 'พบข้อผิดพลาด connection (${s.statusCode})');
      return;
    }
    if (s.code != 200) {
      _endProcessing();
      // FF: `$.message` is dynamic → 'null' when absent (kept).
      await showAlert(context, 'พบข้อผิดพลาด (${s.at('message')})');
      return;
    }
    final saved = s.at('results.data.quotations.quotation_status');
    setState(() => _p.status = saved == null ? '' : '$saved');

    final d = await withLoading(context, () => _api.getApplicationDetail(_state.quotationId));
    if (!mounted) return;
    if (!await requestCheck(context, statusCode: d.statusCode, code: d.code, message: d.message)) {
      _endProcessing();
      return;
    }
    setState(() => _p.applyAfterSave(ApplicationDetail(d.json, leadDtlId: _state.leadDtlId)));
    if (!mounted) return;
    await showAlert(context, 'บันทึกสำเร็จ');
    // FF kept isProcessing for 10 s after a save (anti double-tap) — kept.
    _holdProcessing(const Duration(seconds: 10));
  }

  /// 'ยืนยันทำประกัน' / 'ส่งเรื่องให้บริษัทประกัน' (§6.7).
  Future<void> _confirm() async {
    if (_processing) {
      await showAlert(context, 'กรุณารอ 10 วินาที');
      return;
    }
    setState(() => _processing = true);

    // FF left its loading sheet open and isProcessing stuck on every early
    // return here; the port always clears both.
    final t = await withLoading(context, () => _api.getServerDateTime());
    if (!mounted) return;
    if (!t.isHttpOk) {
      _endProcessing();
      await showAlert(context, 'พบข้อผิดพลาดConnection (${t.statusCode})');
      return;
    }
    if (t.localStatus != 200) {
      _endProcessing();
      await showAlert(context, t.message ?? '');
      return;
    }
    final today = '${t.at('info.DateYMD') ?? ''}';
    final hasAct = _p.actFlag == '1';
    bool insureOk() =>
        checkCurrentDateIsBeforeInputDate(today, _rules.checksInsureDate ? _p.effectiveDateInsure : today);
    bool actOk() => hasAct ? checkCurrentDateIsBeforeInputDate(today, _p.effectiveDateAct) : true;

    if (!(insureOk() && actOk())) {
      final picked = await showEffectiveDatePicker(
        context,
        insurerFlag: insureOk(),
        actDateFlag: actOk(),
        actFlag: hasAct,
        currentDate: today,
      );
      if (!mounted) return;
      if (picked?.insure != null) _p.effectiveDateInsure = picked!.insure!;
      if (picked?.act != null) _p.effectiveDateAct = picked!.act!;
      if (!(insureOk() && actOk())) {
        _endProcessing();
        await showAlert(context, 'กรุณาเลือกวันที่คุ้มครองประกันหรือวันที่คุ้มครอง พ.ร.บ.');
        return;
      }
      final e = await withLoading(
        context,
        () => _api.editApplication(
          subProduct: _p.subProduct,
          quotationId: _state.quotationId,
          effectiveDateInsure: _p.effectiveDateInsure,
          effectiveDateAct: hasAct ? _p.effectiveDateAct : '',
          // FF IbsApplicationsEditCall defaults (kept).
          firstNameTh: '',
          lastNameTh: '',
          carRegistration: '',
        ),
      );
      if (!mounted) return;
      if (!e.isHttpOk || e.code != 200) {
        _endProcessing();
        await showAlert(context, !e.isHttpOk ? 'พบข้อผิดพลาดConnection (${e.statusCode})' : (e.message ?? ''));
        return;
      }
    }

    final r = await withLoading(context, () => _api.issuePolicy(_state.quotationId));
    if (!mounted) return;
    if (!await requestCheck(context, statusCode: r.statusCode, code: r.code, message: r.message)) {
      _endProcessing();
      return;
    }
    if (!mounted) return;
    // FF waited 30 s before clearing isProcessing (page 5 is pushed on top
    // meanwhile); dropped — the flag is cleared right away.
    _endProcessing();
    context.push(AppRoutes.requestStatus);
  }

  void _back() => context.canPop() ? context.pop() : leaveRequestFlow(context);

  // ---- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // FF: back arrow only while the status is 'เตรียมข้อมูล' (system back
    // disabled; the app's bottom nav was the way out). The web has no bottom
    // nav, so other statuses get an exit to the quotation list (same as P5,
    // user decision 2026-10-16).
    final showBack = _loading || _p.isPreparing;
    return PopScope(
      canPop: false,
      child: UnfocusOnTap(
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: requestAppBar(title: _title, onBack: showBack ? _back : () => leaveRequestFlow(context)),
          body: _loading
              ? const PageLoadingView()
              : SafeArea(
                  child: RefreshIndicator(
                    color: AppColors.brandOrange,
                    onRefresh: _pullRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: _content(context),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final p = _p;
    final rules = _rules;
    // Not ported: CMI (`InfomationCustomerAct`) / House cards — the flow
    // only runs for motor / EV / MC.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RequestSummaryCard(),
        const RequestStepIndicator(current: 4),
        _block('สถานะการดำเนินงาน', _text(p.status)),
        _block(
          'สถานะการชำระเงิน',
          Row(
            children: [
              Expanded(child: _text(p.paymentStatus, color: kRequestGrey)),
              if (!p.isPreparing)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: _refresh,
                    child: const Icon(Icons.refresh, color: AppColors.secondaryText, size: 24),
                  ),
                ),
            ],
          ),
        ),
        _block('ประเภทการชำระเงิน', _readOnly(p.paymentType, hint: p.paymentType)),
        _block('ช่องการชำระเงิน', _readOnly(p.paymentChannel, hint: p.paymentChannel)),
        if (rules.showsNetPremium)
          _block('ราคาเบี้ย', _readOnly(showNumberWithComma(p.netPremiumTotal), hint: p.netPremiumTotal)),
        if (p.discountFlg == '1')
          // FF hint = NetPremiumTotal (copy/paste; never visible).
          _block('ราคาส่วนลด', _readOnly(showNumberWithComma(p.discountOther), hint: p.netPremiumTotal)),
        if (rules.showsActTotal) _block('ราคา พ.ร.บ (ถ้ามี)', _readOnly(showNumberWithComma(p.actTotal), hint: p.actTotal)),
        if (!p.isInstallment)
          _block(
            'ราคาทั้งหมด',
            Row(
              children: [
                Expanded(child: _readOnly(showNumberWithComma(p.grossTotal), hint: p.grossTotal)),
                _qrIcon(active: !p.isPreparing && p.isWaitingPayment, grey: p.isPaid),
              ],
            ),
          ),
        if (p.isInstallment) ...[
          _block(
            'ระบุงวด',
            _pickerBox(p.selectTenor.isNotEmpty ? p.selectTenor : 'เลือกงวด', _pickTenor),
            tag: '(บังคับเลือก)',
          ),
          if (p.selectTenor.isNotEmpty)
            _block(
              'ระบุงวดที่ต้องการจ่ายล่วงหน้า',
              _pickerBox(p.tenorOverSelect.isNotEmpty ? p.tenorOverSelect : 'เลือกงวดที่ต้องการจ่ายล่วงหน้า', _pickTenorOver),
              tag: '(บังคับเลือก)',
            ),
          _block('ผ่อนงวดละ', _text(p.selectFirstDue.isNotEmpty ? showNumberWithComma(p.selectFirstDue) : '-')),
          _block('ผ่อนงวดสุดท้าย', _text(p.selectLastDue.isNotEmpty ? showNumberWithComma(p.selectLastDue) : '-')),
          if (!p.isPreparing)
            _block(
              'ยอดที่ต้องชำระตอนนี้',
              Row(
                children: [
                  Expanded(child: _text(p.firstPay.isNotEmpty ? showNumberWithComma(p.firstPay) : '-')),
                  _qrIcon(
                    active: p.isWaitingPayment &&
                        p.status != _waitAdvanceApproval &&
                        p.status != _waitBranchConfirm &&
                        p.checkSavePaymentBtn,
                    grey: p.isPaid,
                  ),
                ],
              ),
            ),
        ],
        _buttons(),
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.20),
      ],
    );
  }

  Widget _block(String label, Widget child, {String tag = ''}) {
    return Container(
      color: _blockBg,
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RequestFieldLabel(label, tag: tag),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: RequestBox(
              child: Padding(padding: const EdgeInsets.only(left: 10), child: child),
            ),
          ),
        ],
      ),
    );
  }

  Widget _text(String value, {Color color = AppColors.primaryText}) =>
      Text(value, style: AppText.style(fontSize: 15, fontWeight: FontWeight.normal, color: color));

  /// FF read-only TextField: the value, or the bold grey hint when empty.
  Widget _readOnly(String value, {required String hint}) => value.isNotEmpty
      ? _text(value)
      : Text(hint, style: AppText.style(fontSize: 15, fontWeight: FontWeight.bold, color: kRequestGrey));

  Widget _pickerBox(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: _text(text)),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.arrow_forward_ios, color: kRequestGrey, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _qrIcon({required bool active, required bool grey}) {
    if (active) {
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: InkWell(onTap: _openQr, child: const Icon(Icons.qr_code, color: AppColors.primaryText, size: 24)),
      );
    }
    if (grey) {
      return const Padding(
        padding: EdgeInsets.only(right: 10),
        child: Icon(Icons.qr_code, color: AppColors.secondaryText, size: 24),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buttons() {
    final p = _p;
    final showSave = !p.isPaid && p.status != _waitAdvanceApproval;
    final showConfirm = p.isPaid && !_processing;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          if (showSave)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AppButton(
                  text: 'บันทึก',
                  onPressed: _save,
                  color: kRequestLightOrange,
                  textColor: const Color(0xFFDF8633),
                  borderColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
          if (showConfirm)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: AppButton(
                  text: _rules.confirmText,
                  onPressed: _confirm,
                  color: kRequestOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
