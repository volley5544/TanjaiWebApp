import '../../../core/utils/ff_functions.dart';
import '../../../router/app_router.dart';
import '../models/request_variant.dart';
import 'step1_data.dart';

/// Product-specific rules of step 1 (FF InsuranceInfoPage1). FF switched on
/// `insuranceinfoActType` ('Motor' / 'MC' / 'CMI' / 'House'); the page asks
/// this object instead.
///
/// Ported: motor / EV / MC (FF save branch A). CMI and House are only partly
/// described here (not reachable in this port).
abstract class Step1Rules {
  const Step1Rules();

  factory Step1Rules.of(RequestVariant v) => switch (v.product) {
        RequestProduct.motor => const MotorStep1Rules(),
        RequestProduct.ev => const EvStep1Rules(),
        RequestProduct.mc => const McStep1Rules(),
        RequestProduct.cmi => const CmiStep1Rules(),
        RequestProduct.house => const HouseStep1Rules(),
      };

  /// Row 9 (birth date + age) — FF `actType != 'CMI'`.
  bool get showsBirthDate;

  /// Rows 16 / 17 (broker licence) — FF `actType != 'CMI'`.
  bool get showsLicence;

  /// Row 3 (TAXID) — FF `(cardType == '5' || isCorporate) && actType == 'CMI'`.
  bool showsTaxIdRow(Step1Data d) => false;

  /// Where 'ถัดไป' goes.
  String get nextRoute;

  /// `id_type_id` of CheckBlackListCall. FF sent `cardType == 'บัตรประชาชน' ?
  /// '1' : '2'` — i.e. '2' for the '1' every load sets (spec B3); the port
  /// sends '1' for both ID-card values.
  String blacklistIdTypeId(String cardType) => step1IsIdCardType(cardType) ? '1' : '2';

  /// `id_type_id` of the save.
  String saveIdTypeId(Step1Data d) => step1IsIdCardType(d.cardType) ? '1' : '2';

  /// Extra / overridden save keys.
  Map<String, dynamic> extraSaveFields(Step1Data d) => const {};

  /// FF 'บันทึกเตรียมข้อมูล' validations, in FF order; the first failing
  /// message, or null. Call after [Step1Data.copyFreeTextOccupation].
  String? validate(Step1Data d, Step1Form f);
}

/// FF save branch A (actType != 'CMI'): Motor (car).
class MotorStep1Rules extends Step1Rules {
  const MotorStep1Rules();

  @override
  bool get showsBirthDate => true;

  @override
  bool get showsLicence => true;

  @override
  String get nextRoute => AppRoutes.requestVehicle;

  @override
  String? validate(Step1Data d, Step1Form f) {
    if (!(d.licenseId.isNotEmpty && f.licenseCode.isNotEmpty)) return 'บังคับกรอกเลขผู้มีบัตรนายหน้าประกัน';
    if (!(d.cardType.isNotEmpty && d.cardType != kStep1CardTypePh)) return 'บังคับเลือกประเภทบัตร';
    if (!(f.idCard.isNotEmpty || f.passport.isNotEmpty)) return 'บังคับกรอกเลขบัตร';
    if (!(d.gender.isNotEmpty && d.gender != kStep1GenderPh)) return 'บังคับเลือกเพศ';
    if (!(d.title.isNotEmpty && !d.title.contains('เลือก'))) return 'บังคับเลือกคำนำหน้า';
    if (!(d.occupationGroup.isNotEmpty && d.occupationGroup != kStep1OccupationGroupPh)) return 'บังคับเลือกกลุ่มอาชีพ';
    if (f.firstName.isEmpty) return 'บังคับกรอกชื่อ';
    if (f.lastName.isEmpty) return 'บังคับกรอกนามสกุล';
    if (d.occupationSubName.isEmpty) return 'บังคับกรอกอาชีพ';
    if (f.phone.isEmpty) return 'บังคับกรอกเบอร์โทรศัพท์';
    if (f.age.isEmpty) return 'บังคับกรอก วัน/เดือน/ปี เกิด';
    // FF tested "non-empty"; the default text 'กรุณากรอกที่อยู่' passed it.
    // The port treats that placeholder as no address.
    if (!step1HasAddressText(d.idCardAddress.keyword)) return 'บังคับเลือกที่อยู่';
    if (!step1HasAddressText(d.docAddress.keyword)) return 'บังคับเลือกที่อยู่';
    // FF check 14 (`checkIdCardInput(id) || (cardType != 'บัตรประชาชน' ||
    // cardType != '1')`) is always true — the 13-digit check never ran at
    // save (spec B2). Kept as dead: the blacklist check below already needs
    // a valid 13-digit ID for an ID card.
    if (!(f.idCardFlag == 'N' || f.passportFlag == 'N')) return 'กรุณากดตรวจสอบเลขบัตร';
    if (f.email.isNotEmpty && !step1ValidateEmail(f.email)) return 'กรุณากรอกอีเมลให้ถูกต้อง';
    return null;
  }
}

/// EV = sub_product 'Motor' with ev_flag 'Y' — step 1 is identical.
class EvStep1Rules extends MotorStep1Rules {
  const EvStep1Rules();
}

/// MC — step 1 is identical to motor (step 2's title differs).
class McStep1Rules extends MotorStep1Rules {
  const McStep1Rules();
}

/// House (fire) — FF branch A too, but 'ถัดไป' opens FireInsuranceInfoPage2
/// (not ported; FF also defaulted / trimmed `benefitorData` first — not
/// ported). The FireInsurance summary card is not ported either.
class HouseStep1Rules extends MotorStep1Rules {
  const HouseStep1Rules();

  @override
  String get nextRoute => AppRoutes.notPorted('FireInsuranceInfoPage2');
}

/// CMI (stand-alone พ.ร.บ.) — not reachable in this port; FF branch B kept
/// here for when it is. The CMI summary card (InfomationCustomerAct) is not
/// ported.
class CmiStep1Rules extends Step1Rules {
  const CmiStep1Rules();

  @override
  bool get showsBirthDate => false;

  @override
  bool get showsLicence => false;

  @override
  bool showsTaxIdRow(Step1Data d) => d.cardType == '5' || d.isCorporate;

  @override
  String get nextRoute => AppRoutes.requestVehicle;

  @override
  String saveIdTypeId(Step1Data d) {
    if (step1IsIdCardType(d.cardType)) return '1';
    if (step1IsTaxIdType(d.cardType) || d.isCorporate) return '5';
    return '2';
  }

  @override
  Map<String, dynamic> extraSaveFields(Step1Data d) => {
        'birth_day': '',
        // FF typo 'บุลคลธรรมดา' is what the API receives — kept.
        'customer_type': d.isCorporate ? 'นิติบุคคล' : 'บุลคลธรรมดา',
      };

  @override
  String? validate(Step1Data d, Step1Form f) {
    if (d.isCorporate) {
      if (!(f.idCard.isNotEmpty || f.passport.isNotEmpty || f.taxId.isNotEmpty)) return 'บังคับกรอกเลขบัตร';
      if (f.firstName.isEmpty) return 'บังคับกรอกชื่อบริษัท';
      if (f.phone.isEmpty) return 'บังคับกรอกเบอร์โทรศัพท์';
      if (!step1HasAddressText(d.idCardAddress.keyword)) return 'บังคับเลือกที่อยู่';
      if (!step1HasAddressText(d.docAddress.keyword)) return 'บังคับเลือกที่อยู่';
      if (!checkIdCardInput(removeCommaFromNumText(f.taxId))) return 'กรุณากรอกเลขบัตร 13 หลัก';
      if (f.taxIdFlag != 'N') return 'กรุณากดตรวจสอบเลขบัตร';
    } else {
      if (!(d.cardType.isNotEmpty && d.cardType != kStep1CardTypePh)) return 'บังคับเลือกประเภทบัตร';
      if (!(f.idCard.isNotEmpty || f.passport.isNotEmpty)) return 'บังคับกรอกเลขบัตร';
      if (!(d.gender.isNotEmpty && d.gender != kStep1GenderPh)) return 'บังคับเลือกเพศ';
      if (!(d.title.isNotEmpty && !d.title.contains('เลือก'))) return 'บังคับเลือกคำนำหน้า';
      if (!(d.occupationGroup.isNotEmpty && d.occupationGroup != kStep1OccupationGroupPh)) return 'บังคับเลือกกลุ่มอาชีพ';
      if (f.firstName.isEmpty) return 'บังคับกรอกชื่อ';
      if (f.lastName.isEmpty) return 'บังคับกรอกนามสกุล';
      if (d.occupationSubName.isEmpty) return 'บังคับกรอกอาชีพ';
      if (f.phone.isEmpty) return 'บังคับกรอกเบอร์โทรศัพท์';
      if (!step1HasAddressText(d.idCardAddress.keyword)) return 'บังคับเลือกที่อยู่';
      if (!step1HasAddressText(d.docAddress.keyword)) return 'บังคับเลือกที่อยู่';
      if (!(f.idCardFlag == 'N' || f.passportFlag == 'N')) return 'กรุณากดตรวจสอบเลขบัตร';
    }
    if (f.email.isNotEmpty && !step1ValidateEmail(f.email)) return 'กรุณากรอกอีเมลให้ถูกต้อง';
    return null;
  }
}
