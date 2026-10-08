import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firestore_rest.dart';
import '../../../../core/utils/ff_functions.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../router/app_router.dart';
import '../../models/vehicle_usage.dart';
import '../../state/search_package_state.dart';
import '../searchable_list_page.dart';

/// The search form's picker flows: open [SearchableListPage] with the FF
/// params and apply the result the way FF SearchableListPage did for that
/// mode (spec 02 §4: single-select modes 2, 3, 4, 22, 23; multi modes 5, 6).
///
/// These are identical for every product (they only touch that product's
/// [SearchPackageState]), so the product pages share them.
abstract final class SearchPickers {
  /// ยี่ห้อรถ (mode 2, single): filter the models of the brand by the chosen
  /// vehicle type; no models → 'ไม่พบข้อมูลประกัน' → work-select page.
  static Future<void> brand(BuildContext context, SearchPackageState state) async {
    final picked = await SearchableListPage.open(
      context,
      titleText: 'เลือกยี่ห้อรถ',
      searchLabel: 'ระบุยี่ห้อรถ',
      items: [for (final b in state.brands) b.name],
    );
    if (picked == null || picked.isEmpty) return;
    final brand = state.brands[picked.first];
    final group = state.vehicleGroup;
    state.models = [
      for (final m in state.modelsOriginal)
        if (m.brandId == brand.id &&
            m.carGroup.contains(group) &&
            // PICKUP also matches the pick-up sub-type and doors
            // (FF returnMappedListFrom3List vs …3ListOther).
            (group != 'PICKUP' ||
                (state.carTypeContain == m.carGroupDetail && (state.carTypeDoors == m.carDoors || m.carDoors == '-'))))
          m,
    ];
    state.selectedModel = null;
    state.checkFilled[1] = true;
    if (state.models.isNotEmpty) {
      state.selectedBrand = brand;
      state.notify();
      return;
    }
    // FF quirk kept: the model was already reset; the brand is not stored.
    state.notify();
    if (!context.mounted) return;
    await showAlert(context, 'ไม่พบข้อมูลประกัน');
    if (context.mounted) context.go(AppRoutes.workSelect(state.product));
  }

  /// รุ่นรถ (mode 23).
  static Future<void> model(BuildContext context, SearchPackageState state) async {
    final picked = await SearchableListPage.open(
      context,
      titleText: 'เลือกรุ่นรถ',
      searchLabel: 'ระบุรุ่นรถ',
      items: [for (final m in state.models) m.name],
    );
    if (picked == null || picked.isEmpty) return;
    state.selectedModel = state.models[picked.first];
    state.checkFilled[2] = true;
    state.notify();
  }

  /// ปีจดทะเบียน (mode 3) — BE years from this year down to 2500.
  static Future<void> year(BuildContext context, SearchPackageState state) async {
    final years = registrationYearsBE();
    final picked = await SearchableListPage.open(
      context,
      titleText: 'เลือกปีจดทะเบียน',
      searchLabel: 'ระบุปีจดทะเบียน',
      items: years,
    );
    if (picked == null || picked.isEmpty) return;
    state.yearBE = years[picked.first];
    state.checkFilled[3] = true;
    state.notify();
  }

  /// ลักษณะการใช้รถ (mode 4). 2-door pick-ups list the Firestore
  /// `PickUp2Doors` usages. FF then looked the tapped row up in the API list
  /// and crashed (index −1) when it wasn't there; here the row is taken from
  /// the list that was displayed.
  static Future<void> usage(BuildContext context, SearchPackageState state) async {
    final options = usageOptions(state);
    final picked = await SearchableListPage.open(
      context,
      titleText: 'เลือกลักษณะการใช้รถ',
      searchLabel: 'ระบุลักษณะการใช้รถ',
      items: [for (final u in options) usageLabel(u)],
    );
    if (picked == null || picked.isEmpty) return;
    state.selectedUsage = options[picked.first];
    state.checkFilled[4] = true;
    state.notify();
  }

  /// ประเภทชั้นประกัน (multi mode 5).
  static Future<void> coverTypes(BuildContext context, SearchPackageState state) async {
    final picked = await SearchableListPage.open(
      context,
      titleText: 'เลือกประเภทชั้นประกัน',
      searchLabel: 'ระบุประเภทชั้นประกัน',
      items: [for (final c in state.coverTypes) c.name],
      multiSelect: true,
    );
    if (picked == null) return;
    state.selectedCoverTypes = [for (final i in picked) state.coverTypes[i]];
    state.notify();
  }

  /// ประเภทการซ่อม (multi mode 6).
  static Future<void> garageTypes(BuildContext context, SearchPackageState state) async {
    final names = state.garageTypeNames;
    final picked = await SearchableListPage.open(
      context,
      titleText: 'เลือกประเภทการซ่อม',
      searchLabel: 'ระบุประเภทการซ่อม',
      items: names,
      multiSelect: true,
    );
    if (picked == null) return;
    state.selectedGarageTypes = [for (final i in picked) names[i]];
    state.notify();
  }

  /// จังหวัดที่จดทะเบียน (mode 22).
  static Future<void> province(BuildContext context, SearchPackageState state) async {
    final picked = await SearchableListPage.open(
      context,
      titleText: 'เลือกจังหวัดที่จดทะเบียน',
      searchLabel: 'เลือกจังหวัดที่จดทะเบียน',
      items: [for (final p in state.provinces) p.nameTh],
    );
    if (picked == null || picked.isEmpty) return;
    state.selectedProvince = state.provinces[picked.first];
    state.notify();
  }
}

// ── Pure helpers ─────────────────────────────────────────────────────────

/// FF `reverseList(ganerateYearList(2500, currentYearBE))`.
List<String> registrationYearsBE() => reverseList(ganerateYearList(2500, DateTime.now().year + 543));

/// FF `generateInsuranceVehicleTypeDropdown` row: `'<code> <type>-<name>'`.
String usageLabel(VehicleUsage u) => '${u.code} ${u.type}-${u.name}';

/// Usage rows offered for the chosen vehicle type.
List<VehicleUsage> usageOptions(SearchPackageState state) =>
    state.carTypeDoors == '2 Doors' ? state.pickUp2DoorUsages : state.vehicleUsages;

/// Usage tile text. FF looked the selected code up in the API list; a code
/// not found there (2-door pick-up rows) falls back to the row itself
/// instead of crashing.
String usageDisplay(SearchPackageState state) {
  final selected = state.selectedUsage;
  if (selected == null) return SearchPlaceholders.usage;
  for (final u in state.vehicleUsages) {
    if (u.code == selected.code) return usageLabel(u);
  }
  return usageLabel(selected);
}

/// FF placeholder rule: grey when the value contains 'เลือก'.
bool isPlaceholderText(String value) => containWordinStringUrl('เลือก', value);

/// Firestore `Vehicle_Type_Dropdown` (first doc) → `PickUp2Doors` usages.
/// Returns null when the document can't be read.
Future<List<VehicleUsage>?> loadPickUp2DoorUsagesFromFirestore() async {
  final doc = await FirestoreRest.instance.firstWhere('Vehicle_Type_Dropdown');
  if (doc == null) return null;
  final info = doc['PickUp2Doors'];
  if (info is! Map) return const [];
  List<String> list(String key) {
    final v = info[key];
    return v is List ? [for (final e in v) e?.toString() ?? ''] : const [];
  }

  final ids = list('vehicle_id');
  final codes = list('vehicle_code');
  final types = list('vehicle_type');
  final names = list('vehicle_name');
  String at(List<String> l, int i) => i < l.length ? l[i] : '';
  return [
    for (var i = 0; i < codes.length; i++)
      VehicleUsage(id: at(ids, i), code: codes[i], type: at(types, i), name: at(names, i)),
  ];
}

/// FF FILTER_BRANDS: keep brands whose car group contains [state.vehicleGroup]
/// (substring match, as in FF).
void filterBrandsByVehicleGroup(SearchPackageState state) {
  state.brands = [
    for (final b in state.brandsOriginal)
      if (b.carGroup.contains(state.vehicleGroup)) b,
  ];
}

/// FF RESET_BRAND_MODEL.
void resetBrandAndModel(SearchPackageState state) {
  state.selectedBrand = null;
  state.selectedModel = null;
}
