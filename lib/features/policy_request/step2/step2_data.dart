import '../models/application_detail.dart';

/// Step 2 (vehicle: plate, chassis, engine, seats, cc, branch, effective dates, accessories, พ.ร.บ., beneficiary).
///
/// Owned by `step2/`. Filled from the application detail by [loadFromDetail]
/// (called by `PolicyRequestState.applyDetail`); edited by the step's pages.
class Step2Data {
  void reset() {}

  void loadFromDetail(ApplicationDetail d) {}
}
