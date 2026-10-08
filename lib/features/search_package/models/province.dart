import 'json_read.dart';

/// One row of `get_province` (`$.results.data[:]`).
///
/// FF lists: `insuranceInfoRegistrationCodeList` (id) and
/// `insuranceInfoRegistrationprovinceList` (nameTh). JSON null → `''`.
class Province {
  const Province({required this.id, required this.nameTh, required this.nameEn});

  factory Province.fromJson(Map<String, dynamic> json) => Province(
        id: jsonStr(json['prov_id']),
        nameTh: jsonStr(json['prov_th']),
        nameEn: jsonStr(json['prov_en']),
      );

  /// FF getter `provinceID` — `prov_id`.
  final String id;

  /// FF getter `provinceNameTH` — `prov_th`.
  final String nameTh;

  /// FF getter `provinceNameEN` — `prov_en`.
  final String nameEn;
}
