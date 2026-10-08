import 'package:flutter/material.dart';

import '../state/search_package_state.dart';
import 'search_form/search_pickers.dart';
import 'vehicle_type_card.dart';

/// เลือกประเภทรถกระบะ 2 ประตู — 2-door pick-up sub-type picker (FF
/// SearchablePickUpListPage, fromPage 'searchPackage' path only, spec 13).
///
/// Opened by [CarTypePage] *replacing* itself, so back / a selection returns
/// to the search page. Back without picking keeps what CarTypePage wrote
/// (รถกระบะ / PICKUP / filtered brands) — FF behaviour.
class PickupTypePage extends StatelessWidget {
  const PickupTypePage({super.key, required this.state});

  final SearchPackageState state;

  void _select(BuildContext context, String label, String contain) {
    state.vehicleTypeLabel = label;
    state.checkFilled[0] = true;
    state.carTypeDetailSelected = label;
    state.carTypeContain = contain;
    state.carTypeDoors = '2 Doors';
    resetBrandAndModel(state);
    state.notify();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return VehicleTypePickerScaffold(
      title: 'เลือกประเภทรถกระบะ 2 ประตู',
      cards: [
        VehicleTypeCard(
          label: 'กระบะไม่ต่อเติม',
          image: 'assets/images/pickup_no_extension.png',
          imageWidth: 100,
          imageRightPadding: 16,
          onTap: () => _select(context, 'กระบะไม่ต่อเติม', '-'),
        ),
        VehicleTypeCard(
          label: 'กระบะต่อเติมเกินหัวเก๋ง',
          image: 'assets/images/pickup_extension_above_cab.png',
          imageWidth: 130,
          imageRightPadding: 0,
          onTap: () => _select(context, 'กระบะต่อเติมเกินหัวเก๋ง', 'ต่อเติมเกินหัวเก๋ง'),
        ),
        VehicleTypeCard(
          label: 'กระบะต่อเติมไม่เกินหัวเก๋ง',
          image: 'assets/images/pickup_extension_below_cab.png',
          imageWidth: 130,
          imageRightPadding: 0,
          onTap: () => _select(context, 'กระบะต่อเติมไม่เกินหัวเก๋ง', 'ต่อเติมไม่เกินหัวเก๋ง'),
        ),
        VehicleTypeCard(
          label: 'กระบะตู้ทึบ/ตู้แห้ง',
          image: 'assets/images/pickup_box.png',
          imageWidth: 100,
          imageRightPadding: 16,
          // FF searchPackage value has no slash (NonePackage had one) — kept.
          onTap: () => _select(context, 'กระบะตู้ทึบ/ตู้แห้ง', 'ตู้ทึบตู้แห้ง'),
        ),
      ],
    );
  }
}
