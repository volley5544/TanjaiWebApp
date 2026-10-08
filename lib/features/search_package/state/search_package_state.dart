import 'package:flutter/foundation.dart';

import '../models/brand.dart';
import '../models/car_model.dart';
import '../models/cover_type.dart';
import '../models/insurance_package.dart';
import '../models/insurer_group.dart';
import '../models/province.dart';
import '../models/quotation_save_request.dart';
import '../models/vehicle_usage.dart';
import '../product_type.dart';

/// Placeholders the FF form uses as "nothing selected yet" values. They are
/// shown in grey and checked by the search validation, exactly as in the app.
abstract final class SearchPlaceholders {
  static const vehicleType = 'เลือกประเภทรถ';
  static const brand = 'เลือกยี่ห้อรถ';
  static const model = 'เลือกรุ่นรถ';
  static const year = 'เลือกปีจดทะเบียน พ.ศ.';
  static const usage = 'เลือกการใช้งาน';
}

/// A min–max range filter (FF `slider*` app-state strings, as doubles).
class RangeFilter {
  RangeFilter({required this.boundMin, required this.boundMax, double? currentMin, double? currentMax})
      : currentMin = currentMin ?? boundMin,
        currentMax = currentMax ?? boundMax;

  double boundMin;
  double boundMax;
  double currentMin;
  double currentMax;

  RangeFilter copy() =>
      RangeFilter(boundMin: boundMin, boundMax: boundMax, currentMin: currentMin, currentMax: currentMax);

  bool contains(double v) => currentMin <= v && v <= currentMax;
}

/// The criteria the search page hands to the result pages (the FF route params
/// of InsurerListOverallPage / InsurerListPage).
class SearchCriteria {
  const SearchCriteria({
    required this.brandCode,
    required this.modelCode,
    required this.yearCE,
    required this.province,
    required this.provinceCode,
    required this.vehicleUsage,
    required this.coverType,
    required this.garageType,
    required this.brandName,
    required this.modelName,
    this.carTypeDetail = '',
    this.oldVmiExpDate = '',
    this.idCard = '',
    this.customerType = '',
    this.driverFlag = '0',
    this.driverBehaviorScoreList = const ['0', '0', '0', '0', '0'],
  });

  final String brandCode;
  final String modelCode;

  /// Registration year in CE (FF: `int.parse(insuranceBasicYear) - 543`).
  final String yearCE;
  final String province;
  final String provinceCode;
  final String vehicleUsage;
  final List<String> coverType;
  final List<String> garageType;
  final String brandName;
  final String modelName;
  final String carTypeDetail;
  final String oldVmiExpDate;
  final String idCard;
  final String customerType;
  final String driverFlag;
  final List<String> driverBehaviorScoreList;
}

/// All state of one product's search-package flow — the FF `FFAppState`
/// fields this feature used, grouped and typed. There is one instance per
/// [ProductType] ([SearchPackageState.of]); the motor, EV and MC flows never
/// share state.
///
/// Mutate fields directly, then call [notify] (FF's `FFAppState().update`).
class SearchPackageState extends ChangeNotifier {
  SearchPackageState(this.product);

  final ProductType product;

  static final Map<ProductType, SearchPackageState> _instances = {};

  static SearchPackageState of(ProductType product) =>
      _instances.putIfAbsent(product, () => SearchPackageState(product));

  void notify() => notifyListeners();

  // ── Master data (loaded by the search page) ────────────────────────────
  /// Full brand list from the API (FF `insuranceBasicBrand*ListOriginal`).
  List<Brand> brandsOriginal = [];

  /// Brands offered in the picker, filtered by vehicle type
  /// (FF `insuranceBasicBrandNameList` / `insuranceBasicBrandIdList`).
  List<Brand> brands = [];

  /// Full model list (FF `insuranceBasicModel*ListOriginal`, `insuranceBasicVehicleGroupList`,
  /// `insuranceBasicCarGroupDetail`, `insuranceBasicCarDoorList`).
  List<CarModel> modelsOriginal = [];

  /// Models of the selected brand (FF `insuranceBasicModelNameList` / `…IdList`).
  List<CarModel> models = [];

  List<CoverType> coverTypes = [];
  List<VehicleUsage> vehicleUsages = [];

  /// Firestore `Vehicle_Type_Dropdown.PickUp2Doors` usages (2-door pick-ups).
  List<VehicleUsage> pickUp2DoorUsages = [];
  List<Province> provinces = [];

  /// FF `insuranceBasicGarageTypeNameList` default.
  List<String> garageTypeNames = ['ซ่อมอู่', 'ซ่อมห้าง'];

  /// FF `insuranceBasicVehicleTypeDropdownList` default.
  List<String> vehicleTypeOptions = ['รถเก๋ง', 'รถตู้', 'รถกระบะ', 'รถบรรทุก หัวลาก หางพ่วง', 'รถแต่ง ต่อคอก'];

  bool masterDataLoaded = false;

  // ── Search form ────────────────────────────────────────────────────────
  /// FF `insuranceVehicleTypeDropDown` ('มอเตอร์ไซค์' for MC).
  String vehicleTypeLabel = SearchPlaceholders.vehicleType;

  /// FF `insuranceCarTypeDetailSelected`.
  String carTypeDetailSelected = '';

  /// FF `insuranceBasicVehicleGroup` (car group of the chosen vehicle type).
  String vehicleGroup = '';

  /// FF `insuranceBasicCarTypeContain`.
  String carTypeContain = '';

  /// FF `insuranceBasicCarTypeDoors` ('2 Doors' for 2-door pick-ups).
  String carTypeDoors = '';

  /// FF `searchPackageCheckFilled` (5 flags: type, brand, model, year, usage).
  List<bool> checkFilled = List.filled(5, false);

  Brand? selectedBrand;
  CarModel? selectedModel;

  /// FF `isSelectBrandInPackage` — shows the รุ่นรถ field.
  bool get isBrandSelected => selectedBrand != null;

  /// Registration year, Buddhist Era (FF `insuranceBasicYear`).
  String? yearBE;

  /// Chosen usage (FF `insuranceBasicVehicleUsedType{Id,Code,Name}`).
  VehicleUsage? selectedUsage;

  /// FF `insuranceBasicCoverType{Name,Code,Id}OutputList`.
  List<CoverType> selectedCoverTypes = [];

  /// FF `insuranceBasicGarageTypeInPackage` (names: ซ่อมอู่ / ซ่อมห้าง).
  List<String> selectedGarageTypes = [];

  /// FF `insuranceInfoRegistrationProvinceSelect` / `…CodeSelect`.
  Province? selectedProvince;

  /// FF `insuranceBasicOldVmiExpDate` (optional old-policy expiry date).
  DateTime? oldPolicyExpiry;

  String get brandLabel => selectedBrand?.name ?? SearchPlaceholders.brand;
  String get modelLabel => selectedModel?.name ?? SearchPlaceholders.model;
  String get yearLabel => yearBE ?? SearchPlaceholders.year;

  // ── Search results ─────────────────────────────────────────────────────
  SearchCriteria? criteria;

  /// Raw search result (car: insurers + flattened packages; MC: packages).
  PackageSearchResult? result;

  List<InsurerGroup> get insurers => result?.insurers ?? const [];
  List<InsurancePackage> get packages => result?.packages ?? const [];

  // ── Result filters (FF filter* / slider* / selectInsurerList) ─────────
  /// FF `filterInsurerList` / `filterCoverTypeList` / `filterGarageTypeList`.
  List<String> filterInsurers = [];
  List<String> filterCoverTypes = [];
  List<String> filterGarageTypes = [];

  /// Insurer overview page ranges (FF `slider*Page2`).
  RangeFilter grossPage2 = RangeFilter(boundMin: 1000, boundMax: 10000);
  RangeFilter sumInsuredPage2 = RangeFilter(boundMin: 0, boundMax: 1000000);

  /// Package list page ranges (FF `slider*Page3`).
  RangeFilter grossPage3 = RangeFilter(boundMin: 1000, boundMax: 10000);
  RangeFilter sumInsuredPage3 = RangeFilter(boundMin: 0, boundMax: 1000000);

  /// Compare check-boxes, parallel to [packages] (FF `selectInsurerList`).
  List<bool> compareSelection = [];

  // ── Detail / compare / customer / quotation ────────────────────────────
  /// Package opened on the detail page.
  InsurancePackage? selectedPackage;

  /// Packages ticked for comparison (max 3) and the tab shown.
  List<InsurancePackage> comparePackages = [];
  int compareIndex = 0;

  /// FF `AddCustomerPage{Firstname,Lastname,Phone,CarRegistration}`.
  String customerFirstName = '';
  String customerLastName = '';
  String customerPhone = '';
  String customerCarRegistration = '';

  /// FF `addCustomerQuotationSaveSuccess`.
  bool quotationSaved = false;

  /// FF `insurarerQuotationPdf` — quotation PDF URLs for the Quotation page.
  List<String> quotationPdfs = [];

  QuotationSaveResult? lastSaveResult;

  // ── Resets ─────────────────────────────────────────────────────────────
  /// Search-page on-load resets (FF initState: filters, sliders, customer,
  /// quotation, province, car-type detail). Brand/model/year/usage/cover/
  /// garage selections are deliberately kept, as in the app.
  void resetOnSearchPageLoad() {
    filterInsurers = [];
    filterCoverTypes = [];
    filterGarageTypes = [];
    grossPage2 = RangeFilter(boundMin: 1000, boundMax: 10000);
    sumInsuredPage2 = RangeFilter(boundMin: 0, boundMax: 1000000);
    grossPage3 = RangeFilter(boundMin: 1000, boundMax: 10000);
    sumInsuredPage3 = RangeFilter(boundMin: 0, boundMax: 1000000);
    customerFirstName = '';
    customerLastName = '';
    customerPhone = '';
    customerCarRegistration = '';
    quotationSaved = false;
    quotationPdfs = [];
    selectedProvince = null;
    carTypeDetailSelected = '';
    vehicleGroup = '';
    carTypeContain = '';
    carTypeDoors = '';
  }

  /// AppBar back on the search page (FF resets these before leaving).
  void resetOnSearchPageBack() {
    vehicleTypeLabel = product == ProductType.mc ? 'มอเตอร์ไซค์' : SearchPlaceholders.vehicleType;
    selectedBrand = null;
    selectedModel = null;
    yearBE = null;
    selectedUsage = null;
    selectedCoverTypes = [];
    selectedGarageTypes = [];
    carTypeDetailSelected = '';
  }
}
