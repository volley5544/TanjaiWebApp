import 'json_read.dart';

/// One row of `get_brands` / `get_brands_mc` (`$.results.data[:]`).
///
/// FF kept these as parallel lists (`insuranceBasicBrandNameList`,
/// `insuranceBasicBrandIdList`, `insuranceBasicVehicleGroupBrandList`); a null
/// in one list shifted the others. Here every row keeps its own fields and a
/// JSON null becomes `''`.
class Brand {
  const Brand({required this.id, required this.name, required this.type, required this.carGroup});

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: jsonStr(json['brand_id']),
        name: jsonStr(json['name']),
        type: jsonStr(json['type']),
        carGroup: jsonStr(json['car_group']),
      );

  /// FF getter `brandID` — `brand_id`.
  final String id;

  /// FF getter `brandName` — `name`.
  final String name;

  /// FF getter `brandType` — `type`.
  final String type;

  /// FF getter `carGroup` — `car_group`.
  final String carGroup;
}
