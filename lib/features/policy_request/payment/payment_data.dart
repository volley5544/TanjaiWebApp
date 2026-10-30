import '../data/policy_request_api.dart';
import '../models/application_detail.dart';
import '../step4/step4_data.dart';

/// One tenor option of `IbsCalculateInstallmentCall`
/// (`$.results.data.calculate.installment[:]`).
class InstallmentOption {
  const InstallmentOption({
    required this.tenor,
    required this.paymentFirst,
    required this.firstDue,
    required this.lastDue,
    required this.tenorFirstDue,
    required this.tenorFirstDueDefault,
  });

  /// `tenor` — number of instalments, e.g. '6'.
  final String tenor;

  /// `payment_first`.
  final String paymentFirst;

  /// `installment_first_due` — amount per instalment.
  final String firstDue;

  /// `installment_last_due` — amount of the last instalment.
  final String lastDue;

  /// `tenor_first_due` — allowed counts of instalments paid up-front.
  final List<String> tenorFirstDue;

  /// `tenor_first_due_default` — `.first` is the normal up-front count.
  final List<String> tenorFirstDueDefault;

  /// FF `tenorFirstDueDefault.first` (empty list → '' instead of FF's crash).
  String get defaultTenorFirstDue => tenorFirstDueDefault.isEmpty ? '' : tenorFirstDueDefault.first;

  static List<InstallmentOption> listFrom(dynamic json) => fromList(jsonPathGet(json, 'results.data.calculate.installment'));

  /// Items of a calc `installment[]` or of the step-4 save's
  /// `payment.installment[]` (same shape — FF read both into
  /// InstallmentDataType).
  static List<InstallmentOption> fromList(dynamic list) {
    String s(Map m, String k) => m[k] == null ? '' : '${m[k]}';
    List<String> l(Map m, String k) => [
          if (m[k] is List)
            for (final e in m[k] as List)
              if (e != null) '$e',
        ];
    return [
      if (list is List)
        for (final e in list)
          if (e is Map)
            InstallmentOption(
              tenor: s(e, 'tenor'),
              paymentFirst: s(e, 'payment_first'),
              firstDue: s(e, 'installment_first_due'),
              lastDue: s(e, 'installment_last_due'),
              tenorFirstDue: l(e, 'tenor_first_due'),
              tenorFirstDueDefault: l(e, 'tenor_first_due_default'),
            ),
    ];
  }
}

/// Step 4.2 payment (FF InsuranceInfoPage42 + PaywithQRcode): the
/// `insuranceInfoPage4*` / `insuranceInfo4page*` / QR FFAppState fields.
///
/// Owned by `payment/`. Filled from the application detail by [loadFromDetail]
/// (called by `PolicyRequestState.applyDetail`); edited by the step's pages.
///
/// FF stored every value with `'${x}'` (JSON null → the text `'null'`, which
/// then showed in the pickers and passed the "required" checks — spec P4_2
/// §8.4). The port reads null as `''`; the '-' display fallbacks are kept.
/// `[:]` getters read the first element (FF crashed on > 1 — §8.6).
class PaymentData {
  /// `quotations.quotation_status` (FF insuranceInfo4pageStatus).
  String status = '';

  /// `payments[0].payment_type` — 'จ่ายเต็ม' / 'ผ่อนชำระ'.
  String paymentType = '';

  /// `payments[0].payment_channel`.
  String paymentChannel = '';

  /// `payments[0].payment_status` — 'รอชำระเงิน' / 'ชำระแล้ว' / …
  String paymentStatus = '';

  /// `app_detail[0].gross_total_net` (FF insuranceInfoGrossTotal).
  String grossTotal = '';

  /// `app_detail[0].act_total` (FF insuranceInfoActAmount).
  String actTotal = '';

  /// `app_detail[0].net_premium_total` (FF insuranceInfoPage4NetPremiumTotal).
  String netPremiumTotal = '';

  /// `leads[0].vehicle_code`.
  String vehicleCode = '';

  /// `app_detail[0].work_type` (FF InsuranceInfoWorkType).
  String workType = '';

  /// `act_flg` (FF insuranceInfoActFlag, '1' = with พ.ร.บ.).
  String actFlag = '';

  /// `leads_detail[LD].insurer_short_name` (FF insuranceInfoCompayId).
  String insurerShortName = '';

  /// `leads_detail[LD].cover_type_code`.
  String coverTypeCode = '';

  /// `leads[0].sub_product` (FF insuranceinfoActType).
  String subProduct = '';

  /// `quotations.quotation_type_bak` (FF insuranceInfoApplicationType).
  String applicationType = '';

  /// `first_name_th` / `last_name_th` (QR page 'คุณ …').
  String firstName = '';
  String lastName = '';

  /// `leads_detail[LD].discount_flg` / `discount_other` (FF appDetailNew).
  String discountFlg = '';
  String discountOther = '';

  /// `app_detail[0].effective_date_insure` / `effective_date_act`
  /// (yyyy-MM-dd); replaced by the effective-date sheet when re-picked.
  String effectiveDateInsure = '';
  String effectiveDateAct = '';

  /// FF insuranceInfoPage4SelectTenor (`payments[0].tenor` on load).
  String selectTenor = '';

  /// FF …SelectInstallMentFirstDue / LastDue (`app_detail[0].installment_first_due` / `_last_due`).
  String selectFirstDue = '';
  String selectLastDue = '';

  /// FF insuranceInfoPage4FirstPay (`payments[0].amount`) — amount to pay now.
  String firstPay = '';

  /// FF insuranceInfoPage4TenorOverSelect (`app_installment[0].tenor_first_due`).
  String tenorOverSelect = '';

  /// FF insurancePageTenorFirstDueFromAPI / insurancePage4TenorDueFromApi —
  /// the plan the server has saved.
  String tenorFirstDueFromApi = '';
  String tenorDueFromApi = '';

  /// FF insurancePage4CheckSavePaymentBtn: the plan on screen equals the
  /// saved one (gates the instalment QR icon).
  bool checkSavePaymentBtn = false;

  /// Calc API result (FF InsuranceInfoPage4Tenor / …FirstDue / …LastDue /
  /// installmentDataTypeAppState).
  List<InstallmentOption> installments = [];

  /// FF insuranceInfoPage4TenorOverList / insuranceinfoPage4TenorDefault.
  List<String> tenorOverList = [];
  String tenorDefault = '';

  /// FF insuranceInfoQrcode* (regenerate/code result, read by the QR page).
  String qrTaxId = '';
  String qrSuffix = '';
  String qrRef1 = '';
  String qrRef2 = '';
  String qrAmount = '';

  bool get isPreparing => status == 'เตรียมข้อมูล';
  bool get isFullPayment => paymentType == 'จ่ายเต็ม';
  bool get isInstallment => paymentType == 'ผ่อนชำระ';
  bool get isPaid => paymentStatus == 'ชำระแล้ว';
  bool get isWaitingPayment => paymentStatus == 'รอชำระเงิน';

  void reset() {
    status = paymentType = paymentChannel = paymentStatus = '';
    grossTotal = actTotal = netPremiumTotal = vehicleCode = workType = actFlag = '';
    insurerShortName = coverTypeCode = subProduct = applicationType = firstName = lastName = '';
    discountFlg = discountOther = effectiveDateInsure = effectiveDateAct = '';
    selectTenor = selectFirstDue = selectLastDue = firstPay = tenorOverSelect = '';
    tenorFirstDueFromApi = tenorDueFromApi = '';
    checkSavePaymentBtn = false;
    installments = [];
    tenorOverList = [];
    tenorDefault = '';
    clearQr();
  }

  void clearQr() => qrTaxId = qrSuffix = qrRef1 = qrRef2 = qrAmount = '';

  /// P4_2 on-load steps 5 + 8 (motor / EV / MC branch).
  ///
  /// FF stopped before step 8 when the status was 'เตรียมข้อมูล' and kept
  /// whatever payment values HR41 had left in app state; the port reads the
  /// same values from the detail (the server saved them in step 4).
  void loadFromDetail(ApplicationDetail d) {
    final ld = d.leadDetail;
    final app = d.appDetail;
    final pay = d.payment;
    String s(Map<String, dynamic> m, String k) => ApplicationDetail.sOf(m, k);

    status = d.s('quotations.quotation_status');
    applicationType = d.applicationType;
    subProduct = d.subProduct;
    firstName = d.s('first_name_th');
    lastName = d.s('last_name_th');
    actFlag = d.s('act_flg');
    vehicleCode = s(d.lead, 'vehicle_code');
    workType = s(app, 'work_type');
    insurerShortName = s(ld, 'insurer_short_name');
    coverTypeCode = s(ld, 'cover_type_code');
    discountFlg = s(ld, 'discount_flg');
    discountOther = s(ld, 'discount_other');
    effectiveDateInsure = s(app, 'effective_date_insure');
    effectiveDateAct = s(app, 'effective_date_act');

    paymentType = s(pay, 'payment_type');
    paymentChannel = s(pay, 'payment_channel');
    paymentStatus = s(pay, 'payment_status');
    grossTotal = s(app, 'gross_total_net');
    actTotal = s(app, 'act_total');
    netPremiumTotal = s(app, 'net_premium_total');
    selectTenor = s(pay, 'tenor');
    selectFirstDue = s(app, 'installment_first_due');
    selectLastDue = s(app, 'installment_last_due');
    firstPay = s(pay, 'amount');
    final tfd = ApplicationDetail.sOf(_first(d.at('app_installment')), 'tenor_first_due');
    tenorOverSelect = tfd;
    tenorFirstDueFromApi = tfd;
    tenorDueFromApi = selectTenor;
    checkSavePaymentBtn = true;
  }

  /// P4_2 §6.1 / §6.2 — pull-to-refresh and the refresh icon re-read only
  /// these fields (no recalculation; SelectTenor is not touched).
  void applyRefresh(ApplicationDetail d) {
    final app = d.appDetail;
    final pay = d.payment;
    String s(Map<String, dynamic> m, String k) => ApplicationDetail.sOf(m, k);
    paymentType = s(pay, 'payment_type');
    paymentChannel = s(pay, 'payment_channel');
    paymentStatus = s(pay, 'payment_status');
    grossTotal = s(app, 'gross_total_net');
    actTotal = s(app, 'act_total');
    vehicleCode = s(d.lead, 'vehicle_code');
    status = d.s('quotations.quotation_status');
    final tfd = ApplicationDetail.sOf(_first(d.at('app_installment')), 'tenor_first_due');
    tenorOverSelect = tfd;
    tenorFirstDueFromApi = tfd;
    checkSavePaymentBtn = true;
    tenorDueFromApi = s(pay, 'tenor');
  }

  /// P4_2 §6.6 step 7 — after 'บันทึก' (FF did not update tenorDueFromApi).
  void applyAfterSave(ApplicationDetail d) {
    firstPay = ApplicationDetail.sOf(d.payment, 'amount');
    paymentStatus = ApplicationDetail.sOf(d.payment, 'payment_status');
    checkSavePaymentBtn = true;
    tenorFirstDueFromApi = ApplicationDetail.sOf(_first(d.at('app_installment')), 'tenor_first_due');
  }

  /// FF HR41 → P4_2 hand-off: while the status is 'เตรียมข้อมูล' FF page 4.2
  /// stopped its on-load and showed what the 4.1 save had written to app
  /// state (payment type / channel / status, totals and — for 'ผ่อนชำระ' —
  /// the tenor list). The detail has no payment yet at that point, so
  /// without this the 'ระบุงวด' picker stayed hidden while 'บันทึก' still
  /// demanded a tenor (user, 2026-10-30).
  void applyStep4Save(Step4SaveResult r) {
    netPremiumTotal = r.netPremiumTotal;
    grossTotal = r.grossTotalNet;
    actTotal = r.actTotal;
    paymentChannel = r.paymentChannel;
    paymentType = r.paymentType;
    paymentStatus = r.paymentStatus;
    if (r.status.isNotEmpty) status = r.status;
    if (r.paymentType == 'ผ่อนชำระ') applyInstallments(InstallmentOption.fromList(r.installments));
  }

  /// P4_2 §3.10 — stores the calc result and the advance-tenor list of the
  /// saved tenor. FF crashed (RangeError, stuck loading) when the saved tenor
  /// was not in the list; the port leaves the advance list empty instead.
  void applyInstallments(List<InstallmentOption> options) {
    installments = options;
    final k = options.indexWhere((o) => o.tenor == selectTenor);
    if (k < 0) {
      tenorOverList = [];
      tenorDefault = '';
    } else {
      tenorOverList = options[k].tenorFirstDue;
      tenorDefault = options[k].defaultTenorFirstDue;
    }
  }

  /// 'ระบุงวด' picker row [i] (FF SearchableListPage 'จำนวนงวด' branch).
  void selectInstallment(int i) {
    final o = installments[i];
    selectTenor = o.tenor;
    selectFirstDue = o.firstDue;
    selectLastDue = o.lastDue;
    tenorOverList = o.tenorFirstDue;
    tenorOverSelect = o.defaultTenorFirstDue;
    tenorDefault = o.defaultTenorFirstDue;
    _recheckSaved();
  }

  /// 'ระบุงวดที่ต้องการจ่ายล่วงหน้า' picker row [i].
  void selectTenorOver(int i) {
    tenorOverSelect = tenorOverList[i];
    _recheckSaved();
  }

  void _recheckSaved() =>
      checkSavePaymentBtn = selectTenor == tenorDueFromApi && tenorOverSelect == tenorFirstDueFromApi;

  /// Advance picker row text (3 spaces each side of 'งวด'). FF `int.parse`
  /// crashed on ''/'null'; unparsable → '(ไม่ต้องรออนุมัติ)'.
  String tenorOverLabel(String n) {
    final a = int.tryParse(n);
    final b = int.tryParse(tenorDefault);
    final waits = a != null && b != null && a < b;
    return '$n   งวด   ${waits ? '(รออนุมัติ)' : '(ไม่ต้องรออนุมัติ)'}';
  }

  /// 'ภาค' extra confirm: advance tenor below the default (FF `int.parse`
  /// crash on '' → false).
  bool get tenorOverBelowDefault {
    final a = int.tryParse(tenorOverSelect);
    final b = int.tryParse(tenorDefault);
    return a != null && b != null && a < b;
  }

  /// `IbsApplicationsPaymentSaveCall` fields ('บันทึก', spec §4).
  /// `act_total`: FF sent `insuranceInfoPage4ActTotal`, which this page never
  /// set (stale / empty when opened from the quotation list — §8.5); the port
  /// sends the detail's `act_total` (the value the page shows).
  Map<String, String> savePaymentFields({required String quotationId, required String leadDtlId}) {
    final full = isFullPayment;
    return {
      'tenor_first_due': tenorOverSelect,
      'quotation_id': quotationId,
      'lead_dtl_id': leadDtlId,
      'payment_type': paymentType,
      'payment_channel': paymentChannel,
      'tenor': full ? '0' : selectTenor,
      'net_premium_total': netPremiumTotal,
      'act_total': actTotal,
      'installment_first_due': full ? '0' : selectFirstDue,
      'installment_last_due': full ? '0' : selectLastDue,
    };
  }

  /// Stores the regenerate/code result (`results.data.payments[0]`, FF `[:]`).
  void applyQr(dynamic json) {
    final p = _first(jsonPathGet(json, 'results.data.payments'));
    String s(String k) => p[k] == null ? '' : '${p[k]}';
    qrRef1 = s('ref1');
    qrRef2 = s('ref2');
    qrSuffix = s('suffix');
    qrTaxId = s('tax_id');
    qrAmount = s('amount');
  }

  static Map<String, dynamic> _first(dynamic v) {
    if (v is List && v.isNotEmpty && v.first is Map) return Map<String, dynamic>.from(v.first as Map);
    if (v is Map) return Map<String, dynamic>.from(v);
    return const {};
  }
}
