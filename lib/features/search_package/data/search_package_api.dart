import 'package:flutter/foundation.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/user_session.dart';
import '../models/brand.dart';
import '../models/car_model.dart';
import '../models/cover_type.dart';
import '../models/insurer_group.dart';
import '../models/json_read.dart';
import '../models/province.dart';
import '../models/quotation_save_request.dart';
import '../models/server_date_time.dart';
import '../models/vehicle_usage.dart';
import 'api_result.dart';

/// SECURITY: shared Basic credential (`takko:123456`) that the mobile app's
/// GetDateTimeAPICall sends to `check-in/getdate-time`. Shipping it in the web
/// bundle makes it public (pentest finding) — the endpoint must move to
/// per-user auth (e.g. the Bearer token) server-side, then drop this constant.
const String _kGetDateTimeBasicAuth = 'Basic dGFra286MTIzNDU2';

/// The search-package endpoints, one method per FF call class used by live
/// code. Bodies keep the FF templates' keys, order and value formats
/// (including the echoed `api_url` / `insurance_url` / `token`), but are
/// built as maps and `jsonEncode`d, so user input is escaped properly.
///
/// Not ported (dead code in the source pages): `GetOccupationCall`
/// (`master/get_occupation`, only behind the dead driver tile) and
/// `CheckBlackListCopyCall` (`contract/check/id-promotion`, only behind the
/// dead discount-check button).
class SearchPackageApi {
  SearchPackageApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  static final SearchPackageApi instance = SearchPackageApi();

  final ApiClient _client;

  String get _base => AppEnvironment.current.insuranceApiBase;

  /// TeleGetBrandAPICall — car (`vehicleGroup: ''`) and EV (`'EV'`).
  Future<ApiResult<List<Brand>>> getBrands({String? vehicleGroup = ''}) => _post(
        '$_base/api/insurance/master/get_brands',
        {'api_url': _base, 'vehicle_group': vehicleGroup},
        (j) => parseDataList(j, Brand.fromJson),
      );

  /// TeleGetBrandMCAPICall (pages never pass `flagGet`, so it is `''`).
  Future<ApiResult<List<Brand>>> getBrandsMc({String? flagGet = ''}) => _post(
        '$_base/api/insurance/master/get_brands_mc',
        {'flag_get': flagGet, 'api_url': _base},
        (j) => parseDataList(j, Brand.fromJson),
      );

  /// TeleGetModelAPICall — car (`''`) and EV (`'EV'`).
  Future<ApiResult<List<CarModel>>> getModels({String? vehicleGroup = ''}) => _post(
        '$_base/api/insurance/master/get_models',
        {'api_url': _base, 'vehicle_group': vehicleGroup},
        (j) => parseDataList(j, CarModel.fromJson),
      );

  /// TeleGetModelMCAPICall.
  Future<ApiResult<List<CarModel>>> getModelsMc() => _post(
        '$_base/api/insurance/master/get_models_mc',
        {'api_url': _base},
        (j) => parseDataList(j, CarModel.fromJson),
      );

  /// TeleGetCoverTypeAPICall — MC passes `'MC'`, car/EV omit it (`''`).
  Future<ApiResult<List<CoverType>>> getCoverTypes({String? carType = ''}) => _post(
        '$_base/api/insurance/master/get_cover_type',
        {'api_url': _base, 'car_type': carType},
        (j) => parseDataList(j, CoverType.fromJson),
      );

  /// InsuranceRequestGetVehicleAPICall — pages pass `vehicleCategory: 'auto'`
  /// and `carType: 'MC'` or `fromMenuAppState` (`'motor'` / `'EV'`).
  /// FF sent no headers here (ApiManager added the JSON content type).
  Future<ApiResult<List<VehicleUsage>>> getVehicles({String? vehicleCategory = '', String? carType = ''}) => _post(
        '$_base/api/insurance/master/get_vehicle',
        {'vehicle_category': vehicleCategory, 'car_type': carType},
        (j) => parseDataList(j, VehicleUsage.fromJson),
      );

  /// TeleGetProvinceAPICall.
  Future<ApiResult<List<Province>>> getProvinces() => _post(
        '$_base/api/insurance/master/get_province',
        {'api_url': _base},
        (j) => parseDataList(j, Province.fromJson),
      );

  /// TelePackageSearchAPICall (car/EV, spec 04). Pages leave the four
  /// min/max values null (sent as JSON null). The FF call's unused
  /// `companyIdList`, `carRegistration` and `apiUrl` args never reached the
  /// body and are omitted.
  Future<ApiResult<PackageSearchResult>> searchPackages({
    String? driver = '',
    String? brandCode = '',
    String? modelCode = '',
    String? year = '',
    String? vehicleUsage = '',
    List<String>? coverTypeList,
    List<String>? garageTypeList,
    String? province = '',
    int? minSumInsured,
    int? maxSumInsured,
    int? minGrossTotal,
    int? maxGrossTotal,
    List<String>? driverBehaviorList,
    String? customerType = '',
    String? nationalThaiId = '',
  }) =>
      _post(
        '$_base/api/insurance/get_package',
        {
          'driver': driver,
          'brand_code': brandCode,
          'model_code': modelCode,
          'year': year,
          'vehicle_usage': vehicleUsage,
          'cover_type': coverTypeList ?? const <String>[],
          'garage_type': garageTypeList ?? const <String>[],
          'province': province,
          'min_sum_insured': minSumInsured,
          'max_sum_insured': maxSumInsured,
          'min_gross_total': minGrossTotal,
          'max_gross_total': maxGrossTotal,
          'driver_behavior': driverBehaviorList ?? const <String>[],
          'customer_type': customerType,
          'national_thai_id': nationalThaiId,
        },
        PackageSearchResult.fromCarJson,
      );

  /// TelePackageSearchMCAPICall (MC, spec 05).
  Future<ApiResult<PackageSearchResult>> searchPackagesMc({
    String? brandCode = '',
    String? modelCode = '',
    String? year = '',
    String? vehicleUsage = '',
    List<String>? coverTypeList,
    List<String>? garageTypeList,
    String? province = '',
    String? nationalThaiId = '',
    String? customerType = '',
  }) =>
      _post(
        '$_base/api/insurance/get_package_mc',
        {
          'brand_code': brandCode,
          'model_code': modelCode,
          'year': year,
          'vehicle_usage': vehicleUsage,
          'cover_type': coverTypeList ?? const <String>[],
          'garage_type': garageTypeList ?? const <String>[],
          'province': province,
          'national_thai_id': nationalThaiId,
          'customer_type': customerType,
        },
        PackageSearchResult.fromMcJson,
      );

  /// IbsQuotationsSaveCall (spec 08). Bearer = session token (also echoed in
  /// the body as `token`).
  Future<ApiResult<QuotationSaveResult>> saveQuotation(QuotationSaveRequest request) {
    final token = UserSession.instance.accessToken;
    return _post(
      '$_base/api/quotations/save',
      request.toJson(token: token, insuranceUrl: _base),
      QuotationSaveResult.fromJson,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  /// GetDateTimeAPICall (spec 06/07 weekend check) — on the *local* API base,
  /// body status in `$.status` (→ [ApiResult.code]).
  Future<ApiResult<ServerDateTime>> getServerDateTime() {
    final base = AppEnvironment.current.localApiBase;
    return _post(
      '$base/api/check-in/getdate-time',
      {'token': UserSession.instance.accessToken, 'api_url': base},
      ServerDateTime.fromJson,
      headers: {'Authorization': _kGetDateTimeBasicAuth},
      codeKey: 'status',
    );
  }

  Future<ApiResult<T>> _post<T>(
    String url,
    Map<String, dynamic> body,
    T Function(dynamic json) parse, {
    Map<String, String> headers = const {},
    String codeKey = 'code',
  }) async {
    final res = await _client.postJson(url, body, headers: headers);
    final json = res.json;
    T? data;
    if (json != null) {
      try {
        data = parse(json);
      } catch (e) {
        if (kDebugMode) debugPrint('[SearchPackageApi] parse failed for $url: $e');
      }
    }
    return ApiResult<T>(
      statusCode: res.statusCode,
      code: codeKey == 'code' ? res.code : jsonInt(jsonAt(json, codeKey)),
      message: res.message,
      data: data,
    );
  }
}
