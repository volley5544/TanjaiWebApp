import '../../search_package/models/json_read.dart';

/// One fire-insurance package from `api/insurance/house/get_package` — FF
/// `GetPackageFireInsurerDataTypeStruct`. Every field but [id] is a string in
/// the API (amounts like `'1500000.00000'`).
class FirePackage {
  const FirePackage({
    this.id,
    this.companyId,
    this.packageId,
    this.packageName,
    this.sumInsured,
    this.yearCover,
    this.fireAndExplosion,
    this.naturalDisaster,
    this.strikeAndRiot,
    this.electricalAppliance,
    this.flood,
    this.thief,
    this.buildingRepairs,
    this.lockRepairs,
    this.mirrorDamage,
    this.tppd,
    this.dieFire,
    this.medicalTreat,
    this.netPremium,
    this.vat,
    this.stamp,
    this.grossTotal,
    this.effectiveDate,
    this.expiryDate,
    this.serialName,
    this.shortName,
    this.fullName,
    this.logo,
    this.productId,
  });

  final int? id;
  final String? companyId;
  final String? packageId;
  final String? packageName;
  final String? sumInsured;
  final String? yearCover;
  final String? fireAndExplosion;
  final String? naturalDisaster;
  final String? strikeAndRiot;
  final String? electricalAppliance;
  final String? flood;
  final String? thief;
  final String? buildingRepairs;
  final String? lockRepairs;
  final String? mirrorDamage;
  final String? tppd;
  final String? dieFire;
  final String? medicalTreat;
  final String? netPremium;
  final String? vat;
  final String? stamp;
  final String? grossTotal;
  final String? effectiveDate;
  final String? expiryDate;
  final String? serialName;
  final String? shortName;
  final String? fullName;
  final String? logo;
  final String? productId;

  static FirePackage fromJson(Map<String, dynamic> j) {
    String? s(String key) => j[key] == null ? null : '${j[key]}';
    return FirePackage(
      id: jsonInt(j['id']),
      companyId: s('company_id'),
      packageId: s('package_id'),
      packageName: s('package_name'),
      sumInsured: s('sum_insured'),
      yearCover: s('year_cover'),
      fireAndExplosion: s('fire_and_explosion'),
      naturalDisaster: s('natural_disaster'),
      strikeAndRiot: s('strike_and_riot'),
      electricalAppliance: s('electrical_appliance'),
      flood: s('flood'),
      thief: s('thief'),
      buildingRepairs: s('building_repairs'),
      lockRepairs: s('lock_repairs'),
      mirrorDamage: s('mirror_damage'),
      tppd: s('tppd'),
      dieFire: s('die_fire'),
      medicalTreat: s('medical_treat'),
      netPremium: s('net_premium'),
      vat: s('vat'),
      stamp: s('stamp'),
      grossTotal: s('gross_total'),
      effectiveDate: s('effective_date'),
      expiryDate: s('expiry_date'),
      serialName: s('serial_name'),
      shortName: s('short_name'),
      fullName: s('full_name'),
      logo: s('logo'),
      productId: s('productId'),
    );
  }

  /// FF `toMap()` — same keys and order, nulls dropped (`.withoutNulls`). Sent
  /// as the quotation save's `insurer_package`.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'company_id': companyId,
        'package_id': packageId,
        'package_name': packageName,
        'sum_insured': sumInsured,
        'year_cover': yearCover,
        'fire_and_explosion': fireAndExplosion,
        'natural_disaster': naturalDisaster,
        'strike_and_riot': strikeAndRiot,
        'electrical_appliance': electricalAppliance,
        'flood': flood,
        'thief': thief,
        'building_repairs': buildingRepairs,
        'lock_repairs': lockRepairs,
        'mirror_damage': mirrorDamage,
        'tppd': tppd,
        'die_fire': dieFire,
        'medical_treat': medicalTreat,
        'net_premium': netPremium,
        'vat': vat,
        'stamp': stamp,
        'gross_total': grossTotal,
        'effective_date': effectiveDate,
        'expiry_date': expiryDate,
        'serial_name': serialName,
        'short_name': shortName,
        'full_name': fullName,
        'logo': logo,
        'productId': productId,
      }..removeWhere((_, v) => v == null);
}

/// `api/house/cal-estimated` → `$.results.data` — FF
/// `HouseCalEstimatedModelStruct` (ints default 0).
class HouseEstimate {
  const HouseEstimate({this.houseTypeGroup = '', this.estimatedPrice = 0, this.housePrice = 0, this.usableArea = 0});

  final String houseTypeGroup;
  final int estimatedPrice;
  final int housePrice;
  final int usableArea;

  static HouseEstimate fromJson(Map<String, dynamic> j) => HouseEstimate(
        houseTypeGroup: '${j['house_type_group'] ?? ''}',
        estimatedPrice: jsonInt(j['estimated_price']) ?? 0,
        housePrice: jsonInt(j['house_price']) ?? 0,
        usableArea: jsonInt(j['usable_area']) ?? 0,
      );
}

/// Successful `api/house/quotations/save`.
class FireQuotationSaveResult {
  const FireQuotationSaveResult({this.quotationId = '', this.leadHouseDtlId, this.pdfUrls = const []});

  /// `$.results.data.quotation.quotation_id` (for InsuranceInfoPage1).
  final String quotationId;

  /// `$.results.data.detail_house[0].lead_house_dtl_id`.
  final int? leadHouseDtlId;

  /// `$.results.data.detail_house[:].url` — the quotation PDFs.
  final List<String> pdfUrls;

  static FireQuotationSaveResult fromJson(dynamic json) {
    final data = resultsData(json);
    final details = jsonAt(data, 'detail_house');
    final list = details is List ? details : const [];
    return FireQuotationSaveResult(
      // FF: getJsonField(...).toString() → 'null' when missing.
      quotationId: jsonStrN(jsonAt(jsonAt(data, 'quotation'), 'quotation_id')),
      leadHouseDtlId: list.isEmpty || list.first is! Map ? null : jsonInt((list.first as Map)['lead_house_dtl_id']),
      pdfUrls: [
        for (final d in list)
          if (d is Map && d['url'] != null) '${d['url']}',
      ],
    );
  }
}
