import '../../../core/config/app_environment.dart';
import '../../../core/session/user_session.dart';
import '../../../core/utils/ff_functions.dart' as ff;
import 'insurance_package.dart';
import 'json_read.dart';

/// One element of `insurer_package` in `quotations/save` — the 39-key map
/// FF built with `functions.sendJsonData(...)` from parallel lists.
class QuotationPackageItem {
  const QuotationPackageItem({
    required this.insurerId,
    required this.insurerCode,
    required this.insurerShortName,
    required this.insurerName,
    required this.coverTypeId,
    required this.coverTypeCode,
    required this.coverTypeName,
    required this.garageTypeId,
    required this.garageTypeCode,
    required this.garageTypeName,
    required this.productId,
    required this.packageId,
    required this.packageName,
    required this.sumInsured,
    required this.roadsideAssistance,
    required this.tpbiPerson,
    required this.tpbiAccident,
    required this.tppd,
    required this.flood,
    required this.deductible,
    required this.pa,
    required this.me,
    required this.bb,
    required this.assessory,
    required this.seat,
    required this.netPremium,
    required this.vat,
    required this.stamp,
    required this.grossTotal,
    required this.contractProcessState,
    required this.cc,
    required this.carLost,
    required this.motorAddOn,
    required this.driverBehavior,
    required this.inspectionExcept,
    required this.discountOther,
    required this.discountPercent,
    required this.inspectionExceptPolicyFile,
    required this.inspectionExceptQuotationType,
  });

  /// Builds the item exactly as the FF pages fed `sendJsonData` for package
  /// [p]:
  /// * [viaDetailPage] = true — DetailsInsurancePage → AddCustomerName: the
  ///   list page wrapped several values in `checkNullValueAndReturn`, so a
  ///   `'null'` field is sent as `'-'`.
  /// * false — CompareInsurancePage → AddCustomerName: raw values.
  ///
  /// Both derive cover/garage id + name from the codes with
  /// `coverTypeCodeToId/Name` and `garageTypeCodetoId/CodeToName`.
  factory QuotationPackageItem.fromPackage(InsurancePackage p, {required bool viaDetailPage}) {
    String c(String v) => viaDetailPage ? ff.checkNullValueAndReturn(v) : v;
    final cover = c(p.coverType);
    final garage = c(p.garageType);
    return QuotationPackageItem(
      insurerId: c(p.companyId),
      insurerCode: c(p.serialName),
      insurerShortName: c(p.shortName),
      insurerName: p.fullName,
      coverTypeId: ff.coverTypeCodeToId([cover]).first,
      coverTypeCode: cover,
      coverTypeName: ff.coverTypeCodeToName([cover]).first,
      garageTypeId: ff.garageTypeCodetoId([garage]).first,
      garageTypeCode: garage,
      garageTypeName: ff.garageTypeCodeToName([garage]).first,
      productId: p.productId,
      packageId: p.packageId,
      packageName: p.packageName,
      sumInsured: c(p.sumInsured),
      roadsideAssistance: p.roadsideAssistance,
      tpbiPerson: c(p.tpbiPerson),
      tpbiAccident: c(p.tpbiAccident),
      tppd: c(p.tppd),
      flood: p.flood,
      deductible: p.deductible,
      pa: c(p.pa),
      me: p.me,
      bb: p.bb,
      assessory: c(p.assessory),
      seat: p.seat,
      netPremium: p.netPremium,
      vat: p.vat,
      stamp: p.stamp,
      grossTotal: c(p.grossTotal),
      contractProcessState: p.contractProcessState,
      cc: p.cc,
      carLost: p.carLost,
      motorAddOn: p.motorAddOn,
      driverBehavior: p.driverBehavior,
      inspectionExcept: p.inspectionExcept,
      discountOther: p.discountOther,
      discountPercent: p.discountPercent,
      inspectionExceptPolicyFile: p.inspectionExceptPolicyFile,
      inspectionExceptQuotationType: p.inspectionExceptQuotationType,
    );
  }

  final String insurerId;
  final String insurerCode;
  final String insurerShortName;
  final String insurerName;
  final String coverTypeId;
  final String coverTypeCode;
  final String coverTypeName;
  final String garageTypeId;
  final String garageTypeCode;
  final String garageTypeName;
  final String productId;
  final String packageId;
  final String packageName;
  final String sumInsured;
  final String roadsideAssistance;
  final String tpbiPerson;
  final String tpbiAccident;
  final String tppd;
  final String flood;
  final String deductible;
  final String pa;
  final String me;
  final String bb;
  final String assessory;
  final String seat;
  final String netPremium;
  final String vat;
  final String stamp;
  final String grossTotal;
  final String contractProcessState;
  final String cc;
  final String carLost;
  final String motorAddOn;
  final String driverBehavior;
  final String inspectionExcept;
  final String discountOther;
  final String discountPercent;
  final String inspectionExceptPolicyFile;
  final String inspectionExceptQuotationType;

  /// Same keys, same order as `sendJsonData`.
  Map<String, String> toJson() => {
        'insurer_id': insurerId,
        'insurer_code': insurerCode,
        'insurer_short_name': insurerShortName,
        'insurer_name': insurerName,
        'cover_type_id': coverTypeId,
        'cover_type_code': coverTypeCode,
        'cover_type_name': coverTypeName,
        'garage_type_id': garageTypeId,
        'garage_type_code': garageTypeCode,
        'garage_type_name': garageTypeName,
        'product_id': productId,
        'package_id': packageId,
        'package_name': packageName,
        'sum_insured': sumInsured,
        'roadside_assistance': roadsideAssistance,
        'tpbi_person': tpbiPerson,
        'tpbi_accident': tpbiAccident,
        'tppd': tppd,
        'flood': flood,
        'deductible': deductible,
        'pa': pa,
        'me': me,
        'bb': bb,
        'assessory': assessory,
        'seat': seat,
        'net_premium': netPremium,
        'vat': vat,
        'stamp': stamp,
        'gross_total': grossTotal,
        'contractProcessState': contractProcessState,
        'cc': cc,
        'car_lost': carLost,
        'motor_add_on': motorAddOn,
        'driver_behavior': driverBehavior,
        'inspection_except': inspectionExcept,
        'discount_other': discountOther,
        'discount_percent': discountPercent,
        'inspection_except_policy_file': inspectionExceptPolicyFile,
        'inspection_except_quotation_type': inspectionExceptQuotationType,
      };
}

/// Body of `POST /api/quotations/save` (IbsQuotationsSaveCall), as filled by
/// AddCustomerName (spec 08 "exact request"). Values are what is SENT —
/// callers apply the same transforms FF did:
/// * [phoneNumber] = `removeCommaFromNumText(phone.text)` (digits only);
/// * [carRegistration] = `removeSpacialLetterFromText(plate.text)`;
/// * [carRegistrationYear] = `'${int.parse(insuranceBasicYear) - 543}'`;
/// * [ownerName] = `replaceAllTabAndSpace(first) + ' ' + replaceAllTabAndSpace(last)`;
/// * [ownerPhone], [branchCode], [branchName] = `replaceAllTabAndSpace(...)`.
///
/// `token` and `insurance_url` are echoed in the body as in FF; they default
/// to the session token and the compiled-in insurance base.
class QuotationSaveRequest {
  const QuotationSaveRequest({
    required this.nationalThaiId,
    required this.evFlag,
    required this.subProduct,
    required this.carProvinceName,
    required this.carProvinceCode,
    required this.carTypeDetail,
    required this.oldVmiExpiredDate,
    required this.ownerId,
    required this.firstName,
    required this.phoneNumber,
    required this.carType,
    required this.carRegistration,
    this.driverType = '0',
    required this.carRegistrationYear,
    required this.carBrandId,
    required this.carBrandName,
    required this.carModelName,
    required this.carModelId,
    required this.vehicleId,
    required this.vehicleCode,
    required this.vehicleName,
    required this.ownerName,
    required this.ownerPhone,
    required this.branchCode,
    required this.branchName,
    required this.packages,
    required this.lastName,
  });

  /// `national_thai_id` ← widget.idCard.
  final String? nationalThaiId;

  /// `ev_flag` ← FFAppState().searchPackageEvFlag.
  final String? evFlag;

  /// `sub_product` ← FFAppState().searchPackageSubProduct.
  final String? subProduct;

  /// `car_province_name` ← insuranceInfoRegistrationProvinceSelect.
  final String? carProvinceName;

  /// `car_province_code` ← insuranceInfoRegistrationCodeSelect.
  final String? carProvinceCode;

  /// `car_type_detail` ← insuranceCarTypeDetailSelected.
  final String? carTypeDetail;

  /// `old_VMI_expriedDate` (sic) ← widget.oldVMIExpDate.
  final String? oldVmiExpiredDate;

  /// `owner_id` ← FFAppState().employeeID.
  final String? ownerId;

  /// `first_name`.
  final String? firstName;

  /// `phone_number`.
  final String? phoneNumber;

  /// `car_type` ← insuranceVehicleTypeDropDown.
  final String? carType;

  /// `car_registration`.
  final String? carRegistration;

  /// `driver_type` (AddCustomerName default `'0'`).
  final String? driverType;

  /// `car_registration_year` (Gregorian).
  final String? carRegistrationYear;

  /// `car_brand_id` ← insuranceBasicBrandId.
  final String? carBrandId;

  /// `car_brand_name` ← insuranceBasicBrandName.
  final String? carBrandName;

  /// `car_model_name` ← insuranceBasicModelName.
  final String? carModelName;

  /// `car_model_id` ← insuranceBasicModelId.
  final String? carModelId;

  /// `vehicle_id` ← insuranceBasicVehicleUsedTypeId.
  final String? vehicleId;

  /// `vehicle_code` ← insuranceBasicVehicleUsedTypeCode.
  final String? vehicleCode;

  /// `vehicle_name` ← insuranceBasicVehicleUsedTypeName.
  final String? vehicleName;

  /// `owner_name`.
  final String? ownerName;

  /// `owner_phone`.
  final String? ownerPhone;

  /// `branch_code`.
  final String? branchCode;

  /// `branch_name`.
  final String? branchName;

  /// `insurer_package` — one entry per selected package.
  final List<QuotationPackageItem> packages;

  /// `last_name`.
  final String? lastName;

  /// The FF template's keys, in its order. A null String is sent as JSON
  /// null, as the template did.
  Map<String, dynamic> toJson({String? token, String? insuranceUrl}) => {
        'national_thai_id': nationalThaiId,
        'ev_flag': evFlag,
        'sub_product': subProduct,
        'car_province_name': carProvinceName,
        'car_province_code': carProvinceCode,
        'car_type_detail': carTypeDetail,
        'old_VMI_expriedDate': oldVmiExpiredDate,
        'owner_id': ownerId,
        'token': token ?? UserSession.instance.accessToken,
        'first_name': firstName,
        'phone_number': phoneNumber,
        'car_type': carType,
        'car_registration': carRegistration,
        'driver_type': driverType,
        'car_registration_year': carRegistrationYear,
        'car_brand_id': carBrandId,
        'car_brand_name': carBrandName,
        'car_model_name': carModelName,
        'car_model_id': carModelId,
        'vehicle_id': vehicleId,
        'vehicle_code': vehicleCode,
        'vehicle_name': vehicleName,
        'owner_name': ownerName,
        'owner_phone': ownerPhone,
        'branch_code': branchCode,
        'branch_name': branchName,
        'insurer_package': [for (final p in packages) p.toJson()],
        'insurance_url': insuranceUrl ?? AppEnvironment.current.insuranceApiBase,
        'last_name': lastName,
      };
}

/// One `$.results.data.detail[:]` row of the save response.
class QuotationDetail {
  const QuotationDetail({
    this.leadDtlId,
    this.insurerShortName,
    this.coverTypeCode,
    this.garageTypeCode,
    this.url,
  });

  factory QuotationDetail.fromJson(Map<String, dynamic> j) => QuotationDetail(
        leadDtlId: jsonInt(j['lead_dtl_id']),
        insurerShortName: j['insurer_short_name']?.toString(),
        coverTypeCode: j['cover_type_code']?.toString(),
        garageTypeCode: j['garage_type_code']?.toString(),
        url: j['url']?.toString(),
      );

  /// getter `leaddtlid` — `lead_dtl_id`.
  final int? leadDtlId;

  /// getter `insurershortname` — `insurer_short_name`.
  final String? insurerShortName;

  /// getter `covertypecode` — `cover_type_code`.
  final String? coverTypeCode;

  /// getter `garagetypecode` — `garage_type_code`.
  final String? garageTypeCode;

  /// getter `url` — `url` (per-package quotation PDF).
  final String? url;
}

/// Parsed `$.results.data` of the save response.
class QuotationSaveResult {
  const QuotationSaveResult({
    this.leadId,
    this.urlCompare,
    this.details = const [],
    this.quotationId,
    this.quotationStatus,
  });

  factory QuotationSaveResult.fromJson(dynamic json) {
    final data = resultsData(json);
    final leads = jsonAt(data, 'leads');
    final quotation = jsonAt(data, 'quotation');
    return QuotationSaveResult(
      leadId: jsonInt(jsonAt(leads, 'lead_id')),
      urlCompare: jsonAt(leads, 'url')?.toString(),
      details: List.unmodifiable([
        for (final d in jsonChildren(jsonAt(data, 'detail')))
          if (d is Map) QuotationDetail.fromJson(Map<String, dynamic>.from(d)),
      ]),
      quotationId: jsonInt(jsonAt(quotation, 'quotation_id')),
      quotationStatus: jsonAt(quotation, 'quotation_status')?.toString(),
    );
  }

  /// getter `leadid` — `$.results.data.leads.lead_id`.
  final int? leadId;

  /// getter `urlCompare` — `$.results.data.leads.url` (comparison PDF).
  final String? urlCompare;

  /// getter `detail` — `$.results.data.detail`.
  final List<QuotationDetail> details;

  /// getter `quotationid` — `$.results.data.quotation.quotation_id`.
  final int? quotationId;

  /// getter `quotationstatus` — `$.results.data.quotation.quotation_status`.
  final String? quotationStatus;

  /// getter `url`: non-null detail URLs (FF dropped nulls).
  List<String> get urls => [for (final d in details) if (d.url != null) d.url!];

  /// getter `leaddtlid`: non-null detail ids (FF dropped nulls).
  List<int> get leadDtlIds => [for (final d in details) if (d.leadDtlId != null) d.leadDtlId!];

  /// FF `insurarerQuotationPdf`: [urls] then `'$urlCompare'` appended —
  /// including the literal `'null'` when absent (FF quirk, spec 08).
  List<String> get quotationPdfList => [...urls, '$urlCompare'];
}
