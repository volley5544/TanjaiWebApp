import 'json_read.dart';

/// One row of `get_models` / `get_models_mc` (`$.results.data[:]`).
///
/// FF lists: `insuranceBasicModelIdListOriginal` (code), `…ModelNameListOriginal`,
/// `…ModelBrandIdListOriginal`, `insuranceBasicVehicleGroupList` (carGroup),
/// `insuranceBasicCarGroupDetail`, `insuranceBasicCarDoorList`. JSON null → `''`.
class CarModel {
  const CarModel({
    required this.code,
    required this.name,
    required this.brandId,
    required this.carGroup,
    required this.carGroupDetail,
    required this.carDoors,
    this.vehGroup = '',
    this.noSeats = '',
    this.engineCapacity = '',
    this.weight = '',
  });

  factory CarModel.fromJson(Map<String, dynamic> json) => CarModel(
        code: jsonStr(json['code']),
        name: jsonStr(json['name']),
        brandId: jsonStr(json['brand_id']),
        carGroup: jsonStr(json['car_group']),
        carGroupDetail: jsonStr(json['car_group_detail']),
        carDoors: jsonStr(json['car_doors']),
        vehGroup: jsonStr(json['veh_group']),
        noSeats: jsonStr(json['no_seats']),
        engineCapacity: jsonStr(json['engine_capacity']),
        weight: jsonStr(json['weight']),
      );

  /// FF getter `modelCode` — `code`.
  final String code;

  /// FF getter `modelName` — `name`.
  final String name;

  /// FF getter `brandID` — `brand_id`.
  final String brandId;

  /// FF getter `carGroup` — `car_group`.
  final String carGroup;

  /// FF getter `carGroupDetail` — `car_group_detail`.
  final String carGroupDetail;

  /// FF getter `carDoors` — `car_doors`.
  final String carDoors;

  /// FF getter `modelVehicleGroup` — `veh_group` (not read by the pages).
  final String vehGroup;

  /// FF getter `modelNubmerSeat` (sic) — `no_seats` (not read by the pages).
  final String noSeats;

  /// FF getter `modelEnginCapacity` — `engine_capacity` (not read by the pages).
  final String engineCapacity;

  /// FF getter `modelWeight` — `weight` (not read by the pages).
  final String weight;
}
