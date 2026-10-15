import '../../search_package/models/json_read.dart';

/// One fire quotation lead from `api/house/leads/get` → `$.results.data[:]`
/// (FF `FireGetLeadsApiCall`). FF read the list as parallel
/// `data[:].field` / `data[:].leads_detail_house[:].field` lists (a lead
/// with no detail shifted every later row); the port reads each lead's own
/// object and its first detail.
class FireLead {
  const FireLead({
    required this.raw,
    this.leadId,
    this.quotationId,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.insuranceType,
    this.quotationStatus,
    this.detail = const FireLeadDetail(),
    this.appDetail = const FireLeadDetail(),
  });

  /// The lead as received (FF passed it on as `makeJsonList(item)`).
  final Map<String, dynamic> raw;
  final String? leadId;
  final String? quotationId;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? insuranceType;
  final String? quotationStatus;

  /// First `leads_detail_house` entry.
  final FireLeadDetail detail;

  /// First `app_detail_house` entry (the detail page prefers it when set).
  final FireLeadDetail appDetail;

  static FireLead fromJson(Map<String, dynamic> j) {
    String? s(String key) => j[key] == null ? null : '${j[key]}';
    return FireLead(
      raw: j,
      leadId: s('lead_id'),
      quotationId: s('quotation_id'),
      firstName: s('first_name'),
      lastName: s('last_name'),
      phoneNumber: s('phone_number'),
      insuranceType: s('insurance_type'),
      quotationStatus: s('quotation_status'),
      detail: FireLeadDetail.firstOf(j['leads_detail_house']),
      appDetail: FireLeadDetail.firstOf(j['app_detail_house']),
    );
  }

  /// `$.results.data[:]`.
  static List<FireLead> listFromJson(dynamic json) => parseDataList(json, fromJson);

  /// FF `getJsonField(...).toString()` of a field: JSON null / missing →
  /// `'null'`.
  String text(String key) => jsonStrN(raw[key]);
}

/// A `leads_detail_house` / `app_detail_house` entry. Values are FF
/// `toString()`s: missing → `'null'`.
class FireLeadDetail {
  const FireLeadDetail([this._j = const {}]);

  final Map<dynamic, dynamic> _j;

  /// The first entry of a list, or the object itself.
  static FireLeadDetail firstOf(dynamic v) {
    if (v is List && v.isNotEmpty && v.first is Map) return FireLeadDetail(v.first as Map);
    if (v is Map) return FireLeadDetail(v);
    return const FireLeadDetail();
  }

  bool get isEmpty => _j.isEmpty;

  String _s(String key) => jsonStrN(_j[key]);

  String get image => _s('image');
  String get insurerName => _s('insurer_name');
  String get insurerStatus => _s('insurer_status');
  String get packageName => _s('package_name');
  String get sumInsured => _s('sum_insured');
  String get sumInsuredName => _s('sum_insured_name');
  String get netPremiumTotal => _s('net_premium_total');
  String get pdfQuotation => _s('pdf_quotation');
  String get leadsHouseDtlId => _s('leads_house_dtl_id');

  /// Raw value (null when missing) — the list page used FF
  /// `valueOrDefault`, which only falls back on null / ''.
  String? raw(String key) => _j[key] == null ? null : '${_j[key]}';
}
