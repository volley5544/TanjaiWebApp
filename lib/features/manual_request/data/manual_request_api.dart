import 'package:flutter/foundation.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/config/local_api_auth.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/user_session.dart';
import '../../quotation_list/data/lead_api.dart';
import '../../search_package/models/json_read.dart';
import '../models/lead_detail.dart';
import '../state/none_package_state.dart';

/// One branch of the local API's `check-in/location`.
class NpBranch {
  const NpBranch(this.code, this.name);

  final String code;
  final String name;
}

/// The manual-request ("none-package") endpoints. Master data (provinces,
/// usages, brands, models, cover types) comes from `SearchPackageApi`.
///
/// Envelopes differ per endpoint, as in FF: `get_insurers_all` uses
/// `$.code` / `$.message` (→ [LeadApiResult.status1] / `message1`); save /
/// edit / lead-detail use `$.statusCode` + `$.results.statusCode`.
class ManualRequestApi {
  ManualRequestApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  static final ManualRequestApi instance = ManualRequestApi();

  final ApiClient _client;

  String get _base => AppEnvironment.current.insuranceApiBase;

  Map<String, String> get _bearer => {'Authorization': 'Bearer ${UserSession.instance.accessToken}'};

  /// InsuranceRequestDetailAPICall (`/api/lead/get-lead-detail`).
  Future<LeadApiResult<LeadDetail>> getLeadDetail(String leadId) async {
    final res = await _client.postJson('$_base/api/lead/get-lead-detail', {'lead_id': leadId}, headers: _bearer);
    return _result(res, LeadDetail.fromJson);
  }

  /// InsuranceRequestGetInsurerAPICall (`/api/insurance/master/get_insurers_all`,
  /// unauthenticated). [status1] = `$.code`, [message1] = `$.message`.
  Future<LeadApiResult<List<NpInsurer>>> getInsurers({required String vehicleGroup}) async {
    final res = await _client.postJson('$_base/api/insurance/master/get_insurers_all', {'vehicle_group': vehicleGroup});
    final json = res.json;
    return LeadApiResult(
      httpStatus: res.statusCode,
      status1: jsonInt(jsonAt(json, 'code')),
      message1: jsonAt(json, 'message')?.toString(),
      data: [
        for (final e in jsonChildren(resultsData(json)))
          if (e is Map)
            NpInsurer(
              id: jsonStr(e['company_id']),
              code: jsonStr(e['code']),
              shortName: jsonStr(e['short_name']),
              fullName: jsonStr(e['full_name']),
              listName: jsonStr(e['list_name']),
            ),
      ],
    );
  }

  /// InsuranceRequestSendEmailAPICall (`/api/manual-insurance/save`,
  /// multipart text fields). Creates the request and emails the insurers.
  Future<LeadApiResult<void>> saveRequest(Map<String, String> fields) async {
    final res = await _client.postMultipart('$_base/api/manual-insurance/save', fields, headers: _bearer);
    return _result(res, (_) {});
  }

  /// InsuranceRequestEditAPICall (`/api/manual-insurance/edit`, multipart).
  Future<LeadApiResult<void>> editRequest(Map<String, String> fields) async {
    final res = await _client.postMultipart('$_base/api/manual-insurance/edit', fields, headers: _bearer);
    return _result(res, (_) {});
  }

  /// GetlocationAPICall (local API `check-in/location`): branches.
  /// [status1] = `$.Detail.status`.
  Future<LeadApiResult<List<NpBranch>>> getBranches() async {
    final base = AppEnvironment.current.localApiBase;
    final res = await _client.postJson(
      '$base/api/check-in/location',
      {'token': UserSession.instance.accessToken, 'branch': '', 'api_url': base},
      headers: {'Authorization': kLocalApiBasicAuth},
    );
    final detail = jsonAt(res.json, 'Detail');
    return LeadApiResult(
      httpStatus: res.statusCode,
      status1: jsonInt(jsonAt(detail, 'status')),
      data: [
        for (final e in jsonChildren(jsonAt(detail, 'Location')))
          if (e is Map) NpBranch(jsonStr(e['BRANCH_CODE']), jsonStr(e['BRANCH_NAME'])),
      ],
    );
  }

  LeadApiResult<T> _result<T>(ApiResponse res, T? Function(dynamic) parse) {
    final json = res.json;
    T? data;
    if (json != null) {
      try {
        data = parse(json);
      } catch (e) {
        if (kDebugMode) debugPrint('[ManualRequestApi] parse failed: $e');
      }
    }
    final results = jsonAt(json, 'results');
    return LeadApiResult<T>(
      httpStatus: res.statusCode,
      status1: jsonInt(jsonAt(json, 'statusCode')),
      message1: jsonAt(json, 'statusMessage')?.toString(),
      status2: jsonInt(jsonAt(results, 'statusCode')),
      message2: jsonAt(results, 'statusMessage')?.toString(),
      data: data,
    );
  }
}
