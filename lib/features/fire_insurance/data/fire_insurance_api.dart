import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/user_session.dart';
import '../../search_package/data/api_result.dart';
import '../../search_package/models/json_read.dart';
import '../models/fire_package.dart';

/// FF `HouseInsuranceGroup` calls used by the fire search-package flow, on the
/// insurance API base of the build's environment.
class FireInsuranceApi {
  FireInsuranceApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  static final FireInsuranceApi instance = FireInsuranceApi();

  final ApiClient _client;

  String get _base => AppEnvironment.current.insuranceApiBase;

  /// HouseCalEstimatedApiCall — estimated building value (สิ่งปลูกสร้าง).
  /// [houseAreaType] `'01'` = width × length, `'02'` = square metres.
  ///
  /// FF's floor picker sent this one to the hard-coded UAT host even in prod;
  /// the port always uses the environment's host.
  Future<ApiResult<HouseEstimate>> calEstimated({
    required String houseAreaType,
    required String houseTypeCode,
    required String usableArea,
    required String floor,
    required String width,
    required String length,
  }) {
    return _post(
      '$_base/api/house/cal-estimated',
      {
        'house_area_type': houseAreaType,
        'house_type_code': houseTypeCode,
        'usable_area': usableArea,
        'floor': floor,
        'width': width,
        'length': length,
      },
      (json) => HouseEstimate.fromJson(Map<String, dynamic>.from(resultsData(json) as Map)),
      headers: {'Authorization': 'Bearer ${UserSession.instance.accessToken}'},
    );
  }

  /// GetPackageFireInsuranceCall — packages for a total sum insured.
  Future<ApiResult<List<FirePackage>>> getPackages({
    required String yearCoverMin,
    required String yearCoverMax,
    required String sumInsured,
  }) {
    return _post(
      '$_base/api/insurance/house/get_package?flag_get=1',
      {'year_cover_min': yearCoverMin, 'year_cover_max': yearCoverMax, 'sum_insured': sumInsured},
      (json) => parseDataList(json, FirePackage.fromJson),
    );
  }

  /// SaveQuotationCall — multipart; `insurer_package` is a JSON list holding
  /// the chosen package (FF `returnListDataType(package.toMap())`).
  Future<ApiResult<FireQuotationSaveResult>> saveQuotation({
    required FirePackage package,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String sumInsureHouse,
    required String sumInsureBuildin,
    required String sumInsureTotal,
    required String floor,
    required String width,
    required String length,
    required String usableArea,
    required String houseTypeCode,
    required String houseTypeName,
  }) async {
    final session = UserSession.instance;
    final token = session.accessToken;
    final res = await _client.postMultipart(
      '$_base/api/house/quotations/save',
      {
        'insurer_package': jsonEncode([package.toMap()]),
        'sub_product': 'House',
        'owner_id': session.employeeId,
        'token': token,
        'first_name': firstName,
        'phone_number': phoneNumber,
        // FF: profileFullName / ProfilePhoneNumber / profileBranch /
        // profileUnitCodeName, handed over as the page's userProfileData.
        'owner_name': '${session.firstName} ${session.lastName}'.trim(),
        'owner_phone': session.phone,
        'branch_code': session.branchCode,
        'branch_name': session.branchName,
        'sum_insure_house': sumInsureHouse,
        'sum_insure_buildin': sumInsureBuildin,
        'sum_insure_total': sumInsureTotal,
        'floor': floor,
        'width': width,
        'length': length,
        'usable_area': usableArea,
        'house_type_code': houseTypeCode,
        'house_type_name': houseTypeName,
        'last_name': lastName,
      },
      headers: {'Authorization': 'Bearer $token'},
    );
    return _result(res, FireQuotationSaveResult.fromJson);
  }

  Future<ApiResult<T>> _post<T>(
    String url,
    Map<String, dynamic> body,
    T Function(dynamic json) parse, {
    Map<String, String> headers = const {},
  }) async {
    final res = await _client.postJson(url, body, headers: headers);
    return _result(res, parse);
  }

  ApiResult<T> _result<T>(ApiResponse res, T Function(dynamic json) parse) {
    T? data;
    if (res.json != null) {
      try {
        data = parse(res.json);
      } catch (e) {
        if (kDebugMode) debugPrint('[FireInsuranceApi] parse failed: $e');
      }
    }
    return ApiResult<T>(statusCode: res.statusCode, code: res.code, message: res.message, data: data);
  }
}
