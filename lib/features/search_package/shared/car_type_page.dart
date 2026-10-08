import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_dialogs.dart';
import '../../../router/app_router.dart';
import '../state/search_package_state.dart';
import 'pickup_type_page.dart';
import 'search_form/search_pickers.dart';
import 'vehicle_type_card.dart';

/// เลือกประเภทรถ — vehicle-type picker of the motor / EV search pages
/// (FF SearchableCarListPage, fromPage 'searchPackage' path only, spec 03).
///
/// Writes the choice into [state] like FF did and pops back to the search
/// page. 2-door pick-up replaces itself with [PickupTypePage]; truck /
/// modified car / bus go to the work-select page.
class CarTypePage extends StatelessWidget {
  const CarTypePage({super.key, required this.state});

  final SearchPackageState state;

  /// Pushed with Navigator (not a route), above the search page.
  static Future<void> open(BuildContext context, SearchPackageState state) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => CarTypePage(state: state)));
  }

  /// Sedan / van / 4-door pick-up.
  Future<void> _selectCar(
    BuildContext context, {
    required String label,
    required String detail,
    required String group,
    required String doors,
  }) async {
    state.vehicleTypeLabel = label;
    state.checkFilled[0] = true;
    state.carTypeDetailSelected = detail;
    state.vehicleGroup = group;
    state.carTypeContain = '-';
    state.carTypeDoors = doors;
    filterBrandsByVehicleGroup(state);
    resetBrandAndModel(state);
    state.notify();
    if (!await _ensureBrands(context)) return;
    if (context.mounted) Navigator.of(context).pop();
  }

  /// 2-door pick-up: no Contain/Doors write and no brand/model reset here
  /// (the sub-type page does that); this page is replaced by the sub-type
  /// page so its back / selection lands on the search page.
  Future<void> _selectPickup2Doors(BuildContext context) async {
    state.vehicleTypeLabel = 'รถกระบะ';
    state.checkFilled[0] = true;
    state.carTypeDetailSelected = 'รถกระบะ 2 ประตู';
    state.vehicleGroup = 'PICKUP';
    filterBrandsByVehicleGroup(state);
    state.notify();
    if (!await _ensureBrands(context)) return;
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PickupTypePage(state: state)));
  }

  /// FF NO_BRANDS_CHECK. Returns false after sending the user to work-select.
  Future<bool> _ensureBrands(BuildContext context) async {
    if (state.brands.isNotEmpty) return true;
    state.vehicleTypeLabel = SearchPlaceholders.vehicleType;
    state.notify();
    if (!context.mounted) return false;
    await showAlert(context, 'ไม่พบข้อมูลประกัน');
    if (context.mounted) context.go(AppRoutes.workSelect(state.product));
    return false;
  }

  void _goWorkSelect(BuildContext context) => context.go(AppRoutes.workSelect(state.product));

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
          onTap: () => _selectCar(context, label: 'รถเก๋ง', detail: 'รถเก๋ง', group: 'OTHER', doors: '-'),
        ),
        VehicleTypeCard(
          label: 'รถตู้',
          image: 'assets/images/car_van.png',
          imageWidth: 90,
          imageRightPadding: 20,
          onTap: () => _selectCar(context, label: 'รถตู้', detail: 'รถตู้', group: 'VAN', doors: '-'),
        ),
        VehicleTypeCard(
          label: 'รถกระบะ 2 ประตู',
          image: 'assets/images/car_pickup_2_doors.png',
          imageWidth: 90,
          imageRightPadding: 20,
          onTap: () => _selectPickup2Doors(context),
        ),
        VehicleTypeCard(
          label: 'รถกระบะ 4 ประตู',
          image: 'assets/images/car_pickup_4_doors.png',
          imageWidth: 90,
          imageRightPadding: 20,
          onTap: () =>
              _selectCar(context, label: 'รถกระบะ', detail: 'รถกระบะ 4 ประตู', group: 'PICKUP', doors: '4 Doors'),
        ),
        // Not sold online: always the work-select page (FF `if (true)`).
        VehicleTypeCard(
          label: 'รถบรรทุก หัวลาก หางพ่วง',
          image: 'assets/images/car_truck.png',
          imageWidth: 140,
          imageRightPadding: 20,
          onTap: () => _goWorkSelect(context),
        ),
        VehicleTypeCard(
          label: 'รถเเต่ง', // 'เเ' = two SARA E, verbatim from FF
          image: 'assets/images/car_modified.png',
          imageWidth: 90,
          imageRightPadding: 20,
          onTap: () => _goWorkSelect(context),
        ),
        VehicleTypeCard(
          label: 'รถโดยสารประจำทาง',
          image: 'assets/images/car_bus.png',
          imageWidth: 130,
          imageRightPadding: 0,
          onTap: () => _goWorkSelect(context),
        ),
      ],
    );
  }
}
