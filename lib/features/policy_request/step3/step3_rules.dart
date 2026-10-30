import '../models/request_variant.dart';
import 'step3_data.dart';

/// Which of FF InsuranceInfoPage3's three 'บันทึกเตรียมข้อมูล' buttons applies.
enum Step3SaveKind {
  /// FF VIM1Btn — ชั้น 1, inspection not waived: documents + 9 photos.
  vim1,

  /// FF OtherVIMBtn — other covers or inspection waived: documents + old policy.
  otherVim,

  /// FF OtherVIMBtnRenew — renewal / MC / CMI: ID card (+ blue book).
  renew,
}

const kStep3MissingPhotos = 'บังคับถ่ายรูปให้ครบ';
const kStep3MissingConsent = 'กรุณาเลือกยินยอม';
const kStep3MissingOldPolicy = 'บังคับถ่ายรูปตารางกรมธรรม์เดิมที่ยังไม่หมดอายุ';

/// Product rules of step 3 (FF InsuranceInfoPage3, auto work type). FF read
/// the product from `insuranceinfoActType` ('Motor' / 'MC' / 'CMI'); EV is
/// 'Motor' and has no step-3 difference.
///
/// Manual work type uses FF InsuranceInfoPage31 — not ported (separate page:
/// insurer quotation upload, trailer photos, renew documents).
abstract class Step3Rules {
  const Step3Rules();

  factory Step3Rules.of(RequestVariant v) => switch (v.product) {
        RequestProduct.mc => const McStep3Rules(),
        RequestProduct.cmi => const CmiStep3Rules(),
        RequestProduct.ev => const EvStep3Rules(),
        // House: separate FF FireInsuranceInfoPage3 — not ported.
        _ => const MotorStep3Rules(),
      };

  /// 'ดาวน์โหลดเอกสาร ใบตรวจสภาพรถ SSW' (FF: not CMI, not MC).
  bool get showsInspectionFormLink;

  /// Inspection form row (FF: not renewal, not CMI, not MC).
  bool showsExamination(Step3Data d);

  /// Red 'บังคับอัพโหลดรูป' on the inspection form + its validation.
  bool examinationRequired(Step3Data d) => d.coverType == 'ชั้น 1';

  /// Blue book row (FF: not renewal — also for CMI / MC).
  bool showsBluebook(Step3Data d) => !d.isRenewal;

  /// Old-policy row (FF: policy file not waived and ชั้น 1, every product).
  bool showsOldPolicy(Step3Data d) => d.inspectionExceptPolicyFile != 'Y' && d.coverType == 'ชั้น 1';

  /// 'รูปเอกสารอื่นๆ' / 'รูปรอยแผล' / 'รูปอุปกรณ์เสริม' rows.
  bool showsMultiPhotos(Step3Data d);

  /// The 9-photo tap map + status list.
  bool showsInspection(Step3Data d) => d.coverType == 'ชั้น 1' && d.inspectionExcept != 'Y' && !d.isRenewal;

  Step3SaveKind saveKind(Step3Data d);

  /// Renew button: blue book required (FF `actType == 'CMI' || 'MC'`).
  bool get renewRequiresBluebook;

  /// Renew button: `image_bluebook` sent (FF only for CMI).
  bool get renewSendsBluebook;

  /// FF 'ถัดไป' for CMI saved step 4 ('จ่ายเต็ม') and went to P4_2.
  bool get nextSavesStep4 => false;

  /// The FF checks of the save button, in FF order; null = OK.
  String? validate(Step3Data d, Step3Consents c) {
    switch (saveKind(d)) {
      case Step3SaveKind.vim1:
        final ok = (!examinationRequired(d) || d.examination.isNotEmpty) &&
            d.bluebook.isNotEmpty &&
            d.idCard.isNotEmpty &&
            InspectionPhoto.values.every((p) => d.photos[p]!.isNotEmpty);
        if (!ok) return kStep3MissingPhotos;
        if (!c.ok) return kStep3MissingConsent;
        // FF VIM1Btn neither checks nor sends the old policy although the
        // row is shown (kept).
        return null;
      case Step3SaveKind.otherVim:
        final ok =
            (!examinationRequired(d) || d.examination.isNotEmpty) && d.bluebook.isNotEmpty && d.idCard.isNotEmpty;
        if (!ok) return kStep3MissingPhotos;
        if (!c.ok) return kStep3MissingConsent;
        // FF also for non-ชั้น-1 covers, where the row is hidden (kept: the
        // image normally comes from the quotation; see report).
        if (d.inspectionExceptPolicyFile != 'Y' && d.oldVmi.isEmpty) return kStep3MissingOldPolicy;
        return null;
      case Step3SaveKind.renew:
        if (d.idCard.isEmpty) return kStep3MissingPhotos;
        if (!c.ok) return kStep3MissingConsent;
        if (renewRequiresBluebook && d.bluebook.isEmpty) return kStep3MissingPhotos;
        return null;
    }
  }

  /// The step-3 save fields (`action` / `step` / `token` / `insurance_url`
  /// are added by `PolicyRequestApi.saveApplication`; every other key "").
  Map<String, dynamic> saveFields(
    Step3Data d,
    Step3Consents c, {
    required String quotationId,
    required String leadDtlId,
  }) {
    final base = <String, dynamic>{
      'quotation_id': quotationId,
      'lead_dtl_id': leadDtlId,
      ...c.toFields(),
    };
    switch (saveKind(d)) {
      case Step3SaveKind.vim1:
        return {
          ...base,
          ..._documents(d),
          for (final p in InspectionPhoto.values) p.apiKey: d.photos[p]!,
        };
      case Step3SaveKind.otherVim:
        return {
          ...base,
          ..._documents(d),
          'old_VMI_image': d.oldVmi,
        };
      case Step3SaveKind.renew:
        return {
          ...base,
          'image_idcard': d.idCard,
          'sub_product': d.subProduct,
          'image_bluebook': renewSendsBluebook ? d.bluebook : '',
        };
    }
  }

  static Map<String, dynamic> _documents(Step3Data d) => {
        'image_examination': d.examination,
        'image_bluebook': d.bluebook,
        'image_idcard': d.idCard,
        'image_other': d.other,
        'image_wound': d.wound.join(','),
        'image_accessories': d.accessories.join(','),
      };
}

/// Car (sub_product 'Motor', ev_flag ≠ 'Y').
class MotorStep3Rules extends Step3Rules {
  const MotorStep3Rules();

  @override
  bool get showsInspectionFormLink => true;

  @override
  bool showsExamination(Step3Data d) => !d.isRenewal;

  @override
  bool showsMultiPhotos(Step3Data d) => !d.isRenewal;

  @override
  Step3SaveKind saveKind(Step3Data d) {
    if (d.isRenewal) return Step3SaveKind.renew;
    if (d.coverType == 'ชั้น 1' && d.inspectionExcept != 'Y') return Step3SaveKind.vim1;
    return Step3SaveKind.otherVim;
  }

  @override
  bool get renewRequiresBluebook => false;

  @override
  bool get renewSendsBluebook => false;
}

/// EV — FF page 3 has no EV branch (EV is sub_product 'Motor').
class EvStep3Rules extends MotorStep3Rules {
  const EvStep3Rules();
}

/// Motorcycle (sub_product 'MC'): blue book + ID card on the renew button.
class McStep3Rules extends Step3Rules {
  const McStep3Rules();

  @override
  bool get showsInspectionFormLink => false;

  @override
  bool showsExamination(Step3Data d) => false;

  @override
  bool showsMultiPhotos(Step3Data d) => false;

  /// FF quirk kept: the 9-photo map is shown for ชั้น 1 (inspection not
  /// waived) but the MC button neither requires nor sends the photos.
  @override
  bool showsInspection(Step3Data d) => super.showsInspection(d);

  @override
  Step3SaveKind saveKind(Step3Data d) => Step3SaveKind.renew;

  @override
  bool get renewRequiresBluebook => true;

  /// FF required the blue book for MC but sent `image_bluebook` "" (only
  /// CMI sent it), so the photo was lost on the next visit — sent here
  /// (user, 2026-10-30).
  @override
  bool get renewSendsBluebook => true;
}

/// Stand-alone พ.ร.บ. (sub_product 'CMI') — not reachable in the web port
/// yet (variant unsupported); rules kept from FF. Its summary card
/// (InfomationCustomerAct) is not ported.
class CmiStep3Rules extends McStep3Rules {
  const CmiStep3Rules();

  @override
  bool showsInspection(Step3Data d) => false;

  @override
  bool get nextSavesStep4 => true;
}
