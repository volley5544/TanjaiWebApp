import '../models/application_detail.dart';

/// Step 3 (document / vehicle photos, consents).
///
/// Owned by `step3/`. Filled from the application detail by [loadFromDetail]
/// (called by `PolicyRequestState.applyDetail`); edited by the step's pages.
class Step3Data {
  void reset() {}

  void loadFromDetail(ApplicationDetail d) {}
}
