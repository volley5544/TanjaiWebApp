import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../router/app_router.dart';
import '../data/api_result.dart';
import '../data/search_package_api.dart';
import '../product_type.dart';
import '../state/search_package_state.dart';

/// On-load, validation and navigation of the motorcycle (มอเตอร์ไซค์) search page
/// — the FF SearchInsurancePage `fromIcon == 'MC'` branch. The vehicle type is
/// fixed to 'มอเตอร์ไซค์' and the result goes straight to the package list.
class McSearchController {
  final SearchPackageState state = SearchPackageState.of(ProductType.mc);
  final SearchPackageApi _api = SearchPackageApi.instance;

  /// FF initState resets (filters, sliders, customer, quotation, province,
  /// car-type detail/group/contain/doors). `datePicked` was page-local in FF,
  /// so the old-policy date starts empty on every open.
  void resetOnLoad() {
    state.resetOnSearchPageLoad();
    state.oldPolicyExpiry = null;
    state.notify();
  }

  /// FF on-load master data, called one after another (spec 01 §3.1).
  /// Returns the dialog text of the first failure, or null on success.
  Future<String?> loadMasterData() async {
    state.masterDataLoaded = false;

    final brands = await _api.getBrandsMc();
    final brandError = _errorOf(brands);
    if (brandError != null) return brandError;
    state.brandsOriginal = brands.data ?? [];
    state.brands = List.of(state.brandsOriginal);

    final models = await _api.getModelsMc();
    final modelError = _errorOf(models);
    if (modelError != null) return modelError;
    state.modelsOriginal = models.data ?? [];

    final covers = await _api.getCoverTypes(carType: 'MC');
    final coverError = _errorOf(covers);
    if (coverError != null) return coverError;
    state.coverTypes = covers.data ?? [];

    final vehicles = await _api.getVehicles(vehicleCategory: 'auto', carType: 'MC');
    final vehicleError = _errorOf(vehicles);
    if (vehicleError != null) return vehicleError;
    state.vehicleUsages = vehicles.data ?? [];
    state.masterDataLoaded = true; // FF insuranceRequestIsLoadDataMc

    final provinces = await _api.getProvinces();
    final provinceError = _errorOf(provinces);
    if (provinceError != null) return provinceError;
    state.provinces = provinces.data ?? [];

    state.vehicleTypeLabel = 'มอเตอร์ไซค์';
    state.notify();
    return null;
  }

  /// ค้นหา: FF validation order and texts, then the MC package list
  /// (FF InsurerListPage, `driver: '0'`).
  Future<void> search(BuildContext context) async {
    final s = state;
    final usage = s.selectedUsage;
    String? message;
    if (_unset(s.vehicleTypeLabel, SearchPlaceholders.vehicleType)) {
      message = 'กรุณาเลือกประเภทรถ';
    } else if (_unset(s.brandLabel, SearchPlaceholders.brand)) {
      message = 'กรุณาเลือกยี่ห้อรถ';
    } else if (_unset(s.modelLabel, SearchPlaceholders.model)) {
      message = 'กรุณาเลือกรุ่นรถ';
    } else if (_unset(s.yearLabel, SearchPlaceholders.year)) {
      message = 'กรุณาเลือกปีจดทะเบียน';
    } else if (usage == null || _unset(usage.name, SearchPlaceholders.usage)) {
      message = 'กรุณาเลือกลักษณะการใช้รถ';
    } else if (s.selectedCoverTypes.isEmpty) {
      message = 'กรุณาเลือกประเภทชั้นประกัน';
    } else if (s.selectedGarageTypes.isEmpty) {
      message = 'กรุณาเลือกประเภทการซ่อม';
    }
    if (message != null) {
      await showAlert(context, message);
      return;
    }
    if (!s.models.any((m) => m.name == s.modelLabel)) {
      await showAlert(context, 'ไม่พบรุ่นย่อยรถนี้ในแพ็กเกจประกัน');
      if (context.mounted) context.push(AppRoutes.workSelect(s.product));
      return;
    }
    final province = s.selectedProvince;
    if (province == null || province.nameTh.isEmpty) {
      await showAlert(context, 'กรุณาเลือกจังหวัดที่จดทะเบียน');
      return;
    }

    s.filterInsurers = [];
    s.filterGarageTypes = [];
    s.filterCoverTypes = [];
    final expiry = s.oldPolicyExpiry;
    // The ID-card / discount / driver inputs are dead UI in FF, so idCard,
    // customerType, driverFlag and the behaviour scores keep their defaults.
    s.criteria = SearchCriteria(
      brandCode: s.selectedBrand!.id,
      modelCode: s.selectedModel!.code,
      yearCE: ((int.tryParse(s.yearBE!) ?? 0) - 543).toString(),
      province: province.nameTh,
      provinceCode: province.id,
      vehicleUsage: usage!.code,
      coverType: [for (final c in s.selectedCoverTypes) c.code],
      garageType: createGarageTypeCodeList(s.selectedGarageTypes),
      brandName: s.brandLabel,
      modelName: s.modelLabel,
      oldVmiExpDate: expiry != null ? getDateFormat(expiry) : '',
    );
    s.notify();
    if (context.mounted) context.push(AppRoutes.packages(s.product));
  }

  /// AppBar back: FF resets the form, then `goNamed('SuperAppPage')`.
  void back(BuildContext context) {
    state.resetOnSearchPageBack();
    state.notify();
    // TODO(bridge): hand control back to the host app instead of the web menu.
    context.go(AppRoutes.home);
  }

  static bool _unset(String value, String placeholder) => value.isEmpty || value == placeholder;

  /// FF pattern: HTTP != 200 → 'พบข้อผิดพลาด (code)'; body code != 200 → message.
  static String? _errorOf(ApiResult<Object?> r) {
    if (!r.isHttpOk) return httpErrorText(r.statusCode);
    if (r.code != 200) return r.message ?? '';
    return null;
  }
}
