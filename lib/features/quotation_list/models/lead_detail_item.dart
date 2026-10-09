import '../../search_package/models/json_read.dart';

/// One card of MakeInsuranceListPage — an item of `get-lead-by-id`
/// `$.results.info.watingInfo[:]` (sic, the API's spelling).
///
/// FF read each field with `getJsonField(item, r'$.x').toString()`, which
/// gives the literal `'null'` for a missing / null field; the getters keep
/// that (several visibility checks compare against `''`, so `'null'` counts
/// as "present", as in FF).
class LeadDetailItem {
  const LeadDetailItem(this._json);

  factory LeadDetailItem.fromJson(Map<String, dynamic> json) => LeadDetailItem(json);

  final Map<String, dynamic> _json;

  String _s(String key) => jsonStrN(_json[key]);

  String get image => _s('image');
  String get insurerName => _s('insurer_name');
  String get insurerShortName => _s('insurer_short_name');
  String get insurerStatus => _s('insurer_status');
  String get insurerRemark => _s('insurer_remark');
  String get firstName => _s('first_name');
  String get lastName => _s('last_name');
  String get subProduct => _s('sub_product');
  String get subProductName => _s('sub_product_name');
  String get coverTypeName => _s('cover_type_name');
  String get garageTypeName => _s('garage_type_name');
  String get sumInsured => _s('sum_insured');
  String get actTotal => _s('act_total');
  String get grossTotalNet => _s('gross_total_net');
  String get quotationStatus => _s('quotation_status');
  String get quotationType => _s('quotation_type');
  String get quotationTypeName => _s('quotation_type_name');
  String get quotationTypeBakName => _s('quotation_type_bak_name');
  String get quotationId => _s('quotation_id');
  String get leadId => _s('lead_id');
  int? get leadDtlId => jsonInt(_json['lead_dtl_id']);
  String get paymentStatus => _s('payment_status');
  String get pdfQuotationText => _s('pdf_quotation');
  String get flgAct => _s('flg_act');
  String get isActive => _s('is_active');
  String get vmiDocumentUrl => _s('VMI_documentUrl');

  /// `payment_status_check` / `_sec` are JSON booleans (FF used them as such).
  bool get paymentStatusCheck => _json['payment_status_check'] == true;
  bool get paymentStatusCheckSec => _json['payment_status_check_sec'] == true;

  /// The QuotationCopy page's `quotation` param:
  /// `getJsonField(item, r'$.pdf_quotation', true)` — a single string becomes
  /// a one-element list, a list stays a list, null → empty.
  List<String> get pdfQuotationList {
    final v = _json['pdf_quotation'];
    if (v == null) return const [];
    if (v is List) return [for (final e in v) '$e'];
    return ['$v'];
  }

  bool get isCmi => subProduct == 'CMI';
  bool get isManual => quotationType == 'manual';
}

/// `get-lead-by-id` body: `results.counting.status_waiting_info` (FF's
/// `checkTotal`) and `results.info.watingInfo` (the cards).
class LeadByIdResult {
  const LeadByIdResult({
    required this.waitingInfoCount,
    required this.waitingInfo,
    required this.videoUrls,
  });

  final int? waitingInfoCount;
  final List<LeadDetailItem> waitingInfo;

  /// `$.results.info.watingInfo[:].video_url`.
  final List<String> videoUrls;

  static LeadByIdResult fromJson(dynamic json) {
    final results = jsonAt(json, 'results');
    final waiting = jsonAt(jsonAt(results, 'info'), 'watingInfo');
    final items = [
      for (final e in jsonChildren(waiting))
        if (e is Map) Map<String, dynamic>.from(e),
    ];
    return LeadByIdResult(
      waitingInfoCount: jsonInt(jsonAt(jsonAt(results, 'counting'), 'status_waiting_info')),
      waitingInfo: [for (final e in items) LeadDetailItem.fromJson(e)],
      videoUrls: [
        for (final e in items)
          if (e['video_url'] != null) '${e['video_url']}',
      ],
    );
  }
}
