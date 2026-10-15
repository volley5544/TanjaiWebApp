import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/loading_scene.dart';
import '../../router/app_router.dart';
import '../search_package/product_type.dart';
import '../search_package/state/search_package_state.dart';
import 'data/manual_request_api.dart';
import 'state/none_package_state.dart';

/// 'นอกเรท' on the work-select page ([gated]: copy only the search fields the
/// user filled) or the result pages (copy all). Both open `workType: 'ev'`
/// for EV (FF work-select lost it — it never received fromIcon; fixed).
void startManualRequestFromSearch(
  BuildContext context,
  SearchPackageState st, {
  required bool gated,
  required String workType,
}) {
  NonePackageState.instance.startNew(
    workType: workType,
    fromMenu: st.product == ProductType.ev ? 'EV' : 'motor',
    gated: gated,
    checkFilled: st.checkFilled,
    vehicleTypeLabel: st.vehicleTypeLabel,
    brand: st.selectedBrand,
    model: st.selectedModel,
    brandModels: st.models,
    yearBE: st.yearBE,
    usage: st.selectedUsage,
    oldPolicyExpiry: st.oldPolicyExpiry,
    vehicleGroup: st.vehicleGroup,
    carTypeContain: st.carTypeContain,
    carTypeDoors: st.carTypeDoors,
  );
  context.push(AppRoutes.manualReason);
}

/// Quotation list 'คัดลอก' (copy → new request form) and 'แก้ไข' (edit the
/// request's photos): load `get-lead-detail`, fill the flow state, open.
Future<void> openManualLead(BuildContext context, {required String leadId, required bool edit}) async {
  final r = await withLoading(context, () => ManualRequestApi.instance.getLeadDetail(leadId));
  if (!context.mounted) return;
  // FF: no HTTP check (a transport error showed '(null)'); the edit dialog
  // has no space before '(' — both kept.
  final gap = edit ? '' : ' ';
  if (r.status1 != 200) {
    await showAlert(context, 'กรุณาติดต่อเจ้าหน้าที่$gap(${r.message1})', title: 'พบข้อผิดพลาด');
    return;
  }
  if (r.status2 != 200 || r.data == null) {
    await showAlert(context, 'กรุณาติดต่อเจ้าหน้าที่$gap(${r.message2})', title: 'พบข้อผิดพลาด');
    return;
  }
  final s = NonePackageState.instance;
  if (edit) {
    s.startEdit(r.data!);
    context.push(AppRoutes.manualEdit);
  } else {
    s.startCopy(r.data!);
    context.push(AppRoutes.manualBasic);
  }
}
