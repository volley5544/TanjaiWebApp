import '../../search_package/models/json_read.dart';

/// One card of the quotation list — an item of `get-lead-list`
/// (`list: 'quotation'`) `$.results.info[:]`.
///
/// FF read every field as a separate `$.results.info[:].x` list with
/// `.withoutNulls`, so a null field shifted that column against the others;
/// here each card reads its own object, and a JSON null stays null (the
/// pages run those through `checkNullValueAndReturn` / `valueOrDefault`, both
/// of which show '-').
class QuotationLead {
  const QuotationLead(this._json);

  factory QuotationLead.fromJson(Map<String, dynamic> json) => QuotationLead(json);

  final Map<String, dynamic> _json;

  String? _s(String key) {
    final v = _json[key];
    return v == null ? null : '$v';
  }

  int? get leadId => jsonInt(_json['lead_id']);
  String? get firstName => _s('first_name');
  String? get lastName => _s('last_name');
  String? get phoneNumber => _s('phone_number');
  String? get quotationType => _s('quotation_type');
  String? get quotationTypeBak => _s('quotation_type_bak');
  String? get quotationTypeBakName => _s('quotation_type_bak_name');
  String? get quotationTypeName => _s('quotation_type_name');
  String? get subProductName => _s('sub_product_name');
  String? get quotationDate => _s('quotation_date');
  String? get expireDate => _s('expire_date');
  String? get quotationStatus => _s('quotation_status');
  String? get quotationNo => _s('quotation_no');
  int? get flagExpired => jsonInt(_json['flag_expired']);
  String? get flagRenew => _s('flg_renew');
  String? get refRenewId => _s('ref_renew_id');
}

/// `get-lead-list` body: `results.statusCode` 200 = rows, 404 = none.
class QuotationLeadList {
  const QuotationLeadList({required this.leads});

  final List<QuotationLead> leads;

  static QuotationLeadList fromJson(dynamic json) => QuotationLeadList(leads: [
        for (final e in jsonChildren(jsonAt(jsonAt(json, 'results'), 'info')))
          if (e is Map) QuotationLead.fromJson(Map<String, dynamic>.from(e)),
      ]);
}
