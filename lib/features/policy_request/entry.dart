import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import 'state/policy_request_state.dart';

/// Entry points into the request-policy flow (FF `in_package_insurance`).
/// The ids go into [PolicyRequestState], never into the URL. [replace] =
/// FF `goNamed` (stack replaced); otherwise `pushNamed`.

/// FF `insuranceInfoPage1(quotationId, leadDtailId, fromPage)`.
void openRequestStep1(
  BuildContext context, {
  required String quotationId,
  required int? leadDtlId,
  String fromPage = '',
  bool replace = false,
}) {
  PolicyRequestState.instance.start(quotationId: quotationId, leadDtlId: leadDtlId, fromPage: fromPage);
  replace ? context.go(AppRoutes.requestCustomer) : context.push(AppRoutes.requestCustomer);
}

/// FF `insuranceInfoPage42(quotationId, leadDetailId)` — payment.
void openRequestPayment(BuildContext context, {required String quotationId, required int? leadDtlId, bool replace = false}) {
  PolicyRequestState.instance.start(quotationId: quotationId, leadDtlId: leadDtlId);
  replace ? context.go(AppRoutes.requestPayment) : context.push(AppRoutes.requestPayment);
}

/// FF `insuranceInfoPage5(quotationId, leadDtlId, fromPage)` — status.
void openRequestStatus(
  BuildContext context, {
  required String quotationId,
  required int? leadDtlId,
  String fromPage = '',
  bool replace = false,
}) {
  PolicyRequestState.instance.start(quotationId: quotationId, leadDtlId: leadDtlId, fromPage: fromPage);
  replace ? context.go(AppRoutes.requestStatus) : context.push(AppRoutes.requestStatus);
}
