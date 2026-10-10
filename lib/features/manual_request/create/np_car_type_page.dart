import 'package:flutter/material.dart';

import '../../search_package/shared/vehicle_type_card.dart';
import '../state/none_package_state.dart';

/// FF SearchableCarListPage with `fromPage: 'NonePackage'` (spec basic_page
/// §4.2): same cards as the search package, but every type is selectable
/// and the choice goes into [NonePackageState]. Picking a type does not
/// clear brand / model (FF).
class NpCarTypePage extends StatelessWidget {
  const NpCarTypePage({super.key});

  static Future<void> open(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NpCarTypePage()));
  }

  NonePackageState get _s => NonePackageState.instance;

  /// FF filterBrands(): brands whose `car_group` contains the vehicle group.
  void _filterBrands() {
    _s.brands = [for (final b in _s.brandsOriginal) if (b.carGroup.contains(_s.vehicleGroup)) b];
  }

  void _select(
    BuildContext context, {
    required String type,
    required String detail,
    String? group,
    String? contain,
    String? doors,
  }) {
    _s
      ..vehicleType = type
      ..vehicleTypeDetail = detail;
    if (group != null) {
      _s.vehicleGroup = group;
      if (contain != null) _s.carTypeContain = contain;
      if (doors != null) _s.carTypeDoors = doors;
      _filterBrands();
    }
    _s.notify();
    Navigator.of(context).pop();
  }

  void _pickup2Doors(BuildContext context) {
    _s
      ..vehicleType = pickup
      ..vehicleTypeDetail = 'รถกระบะ 2 ประตู'
      ..vehicleGroup = 'PICKUP';
    _filterBrands();
    _s.notify();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const NpPickupTypePage()));
  }

  @override
  Widget build(BuildContext context) {
    return VehicleTypePickerScaffold(
      title: 'เลือกประเภทรถ',
      cards: [
        VehicleTypeCard(
          label: 'รถเก๋ง',
          image: 'assets/images/car_sedan.png',
          imageWidth: 90,
          imageRightPadding: 20,
          onTap: () => _select(context, type: 'รถเก๋ง', detail: 'รถเก๋ง', group: 'OTHER', contain: '-', doors: '-'),
        ),
        VehicleTypeCard(
          label: 'รถตู้',
          image: 'assets/images/car_van.png',
          imageWidth: 90,
          imageRightPadding: 20,
          onTap: () => _select(context, type: 'รถตู้', detail: 'รถตู้', group: 'VAN', contain: '-', doors: '-'),
        ),
        VehicleTypeCard(
          label: 'รถกระบะ 2 ประตู',
          image: 'assets/images/car_pickup_2_doors.png',
          imageWidth: 90,
          imageRightPadding: 20,
          onTap: () => _pickup2Doors(context),
        ),
        VehicleTypeCard(
          label: 'รถกระบะ 4 ประตู',
          image: 'assets/images/car_pickup_4_doors.png',
          imageWidth: 90,
          imageRightPadding: 20,
          onTap: () => _select(context,
              type: pickup, detail: 'รถกระบะ 4 ประตู', group: 'PICKUP', contain: '-', doors: '4 Doors'),
        ),
        VehicleTypeCard(
          label: truck,
          image: 'assets/images/car_truck.png',
          imageWidth: 140,
          imageRightPadding: 20,
          onTap: () => _select(context, type: truck, detail: truck, group: 'TRUCK', contain: '-', doors: '-'),
        ),
        VehicleTypeCard(
          label: 'รถเเต่ง', // two SARA E, verbatim from FF
          image: 'assets/images/car_modified.png',
          imageWidth: 90,
          imageRightPadding: 20,
          onTap: () => _select(context, type: 'รถเเต่ง', detail: 'รถเเต่ง'),
        ),
        VehicleTypeCard(
          label: 'รถโดยสารประจำทาง',
          image: 'assets/images/car_bus.png',
          imageWidth: 130,
          imageRightPadding: 0,
          onTap: () => _select(context, type: 'รถโดยสารประจำทาง', detail: 'รถโดยสารประจำทาง'),
        ),
      ],
    );
  }
}

/// FF SearchablePickUpListPage (`fromPage: 'NonePackage'`): the 2-door
/// pick-up sub-type becomes the vehicle type itself (so the 4-door-only
/// carrier sections don't show — FF behaviour).
class NpPickupTypePage extends StatelessWidget {
  const NpPickupTypePage({super.key});

  void _select(BuildContext context, String label, String contain) {
    NonePackageState.instance
      ..vehicleType = label
      ..vehicleTypeDetail = label
      ..carTypeContain = contain
      ..carTypeDoors = '2 Doors'
      ..notify();
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
          onTap: () => _select(context, 'กระบะตู้ทึบ/ตู้แห้ง', 'ตู้ทึบ/ตู้แห้ง'),
        ),
      ],
    );
  }
}
