import '../../../core/utils/ff_functions.dart';
import '../models/application_detail.dart';

/// Step 2 (vehicle: plate, chassis, engine, seats, cc, branch, effective
/// dates, accessories, พ.ร.บ., beneficiary) — the FF `insuranceInfo*` /
/// `nonePackage*` FFAppState fields page 2 and its sub-pages (HR21 / 22 / 23)
/// read and write.
///
/// Owned by `step2/`. Filled from the application detail by [loadFromDetail]
/// (called by `PolicyRequestState.applyDetail`, spec page1 §3.3); edited by
/// the step's pages. Values that FF read with `'${x}'` (null → `'null'`) are
/// read null-safe here (null → `''`): the `'null'` text only caused bugs on
/// page 2 (`int.parse('null')` on the registration year, 'null' sent back as
/// `make_year`, …).
class Step2Data {
  // ---- vehicle (leads[0] / data) -------------------------------------------

  /// FF insuranceInfoVehicleType (`leads[0].car_type`).
  String vehicleType = '';

  /// FF insuranceInfoCarTypeDetail (`leads[0].car_type_detail`) — picks the image.
  String carTypeDetail = '';
  String brandName = '';
  String brandId = '';
  String modelName = '';

  /// FF `insuarnceInfoModelId` (sic).
  String modelId = '';

  /// FF insuranceInfoCarRegis.
  String carRegis = '';
  String bodyNumber = '';
  String engineNumber = '';
  String carSeat = '';

  /// FF insuranceInfoSizeCar (cc).
  String sizeCar = '';

  /// FF insuranceInfoHorsePower (EV).
  String horsePower = '';
  String weightCar = '';

  /// FF insuranceInfoRegisYear — registration year, **CE** (shown +543).
  String regisYear = '';

  /// FF insuranceInfoProductYear — production year, CE.
  String productYear = '';

  /// FF insuranceInfoRegistrationCodeSelect / …ProvinceSelect.
  String provinceCode = '';
  String provinceName = '';

  /// FF insuranceInfoVehicleUsage (`'<vehicle_code> <vehicle_name>'`).
  String vehicleUsage = '';
  String vehicleId = '';
  String vehicleCode = '';
  String vehicleName = '';

  // ---- choices -------------------------------------------------------------

  /// FF insuranceInfoAccessory (`leads_detail[LD].accessory_total`).
  String accessory = '';

  /// FF insuranceInfoAccessoryProtect: [kAccessoryProtect] / [kAccessoryNoProtect] / ''.
  String accessoryProtect = '';

  /// FF insuranceInfoActOflLegislation: [kActIncluded] / [kActExcluded] / ''.
  String actOfLegislation = '';
  String beneficiaryName = '';

  /// FF insuranceInfoPage2DriverType ('1' = named drivers).
  String driverType = '';

  /// FF DriverList (`app_driver[]`, the driver struct's keys as strings).
  List<Map<String, String>> drivers = [];

  // ---- dates / branch / renew ----------------------------------------------

  /// yyyy-MM-dd (FF insuranceInfoEffectiveDateInsure / …Act).
  String effectiveDateInsure = '';
  String effectiveDateAct = '';

  /// FF insuranceInfoBranchCode / insuranceInfoBranchNameOutput (the branch
  /// the work is credited to; `app_detail[0].branch_code / _name`).
  String branchCode = '';
  String branchName = '';

  /// FF flagRenew (`app_detail[0].flg_renew` || `leads[0].flg_renew`).
  String flagRenew = '';

  /// FF nonePackageFlagRenew (`leads[0].flg_renew == '1'`).
  bool leadFlagRenew = false;

  /// FF nonePackageOldVmi / nonePackageOldVmiExpDate (yyyy-MM-dd or '').
  String oldVmi = '';
  String oldVmiExpDate = '';

  /// FF nonePackageCustomerType.
  String customerType = '';

  /// FF nonePackageWorkType (`app_detail[0].work_type`).
  String workType = '';

  // ---- EV (no live UI on page 2 — FF `&& false`; sent back unchanged) ------

  String evFlag = '';
  List<String> carMotor = [];
  String changeBatteryFlag = '';
  String batteryNumber1 = '';
  String batteryNumber2 = '';
  String wallChargerNumber = '';

  /// FF EvBatteryData (`app_battery[]`, the battery struct's keys as strings).
  List<Map<String, String>> batteries = [];

  /// FF insuranceInfoPage2SaveDataCheckBool — shows 'ถัดไป'. Not touched by
  /// [loadFromDetail] (the detail is reloaded right after a save).
  bool saved = false;

  static const kAccessoryProtect = 'คุ้มครองอุปกรณ์เสริม';
  static const kAccessoryNoProtect = 'ไม่คุ้มครองอุปกรณ์เสริม';
  static const kActIncluded = 'ราคารวม พ.ร.บ';
  static const kActExcluded = 'ราคาไม่รวม พ.ร.บ';

  /// FF DriverDataStruct.toMap keys.
  static const driverKeys = [
    'driver_id', 'driver_no', 'application_id', 'id_type_id', 'national_thai_id', 'license_no', 'gender',
    'title_th_id', 'title_th', 'first_name_th', 'last_name_th', 'birth_day', 'image_idcard', 'image_license_no',
    'occupation_id', 'occupation_code', 'occupation_name', 'occupation_subcode', 'occupation_subname',
    'driver_behavior', 'email1', 'mobile1', 'driver_consent', 'license_expiredate', 'license_is_life_long',
    'image_behavior',
  ];

  /// FF BatteryDataModelStruct.toMap keys.
  static const batteryKeys = [
    'battery_id', 'application_id', 'battery_no', 'battery_number', 'battery_year', 'battery_purchase_date',
    'battery_price', 'battery_rep_sum_insured',
  ];

  void reset() {
    vehicleType = carTypeDetail = brandName = brandId = modelName = modelId = '';
    carRegis = bodyNumber = engineNumber = carSeat = sizeCar = horsePower = weightCar = '';
    regisYear = productYear = provinceCode = provinceName = '';
    vehicleUsage = vehicleId = vehicleCode = vehicleName = '';
    accessory = accessoryProtect = actOfLegislation = beneficiaryName = driverType = '';
    drivers = [];
    effectiveDateInsure = effectiveDateAct = branchCode = branchName = flagRenew = '';
    leadFlagRenew = false;
    oldVmi = oldVmiExpDate = customerType = workType = '';
    evFlag = changeBatteryFlag = batteryNumber1 = batteryNumber2 = wallChargerNumber = '';
    carMotor = [];
    batteries = [];
    saved = false;
  }

  /// FF step 1 load (spec page1 §3.3 "Vehicle", "Dates/renew", "Branch", "EV",
  /// premium choices). Not the House branch (fire — not ported).
  void loadFromDetail(ApplicationDetail d) {
    final lead = d.lead;
    final app = d.appDetail;
    final ld = d.leadDetail;
    String l(String k) => ApplicationDetail.sOf(lead, k);
    String a(String k) => ApplicationDetail.sOf(app, k);
    String or(String v, String fallback) => v.isNotEmpty ? v : fallback;

    vehicleType = l('car_type');
    carTypeDetail = l('car_type_detail');
    brandName = l('car_brand_name');
    brandId = l('car_brand_id');
    modelName = l('car_model_name');
    modelId = l('car_model_id');
    carRegis = or(d.s('car_registration'), l('car_registration'));
    bodyNumber = d.s('body_number');
    engineNumber = d.s('engine_number');
    carSeat = or(a('seat'), d.s('seat'));
    sizeCar = or(d.s('cc'), ApplicationDetail.sOf(ld, 'cc'));
    horsePower = d.s('horsepower');
    weightCar = d.s('weight');
    regisYear = l('car_registration_year');
    productYear = d.s('make_year');
    provinceCode = or(d.s('registration_code'), l('car_province_code'));
    provinceName = or(d.s('registration_province'), l('car_province_name'));
    vehicleId = l('vehicle_id');
    vehicleCode = l('vehicle_code');
    vehicleName = l('vehicle_name');
    // FF `'${code} ${name}'` (always non-empty: ' ' when both are missing —
    // the port trims so an empty usage fails the 'ลักษณะการใช้รถ' check).
    vehicleUsage = '$vehicleCode $vehicleName'.trim();

    accessory = ApplicationDetail.sOf(ld, 'accessory_total');
    accessoryProtect = switch (d.s('accessory_flg')) {
      '1' => kAccessoryProtect,
      '0' => kAccessoryNoProtect,
      _ => '',
    };
    actOfLegislation = switch (d.s('act_flg')) {
      '1' => kActIncluded,
      '0' => kActExcluded,
      _ => '',
    };
    beneficiaryName = d.s('beneficiary_name');
    driverType = or(d.s('driver_type'), l('driver_type'));
    final appDrivers = _maps(d.at('app_driver'), driverKeys);
    drivers = appDrivers.isNotEmpty ? appDrivers : [emptyDriver()];

    effectiveDateInsure = a('effective_date_insure');
    effectiveDateAct = a('effective_date_act');
    branchCode = a('branch_code');
    branchName = a('branch_name');
    flagRenew = or(a('flg_renew'), l('flg_renew'));
    leadFlagRenew = l('flg_renew') == '1';
    oldVmi = l('old_VMI_policyNumber');
    oldVmiExpDate = l('old_VMI_expriedDate');
    customerType = l('customer_type');
    workType = a('work_type');

    evFlag = d.evFlag;
    final motors = d.at('car_motor');
    carMotor = evFlag == 'Y' && motors is List ? [for (final m in motors) if (m != null) '$m'] : [];
    changeBatteryFlag = d.s('change_battery_flag');
    batteryNumber1 = d.s('battery_number');
    batteryNumber2 = d.s('battery_number_2');
    wallChargerNumber = d.s('wall_charger_number');
    final appBatteries = _maps(d.at('app_battery'), batteryKeys);
    batteries = appBatteries.isNotEmpty ? appBatteries : [emptyBattery()];
  }

  /// Copies every field of [o] (used to keep the page's values across the
  /// detail reload after a save).
  void copyFrom(Step2Data o) {
    vehicleType = o.vehicleType;
    carTypeDetail = o.carTypeDetail;
    brandName = o.brandName;
    brandId = o.brandId;
    modelName = o.modelName;
    modelId = o.modelId;
    carRegis = o.carRegis;
    bodyNumber = o.bodyNumber;
    engineNumber = o.engineNumber;
    carSeat = o.carSeat;
    sizeCar = o.sizeCar;
    horsePower = o.horsePower;
    weightCar = o.weightCar;
    regisYear = o.regisYear;
    productYear = o.productYear;
    provinceCode = o.provinceCode;
    provinceName = o.provinceName;
    vehicleUsage = o.vehicleUsage;
    vehicleId = o.vehicleId;
    vehicleCode = o.vehicleCode;
    vehicleName = o.vehicleName;
    accessory = o.accessory;
    accessoryProtect = o.accessoryProtect;
    actOfLegislation = o.actOfLegislation;
    beneficiaryName = o.beneficiaryName;
    driverType = o.driverType;
    drivers = [for (final m in o.drivers) Map<String, String>.from(m)];
    effectiveDateInsure = o.effectiveDateInsure;
    effectiveDateAct = o.effectiveDateAct;
    branchCode = o.branchCode;
    branchName = o.branchName;
    flagRenew = o.flagRenew;
    leadFlagRenew = o.leadFlagRenew;
    oldVmi = o.oldVmi;
    oldVmiExpDate = o.oldVmiExpDate;
    customerType = o.customerType;
    workType = o.workType;
    evFlag = o.evFlag;
    carMotor = List<String>.from(o.carMotor);
    changeBatteryFlag = o.changeBatteryFlag;
    batteryNumber1 = o.batteryNumber1;
    batteryNumber2 = o.batteryNumber2;
    wallChargerNumber = o.wallChargerNumber;
    batteries = [for (final m in o.batteries) Map<String, String>.from(m)];
    saved = o.saved;
  }

  /// FF after a successful save: the step keeps what the user entered and
  /// only takes `work_type` and `flg_renew` from the reloaded detail (FF set
  /// nonePackageWorkType / flagRenew; act / premium amounts and the phone
  /// live in the summary, which `applyDetail` refreshes). Some values on
  /// this page come from `leads[0]` (e.g. the registration year), which a
  /// step-2 save may not update, so a plain reload could undo a pick.
  void keepAfterReload(Step2Data before) {
    final wt = workType;
    final fr = flagRenew;
    copyFrom(before);
    workType = wt;
    flagRenew = fr;
  }

  /// 'ถัดไป' text write-back. FF wrote the **raw** controller texts here
  /// (after the save had stored cleaned ones); the port writes the cleaned
  /// values like the save.
  void applyNextTexts(Step2Form f) {
    carRegis = removeSpacialLetterFromText(f.plate);
    bodyNumber = removeDatAndMakeUpperCase(f.chassis);
    engineNumber = removeDatAndMakeUpperCase(f.engine);
    carSeat = f.seats;
    sizeCar = f.size;
    weightCar = f.weight;
  }

  /// FF default DriverData (all '' except the two 'N' flags).
  static Map<String, String> emptyDriver() => {
        for (final k in driverKeys) k: '',
        'driver_consent': 'N',
        'license_is_life_long': 'N',
      };

  static Map<String, String> emptyBattery() => {for (final k in batteryKeys) k: ''};

  /// The 'ระบุผู้ขับขี่' rule: driver type '1' and the first driver has
  /// name, birth date, ID, licence no. and both photos.
  bool get firstDriverComplete {
    if (drivers.isEmpty) return false;
    final f = drivers.first;
    return const [
      'first_name_th', 'last_name_th', 'birth_day', 'national_thai_id', 'license_no', 'image_idcard',
      'image_license_no',
    ].every((k) => (f[k] ?? '').isNotEmpty);
  }

  /// FF struct `fromMap` (fields typed String; non-strings stringified here
  /// instead of FF's `as String?` crash) + `toMap().withoutNulls`.
  static List<Map<String, String>> _maps(dynamic list, List<String> keys) => [
        if (list is List)
          for (final e in list)
            if (e is Map)
              {
                for (final k in keys)
                  if (e[k] != null) k: '${e[k]}',
              },
      ];
}

/// The page-2 text fields at the moment a button is pressed (FF read the
/// controllers, not the state).
class Step2Form {
  const Step2Form({
    this.plate = '',
    this.chassis = '',
    this.engine = '',
    this.seats = '',
    this.size = '',
    this.weight = '',
    this.oldVmi = '',
  });

  final String plate;
  final String chassis;
  final String engine;
  final String seats;
  final String size;
  final String weight;
  final String oldVmi;
}
