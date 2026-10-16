import '../data/policy_request_api.dart';
import '../models/application_detail.dart';

/// Step 5 (FF InsuranceInfoPage5 + cancel): the `page5*` and the
/// `insuranceInfo*` fields page 5 wrote.
///
/// Owned by `step5/`. [loadFromDetail] (called by
/// `PolicyRequestState.applyDetail`) fills the applications-detail values;
/// [applyPolicy] the `insurance/get/policy` ones.
///
/// FF wrote every value with `'${x}'` (JSON null → the text 'null', and
/// crashes in `convertToBDYearAndTime` / `showDateBE` — spec P5 §8.3); the
/// port treats null as '' (→ '-' where FF had a '-' fallback). `[:]` getters
/// read the first element (FF crashed on > 1 — §8.4).
class Step5Data {
  // ---- from applications/list (detail) --------------------------------------
  String firstName = '';
  String lastName = '';

  /// `leads[0].phone_number`, else `mobile1`.
  String phone = '';
  String garageType = '';
  String coverType = '';

  /// `app_detail[0].gross_total_net` (FF insuranceInfoGrossTotal).
  String grossTotal = '';

  /// `quotations.quotation_type` (FF insuranceInfoApplicationType /
  /// insuranceInfoQuotationType on page 5 — **not** `_bak`): 'auto' gates the
  /// cancel button and the premium format.
  String quotationType = '';

  /// `quotations.quotation_type_bak` (FF insuranceInfoPage5QuotationType;
  /// step-5 document sheet).
  String quotationTypeBak = '';

  /// `leads_detail[LD].insurer_short_name` (FF insuranceInfoCompayId).
  String insurerShortName = '';
  String actFlag = '';
  String applicationNo = '';
  String insurerLogo = '';

  /// `app_detail[0].expiry_date_insure` (FF nonePackageOldVmiExpDate).
  String oldVmiExpDate = '';

  /// `app_document[0].file_application` (application form PDF).
  String fileApplication = '';

  /// `leads[0].sub_product` (FF insuranceinfoActType).
  String subProduct = '';
  String quotationTypeName = '';
  String quotationTypeBakName = '';
  String subProductName = '';

  /// `payments[0].refund_remark` / `payments[0].amount`.
  String refundRemark = '';
  String amount = '';

  /// `leads_detail[LD].discount_*` (FF appDetailNew).
  String discountOther = '';
  String discountFlg = '';
  String discountPercent = '';

  /// `quotations.quotation_status` of the detail.
  String detailStatus = '';

  // ---- from getdate-time ------------------------------------------------------

  /// Server date yyyy-MM-dd (FF page5DateNow).
  String dateNow = '';

  // ---- from insurance/get/policy ------------------------------------------------

  /// FF page5QuotationStatus: on load the **detail's** status, on refresh the
  /// policy API's (FF quirk §8.8, kept).
  String status = '';

  /// The on-load policy response's `quotation_status` (FF `_model.getPolicy`)
  /// — 'ทำรายการใหม่' visibility; refresh never updates it (FF, kept).
  String onLoadPolicyStatus = '';

  String createdDate = '-';
  String completedDate = '-';
  String contractId = '-';
  String vmiPolicyNo = '-';
  String reason = '-';
  String paymentStatus = '-';
  String paymentType = '-';
  String paymentChannel = '-';
  String netPremium = '-';
  String actPrice = '-';
  String grossTotalNet = '-';
  String firstDue = '-';
  String lastDue = '-';
  String vloanContNo = '-';
  String cusIdCardNo = '-';
  String tenor = '-';

  /// `VMI.VMI_documentUrl` (overwritten by get-file-vmi) or '-'.
  String vmiDocUrl = '-';

  /// `CMI.CMI_documentUrl` (overwritten by get-file-cmi) or '-'.
  String cmiDocUrl = '-';

  bool get isApproved => status == 'อนุมัติ';

  void reset() {
    firstName = lastName = phone = garageType = coverType = grossTotal = '';
    quotationType = quotationTypeBak = insurerShortName = actFlag = applicationNo = insurerLogo = '';
    oldVmiExpDate = fileApplication = subProduct = quotationTypeName = quotationTypeBakName = subProductName = '';
    refundRemark = amount = discountOther = discountFlg = discountPercent = detailStatus = dateNow = '';
    status = onLoadPolicyStatus = '';
    createdDate = completedDate = contractId = vmiPolicyNo = reason = '-';
    paymentStatus = paymentType = paymentChannel = '-';
    netPremium = actPrice = grossTotalNet = firstDue = lastDue = '-';
    vloanContNo = cusIdCardNo = tenor = vmiDocUrl = cmiDocUrl = '-';
  }

  /// P5 on-load step 4 (applications/list).
  void loadFromDetail(ApplicationDetail d) {
    final ld = d.leadDetail;
    String s(Map<String, dynamic> m, String k) => ApplicationDetail.sOf(m, k);
    firstName = d.s('first_name_th');
    lastName = d.s('last_name_th');
    final ph = s(d.lead, 'phone_number');
    phone = ph.isNotEmpty ? ph : d.s('mobile1');
    garageType = s(ld, 'garage_type_name');
    coverType = s(ld, 'cover_type_name');
    grossTotal = s(d.appDetail, 'gross_total_net');
    quotationType = d.s('quotations.quotation_type');
    quotationTypeBak = d.s('quotations.quotation_type_bak');
    insurerShortName = s(ld, 'insurer_short_name');
    actFlag = d.s('act_flg');
    applicationNo = d.s('application_no');
    insurerLogo = s(ld, 'insurer_logo');
    oldVmiExpDate = s(d.appDetail, 'expiry_date_insure');
    fileApplication = s(d.appDocument, 'file_application');
    subProduct = d.subProduct;
    quotationTypeName = d.s('quotation_type_name');
    quotationTypeBakName = d.s('quotation_type_bak_name');
    subProductName = d.s('sub_product_name');
    refundRemark = s(d.payment, 'refund_remark');
    amount = s(d.payment, 'amount');
    discountOther = s(ld, 'discount_other');
    discountFlg = s(ld, 'discount_flg');
    discountPercent = s(ld, 'discount_percent');
    detailStatus = d.s('quotations.quotation_status');
  }

  /// P5 on-load step 6 ([refresh] false) / refresh icon step 5 ([refresh]
  /// true) from `insurance/get/policy` ([json] = the whole response).
  /// House (`app_detail_house`) values are not ported.
  void applyPolicy(dynamic json, {required bool refresh}) {
    String v(String path) {
      final x = jsonPathGet(json, 'results.data.$path');
      return x == null ? '' : '$x';
    }

    String first(String list, String key) {
      final x = jsonPathGet(json, 'results.data.$list');
      final m = x is List ? (x.isNotEmpty ? x.first : null) : x;
      return m is Map && m[key] != null ? '${m[key]}' : '';
    }

    String dash(String x) => x.isNotEmpty ? x : '-';

    final policyStatus = v('quotation_status');
    if (refresh) {
      status = policyStatus;
    } else {
      status = detailStatus;
      onLoadPolicyStatus = policyStatus;
    }
    createdDate = _bd(v('api_send_date'));
    completedDate = _bd(v('api_complete_date'));
    contractId = dash(v('VMI.VMI_contractId'));
    vmiPolicyNo = dash(v('VMI.VMI_policyNumber'));
    // FF refresh skipped cancel_reason_name (kept).
    final cancelReason = refresh ? '' : v('cancel_reason_name');
    final vmiError = v('VMI.VMI_errorMessage');
    final cmiError = v('CMI.CMI_errorMessage');
    reason = cancelReason.isNotEmpty
        ? cancelReason
        : vmiError.isNotEmpty
            ? vmiError
            : dash(cmiError);
    paymentStatus = dash(first('payments', 'payment_status'));
    paymentType = dash(first('payments', 'payment_type'));
    paymentChannel = dash(first('payments', 'payment_channel'));
    netPremium = dash(first('app_detail', 'net_premium_total'));
    actPrice = dash(first('app_detail', 'act_total'));
    grossTotalNet = dash(first('app_detail', 'gross_total_net'));
    firstDue = dash(first('app_detail', 'installment_first_due'));
    lastDue = dash(first('app_detail', 'installment_last_due'));
    vloanContNo = dash(v('vloan_contract_no'));
    cusIdCardNo = dash(v('vloan_cuscod'));
    tenor = dash(first('payments', 'tenor'));
    vmiDocUrl = dash(v('VMI.VMI_documentUrl'));
    cmiDocUrl = dash(v('CMI.CMI_documentUrl'));
  }

  /// '' → '-', else FF `convertToBDYearAndTime` (unparsable → '-'; FF crashed).
  static String _bd(String x) => x.isEmpty ? '-' : (convertToBDYearAndTime(x) ?? '-');

  /// 'วันหมดอายุ' value: FF `showDateBE` (crashed on 'null' / bad dates) → '-'.
  String get oldVmiExpDateText {
    if (DateTime.tryParse(oldVmiExpDate) == null) return '-';
    final d = DateTime.parse(oldVmiExpDate);
    return '${_two(d.day)}/${_two(d.month)}/${d.year + 543}';
  }

  /// Cancel allowed only on the approval day (FF `checkDatePage5`).
  bool get completedToday => checkDatePage5(completedDate, dateNow);
}

String _two(int n) => n.toString().padLeft(2, '0');

/// FF `convertToBDYearAndTime`: `yyyy-MM-dd HH:mm:ss` with a BE year.
/// Unparsable → null (FF crashed).
String? convertToBDYearAndTime(String input) {
  final g = DateTime.tryParse(input);
  if (g == null) return null;
  return '${g.year + 543}-${_two(g.month)}-${_two(g.day)} ${_two(g.hour)}:${_two(g.minute)}:${_two(g.second)}';
}

/// FF `checkDatePage5`: the BE completed date is the same calendar day as
/// the server date. FF crashed on '-' / ''; the port returns false.
bool checkDatePage5(String apiCompleteDate, String currentDate) {
  final c = DateTime.tryParse(apiCompleteDate);
  final n = DateTime.tryParse(currentDate);
  if (c == null || n == null) return false;
  return c.year == n.year + 543 && c.month == n.month && c.day == n.day;
}
