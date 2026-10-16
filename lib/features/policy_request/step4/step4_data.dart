import '../data/policy_request_api.dart';
import '../models/application_detail.dart';

/// The five payment documents of FF InsuranceInfoPage4 (upload slots).
enum PaymentDocument {
  /// 1. ใบคำขอเอาประกัน — `image_application`.
  application('image_application'),

  /// 2. คําขอแบ่งชําระค่าเบี้ยประกันภัยฯ — `file_loan_application_register`.
  loanApplication('file_loan_application_register'),

  /// 3. หนังสือขอบอกเลิกสัญญาประกันภัย — `file_cancel_loan`.
  cancelLoan('file_cancel_loan'),

  /// 4. หนังสือมอบอำนาจยกเลิกกรมธรรม์ — `power_of_attorney`.
  powerOfAttorney('power_of_attorney'),

  /// 5. สำเนาบัตรประชาชนสำหรับมอบอำนาจ — `id_card_power_of_attorney`.
  idCardPowerOfAttorney('id_card_power_of_attorney');

  const PaymentDocument(this.apiKey);

  /// Key in the detail `app_document` and in the step-4 save body.
  final String apiKey;
}

/// Step 4 (payment documents) + 4.1 (payment type). Replaces FF
/// `insuranceInfoPage4ImageApplication` (+ legacy `insuranceInfoImageApplication`),
/// `…FileLoanApplicationRegister` (+ legacy copy), `…FileCancelLoan`,
/// `InsuranceInfoPage4PowerOfAttoney`, `…IdCardPowerattorney`,
/// `…ImageApp2`, `flagRenew` and the 4.1 save outputs.
class Step4Data {
  /// `app_detail[0].flg_renew`, else `leads[0].flg_renew` ('0' new, '1' renew).
  String flagRenew = '';

  final Map<PaymentDocument, String> docs = {for (final d in PaymentDocument.values) d: ''};

  /// `app_document[0].image_application_2` (only prefilled; sent back by 4.1).
  String imageApplication2 = '';

  /// Outputs of the 4.1 save (FF insuranceInfoPage4NetPremiumTotal …). The
  /// payment page reloads the detail, so these are informational.
  Step4SaveResult? lastSave;

  String doc(PaymentDocument d) => docs[d]!;

  void reset() {
    flagRenew = '';
    for (final d in PaymentDocument.values) {
      docs[d] = '';
    }
    imageApplication2 = '';
    lastSave = null;
  }

  /// FF page 1 §3.3. FF prefilled `'${x}'` — a null became the text 'null'
  /// and counted as uploaded; the port treats null / 'null' as empty.
  void loadFromDetail(ApplicationDetail d) {
    final doc = d.appDocument;
    final appRenew = _clean(d.appDetail['flg_renew']);
    flagRenew = appRenew.isNotEmpty ? appRenew : _clean(d.lead['flg_renew']);
    for (final p in PaymentDocument.values) {
      docs[p] = _clean(doc[p.apiKey]);
    }
    imageApplication2 = _clean(doc['image_application_2']);
  }

  static String _clean(dynamic v) {
    if (v == null) return '';
    final s = '$v'.trim();
    return s == 'null' ? '' : s;
  }
}

/// `$.results.data.payment` of the step-4 save (FF HR41 outputs).
class Step4SaveResult {
  Step4SaveResult({
    required this.netPremiumTotal,
    required this.grossTotalNet,
    required this.actTotal,
    required this.paymentChannel,
    required this.paymentType,
    required this.paymentStatus,
    required this.status,
    required this.installments,
  });

  final String netPremiumTotal;
  final String grossTotalNet;
  final String actTotal;
  final String paymentChannel;
  final String paymentType;
  final String paymentStatus;
  final String status;

  /// `payment.installment[]` (only kept when payment_type is 'ผ่อนชำระ', as FF).
  final List<Map<String, dynamic>> installments;

  factory Step4SaveResult.fromJson(dynamic json) {
    String s(String k) {
      final v = jsonPathGet(json, 'results.data.payment.$k');
      return v == null ? '' : '$v';
    }

    final type = s('payment_type');
    final raw = jsonPathGet(json, 'results.data.payment.installment');
    return Step4SaveResult(
      netPremiumTotal: s('net_premium_total'),
      grossTotalNet: s('gross_total_net'),
      actTotal: s('act_total'),
      paymentChannel: s('payment_channel'),
      paymentType: type,
      paymentStatus: s('payment_status'),
      status: s('status'),
      installments: type == 'ผ่อนชำระ' && raw is List
          ? [
              for (final e in raw)
                if (e is Map) Map<String, dynamic>.from(e),
            ]
          : const [],
    );
  }
}
