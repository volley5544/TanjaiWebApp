import '../models/application_detail.dart';

/// Step 4 (payment documents) + 4.1 (payment type).
///
/// Owned by `step4/`. Filled from the application detail by [loadFromDetail]
/// (called by `PolicyRequestState.applyDetail`); edited by the step's pages.
class Step4Data {
  void reset() {}

  void loadFromDetail(ApplicationDetail d) {}
}
