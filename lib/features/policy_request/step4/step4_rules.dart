import '../models/request_variant.dart';
import 'step4_data.dart';

const kStep4MissingApplication = 'กรุณาอัพโหลดรูปหลักฐานการเซ็นใบคำขอเอาประกัน';
const kStep4MissingLoanApplication = 'กรุณาอัพโหลดรูปเอกสาร ใบคำขอสินเชื่อเป้า ง';

/// FF: trailing space, no document name (kept).
const kStep4MissingDocument = 'กรุณาอัพโหลดรูปเอกสาร ';
const kStep4ChoosePayment = 'กรุณาเลือกการชำระเงิน';

const kPaymentFull = 'จ่ายเต็ม';
const kPaymentInstallment = 'ผ่อนชำระ';

/// Product rules of step 4 (FF InsuranceInfoPage4 + HomepageRequest41).
/// The only product difference is the installment-request form.
abstract class Step4Rules {
  const Step4Rules();

  factory Step4Rules.of(RequestVariant v) => switch (v.product) {
        RequestProduct.mc => const McStep4Rules(),
        RequestProduct.ev => const EvStep4Rules(),
        // CMI: FF step 3 skips P4 (saves step 4 'จ่ายเต็ม' → P4_2).
        // House: separate FF FireInsuranceInfoPage4 — not ported.
        _ => const MotorStep4Rules(),
      };

  /// Firestore `urlLinkStorage.url_name` of doc 2's form (FF: 'Motor' for MC,
  /// else 'CTV').
  String get installmentFormName;

  /// Doc 1 + its download link. FF: `flagRenew == '0'`, yet doc 1 was
  /// required unless `flagRenew == '1'` — any other value (''/'null') hid the
  /// row but still blocked 'ชำระเงิน'. Fixed: shown whenever it is required.
  bool showsApplicationForm(Step4Data d) => d.flagRenew != '1';

  /// FF 'ชำระเงิน' checks, in order; null = OK.
  String? validate(Step4Data d) {
    if (!(d.doc(PaymentDocument.application).isNotEmpty || d.flagRenew == '1')) return kStep4MissingApplication;
    if (d.doc(PaymentDocument.loanApplication).isEmpty) return kStep4MissingLoanApplication;
    if (d.doc(PaymentDocument.cancelLoan).isEmpty) return kStep4MissingDocument;
    if (d.doc(PaymentDocument.powerOfAttorney).isEmpty) return kStep4MissingDocument;
    if (d.doc(PaymentDocument.idCardPowerOfAttorney).isEmpty) return kStep4MissingDocument;
    return null;
  }

  /// HR41 step-4 save fields (`action` / `step` / `token` / `insurance_url`
  /// are added by `PolicyRequestApi.saveApplication`; every other key "").
  Map<String, dynamic> saveFields(
    Step4Data d, {
    required bool fullPayment,
    required String quotationId,
    required String leadDtlId,
    required String subProduct,
  }) =>
      {
        'quotation_id': quotationId,
        'lead_dtl_id': leadDtlId,
        'payment_type': fullPayment ? kPaymentFull : kPaymentInstallment,
        for (final p in PaymentDocument.values) p.apiKey: d.doc(p),
        'image_application_2': d.imageApplication2,
        'sub_product': subProduct,
      };
}

class MotorStep4Rules extends Step4Rules {
  const MotorStep4Rules();

  @override
  String get installmentFormName => 'CTV';
}

/// EV — no step-4 difference (sub_product 'Motor').
class EvStep4Rules extends MotorStep4Rules {
  const EvStep4Rules();
}

class McStep4Rules extends Step4Rules {
  const McStep4Rules();

  @override
  String get installmentFormName => 'Motor';
}

/// Firestore `InsurerConfig2` (first document) — HR41 payment options.
class InsurerPaymentConfig {
  const InsurerPaymentConfig({
    this.fullPaymentHidden = const [],
    this.installmentHidden = const [],
    this.renewInstallment = false,
    this.positions = const [],
    this.employees = const [],
    this.levels = const [],
    this.vmi1 = const [],
    this.vmi2 = const [],
    this.vmi2plus = const [],
    this.vmi3 = const [],
    this.vmi3plus = const [],
  });

  /// `InsurerFullPayment` — insurers whose 'ชำระเต็มจำนวน' is hidden.
  final List<String> fullPaymentHidden;

  /// `InsurerInstallment` — insurers whose installment is hidden.
  final List<String> installmentHidden;
  final bool renewInstallment;

  /// `canInstallmentList` / `canInstallmentListEmployee` / `canInstallmentLevel`.
  final List<String> positions;
  final List<String> employees;
  final List<String> levels;

  /// `checkInstallmentVmi1` / `…Vmi2` / `…Vmi2plus` / `…Vmi3` / `…Vmi3plus`.
  final List<String> vmi1;
  final List<String> vmi2;
  final List<String> vmi2plus;
  final List<String> vmi3;
  final List<String> vmi3plus;

  factory InsurerPaymentConfig.fromFirestore(Map<String, dynamic> doc) {
    List<String> l(String k) => [for (final x in (doc[k] is List ? doc[k] as List : const [])) '$x'];
    return InsurerPaymentConfig(
      fullPaymentHidden: l('InsurerFullPayment'),
      installmentHidden: l('InsurerInstallment'),
      renewInstallment: doc['renewInstallment'] == true,
      positions: l('canInstallmentList'),
      employees: l('canInstallmentListEmployee'),
      levels: l('canInstallmentLevel'),
      vmi1: l('checkInstallmentVmi1'),
      vmi2: l('checkInstallmentVmi2'),
      vmi2plus: l('checkInstallmentVmi2plus'),
      vmi3: l('checkInstallmentVmi3'),
      vmi3plus: l('checkInstallmentVmi3plus'),
    );
  }

  /// 'ชำระเต็มจำนวน' card.
  bool showsFullPayment(String insurer) => !fullPaymentHidden.contains(insurer);

  /// 'ผ่อนชำระ (เป้า ง)' card (FF HR41 condition, verbatim).
  bool showsInstallment({
    required String insurer,
    required String flagRenew,
    required String coverTypeCode,
    required String positionName,
    required String employeeId,
    required String level,
  }) {
    if (flagRenew == '1' && renewInstallment) return !installmentHidden.contains(insurer);
    final permitted = positions.contains(positionName) || employees.contains(employeeId) || levels.contains(level);
    final coverOk = switch (coverTypeCode) {
      'VMI1' => vmi1.contains(insurer),
      'VMI2' => vmi2.contains(insurer),
      'VMI2+' => vmi2plus.contains(insurer),
      'VMI3' => vmi3.contains(insurer),
      'VMI3+' => vmi3plus.contains(insurer),
      _ => true,
    };
    return !installmentHidden.contains(insurer) && permitted && coverOk;
  }
}
