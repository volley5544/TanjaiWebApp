import 'package:flutter/foundation.dart';

import '../models/application_detail.dart';
import '../models/request_variant.dart';
import '../payment/payment_data.dart';
import '../step1/step1_data.dart';
import '../step2/step2_data.dart';
import '../step3/step3_data.dart';
import '../step4/step4_data.dart';
import '../step5/step5_data.dart';

/// Request-policy flow state (FF `in_package_insurance`): replaces the ~300
/// `insuranceInfo*` FFAppState fields. Never put in the URL; a step page
/// opened without an active flow ([isActive] false) sends the user to the
/// quotation list.
///
/// Layout:
/// * ids + [variant] + the last loaded [detail] (shared);
/// * [summary] — the customer/quotation card shown on every step;
/// * one data object per step ([step1] … [step5], [payment]), each owned by
///   its step folder and filled by its `loadFromDetail` (FF step 1 loaded
///   everything on open; entering P4_2 / P5 directly reloads the detail and
///   runs every loader, so no stale values from another flow are used).
class PolicyRequestState extends ChangeNotifier {
  PolicyRequestState._();

  static final PolicyRequestState instance = PolicyRequestState._();

  String quotationId = '';

  /// FF `leadDtailId` / `leadDetailId` / `leadDtlId` route param.
  int? leadDtlId;

  /// FF P1 `fromPage` ('FireInsurance' → back to the fire list).
  String fromPage = '';

  RequestVariant variant = const RequestVariant(RequestProduct.motor, RequestWorkType.auto);
  ApplicationDetail? detail;

  final summary = RequestSummary();
  final step1 = Step1Data();
  final step2 = Step2Data();
  final step3 = Step3Data();
  final step4 = Step4Data();
  final payment = PaymentData();
  final step5 = Step5Data();

  bool get isActive => quotationId.isNotEmpty;

  /// Starts a flow for [quotationId] / [leadDtlId] (all step data cleared).
  void start({required String quotationId, required int? leadDtlId, String fromPage = ''}) {
    this.quotationId = quotationId;
    this.leadDtlId = leadDtlId;
    this.fromPage = fromPage;
    detail = null;
    summary.reset();
    step1.reset();
    step2.reset();
    step3.reset();
    step4.reset();
    payment.reset();
    step5.reset();
  }

  /// Stores a freshly loaded detail and refreshes the variant, the summary
  /// and every step's data from it.
  void applyDetail(ApplicationDetail d) {
    detail = d;
    variant = RequestVariant.from(subProduct: d.subProduct, evFlag: d.evFlag, applicationType: d.applicationType);
    summary.loadFromDetail(d, quotationId: quotationId);
    step1.loadFromDetail(d);
    step2.loadFromDetail(d);
    step3.loadFromDetail(d);
    step4.loadFromDetail(d);
    payment.loadFromDetail(d);
    step5.loadFromDetail(d);
    notifyListeners();
  }

  void notify() => notifyListeners();
}

/// Values of the FF `InfomationCustomer` card (+ ids / type names every step
/// reads). Filled from the detail like FF step 1 (§3.2 / 3.3 of the spec):
/// FF `'${x}'` reads are kept where they were shown as-is.
class RequestSummary {
  String quotationId = '';
  String firstName = '';
  String lastName = '';
  String phone = '';

  /// `leads_detail[LD].garage_type_name` (FF insuranceInfoGarageType).
  String garageType = '';

  /// `leads_detail[LD].cover_type_name` (FF insuranceInfocoverType).
  String coverType = '';

  /// `leads_detail[LD].cover_type_code` (FF insuranceInfoCoverTypeCode).
  String coverTypeCode = '';

  /// FF insuranceInfoPage4NetPremiumTotal.
  String netPremiumTotal = '';

  /// FF insuranceInfoActFlag ('1' = with พ.ร.บ.).
  String actFlag = '';

  /// FF insuranceInfoActAmount.
  String actAmount = '';

  /// FF insuranceInfoGrosstotalNet.
  String grossTotalNet = '';

  /// FF appDetailNew.discountFlg / discountOther / discountPercent.
  String discountFlg = '';
  String discountOther = '';
  String discountPercent = '';

  String quotationTypeName = '';
  String quotationTypeBakName = '';
  String subProductName = '';

  /// `leads_detail[LD].insurer_logo`.
  String insurerLogo = '';

  /// `leads_detail[LD].insurer_short_name` (FF insuranceInfoCompayId).
  String insurerShortName = '';

  /// FF insuranceInfoApplicationType (`quotation_type_bak`).
  String applicationType = '';

  /// FF insuranceinfoActType (`leads[0].sub_product`).
  String actType = '';

  /// FF insuranceInfoApplicationId.
  String applicationId = '';

  /// FF insuranceInfoLeadDetailId (string form, as the save body sends it).
  String leadDetailId = '';

  void reset() {
    quotationId = firstName = lastName = phone = garageType = coverType = coverTypeCode = '';
    netPremiumTotal = actFlag = actAmount = grossTotalNet = '';
    discountFlg = discountOther = discountPercent = '';
    quotationTypeName = quotationTypeBakName = subProductName = insurerLogo = insurerShortName = '';
    applicationType = actType = applicationId = leadDetailId = '';
  }

  void loadFromDetail(ApplicationDetail d, {required String quotationId}) {
    final ld = d.leadDetail;
    final app = d.appDetail;
    final lead = d.lead;
    String ldf(String k) => ApplicationDetail.ffOf(ld, k);
    // Null-safe "non-empty" test (FF `'${x}' != ''` let a JSON null through
    // as the text 'null'; the port treats null as empty).
    String pick(String primary, String fallback) => primary.isNotEmpty && primary != 'null' ? primary : fallback;

    this.quotationId = quotationId;
    applicationType = d.applicationType;
    actType = d.subProduct;
    applicationId = d.s('application_id');
    leadDetailId = ld.isEmpty ? '' : '${ld['lead_dtl_id']}';

    firstName = pick(d.s('first_name_th'), ApplicationDetail.sOf(lead, 'first_name'));
    lastName = pick(d.s('last_name_th'), ApplicationDetail.sOf(lead, 'last_name'));
    phone = pick(d.s('mobile1'), ApplicationDetail.sOf(lead, 'phone_number'));

    garageType = ldf('garage_type_name');
    coverType = ldf('cover_type_name');
    coverTypeCode = ldf('cover_type_code');
    insurerLogo = ApplicationDetail.sOf(ld, 'insurer_logo');
    insurerShortName = ldf('insurer_short_name');
    discountFlg = ldf('discount_flg');
    discountOther = ldf('discount_other');
    discountPercent = ldf('discount_percent');

    final appNet = ApplicationDetail.sOf(app, 'net_premium_total');
    netPremiumTotal = appNet != '0' && appNet.isNotEmpty ? appNet : ldf('net_premium_total');
    if (d.applicationType == 'auto') {
      actFlag = d.ff('act_flg');
      actAmount = ApplicationDetail.ffOf(app, 'act_total');
      grossTotalNet = pick(ApplicationDetail.sOf(app, 'gross_total_net'), ldf('gross_total_net'));
    } else {
      // FF non-auto branch (manual work type — not ported yet; kept so the
      // card is right when it is).
      final actFlg = d.s('act_flg');
      actFlag = actFlg.isEmpty ? ApplicationDetail.ffOf(lead, 'flg_act') : actFlg;
      actAmount = ldf('act_amount');
      grossTotalNet = ldf('gross_total_net');
    }

    quotationTypeName = d.ff('quotation_type_name');
    quotationTypeBakName = d.ff('quotation_type_bak_name');
    subProductName = d.ff('sub_product_name');
  }
}
