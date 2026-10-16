import '../models/application_detail.dart';

/// Step 5 (policy status / documents / cancel).
///
/// Owned by `step5/`. Filled from the application detail by [loadFromDetail]
/// (called by `PolicyRequestState.applyDetail`); edited by the step's pages.
class Step5Data {
  void reset() {}

  void loadFromDetail(ApplicationDetail d) {}
}
