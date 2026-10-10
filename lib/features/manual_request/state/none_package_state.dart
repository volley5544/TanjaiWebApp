import 'package:flutter/foundation.dart';

import '../../../core/utils/ff_functions.dart';
import '../../search_package/models/brand.dart';
import '../../search_package/models/car_model.dart';
import '../../search_package/models/cover_type.dart';
import '../../search_package/models/province.dart';
import '../../search_package/models/vehicle_usage.dart';
import '../models/lead_detail.dart';

/// Placeholder texts the FF flow kept *inside* the state values (a value still
/// containing 'กรุณา' / 'เลือก' means "not chosen yet"). Kept as-is because the
/// pages show them and the submit strips them the same way FF did.
abstract final class NpPlaceholders {
  static const vehicleType = 'กรุณาเลือกประเภทรถ';
  static const brandName = 'กรุณาเลือกยี่ห้อรถ';
  static const modelName = 'กรุณากรอกรุ่นรถ';
  static const year = 'กรุณาเลือกปีจดทะเบียน';
  static const usedTypeName = 'กรุณาเลือกลักษณะการใช้รถ';
  static const cusFullname = 'กรุณากรอกชื่อ';
  static const cusPhone = 'กรุณากรอกเบอร์โทรศัพท์';
  static const province = 'กรุณาเลือกจังหวัดจดทะเบียน';
  static const sumInsured = 'กรุณากรอกทุนประกัน';
  static const carrierType = 'กรุณาเลือกประเภทตู้เหล็ก';
  static const truckPart = 'กรุณาเลือกส่วนของรถบรรทุก';
  static const cusMembership = 'กรุณาเลือกประเภทลูกค้า';
  static const truckCurrentPrice = 'กรุณากรอกราคาซื้อขายปัจจุบัน';
  static const plateAdditional = 'กรุณากรอกเลขทะเบียนหางพ่วง';
  static const truckCarryPurpose = 'กรุณากรอกรถใช้บรรทุกอะไร';
  static const trailerSumInsured = 'กรุณากรอกทุนประกันหางพ่วง';
  static const coverTypeName = 'กรุณาเลือกประเภทชั้นประกัน';
  static const garageTypeName = 'กรุณาเลือกประเภทการซ่อม';
  static const oldVmiExpDate = 'กรุณาเลือกวันที่หมดอายุประกันเดิม';
}

/// FF `containWordinStringUrl('กรุณา', x)` — "still a placeholder".
bool isPh(String v) => v.contains('กรุณา');

/// FF `ph(x)` on submit: placeholder → ''.
String noPh(String v) => isPh(v) ? '' : v;

const truck = 'รถบรรทุก หัวลาก หางพ่วง';
const truckWithTrailer = 'หัวลาก + หางพ่วง';
const pickup = 'รถกระบะ';

/// The 17 vehicle photo slots (9 car + 8 trailer) of the create / edit flows.
enum CarSlot {
  front, rightFront, right, rightRear, rear, leftRear, left, leftFront, roof,
  trailerFront, trailerRightFront, trailerRight, trailerRightRear, trailerRear,
  trailerLeftRear, trailerLeft, trailerLeftFront;

  bool get isTrailer => index >= 9;

  /// API form field (`image_front`, …, `image_front_trailer`, …).
  String get field => const [
        'image_front', 'image_rightfront', 'image_right', 'image_rightrear', 'image_rear',
        'image_leftrear', 'image_left', 'image_leftfront', 'image_roof',
        'image_front_trailer', 'image_rightfront_trailer', 'image_right_trailer',
        'image_rightrear_trailer', 'image_rear_trailer', 'image_leftrear_trailer',
        'image_left_trailer', 'image_leftfront_trailer',
      ][index];

  static const car = [front, rightFront, right, rightRear, rear, leftRear, left, leftFront, roof];
  static const trailer = [
    trailerFront, trailerRightFront, trailerRight, trailerRightRear,
    trailerRear, trailerLeftRear, trailerLeft, trailerLeftFront,
  ];
}

/// One insurer of `get_insurers_all`.
class NpInsurer {
  const NpInsurer({
    required this.id,
    required this.code,
    required this.shortName,
    required this.fullName,
    required this.listName,
  });

  final String id;
  final String code;
  final String shortName;
  final String fullName;
  final String listName;
}

/// State of the manual ("none-package", งานนอกเรท / ต่ออายุ / โอนโค้ด)
/// request flows — replaces the ~150 FF `nonePackage*` app-state fields the
/// create and edit pages shared. Never put in the URL; a page opened without
/// an active flow goes back to its entry.
class NonePackageState extends ChangeNotifier {
  NonePackageState._();

  static final NonePackageState instance = NonePackageState._();

  /// A create flow was started (entry pages set it).
  bool active = false;

  /// An edit flow was loaded from get-lead-detail.
  bool editActive = false;

  // ── Request kind ─────────────────────────────────────────────────────────
  /// Route param `workType`: 'manual' | 'ev' | 'renew' | 'transfer'.
  String workType = 'manual';

  /// FF `fromMenuAppState` — master-data `vehicle_group` / `car_type`
  /// ('motor' / 'EV').
  String fromMenu = 'motor';
  bool flagRenew = false;

  /// FF `nonePackageReason` (3 reasons, single choice).
  List<bool> reason = [false, false, false];
  bool buttonOrdinary = false;
  bool buttonCorporation = false;

  // ── Vehicle ──────────────────────────────────────────────────────────────
  String vehicleType = NpPlaceholders.vehicleType;
  String vehicleTypeDetail = ''; // FF nonepackagevehicletypeDetail
  String vehicleGroup = ''; // FF insuranceBasicVehicleGroup
  String carTypeContain = '';
  String carTypeDoors = '';
  String brandName = NpPlaceholders.brandName;
  String brandId = '';
  String modelName = NpPlaceholders.modelName;
  String modelCode = '';
  List<CarModel> searchModels = []; // FF nonePackageSearchModel(Id)List
  String year = NpPlaceholders.year; // BE
  String yearChrist = '';
  String usedTypeId = '';
  String usedTypeCode = '';
  String usedTypeName = NpPlaceholders.usedTypeName;
  String coverTypeId = '';
  String coverTypeCode = '';
  String coverTypeName = NpPlaceholders.coverTypeName;
  String garageTypeId = '';
  String garageTypeCode = '';
  String garageTypeName = NpPlaceholders.garageTypeName;

  // Truck / pick-up extras.
  String truckPart = NpPlaceholders.truckPart;
  String cusMembership = NpPlaceholders.cusMembership;
  String truckCurrentPrice = NpPlaceholders.truckCurrentPrice;
  String truckCarryPurpose = NpPlaceholders.truckCarryPurpose;
  String plateAdditional = NpPlaceholders.plateAdditional;
  String trailerSumInsured = NpPlaceholders.trailerSumInsured;
  bool flagCarrier = false;
  bool flagCoop = false;
  String carrierType = NpPlaceholders.carrierType;
  String carrierPrice = '';

  // ── Customer / policy ────────────────────────────────────────────────────
  String cusFullname = NpPlaceholders.cusFullname;
  String cusPhone = NpPlaceholders.cusPhone;
  String plate = '';
  String province = NpPlaceholders.province;
  String provinceId = '';
  String sumInsured = NpPlaceholders.sumInsured;
  String remark = '';
  bool flagAct = true;
  String oldVmi = '';
  String oldVmiExpDate = NpPlaceholders.oldVmiExpDate;
  String branchCode = '';
  String branchName = '';

  // ── Master data (loaded by the basic page) ───────────────────────────────
  List<Province> provinces = [];
  List<VehicleUsage> usages = [];
  List<Brand> brandsOriginal = [];
  List<Brand> brands = [];
  List<CarModel> modelsOriginal = [];
  List<CoverType> coverTypes = [];

  // ── Photos (download URLs) ───────────────────────────────────────────────
  final Map<CarSlot, String> carPhotos = {};
  String blueBookUrl = '';
  String idCardUrl = '';
  String oldVmiImageUrl = '';
  String companyBookUrl = '';
  List<String> otherPhotos = List.filled(5, '');

  // ── Insurers ─────────────────────────────────────────────────────────────
  List<NpInsurer> insurers = [];
  List<bool> insurerSelected = [];

  /// FF `nonePackageInsurerShortNameDupList` — pre-selected on the insurer
  /// page (set by "คัดลอก").
  List<String> insurerShortNameDup = [];

  // ── Copy ('คัดลอก') initial texts for the basic page ─────────────────────
  Map<String, String> copyTexts = {};

  // ── Edit flow ────────────────────────────────────────────────────────────
  LeadDetail? lead;
  bool editEvFlag = false;
  bool oldVmiFlag = false;
  String customerType = '';
  int insurerIndex = 0; // FF nonePackageInsurerOutputIndex
  String insurerDisplayOutput = '';

  String carPhoto(CarSlot s) => carPhotos[s] ?? '';

  bool get isTruck => vehicleType == truck;
  bool get hasTrailer => isTruck && truckPart == truckWithTrailer;

  /// FF RESET_NP + CLEAR_UPLOADED (+ the never-reset fields, reset here so
  /// they can't leak into the next request).
  void reset() {
    active = false;
    editActive = false;
    workType = 'manual';
    fromMenu = 'motor';
    flagRenew = false;
    reason = [false, false, false];
    buttonOrdinary = false;
    buttonCorporation = false;
    vehicleType = NpPlaceholders.vehicleType;
    vehicleTypeDetail = '';
    vehicleGroup = '';
    carTypeContain = '';
    carTypeDoors = '';
    brandName = NpPlaceholders.brandName;
    brandId = '';
    modelName = NpPlaceholders.modelName;
    modelCode = '';
    searchModels = [];
    year = NpPlaceholders.year;
    yearChrist = '';
    usedTypeId = '';
    usedTypeCode = '';
    usedTypeName = NpPlaceholders.usedTypeName;
    coverTypeId = '';
    coverTypeCode = '';
    coverTypeName = NpPlaceholders.coverTypeName;
    garageTypeId = '';
    garageTypeCode = '';
    garageTypeName = NpPlaceholders.garageTypeName;
    truckPart = NpPlaceholders.truckPart;
    cusMembership = NpPlaceholders.cusMembership;
    truckCurrentPrice = NpPlaceholders.truckCurrentPrice;
    truckCarryPurpose = NpPlaceholders.truckCarryPurpose;
    plateAdditional = NpPlaceholders.plateAdditional;
    trailerSumInsured = NpPlaceholders.trailerSumInsured;
    flagCarrier = false;
    flagCoop = false;
    carrierType = NpPlaceholders.carrierType;
    carrierPrice = '';
    cusFullname = NpPlaceholders.cusFullname;
    cusPhone = NpPlaceholders.cusPhone;
    plate = '';
    province = NpPlaceholders.province;
    provinceId = '';
    sumInsured = NpPlaceholders.sumInsured;
    remark = '';
    flagAct = true;
    oldVmi = '';
    oldVmiExpDate = NpPlaceholders.oldVmiExpDate;
    branchCode = '';
    branchName = '';
    carPhotos.clear();
    blueBookUrl = '';
    idCardUrl = '';
    oldVmiImageUrl = '';
    companyBookUrl = '';
    otherPhotos = List.filled(5, '');
    insurers = [];
    insurerSelected = [];
    insurerShortNameDup = [];
    copyTexts = {};
    lead = null;
    editEvFlag = false;
    oldVmiFlag = false;
    customerType = '';
    insurerIndex = 0;
    insurerDisplayOutput = '';
  }

  /// FF `searchPackageCheckFilled`-driven prefill used by the 'นอกเรท'
  /// buttons. [gated] = work-select page (copy only filled fields); the result
  /// pages copy everything.
  void startNew({
    required String workType,
    required String fromMenu,
    required bool gated,
    required List<bool> checkFilled,
    required String vehicleTypeLabel,
    required Brand? brand,
    required CarModel? model,
    required List<CarModel> brandModels,
    required String? yearBE,
    required VehicleUsage? usage,
    required DateTime? oldPolicyExpiry,
    required String vehicleGroup,
    required String carTypeContain,
    required String carTypeDoors,
  }) {
    reset();
    active = true;
    this.workType = workType;
    this.fromMenu = fromMenu;
    bool on(int i) => !gated || checkFilled[i];
    if (on(0)) vehicleType = vehicleTypeLabel;
    if (on(1) && brand != null) {
      brandName = brand.name;
      brandId = brand.id;
      searchModels = brandModels;
    }
    if (on(2) && model != null) {
      modelName = model.name;
      modelCode = model.code;
    }
    if (on(3) && yearBE != null) {
      year = yearBE;
      yearChrist = '${(int.tryParse(yearBE) ?? 543) - 543}';
    }
    if (on(4) && usage != null) {
      usedTypeId = usage.id;
      usedTypeCode = usage.code;
      usedTypeName = usage.name;
    }
    this.vehicleGroup = vehicleGroup;
    this.carTypeContain = carTypeContain;
    this.carTypeDoors = carTypeDoors;
    // FF `nonePackageOldVmiExpDate = insuranceBasicOldVmiExpDate` ('' when unset).
    oldVmiExpDate = oldPolicyExpiry == null ? '' : getDateFormat(oldPolicyExpiry);
    notifyListeners();
  }

  /// 'คัดลอก' on the quotation list (spec basic_page §7.6).
  void startCopy(LeadDetail d) {
    reset();
    active = true;
    String dash(String v, String ph) => v == '-' ? ph : v;
    flagCarrier = d.flgCarrier == '1';
    vehicleType = dash(d.carType, NpPlaceholders.vehicleType);
    vehicleTypeDetail = d.carType == '-' ? '' : d.carType;
    brandName = dash(d.carBrandName, '');
    brandId = dash(d.carBrandId, '');
    modelName = dash(d.carModelName, '');
    modelCode = dash(d.carModelId, '');
    final y = int.tryParse(d.carRegistrationYear);
    year = y == null ? NpPlaceholders.year : '${y + 543}';
    yearChrist = y == null ? '' : '$y';
    usedTypeId = dash(d.vehicleId, '');
    usedTypeCode = dash(d.vehicleCode, '');
    usedTypeName = dash(d.vehicleName, NpPlaceholders.usedTypeName);
    cusFullname = dash(d.firstName, ''); // FF copied the first name only
    cusPhone = dash(d.phoneNumber, '');
    plate = dash(d.carRegistration, '');
    province = dash(d.carProvinceName, NpPlaceholders.province);
    provinceId = dash(d.carProvinceCode, '');
    sumInsured = dash(d.sumInsured, '');
    flagAct = d.flgAct == '1';
    carrierType = dash(d.carrierType, NpPlaceholders.carrierType);
    flagCoop = d.flgCoOrg == '1';
    truckPart = dash(d.truckPart, NpPlaceholders.truckPart);
    cusMembership = dash(d.customerMemberchip, NpPlaceholders.cusMembership);
    truckCurrentPrice = dash(d.truckCurrentPrice, '');
    plateAdditional = dash(d.trailerCarRegistration, '');
    truckCarryPurpose = dash(d.carrierPropose, '');
    trailerSumInsured = dash(d.trailerSumInsured, '');
    carrierPrice = dash(d.carrierPrice, '');
    final first = d.details.isEmpty ? null : d.details.first;
    coverTypeId = dash(first?.coverTypeId ?? '-', '');
    coverTypeCode = dash(first?.coverTypeCode ?? '-', '');
    coverTypeName = dash(first?.coverTypeName ?? '-', NpPlaceholders.coverTypeName);
    garageTypeId = dash(first?.garageTypeId ?? '-', '');
    garageTypeName = dash(first?.garageTypeName ?? '-', NpPlaceholders.garageTypeName);
    garageTypeCode = dash(first?.garageTypeCode ?? '-', '');
    flagRenew = d.flgRenew == '1';
    oldVmiExpDate = dash(d.oldVmiExpiredDate, NpPlaceholders.oldVmiExpDate);
    oldVmi = dash(d.oldVmiPolicyNumber, '');
    branchCode = dash(d.branchCode, '');
    branchName = dash(d.branchName, '');
    remark = dash(d.remark, '');
    insurerShortNameDup = [for (final x in d.details) x.insurerShortName];
    reason = [false, false, false];
    reason[d.reason == 'ไม่มีในเรท' ? 0 : (d.reason == 'ไม่พอใจในทุนประกัน' ? 1 : 2)] = true;
    buttonOrdinary = d.customerType == 'บุคคลธรรมดา';
    buttonCorporation = d.customerType == 'นิติบุคคล';
    fromMenu = d.evFlag == 'Y' ? 'EV' : 'motor';
    workType = d.evFlag == 'Y' ? 'ev' : 'manual';
    // FF passed these as the basic page's text-field params.
    copyTexts = {
      'carryPurpose': truckCarryPurpose,
      'currentPrice': truckCurrentPrice,
      'carrierPrice': carrierPrice,
      'cusName': cusFullname,
      'cusPhone': cusPhone,
      'plate': plate,
      'plateAdditional': plateAdditional,
      'sumInsured': sumInsured,
      'trailerSumInsured': trailerSumInsured,
      'remark': remark,
    };
    notifyListeners();
  }

  /// 'แก้ไข' on the quotation list (spec edit_pages §1.3).
  void startEdit(LeadDetail d) {
    reset();
    editActive = true;
    lead = d;
    editEvFlag = d.evFlag == 'Y';
    flagCarrier = d.flgCarrier == '1';
    vehicleType = d.carType;
    brandName = d.carBrandName;
    modelName = d.carModelName;
    year = d.carRegistrationYear; // Christian year in the edit flow (FF)
    usedTypeId = d.vehicleId;
    usedTypeCode = d.vehicleCode;
    usedTypeName = d.vehicleName;
    cusFullname = '${d.rawFirstName} ${d.rawLastName}' == 'null null'
        ? '-'
        : checkNullValueAndReturn('${d.rawFirstName} ${d.rawLastName}');
    cusPhone = d.phoneNumber;
    plate = d.carRegistration;
    province = d.carProvinceName;
    sumInsured = d.sumInsured;
    flagAct = d.flgAct == '1';
    carrierType = d.carrierType;
    flagCoop = d.flgCoOrg == '1';
    truckPart = d.truckPart;
    cusMembership = d.customerMemberchip;
    truckCurrentPrice = d.truckCurrentPrice;
    plateAdditional = d.trailerCarRegistration;
    truckCarryPurpose = d.carrierPropose;
    trailerSumInsured = d.trailerSumInsured;
    carrierPrice = d.carrierPrice;
    coverTypeName = d.details.isEmpty ? '-' : d.details.first.coverTypeName;
    garageTypeName = d.details.isEmpty ? '-' : d.details.first.garageTypeName;
    flagRenew = d.flgRenew == '1';
    oldVmiExpDate = d.oldVmiExpiredDate;
    oldVmi = d.oldVmiPolicyNumber;
    customerType = d.customerType;
    buttonOrdinary = customerType == 'บุคคลธรรมดา';
    buttonCorporation = customerType != 'บุคคลธรรมดา'; // FF: '-' counts as corporate
    remark = d.remark;
    // FF stored '${branch_code}' without the null check ('null' possible).
    branchCode = d.rawBranchCode;
    branchName = d.rawBranchName;
    oldVmiFlag = d.oldVmiFlg == '1';
    insurerSelected = List.filled(d.details.length, false);
    notifyListeners();
  }

  void notify() => notifyListeners();
}
