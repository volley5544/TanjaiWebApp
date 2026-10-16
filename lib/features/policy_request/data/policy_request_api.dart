import 'package:flutter/foundation.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/config/local_api_auth.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/user_session.dart';

/// Raw response of one request-flow API call. Pages read the FF JSONPaths
/// with [at] (`'results.data.payment.ref1'`, `'results.data.leads[0].car_type'`).
///
/// [statusCode] is the HTTP status (-1 = no response). Envelopes differ per
/// API family, as in FF:
/// * insurance APIs: [code] = `$.code`, [message] = `$.message`;
/// * quotation-file APIs: `$.statusCode` / `$.statusMessage` ([fileStatus]);
/// * local APIs: `$.status` ([localStatus]).
class PrResponse {
  const PrResponse(this.statusCode, this.json);

  final int statusCode;
  final dynamic json;

  bool get isHttpOk => statusCode == 200;

  int? get code => _int(at('code'));
  String? get message => at('message')?.toString();
  int? get fileStatus => _int(at('statusCode'));
  String? get fileMessage => at('statusMessage')?.toString();
  int? get localStatus => _int(at('status'));

  /// HTTP 200 and `$.code == 200`.
  bool get isOk => isHttpOk && code == 200;

  /// Value at a dotted path with `[n]` indexes, e.g. `results.data.leads[0].car_type`.
  dynamic at(String path) => jsonPathGet(json, path);

  static int? _int(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');
}

/// Dotted-path reader shared by the flow (`a.b[0].c`). Missing → null.
dynamic jsonPathGet(dynamic json, String path) {
  dynamic cur = json;
  for (final part in path.split('.')) {
    if (part.isEmpty) continue;
    final m = RegExp(r'^([^\[]*)((\[\d+\])*)$').firstMatch(part);
    if (m == null) return null;
    final key = m.group(1)!;
    if (key.isNotEmpty) {
      if (cur is! Map) return null;
      cur = cur[key];
    }
    for (final idx in RegExp(r'\[(\d+)\]').allMatches(m.group(2) ?? '')) {
      final i = int.parse(idx.group(1)!);
      if (cur is! List || i >= cur.length) return null;
      cur = cur[i];
    }
  }
  return cur;
}

/// Every FF `*Call` the request-policy flow uses (`lib/in_package_insurance`).
/// Bodies keep the FF fields (incl. the redundant `token` / `insurance_url` /
/// `api_url`) but are built with `jsonEncode` (FF interpolated raw strings).
/// Tokens / owner ids are never logged.
///
/// WRITE calls (change UAT data — never call them in automated tests without
/// the user's OK): [saveApplication], [editApplication], [savePayment],
/// [regeneratePaymentCode], [issuePolicy], [cancelPolicy].
class PolicyRequestApi {
  PolicyRequestApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  static final PolicyRequestApi instance = PolicyRequestApi();

  final ApiClient _client;

  String get _ins => AppEnvironment.current.insuranceApiBase;
  String get _local => AppEnvironment.current.localApiBase;
  String get _token => UserSession.instance.accessToken;
  String get _empId => UserSession.instance.employeeId;
  Map<String, String> get _bearer => {'Authorization': 'Bearer $_token'};

  Future<PrResponse> _post(String url, Map<String, dynamic> body, {Map<String, String> headers = const {}}) async {
    final r = await _client.postJson(url, body, headers: headers);
    if (kDebugMode && r.statusCode != 200) debugPrint('[PolicyRequestApi] ${Uri.parse(url).path} → ${r.statusCode}');
    return PrResponse(r.statusCode, r.json);
  }

  // ---- application ---------------------------------------------------------

  /// IbsApplicationsDetailCall — the whole application (`$.results.data`).
  Future<PrResponse> getApplicationDetail(String quotationId) => _post(
        '$_ins/api/applications/list/$quotationId',
        {'quotation_id': quotationId, 'insurance_url': _ins, 'token': _token},
        headers: _bearer,
      );

  /// IbsApplicationsSaveCall (`action: save_draft`). FF always sent all ~170
  /// keys, `""` for the ones a step doesn't fill — [fields] overrides the
  /// [saveTemplate] defaults. **WRITE.**
  Future<PrResponse> saveApplication({required String step, required Map<String, dynamic> fields}) {
    final body = saveTemplate()
      ..addAll(fields)
      ..['action'] = 'save_draft'
      ..['step'] = step
      ..['insurance_url'] = _ins
      ..['token'] = _token;
    return _post('$_ins/api/applications/save', body, headers: _bearer);
  }

  /// IbsApplicationsEditCall (P4_2 effective-date edit). **WRITE.**
  Future<PrResponse> editApplication({
    required String subProduct,
    required String quotationId,
    required String effectiveDateInsure,
    required String effectiveDateAct,
    required String firstNameTh,
    required String lastNameTh,
    required String carRegistration,
  }) =>
      _post(
        '$_ins/api/applications/edit',
        {
          'sub_product': subProduct,
          'insurance_url': _ins,
          'token': _token,
          'quotation_id': quotationId,
          'effective_date_insure': effectiveDateInsure,
          'effective_date_act': effectiveDateAct,
          'first_name_th': firstNameTh,
          'last_name_th': lastNameTh,
          'car_registration': carRegistration,
        },
        headers: _bearer,
      );

  // ---- payment -------------------------------------------------------------

  /// IbsCalculateInstallmentCall.
  Future<PrResponse> calculateInstallment({
    required String workType,
    required String actFlg,
    required String insurerCode2,
    required String coverTypeCode,
    required String grossTotalNet,
    required String vehicleCode,
    required String actTotal,
    required String subProduct,
  }) =>
      _post(
        '$_ins/api/payment/calculate/installment',
        {
          'work_type': workType,
          'act_flg': actFlg,
          'insurer_code2': insurerCode2,
          'cover_type_code': coverTypeCode,
          'insurance_url': _ins,
          'gross_total_net': grossTotalNet,
          'vehicle_code': vehicleCode,
          'act_total': actTotal,
          'token': _token,
          'sub_product': subProduct,
        },
        headers: _bearer,
      );

  /// IbsApplicationsPaymentSaveCall. **WRITE.**
  Future<PrResponse> savePayment({
    required String tenorFirstDue,
    required String quotationId,
    required String leadDtlId,
    required String paymentType,
    required String paymentChannel,
    required String tenor,
    required String netPremiumTotal,
    required String actTotal,
    required String installmentFirstDue,
    required String installmentLastDue,
  }) =>
      _post(
        '$_ins/api/payment/save',
        {
          'tenor_first_due': tenorFirstDue,
          'quotation_id': quotationId,
          'insurance_url': _ins,
          'lead_dtl_id': leadDtlId,
          'payment_type': paymentType,
          'payment_channel': paymentChannel,
          'tenor': tenor,
          'net_premium_total': netPremiumTotal,
          'act_total': actTotal,
          'installment_first_due': installmentFirstDue,
          'installment_last_due': installmentLastDue,
          'token': _token,
        },
        headers: _bearer,
      );

  /// IbsPaymentRegenerateCodeCall — new QR refs. **WRITE.**
  Future<PrResponse> regeneratePaymentCode(String quotationId) => _post(
        '$_ins/api/payment/regenerate/code',
        {'insurance_url': _ins, 'quotation_id': quotationId, 'token': _token},
        headers: _bearer,
      );

  // ---- policy --------------------------------------------------------------

  /// PostInsurancePolicyApiCall — sends the application to the insurer.
  /// **WRITE (issues the policy).**
  Future<PrResponse> issuePolicy(String quotationId) => _post(
        '$_ins/api/insurance/post/issue_policy',
        {'quotation_id': quotationId, 'api_url': _ins, 'token': _token},
        headers: _bearer,
      );

  /// GetInsurancePolicyApiCall.
  Future<PrResponse> getPolicy(String quotationId) =>
      _post('$_ins/api/insurance/get/policy', {'quotation_id': quotationId}, headers: _bearer);

  /// CancelInsurancePolicyApiCall. **WRITE (cancels the policy).**
  Future<PrResponse> cancelPolicy({required String quotationId, required String reason}) => _post(
        '$_ins/api/insurance/cancel/policy',
        {'quotation_id': quotationId, 'cancel_reason_name': reason, 'owner_id': _empId},
        headers: _bearer,
      );

  /// GetFileVmiApiCall → `$.VMI_documentUrl` ([PrResponse.fileStatus]).
  Future<PrResponse> getFileVmi(String quotationId) => _post(
        '$_ins/api/quotations/get-file-vmi',
        {'quotation_id': quotationId, 'owner_id': _empId},
        headers: _bearer,
      );

  /// GetFileCmiApiCall → `$.CMI_documentUrl`.
  Future<PrResponse> getFileCmi(String quotationId) => _post(
        '$_ins/api/quotations/get-file-cmi',
        {'quotation_id': quotationId, 'owner_id': _empId},
        headers: _bearer,
      );

  // ---- checks / masters ----------------------------------------------------

  /// CheckBlackListCall → `$.results.data.blacklist_flag` ('N' = OK).
  Future<PrResponse> checkBlacklist({
    required String idTypeId,
    required String nationalThaiId,
    required String quotationId,
  }) =>
      _post(
        '$_ins/api/contract/check/blacklist',
        {
          'id_type_id': idTypeId,
          'insurance_url': _ins,
          'national_thai_id': nationalThaiId,
          'quotation_id': quotationId,
          'token': _token,
        },
        headers: _bearer,
      );

  /// InsuranceRequestGetInsurerAPICall.
  Future<PrResponse> getInsurersAll({String vehicleGroup = ''}) =>
      _post('$_ins/api/insurance/master/get_insurers_all', {'vehicle_group': vehicleGroup});

  /// GetLicenseListCall.
  Future<PrResponse> getLicenseList({String flagGet = '1'}) =>
      _post('$_ins/api/insurance/master/get_license_list', {'flag_get': flagGet, 'insurance_url': _ins});

  /// GetOccupationCall.
  Future<PrResponse> getOccupation() => _post('$_ins/api/insurance/master/get_occupation', {'insurance_url': _ins});

  /// GetAddressMasterCall (FF sent no body).
  Future<PrResponse> getAddressMaster() => _post('$_ins/api/insurance/master/get_zipcode', const {});

  /// GetFinanceCall (HR23 beneficiary list).
  Future<PrResponse> getFinance() => _post('$_ins/api/insurance/master/get_finance', {'insurance_url': _ins});

  /// TeleGetBrandAPICall.
  Future<PrResponse> getBrands({String vehicleGroup = ''}) =>
      _post('$_ins/api/insurance/master/get_brands', {'api_url': _ins, 'vehicle_group': vehicleGroup});

  /// TeleGetModelAPICall.
  Future<PrResponse> getModels({String vehicleGroup = ''}) =>
      _post('$_ins/api/insurance/master/get_models', {'api_url': _ins, 'vehicle_group': vehicleGroup});

  /// TeleGetProvinceAPICall.
  Future<PrResponse> getProvinces() => _post('$_ins/api/insurance/master/get_province', {'api_url': _ins});

  /// InsuranceRequestGetVehicleAPICall.
  Future<PrResponse> getVehicles({String vehicleCategory = '', String carType = ''}) => _post(
        '$_ins/api/insurance/master/get_vehicle',
        {'vehicle_category': vehicleCategory, 'car_type': carType},
      );

  /// GetProfileImageCall — [baseUrl] = Firestore `urlLinkStorage`
  /// `SHMpkLIsHEHrCQC183m9.url_link`. → `$.statusCode`, `$.data.img_profile`.
  Future<PrResponse> getProfileImage({required String baseUrl, required String employeeCode}) => _post(
        '$baseUrl/firestore/get-profile/$employeeCode',
        {'employeeCode': employeeCode, 'insurance_url': baseUrl},
      );

  // ---- local API -----------------------------------------------------------

  /// GetDateTimeAPICall → `$.status`, `$.info.DateYMD` (server date).
  Future<PrResponse> getServerDateTime() => _post(
        '$_local/api/check-in/getdate-time',
        {'token': _token, 'api_url': _local},
        headers: {'Authorization': kLocalApiBasicAuth},
      );

  // ---- save template -------------------------------------------------------

  /// FF `IbsApplicationsSaveCall` defaults: every key `""`, except the raw
  /// JSON ones (`address {}`, `app_battery {}`, `car_motor []`,
  /// `app_driver []`, `app_insured_person []`).
  static Map<String, dynamic> saveTemplate() => <String, dynamic>{
        for (final k in _saveStringKeys) k: '',
        'address': <String, dynamic>{},
        'app_battery': <String, dynamic>{},
        'car_motor': <dynamic>[],
        'app_driver': <dynamic>[],
        'app_insured_person': <dynamic>[],
      };

  static const _saveStringKeys = [
    'change_battery_flag', 'image_application_2', 'sum_insure_house', 'sum_insure_buildin', 'sum_insure_total',
    'wall', 'floor_ground', 'floor_upper', 'roof_frame', 'roof', 'amout_house', 'floor', 'width', 'length',
    'assured', 'house_type_code', 'house_type_name', 'usable_area', 'id_card_power_of_attorney',
    'power_of_attorney', 'file_cancel_loan', 'customer_type', 'horsepower', 'battery_number', 'battery_number_2',
    'wall_charger_number', 'ev_flag', 'sub_product', 'image_quotation_insurer', 'effective_date_insure',
    'effective_date_act', 'flg_renew', 'image_company_book', 'old_VMI_image', 'old_VMI_expriedDate',
    'old_VMI_policyNumber', 'accessory_total', 'sensitive_consent', 'privacy_consent', 'sanction_consent',
    'image_front_trailer', 'image_rightfront_trailer', 'image_right_trailer', 'image_rightrear_trailer',
    'image_rear_trailer', 'image_leftrear_trailer', 'image_left_trailer', 'image_leftfront_trailer',
    'flg_carrier', 'flg_co_org', 'carrier_type', 'carrier_price', 'truck_part', 'customer_memberchip',
    'carrier_propose', 'truck_current_price', 'trailer_car_registration', 'trailer_sum_insured',
    'quotation_type', 'car_province_code', 'car_province_name', 'employee_phone_number_license',
    'registration_province', 'registration_code', 'employee_licenseExp_license', 'employee_licenseImg_license',
    'employee_licenseID_license', 'employee_code_license', 'employee_firstname_license',
    'employee_lastname_license', 'employee_branch_license', 'branch_code', 'branch_name',
    'file_loan_application_register', 'image_application', 'payment_type', 'image_wound', 'image_accessories',
    'model_name', 'car_registration', 'registration_year', 'make_year', 'vehicle_id', 'vehicle_code',
    'vehicle_name', 'occupation_name', 'occupation_subcode', 'occupation_subname', 'mobile1', 'mobile2',
    'email1', 'car_type', 'brand_id', 'brand_name', 'model_id', 'body_number', 'engine_number', 'seat', 'cc',
    'weight', 'driver_type', 'accessory_flg', 'act_flg', 'beneficiary_name', 'image_examination',
    'image_bluebook', 'image_idcard', 'image_other', 'image_wound1', 'image_wound2', 'image_wound3',
    'image_wound4', 'image_wound5', 'image_wound6', 'image_accessories1', 'image_accessories2',
    'image_accessories3', 'image_accessories4', 'image_accessories5', 'image_accessories6', 'image_front',
    'image_rear', 'image_left', 'image_right', 'image_rightfront', 'image_rightrear', 'image_leftfront',
    'image_leftrear', 'image_roof', 'quotation_id', 'lead_dtl_id', 'id_type_id', 'national_thai_id', 'gender',
    'title_th_id', 'title_th', 'first_name_th', 'last_name_th', 'birth_day', 'occupation_id', 'occupation_code',
  ];
}
