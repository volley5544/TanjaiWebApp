import 'json_read.dart';

/// One row of `get_cover_type` (`$.results.data[:]`).
///
/// FF lists: `insuranceBasicCoverTypeIdList` / `…CodeList` / `…NameList`.
/// JSON null → `''`.
class CoverType {
  const CoverType({required this.id, required this.code, required this.name});

  factory CoverType.fromJson(Map<String, dynamic> json) => CoverType(
        id: jsonStr(json['cover_type_id']),
        code: jsonStr(json['cover_type_code']),
        name: jsonStr(json['cover_type_name']),
      );

  /// FF getter `coverTypeId` — `cover_type_id`.
  final String id;

  /// FF getter `coverTypeCode` — `cover_type_code` (e.g. `VMI1`, `VMI2+`).
  final String code;

  /// FF getter `coverTypeName` — `cover_type_name`.
  final String name;
}
