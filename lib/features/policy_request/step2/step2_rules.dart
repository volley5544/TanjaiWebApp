import '../../../core/utils/ff_functions.dart';
import '../../../router/app_router.dart';
import '../models/request_variant.dart';
import 'step2_data.dart';

/// Product / work-type rules of step 2 (FF InsuranceInfoPage2 + HR21/22/23).
///
/// * [MotorStep2Rules] — sub_product 'Motor', ev_flag ≠ 'Y' (FF validation
///   branch A).
/// * [EvStep2Rules] — 'Motor' + ev_flag 'Y': horsepower instead of cc, EV
///   save fields. FF's EV-only UI on this page (motors, battery change,
///   batteries, Wall Charge) is dead code (`&& false`) and is not ported.
/// * [McStep2Rules] — 'MC': motorcycle title, no driver / accessory / พ.ร.บ.
///   rows, FF validation branch B.
///
/// Not ported: CMI (stand-alone พ.ร.บ.: Act summary card, act-date row,
/// validation branch C, `act_flg '1'`) and House (fire has its own FF
/// page 2) — both fall back to the motor rules; the flow never opens this
/// page for them yet. Manual work type (non-auto): truck / pickup read-only
/// rows, trailer plate, `flg_carrier` / `truck_part` / … save fields and
/// 'ถัดไป' → InsuranceInfoPage31 — only the navigation is wired.
abstract class Step2Rules {
  factory Step2Rules.of(RequestVariant v) => switch (v.product) {
        RequestProduct.ev => EvStep2Rules(v),
        RequestProduct.mc => McStep2Rules(v),
        _ => MotorStep2Rules(v),
      };

  RequestVariant get variant;

  /// AppBar title.
  String get title;

  bool get isEv;

  /// 'ระบุผู้ขับขี่' row, 'อุปกรณ์เสริม' row, 'พ.ร.บ.' row.
  bool get showsDriver;
  bool get showsAccessory;
  bool get showsAct;

  /// 'ผู้รับผลประโยชน์', old-expiry date, insure date, production year rows
  /// (all hidden only for CMI — not ported).
  bool get showsBeneficiary;

  /// Size row label / hint / validation messages.
  String get sizeLabel;
  String get sizeHint;

  /// Validation of 'บันทึกเตรียมข้อมูล' (FF order and messages). Null = OK.
  String? validateSave(Step2Data d, Step2Form f, {required bool branchRequired});

  /// Validation of 'ถัดไป'. Null = OK.
  String? validateNext(Step2Data d, Step2Form f);

  /// FF "write state" before the save call: cleaned controller values into [d].
  void applyForm(Step2Data d, Step2Form f);

  /// `IbsApplicationsSave` step-2 fields (the API adds action / step /
  /// insurance_url / token and the `""` defaults).
  Map<String, dynamic> saveFields(
    Step2Data d, {
    required String quotationId,
    required String leadDtlId,
    required String subProduct,
    required String ownBranchCode,
    required String ownBranchName,
    required bool branchRequired,
  });

  /// Where 'ถัดไป' goes.
  String get nextRoute;
}

class MotorStep2Rules implements Step2Rules {
  MotorStep2Rules(this.variant);

  @override
  final RequestVariant variant;

  static const truck = 'รถบรรทุก หัวลาก หางพ่วง';

  @override
  String get title => '2. ข้อมูลรถยนต์';
  @override
  bool get isEv => false;
  @override
  bool get showsDriver => true;
  @override
  bool get showsAccessory => true;
  @override
  bool get showsAct => true;
  @override
  bool get showsBeneficiary => true;
  @override
  String get sizeLabel => 'cc';
  @override
  String get sizeHint => 'กรุณากรอกขนาด';

  /// Branch, insure date and the five required texts (FF A / B steps 1–6).
  String? validateHead(Step2Data d, Step2Form f, {required bool branchRequired}) {
    if (branchRequired && (d.branchCode.isEmpty || d.branchName.isEmpty)) return 'กรุณาเลือกสาขาที่จะลงผลงาน';
    if (d.effectiveDateInsure.isEmpty) return 'บังคับกรอกวันที่เริ่มคุ้มครองประกัน';
    if (f.plate.isEmpty) return 'บังคับกรอกเลขทะเบียนรถ';
    if (f.chassis.isEmpty) return 'บังคับกรอกเลขตัวถัง';
    if (f.engine.isEmpty) return 'บังคับกรอกเลขเครื่อง';
    if (f.seats.isEmpty) return 'บังคับกรอกจำนวนที่นั่ง';
    return null;
  }

  /// Size check — FF: not required for the truck type; cc must be 0–1 or
  /// 1000–99999 (FF range kept as is).
  String? validateSize(Step2Data d, Step2Form f) {
    if (d.vehicleType == truck) return null;
    if (f.size.isEmpty) return 'บังคับกรอกขนาด';
    final v = double.tryParse(f.size);
    if (v == null) return 'สูบ (cc) ไม่ถูกต้องกรุณากรอกใหม่';
    final ok = (v >= 0 && v <= 1) || (v >= 1000 && v <= 99999);
    return ok ? null : 'สูบ (cc) ไม่ถูกต้องกรุณากรอกใหม่';
  }

  /// Plate length, province, usage, registration year (FF tail of A / B).
  String? validateTail(Step2Data d, Step2Form f, {bool checkProductYear = true}) {
    if (f.plate.length > 10) return 'ทะเบียนรถเกิน 10 ตัว กรุณากรอกใหม่';
    // FF: the default 'กรุณาเลือกปีผลิต' passed this check and was sent as
    // make_year; the port keeps an unset year as '' so it is caught here.
    if (checkProductYear && d.productYear.isEmpty) return 'กรุณาเลือกปีที่ผลิต';
    if (d.provinceName.isEmpty) return 'กรุณาเลือกจังหวัดที่จดทะเบียน';
    if (d.vehicleUsage.isEmpty) return 'กรุณาเลือกลักษณะการใช้รถ';
    if (d.regisYear.isEmpty) return 'กรุณากรอกปีจดทะเบียน';
    return null;
  }

  @override
  String? validateSave(Step2Data d, Step2Form f, {required bool branchRequired}) {
    return validateHead(d, f, branchRequired: branchRequired) ??
        validateSize(d, f) ??
        (f.weight.isEmpty ? 'บังคับกรอกน้ำหนัก' : null) ??
        (d.accessoryProtect.isEmpty ? 'บังคับเลือกอุปกรณ์เสริม' : null) ??
        (d.actOfLegislation.isEmpty ? 'บังคับเลือก พ.ร.บ' : null) ??
        (d.beneficiaryName.isEmpty ? 'บังคับเลือกผู้รับผลประโยชน์' : null) ??
        validateTail(d, f);
  }

  /// Same list for every product (FF: EV also gets 'บังคับกรอกขนาด').
  @override
  String? validateNext(Step2Data d, Step2Form f) {
    if (f.plate.isEmpty) return 'บังคับกรอกเลขทะเบียนรถ';
    if (f.chassis.isEmpty) return 'บังคับกรอกเลขตัวถัง';
    if (f.engine.isEmpty) return 'บังคับกรอกเลขเครื่อง';
    if (f.seats.isEmpty) return 'บังคับกรอกจำนวนที่นั่ง';
    if (f.size.isEmpty) return 'บังคับกรอกขนาด';
    if (f.weight.isEmpty) return 'บังคับกรอกน้ำหนัก';
    if (d.beneficiaryName.isEmpty) return 'บังคับเลือกผู้รับผลประโยชน์';
    return null;
  }

  @override
  void applyForm(Step2Data d, Step2Form f) {
    d
      ..carRegis = removeSpacialLetterFromText(f.plate)
      ..bodyNumber = removeDatAndMakeUpperCase(f.chassis)
      ..engineNumber = removeDatAndMakeUpperCase(f.engine)
      ..carSeat = f.seats
      ..sizeCar = f.size
      ..weightCar = f.weight
      ..oldVmi = f.oldVmi
      ..batteryNumber1 = ''
      // FF: `isEv ? <dead field text> : ''` — the dead fields start with
      // the loaded values, so EV keeps them.
      ..batteryNumber2 = isEv ? d.batteryNumber2 : ''
      ..wallChargerNumber = isEv ? d.wallChargerNumber : ''
      // FF writes the size field into the horsepower state for every product.
      ..horsePower = f.size;
  }

  String accessoryFlg(Step2Data d) => d.accessoryProtect == Step2Data.kAccessoryProtect ? '1' : '0';

  @override
  Map<String, dynamic> saveFields(
    Step2Data d, {
    required String quotationId,
    required String leadDtlId,
    required String subProduct,
    required String ownBranchCode,
    required String ownBranchName,
    required bool branchRequired,
  }) {
    return <String, dynamic>{
      'quotation_id': quotationId,
      'lead_dtl_id': leadDtlId,
      'car_type': d.vehicleType,
      'brand_id': d.brandId,
      'brand_name': d.brandName,
      'model_id': d.modelId,
      'model_name': d.modelName,
      'car_registration': d.carRegis,
      'registration_year': d.regisYear,
      'make_year': d.productYear,
      'vehicle_id': d.vehicleId,
      'vehicle_code': d.vehicleCode,
      'vehicle_name': d.vehicleName,
      'body_number': d.bodyNumber,
      'engine_number': d.engineNumber,
      'seat': d.carSeat,
      'cc': isEv ? '0' : (d.sizeCar.isEmpty ? '0' : d.sizeCar),
      'horsepower': isEv ? (d.horsePower.isEmpty ? '0' : d.horsePower) : '0',
      'weight': d.weightCar,
      'driver_type': d.driverType,
      'accessory_flg': accessoryFlg(d),
      'accessory_total': d.accessoryProtect == Step2Data.kAccessoryProtect ? d.accessory : '',
      'act_flg': d.actOfLegislation == Step2Data.kActIncluded ? '1' : '0',
      'beneficiary_name': d.beneficiaryName,
      'branch_code': branchRequired ? d.branchCode : ownBranchCode,
      'branch_name': branchRequired ? d.branchName : ownBranchName,
      'car_province_name': d.provinceName,
      'registration_province': d.provinceName,
      'car_province_code': d.provinceCode,
      'registration_code': d.provinceCode,
      // Auto work type: flg_carrier, flg_co_org, carrier_*, truck_*,
      // trailer_car_registration, customer_memberchip stay "" (template).
      'customer_type': d.customerType,
      'flg_renew': d.leadFlagRenew ? '1' : '0',
      'old_VMI_expriedDate': d.oldVmiExpDate,
      'old_VMI_policyNumber': d.oldVmi,
      'effective_date_act': d.effectiveDateAct,
      'effective_date_insure': d.effectiveDateInsure,
      'sub_product': subProduct,
      'app_driver': [for (final m in d.drivers) Map<String, String>.from(m)],
      'battery_number': isEv ? d.batteryNumber1 : '',
      'battery_number_2': isEv ? d.batteryNumber2 : '',
      'wall_charger_number': isEv ? d.wallChargerNumber : '',
      // Non-EV: FF sent `{}` (null JSON → empty object) — the template default.
      if (isEv) 'app_battery': [for (final m in d.batteries) Map<String, String>.from(m)],
      'change_battery_flag': d.changeBatteryFlag,
      'car_motor': List<String>.from(d.carMotor),
    };
  }

  @override
  String get nextRoute =>
      variant.isAuto ? AppRoutes.requestDocuments : AppRoutes.notPorted('InsuranceInfoPage31');
}

class EvStep2Rules extends MotorStep2Rules {
  EvStep2Rules(super.variant);

  @override
  bool get isEv => true;
  @override
  String get sizeLabel => 'แรงม้า';
  @override
  String get sizeHint => 'กรุณากรอกแรงม้า';

  /// FF EV: only "a number ≥ 0" (no range); still skipped for the truck type.
  @override
  String? validateSize(Step2Data d, Step2Form f) {
    if (d.vehicleType == MotorStep2Rules.truck) return null;
    if (f.size.isEmpty) return 'บังคับกรอกแรงม้า';
    final v = double.tryParse(f.size);
    if (v == null || v < 0) return 'แรงม้า ไม่ถูกต้องกรุณากรอกใหม่';
    return null;
  }
}

class McStep2Rules extends MotorStep2Rules {
  McStep2Rules(super.variant);

  @override
  String get title => '2. ข้อมูลมอเตอร์ไซค์';
  @override
  bool get showsDriver => false;
  @override
  bool get showsAccessory => false;
  @override
  bool get showsAct => false;

  /// FF branch B: size only required (no number / range check, no truck
  /// exception); no accessory / พ.ร.บ. / production-year checks.
  @override
  String? validateSave(Step2Data d, Step2Form f, {required bool branchRequired}) {
    return validateHead(d, f, branchRequired: branchRequired) ??
        (f.size.isEmpty ? 'บังคับกรอกขนาด' : null) ??
        (f.weight.isEmpty ? 'บังคับกรอกน้ำหนัก' : null) ??
        (d.beneficiaryName.isEmpty ? 'บังคับเลือกผู้รับผลประโยชน์' : null) ??
        validateTail(d, f, checkProductYear: false);
  }

  /// FF: `accessory_flg` is '0' for MC.
  @override
  String accessoryFlg(Step2Data d) => '0';
}

// ---- shared helpers --------------------------------------------------------

/// Current Buddhist-era year. FF hard-coded `currentYearBE = 2569` and never
/// updated it; the port computes it.
int currentYearBE([DateTime? now]) => (now ?? DateTime.now()).year + 543;

/// 'เลือกปีจดทะเบียน' list: BE years 2500…now, newest first.
List<String> regisYearItems([DateTime? now]) => reverseList(ganerateYearList(2500, currentYearBE(now)));

/// 'เลือกปีที่ผลิต' list: CE years 1957…now, newest first.
List<String> productYearItems([DateTime? now]) => reverseList(ganerateYearList(1957, currentYearBE(now) - 543));

/// FF `checkDateBeforeAnotherDate(days, picked)`: picked ≤ now + days. A
/// missing config ([days] null) puts no limit (FF threw on `days!`).
bool isWithinEffectiveDays(DateTime picked, int? days, [DateTime? now]) {
  if (days == null) return true;
  return !picked.isAfter((now ?? DateTime.now()).add(Duration(days: days)));
}

/// FF `removeDotInString` (`double.parse(x).toStringAsFixed(0)`): '1497.00'
/// → '1497'. Non-numeric text is returned as is (FF crashed).
String removeDotInString(String input) {
  final v = double.tryParse(input);
  return v == null ? input : v.toStringAsFixed(0);
}

/// `showDateBE` that tolerates bad dates (FF crashed): returns [input].
String showDateBESafe(String input) {
  if (DateTime.tryParse(input) == null) return input;
  return showDateBE(input);
}

/// Registration year shown as BE (FF `int.parse(year) + 543`; crashed on
/// 'null' / bad data — the raw text is shown instead).
String regisYearText(String ce) {
  final y = int.tryParse(ce.trim());
  return y == null ? ce : '${y + 543}';
}

/// The vehicle-type image (FF lines 1505–1550). 'กระบะต่อเติมไม่เกินหัวเก๋ง'
/// had no URL in FF (duplicate 'เกินหัวเก๋ง' branch) → a broken image at 130 px;
/// kept: no URL → the error image at that width.
({String url, double width}) carTypeImage(String carTypeDetail) {
  const base = 'https://firebasestorage.googleapis.com/v0/b/sawad-new-ibs.appspot.com/o/carTypeImage%2F';
  return switch (carTypeDetail) {
    'รถเก๋ง' => (
        url: '$base%E0%B8%A3%E0%B8%96%E0%B9%80%E0%B8%81%E0%B9%8B%E0%B8%87.png?alt=media&token=68ef0a76-99d9-4c43-ae86-b48970b7fb09',
        width: 90.0
      ),
    'รถตู้' => (
        url: '$base%E0%B8%A3%E0%B8%96%E0%B8%95%E0%B8%B9%E0%B9%89.png?alt=media&token=8969fa4a-52e0-4b0c-9c44-f349976bc624',
        width: 90.0
      ),
    'รถกระบะ 2 ประตู' => (
        url:
            '$base%E0%B8%81%E0%B8%B0%E0%B8%9A%E0%B8%B0%20%E0%B8%95%E0%B8%AD%E0%B8%99%E0%B9%80%E0%B8%94%E0%B8%B5%E0%B8%A2%E0%B8%A7%20(%E0%B8%A3%E0%B8%A7%E0%B8%A1).png?alt=media&token=bd62e47d-dd92-41ca-8f51-3632edfd54a6',
        width: 90.0
      ),
    'รถกระบะ 4 ประตู' => (
        url:
            '$base%E0%B8%81%E0%B8%B0%E0%B8%9A%E0%B8%B0%204%20%E0%B8%9B%E0%B8%A3%E0%B8%B0%E0%B8%95%E0%B8%B9.png?alt=media&token=45bc2e60-3a29-47dc-aa4d-e9c82a113bbc',
        width: 90.0
      ),
    'รถบรรทุก หัวลาก หางพ่วง' => (
        url:
            '$base%E0%B8%AB%E0%B8%B1%E0%B8%A7%E0%B8%A5%E0%B8%B2%E0%B8%81%20%E0%B8%AB%E0%B8%B2%E0%B8%87%E0%B8%9E%E0%B9%88%E0%B8%A7%E0%B8%87.png?alt=media&token=1d749f04-0765-422a-b0b7-34a3d5d60519',
        width: 130.0
      ),
    'รถแต่ง ต่อคอก' => (
        url:
            '$base%E0%B8%A3%E0%B8%96%E0%B9%81%E0%B8%95%E0%B9%88%E0%B8%87%E0%B8%95%E0%B9%88%E0%B8%AD%E0%B8%84%E0%B8%AD%E0%B8%81.png?alt=media&token=80501c24-fec4-4c34-ac0f-361db3b698b3',
        width: 90.0
      ),
    'กระบะไม่ต่อเติม' => (
        url:
            '$base%E0%B8%81%E0%B8%B0%E0%B8%9A%E0%B8%B0%202%20%E0%B8%9B%E0%B8%A3%E0%B8%B0%E0%B8%95%E0%B8%B9%E0%B9%84%E0%B8%A1%E0%B9%88%E0%B8%95%E0%B9%88%E0%B8%AD%E0%B9%80%E0%B8%95%E0%B8%B4%E0%B8%A1.png?alt=media&token=ca1d014f-d1aa-4f27-bd54-3d97d5efba3f',
        width: 100.0
      ),
    'กระบะต่อเติมเกินหัวเก๋ง' => (
        url:
            '$base%E0%B8%81%E0%B8%A3%E0%B8%B0%E0%B8%9A%E0%B8%B0%E0%B8%95%E0%B9%88%E0%B8%AD%E0%B9%80%E0%B8%95%E0%B8%B4%E0%B8%A1%E0%B9%80%E0%B8%81%E0%B8%B4%E0%B8%99%E0%B8%AB%E0%B8%B1%E0%B8%A7%E0%B9%80%E0%B8%81%E0%B9%8B%E0%B8%87.png?alt=media&token=957c9ae1-6d8a-41d5-b7aa-23965926a562',
        width: 130.0
      ),
    'กระบะต่อเติมไม่เกินหัวเก๋ง' => (url: '-', width: 130.0),
    'กระบะตู้ทึบ/ตู้แห้ง' => (
        url:
            '${base}2_%E0%B8%81%E0%B8%A3%E0%B8%B0%E0%B8%9A%E0%B8%B0%E0%B8%95%E0%B8%B9%E0%B9%89%E0%B8%97%E0%B8%B6%E0%B8%9A_%E0%B8%95%E0%B8%B9%E0%B9%89%E0%B9%81%E0%B8%AB%E0%B9%89%E0%B8%87.png?alt=media&token=71715c79-6196-4a63-9a9e-c179033218ea',
        width: 100.0
      ),
    _ => (url: '-', width: 0.0),
  };
}

/// Firestore `effectiveDayConfig` (first doc) → `effective_days_insure` /
/// `effective_days_act`. Null doc / field = no limit (see [isWithinEffectiveDays]).
({int? insure, int? act}) effectiveDaysFrom(Map<String, dynamic>? doc) {
  int? n(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
  return (insure: n(doc?['effective_days_insure']), act: n(doc?['effective_days_act']));
}
