import 'package:flutter/foundation.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/user_session.dart';
import '../../search_package/models/json_read.dart';
import '../models/lead_detail_item.dart';
import '../models/lead_history.dart';
import '../models/quotation_lead.dart';

/// Outcome of one lead / quotation-file API call. These endpoints use a
/// different envelope from the search-package ones:
///
/// * [status1] / [message1] — `$.statusCode` / `$.statusMessage`
/// * [status2] / [message2] — `$.results.statusCode` / `$.results.statusMessage`
///
/// [httpStatus] is the HTTP status, or -1 when no response arrived.
class LeadApiResult<T> {
  const LeadApiResult({
    required this.httpStatus,
    this.status1,
    this.message1,
    this.status2,
    this.message2,
    this.data,
  });

  final int httpStatus;
  final int? status1;
  final String? message1;
  final int? status2;
  final String? message2;
  final T? data;

  bool get isHttpOk => httpStatus == 200;
}

/// The FF call classes the quotation list / MakeInsuranceListPage use. All
/// are reads (no records are created). Bearer = session token, as in FF.
class LeadApi {
  LeadApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  static final LeadApi instance = LeadApi();

  final ApiClient _client;

  String get _base => AppEnvironment.current.insuranceApiBase;

  /// InsuranceRequestListAPICall (`/api/lead/get-lead-list`). The quotation
  /// list page sends `mode: 'arunsawad'`, `list: 'quotation'`.
  Future<LeadApiResult<QuotationLeadList>> getLeadList({
    String mode = 'arunsawad',
    String list = 'quotation',
  }) =>
      _post(
        '$_base/api/lead/get-lead-list',
        {'owner_id': UserSession.instance.employeeId, 'mode': mode, 'list': list},
        QuotationLeadList.fromJson,
      );

  /// InsuranceRequestListAPIDashBoardCall (`/api/lead/get-lead-by-id`).
  /// 'ทำประกัน' sends `list: FFAppState().typeList` (always `'list'`) and
  /// leaves `search_by` / `search` at their `''` defaults.
  Future<LeadApiResult<LeadByIdResult>> getLeadById({
    required String leadId,
    String mode = 'arunsawad',
    String list = 'list',
    String searchBy = '',
    String search = '',
  }) =>
      _post(
        '$_base/api/lead/get-lead-by-id',
        {'lead_id': leadId, 'mode': mode, 'list': list, 'search_by': searchBy, 'search': search},
        LeadByIdResult.fromJson,
      );

  /// GetFileVmiApiCall → `$.VMI_documentUrl`.
  Future<LeadApiResult<String>> getFileVmi(String quotationId) => _post(
        '$_base/api/quotations/get-file-vmi',
        {'quotation_id': quotationId, 'owner_id': UserSession.instance.employeeId},
        (j) => jsonAt(j, 'VMI_documentUrl')?.toString() ?? '',
      );

  /// GetFileCmiApiCall → `$.CMI_documentUrl`.
  Future<LeadApiResult<String>> getFileCmi(String quotationId) => _post(
        '$_base/api/quotations/get-file-cmi',
        {'quotation_id': quotationId, 'owner_id': UserSession.instance.employeeId},
        (j) => jsonAt(j, 'CMI_documentUrl')?.toString() ?? '',
      );

  /// GetNonePackageHistoryAPICall (`/api/lead/get-history`).
  Future<LeadApiResult<List<LeadHistoryEntry>>> getHistory(String quotationId) => _post(
        '$_base/api/lead/get-history',
        {'quotation_id': quotationId},
        LeadHistoryEntry.listFromJson,
      );

  Future<LeadApiResult<T>> _post<T>(
    String url,
    Map<String, dynamic> body,
    T Function(dynamic json) parse,
  ) async {
    final res = await _client.postJson(
      url,
      body,
      headers: {'Authorization': 'Bearer ${UserSession.instance.accessToken}'},
    );
    final json = res.json;
    T? data;
    if (json != null) {
      try {
        data = parse(json);
      } catch (e) {
        if (kDebugMode) debugPrint('[LeadApi] parse failed for $url: $e');
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
