import '../data/policy_request_api.dart';

/// `IbsApplicationsDetailCall` → `$.results.data`, read the way the FF pages
/// did, but per object instead of FF's parallel `[:]` lists.
///
/// Two string readers mirror the two FF idioms:
/// * [ff] — `'${getJsonField(...)}'`: JSON null / missing → **`'null'`**;
/// * [s]  — null-safe: JSON null / missing → `''`.
/// The page specs say which one each field used; prefer [s] when FF's
/// `'null'` only caused bugs (and comment it).
///
/// [leadDetail] is the `leads_detail[]` entry whose `lead_dtl_id` equals the
/// page's lead-detail id (FF `getIndexOfIntList(...)`; not found → FF read
/// index -1 → `'null'` values → here an empty map).
class ApplicationDetail {
  ApplicationDetail(this.json, {required this.leadDtlId});

  /// The whole response body (`$`), kept for paths outside `results.data`.
  final dynamic json;
  final int? leadDtlId;

  Map<String, dynamic> get data => _map(jsonPathGet(json, 'results.data'));

  /// `results.data.<path>` (dotted, `[n]` allowed). Raw value.
  dynamic at(String path) => jsonPathGet(data, path);

  /// FF `'${value}'` — null → `'null'`.
  String ff(String path) => '${at(path)}';

  /// Null-safe string — null → `''`.
  String s(String path) {
    final v = at(path);
    return v == null ? '' : '$v';
  }

  /// `leads[0]`.
  Map<String, dynamic> get lead => _first(data['leads']);

  /// `app_detail[0]` (FF `app_detail[:]` single-value getters read the first).
  Map<String, dynamic> get appDetail => _first(data['app_detail']);

  /// `app_document[0]`.
  Map<String, dynamic> get appDocument => _first(data['app_document']);

  /// `quotations`.
  Map<String, dynamic> get quotations => _map(data['quotations']);

  /// `payments[0]`.
  Map<String, dynamic> get payment => _first(data['payments']);

  /// `app_address[]`.
  List<Map<String, dynamic>> get addresses => _list(data['app_address']);

  /// `leads_detail[]`.
  List<Map<String, dynamic>> get leadDetails => _list(data['leads_detail']);

  /// The selected `leads_detail[]` entry (see class doc).
  Map<String, dynamic> get leadDetail {
    for (final d in leadDetails) {
      if (_int(d['lead_dtl_id']) == leadDtlId) return d;
    }
    return const {};
  }

  /// `quotations.quotation_type_bak` — FF `insuranceInfoApplicationType`
  /// ('auto' = in-package).
  String get applicationType => s('quotations.quotation_type_bak');

  /// `leads[0].sub_product` — FF `insuranceinfoActType`: 'Motor' (car and
  /// EV), 'MC', 'CMI', 'House'.
  String get subProduct => '${lead['sub_product'] ?? ''}';

  /// `ev_flag` (data) or the lead's.
  String get evFlag {
    final v = s('ev_flag');
    return v.isNotEmpty ? v : '${lead['ev_flag'] ?? ''}';
  }

  /// FF-style string of a map entry: null → `'null'`.
  static String ffOf(Map<String, dynamic> m, String key) => '${m[key]}';

  /// Null-safe string of a map entry: null → `''`.
  static String sOf(Map<String, dynamic> m, String key) => m[key] == null ? '' : '${m[key]}';

  static Map<String, dynamic> _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : const {};
  static Map<String, dynamic> _first(dynamic v) {
    if (v is List && v.isNotEmpty && v.first is Map) return Map<String, dynamic>.from(v.first as Map);
    if (v is Map) return Map<String, dynamic>.from(v);
    return const {};
  }

  static List<Map<String, dynamic>> _list(dynamic v) => [
        if (v is List)
          for (final e in v)
            if (e is Map) Map<String, dynamic>.from(e),
      ];

  static int? _int(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');
}
