import '../models/fire_lead.dart';

/// Fire quotation list → MakeFireInsuranceListPage → FireQuotationCopy flow
/// data (FF route params). Never in the URL; a page opened by refresh
/// without it goes back to the list.
class FireQuotationListState {
  FireQuotationListState._();

  static final FireQuotationListState instance = FireQuotationListState._();

  /// MakeFireInsuranceListPage `list` — the list sends the one lead tapped
  /// ('ทำประกัน': `makeJsonList(item)`, checkPayment / checkVMI '0',
  /// checkTotal 1).
  List<FireLead>? detailLeads;

  /// FireQuotationCopy `quotation` param.
  List<String>? quotationCopyUrls;
}
