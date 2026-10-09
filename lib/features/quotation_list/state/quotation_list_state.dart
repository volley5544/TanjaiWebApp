import 'package:flutter/foundation.dart';

import '../models/lead_detail_item.dart';

/// Flow state of the quotation list → MakeInsuranceListPage → QuotationCopy
/// pages (replaces the FFAppState fields / route params they used). Never
/// put in the URL; a page opened by refresh without it goes back to the list.
class QuotationListState extends ChangeNotifier {
  QuotationListState._();

  static final QuotationListState instance = QuotationListState._();

  /// FFAppState().searchList1 — list filter on `quotation_type`:
  /// `'0'` = all, `'manual'`, `'auto'` (set by the legend sheet).
  String searchList1 = '0';

  /// MakeInsuranceListPage params. `null` [detailItems] = not opened from
  /// the list in this session.
  List<LeadDetailItem>? detailItems;
  int? checkTotal;
  String checkPayment = '0';
  String checkVmi = '0';

  /// FFAppState().searchQuotationStatus (reset to `'0'` when the page opens;
  /// only the dashboard entry point's filter ever changes it).
  String searchQuotationStatus = '0';

  /// QuotationCopy `quotation` param (PDF / image URLs).
  List<String>? quotationCopyUrls;

  void openDetail({
    required List<LeadDetailItem> items,
    required int? checkTotal,
    String checkPayment = '0',
    String checkVmi = '0',
  }) {
    detailItems = items;
    this.checkTotal = checkTotal;
    this.checkPayment = checkPayment;
    this.checkVmi = checkVmi;
    notifyListeners();
  }

  void notify() => notifyListeners();
}
