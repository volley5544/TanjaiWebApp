import 'json_read.dart';

/// One row of `get_vehicle` (`$.results.data[:]`) — the "vehicle used type"
/// (ลักษณะการใช้รถ).
///
/// FF lists: `insuranceBasicVehicleUsedType{Id,Code,Name,Type}List`.
/// JSON null → `''`.
class VehicleUsage {
  const VehicleUsage({required this.id, required this.code, required this.name, required this.type});

  factory VehicleUsage.fromJson(Map<String, dynamic> json) => VehicleUsage(
        id: jsonStr(json['vehicle_id']),
        code: jsonStr(json['vehicle_code']),
        name: jsonStr(json['vehicle_name']),
        type: jsonStr(json['vehicle_type']),
      );

  /// FF getter `vehicleId` — `vehicle_id`.
  final String id;

  /// FF getter `vehicleCode` — `vehicle_code` (sent as `vehicle_usage`).
  final String code;

  /// FF getter `vehicleName` — `vehicle_name`.
  final String name;

  /// FF getter `vehicletype` — `vehicle_type`.
  final String type;
}
