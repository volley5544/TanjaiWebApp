import '../models/application_detail.dart';

/// Step 1 (customer: card, name, occupation, phones, addresses, broker licence).
///
/// Owned by `step1/`. Filled from the application detail by [loadFromDetail]
/// (called by `PolicyRequestState.applyDetail`); edited by the step's pages.
class Step1Data {
  void reset() {}

  void loadFromDetail(ApplicationDetail d) {}
}
