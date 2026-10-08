import 'json_read.dart';

/// Shown when a package/insurer has no logo (FF hard-coded fallback URL).
const String kNoImageUrl =
    'https://is-dev.swpfin.com/ssw_insurance_manual_api/storage/images/No_image_available.png?v=1692265949';

/// One insurance package — an element of `package[:]` in `get_package`
/// (TelePackageSearchAPICall, nested under an insurer) or of
/// `$.results.data[:]` in `get_package_mc` (TelePackageSearchMCAPICall, flat).
///
/// FlutterFlow spread every field over ~48 parallel `FFAppState().search*`
/// lists (see `specs/30_model_mapping.md`); `FFAppState().searchXxx[i]` is
/// `packages[i].field` here. Doc comments name the FF getter(s) — car / MC
/// when they differ — and the JSON key.
///
/// ### Null handling
/// FF list getters dropped JSON nulls, which shifted every later index of
/// that one list (parallel lists misaligned). Here each package keeps its own
/// fields, and a JSON null becomes:
/// * `'null'` (marked **[N]**) for fields the pages pass through
///   `checkNullValueAndReturn` (so they still render as `'-'`) and for fields
///   FF read with raw `getJsonField(...).toString()` (which yielded `'null'`);
/// * `''` for every other String field.
///
/// Numbers are kept as their string form (`1500` → `'1500'`); FF would have
/// thrown on a non-String.
class InsurancePackage {
  const InsurancePackage({
    required this.serialName,
    required this.fullName,
    required this.shortName,
    required this.companyId,
    required this.logo,
    required this.coverType,
    required this.garageType,
    required this.grossTotal,
    required this.sumInsured,
    required this.expiryDate,
    required this.effectiveDate,
    required this.pa,
    required this.tppd,
    required this.tpbiPerson,
    required this.tpbiAccident,
    required this.brandCode,
    required this.brandName,
    required this.modelCode,
    required this.modelName,
    required this.actAmount,
    required this.registrationYear,
    required this.assessory,
    required this.insurerCondition,
    required this.id,
    required this.packageId,
    required this.packageName,
    required this.stamp,
    required this.vat,
    required this.netPremium,
    required this.seat,
    required this.roadsideAssistance,
    required this.bb,
    required this.me,
    required this.flood,
    required this.deductible,
    required this.contractProcessState,
    required this.cc,
    required this.carLost,
    required this.motorAddOn,
    required this.driverBehavior,
    required this.inspectionExcept,
    required this.grossTotalDiscount,
    required this.grossTotalNet,
    required this.discountOther,
    required this.discountPercent,
    required this.discountFlg,
    required this.inspectionExceptPolicyFile,
    required this.inspectionExceptQuotationType,
  });

  factory InsurancePackage.fromJson(Map<String, dynamic> j) => InsurancePackage(
        serialName: jsonStrN(j['serial_name']),
        fullName: jsonStr(j['full_name']),
        shortName: jsonStrN(j['short_name']),
        companyId: jsonStrN(j['company_id']),
        logo: jsonStrN(j['logo']),
        coverType: jsonStrN(j['cover_type']),
        garageType: jsonStrN(j['garage_type']),
        grossTotal: jsonStrN(j['gross_total']),
        sumInsured: jsonStrN(j['sum_insured']),
        expiryDate: jsonStrN(j['expiry_date']),
        effectiveDate: jsonStr(j['effective_date']),
        pa: jsonStrN(j['pa']),
        tppd: jsonStrN(j['tppd']),
        tpbiPerson: jsonStrN(j['tpbi_person']),
        tpbiAccident: jsonStrN(j['tpbi_accident']),
        brandCode: jsonStrN(j['brand_code']),
        brandName: jsonStr(j['brand_name']),
        modelCode: jsonStrN(j['model_code']),
        modelName: jsonStr(j['model_name']),
        actAmount: jsonStrN(j['act_amount']),
        registrationYear: jsonStrN(j['registration_year']),
        assessory: jsonStrN(j['assessory']),
        insurerCondition: jsonStr(j['insurer_condition']),
        id: jsonInt(j['id']),
        packageId: jsonStr(j['package_id']),
        packageName: jsonStr(j['package_name']),
        stamp: jsonStr(j['stamp']),
        vat: jsonStr(j['vat']),
        netPremium: jsonStr(j['net_premium']),
        seat: jsonStr(j['seat']),
        roadsideAssistance: jsonStr(j['roadside_assistance']),
        bb: jsonStr(j['bb']),
        me: jsonStr(j['me']),
        flood: jsonStr(j['flood']),
        deductible: jsonStr(j['deductible']),
        contractProcessState: jsonStr(j['contractprocessstate']),
        cc: jsonStr(j['cc']),
        carLost: jsonStr(j['car_lost']),
        motorAddOn: jsonStr(j['motor_add_on']),
        driverBehavior: jsonStr(j['driver_behavior']),
        inspectionExcept: jsonStr(j['inspection_except']),
        grossTotalDiscount: jsonStrN(j['gross_total_discount']),
        grossTotalNet: jsonStrN(j['gross_total_net']),
        discountOther: jsonStrN(j['discount_other']),
        discountPercent: jsonStrN(j['discount_percent']),
        discountFlg: jsonStrN(j['discount_flg']),
        inspectionExceptPolicyFile: jsonStrN(j['inspection_except_policy_file']),
        inspectionExceptQuotationType: jsonStrN(j['inspection_except_quotation_type']),
      );

  /// **[N]** `serial_name` — getter `serialName`; FF `searchSerialName`.
  /// Holds the insurer code (sent as `insurer_code`; compared against
  /// `filterInsurerList`).
  final String serialName;

  /// `full_name` — getter `fullName`; FF `searchFullName`. Insurer full name
  /// (sent as `insurer_name`).
  final String fullName;

  /// **[N]** `short_name` — getter `shortName`; FF `searchShortName`.
  final String shortName;

  /// **[N]** `company_id` — getter `companyId`; FF `companyId`
  /// (sent as `insurer_id`).
  final String companyId;

  /// **[N]** `logo` — getter `logo`; FF `searchLogo`. See [logoOrPlaceholder].
  final String logo;

  /// **[N]** `cover_type` — getter `coverType`; FF `searchCoverType`
  /// (code, e.g. `VMI1`, `VMI2+`).
  final String coverType;

  /// **[N]** `garage_type` — getter `garageType`; FF `searchGarageType`
  /// (`DEALER` / `COMPANY`).
  final String garageType;

  /// **[N]** `gross_total` — getter `grossTotal`; FF `searchGrossTotal`.
  final String grossTotal;

  /// **[N]** `sum_insured` — getter `sumInsured`; FF `searchSumInsured`.
  final String sumInsured;

  /// **[N]** `expiry_date` — getter `expiryDate`; FF `searchExpDate`.
  final String expiryDate;

  /// `effective_date` — getter `effectiveDate`; FF `effectiveDate`.
  final String effectiveDate;

  /// **[N]** `pa` — getter `pa`; FF `searchPa`.
  final String pa;

  /// **[N]** `tppd` — getter `tppd`; FF `searchTppd`.
  final String tppd;

  /// **[N]** `tpbi_person` — getter `tpbiPerson`; FF `tpbiPerson`.
  final String tpbiPerson;

  /// **[N]** `tpbi_accident` — getter `tpbiAccident`; FF `tpbiAccident`.
  final String tpbiAccident;

  /// **[N]** `brand_code` — getter `brandCode`; FF `teleBrandID`.
  final String brandCode;

  /// `brand_name` — getter `brandName`; FF `teleBrandName`.
  final String brandName;

  /// **[N]** `model_code` — getter `modelCode`; FF `teleModelCode`.
  final String modelCode;

  /// `model_name` — getter `modelName`; FF `teleModelName`.
  final String modelName;

  /// **[N]** `act_amount` — getter `actAmount`; FF `searchActAmount`.
  final String actAmount;

  /// **[N]** `registration_year` — getter `registrationYear`;
  /// FF `searchRegisYearList`.
  final String registrationYear;

  /// **[N]** `assessory` (sic) — getter `accessory`; FF `searchAccessoryList`.
  final String assessory;

  /// `insurer_condition` — getter `insurerCondition`; FF `searchInsurerCondition`.
  final String insurerCondition;

  /// `id` — getter `id` (`List<int>`); FF `searchId`. Sent as `product_id`
  /// (see [productId]).
  final int? id;

  /// `package_id` — getter `packageId`; FF `searchPackageId`.
  final String packageId;

  /// `package_name` — getter `packageName`; FF `serachPackageName` (sic).
  final String packageName;

  /// `stamp` — getter `stamp`; FF `searchStamp`.
  final String stamp;

  /// `vat` — getter `vat`; FF `searchVat`.
  final String vat;

  /// `net_premium` — getter `netPremium`; FF `searchNetPremium`.
  final String netPremium;

  /// `seat` — getter `seat`; FF `searchSeat`.
  final String seat;

  /// `roadside_assistance` — getter `roadsideAssistance`;
  /// FF `searchRoadsideAssistance`.
  final String roadsideAssistance;

  /// `bb` — getter `bb`; FF `searchbb`.
  final String bb;

  /// `me` — getter `me`; FF `searchme`.
  final String me;

  /// `flood` — getter `flood`; FF `searchFlood`.
  final String flood;

  /// `deductible` — getter `deductible`; FF `searchDeductible`.
  final String deductible;

  /// `contractprocessstate` — getter `contractProcessstate`;
  /// FF `searchContractProcessstate`.
  final String contractProcessState;

  /// `cc` — getter `cc`; FF `searchcc`.
  final String cc;

  /// `car_lost` — getter `carlost` (car) / `carLost` (MC); FF `searchCarlost`.
  final String carLost;

  /// `motor_add_on` — getter `motoraddon` (car) / `motorAddOn` (MC);
  /// FF `searchMotoraddon`.
  final String motorAddOn;

  /// `driver_behavior` — getter `driverbehavior` (car) / `driverBehavior` (MC);
  /// FF `searchDriverbehavior`.
  final String driverBehavior;

  /// `inspection_except` — getter `inspectionExcept` (car) /
  /// `inspectionexcept` (MC); FF `searchInspectionExcept` (`'Y'` = no photos).
  final String inspectionExcept;

  /// **[N]** `gross_total_discount` — getter `grosstotaldiscount` (raw);
  /// FF `searchGrosstotaldiscount`.
  final String grossTotalDiscount;

  /// **[N]** `gross_total_net` — getter `grosstotalnet` (raw);
  /// FF `searchGrosstotalnet`.
  final String grossTotalNet;

  /// **[N]** `discount_other` — getter `discountother` (raw);
  /// FF `searchDiscountother`.
  final String discountOther;

  /// **[N]** `discount_percent` — getter `discountpercent` (raw);
  /// FF `searchDiscountpercent`.
  final String discountPercent;

  /// **[N]** `discount_flg` — no getter (page read raw `getJsonField`);
  /// FF `searchDiscountflg` (`'1'` = discounted).
  final String discountFlg;

  /// **[N]** `inspection_except_policy_file` — no getter (raw);
  /// FF `searchinspectionexceptpolicyfile`.
  final String inspectionExceptPolicyFile;

  /// **[N]** `inspection_except_quotation_type` — no getter (raw);
  /// FF `searchinspectionexceptquotationtype`.
  final String inspectionExceptQuotationType;

  /// `searchId[i]?.toString()` — the `productId` the pages forward.
  String get productId => '${id ?? ''}';

  /// FF cards: `searchLogo[i] ?? kNoImageUrl` (the `??` only caught a
  /// missing element; here a missing/null logo also falls back).
  String get logoOrPlaceholder => logo.isEmpty || logo == 'null' ? kNoImageUrl : logo;
}
