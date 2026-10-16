import '../models/application_detail.dart';

/// Step 4.2 payment (full / installment plan, QR refs, effective dates).
///
/// Owned by `payment/`. Filled from the application detail by [loadFromDetail]
/// (called by `PolicyRequestState.applyDetail`); edited by the step's pages.
class PaymentData {
  void reset() {}

  void loadFromDetail(ApplicationDetail d) {}
}
