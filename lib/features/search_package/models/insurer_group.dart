import 'insurance_package.dart';
import 'json_read.dart';

/// One insurer of the car/EV `get_package` response — an object at
/// `$.results.data[*][*]`, with its packages under `package[:]`.
///
/// FF stored these as the `FFAppState().searchInsurer*` parallel lists
/// (insurer index i); `searchInsurerXxx[i]` is `insurers[i].field` here.
/// JSON null → `''` (none of these go through `checkNullValueAndReturn`).
/// MC search (`get_package_mc`) has no insurer level.
class InsurerGroup {
  const InsurerGroup({
    required this.insurerShortName,
    required this.insurerName,
    required this.insurerCode,
    required this.companyId,
    required this.logo,
    required this.coverTypeList,
    required this.garageTypeList,
    required this.maxGrossTotal,
    required this.minGrossTotal,
    required this.maxSumInsured,
    required this.minSumInsured,
    required this.total,
    required this.packages,
  });

  factory InsurerGroup.fromJson(Map<String, dynamic> j) => InsurerGroup(
        insurerShortName: jsonStr(j['insurer_short_name']),
        insurerName: jsonStr(j['insurer_name']),
        insurerCode: jsonStr(j['insurer_code']),
        companyId: jsonStr(j['company_id']),
        logo: jsonStr(j['logo']),
        coverTypeList: jsonStr(j['cover_type_list']),
        garageTypeList: jsonStr(j['garage_type_list']),
        maxGrossTotal: jsonStr(j['max_gross_total']),
        minGrossTotal: jsonStr(j['min_gross_total']),
        maxSumInsured: jsonStr(j['max_sum_insured']),
        minSumInsured: jsonStr(j['min_sum_insured']),
        total: jsonInt(j['total']),
        packages: List.unmodifiable([
          for (final p in jsonChildren(j['package']))
            if (p is Map) InsurancePackage.fromJson(Map<String, dynamic>.from(p)),
        ]),
      );

  /// `insurer_short_name` — getter `insurershortnameall`;
  /// FF `searchInsurerInsurershortname`.
  final String insurerShortName;

  /// `insurer_name` — getter `insurernameall`; FF `searchInsurerInsurername`.
  final String insurerName;

  /// `insurer_code` — getter `insurercodeall`; FF `searchInsurerInsurercode`
  /// (what spec 04 puts in `filterInsurerList`).
  final String insurerCode;

  /// `company_id` — getter `companyidall`; FF `searchInsurerCompanyid`.
  final String companyId;

  /// `logo` — getter `logoall`; FF `searchInsurerLogo`. See [logoOrPlaceholder].
  final String logo;

  /// `cover_type_list` — getter `covertypelistall`;
  /// FF `searchInsurerCovertypelist`. Comma string such as `"1,2+"`.
  final String coverTypeList;

  /// `garage_type_list` — getter `garagetypelistall`;
  /// FF `searchInsurerGaragetypelist`.
  final String garageTypeList;

  /// `max_gross_total` — getter `maxnetpremiumall` (sic);
  /// FF `searchInsurerMaxnetpremium`.
  final String maxGrossTotal;

  /// `min_gross_total` — getter `minnetpremiumall` (sic);
  /// FF `searchInsurerMinnetpremium`.
  final String minGrossTotal;

  /// `max_sum_insured` — getter `maxsuminsuredall`; FF `searchInsurerMaxsuminsured`.
  final String maxSumInsured;

  /// `min_sum_insured` — getter `minsuminsuredall`; FF `searchInsurerMinsuminsured`.
  final String minSumInsured;

  /// `total` — getter `total` (`List<int>`, one per insurer); package count.
  /// Not stored in FFAppState.
  final int? total;

  /// `package[:]` of this insurer, in API order.
  final List<InsurancePackage> packages;

  /// FF card: `stringToImgPath(searchInsurerLogo[i]) ?? kNoImageUrl`.
  String get logoOrPlaceholder => logo.isEmpty || logo == 'null' ? kNoImageUrl : logo;
}

/// Parsed body of `get_package` (car/EV) or `get_package_mc` (MC).
class PackageSearchResult {
  const PackageSearchResult({required this.insurers, required this.packages, this.total, this.dataLength = 0});

  /// Car/EV: `$.results.data` is a list (or object) of objects/lists whose
  /// members are insurer objects — JSONPath `$.results.data[*][*]`.
  factory PackageSearchResult.fromCarJson(dynamic json) {
    final data = resultsData(json);
    final insurers = <InsurerGroup>[
      for (final outer in jsonChildren(data))
        for (final ins in jsonChildren(outer))
          if (ins is Map) InsurerGroup.fromJson(Map<String, dynamic>.from(ins)),
    ];
    return PackageSearchResult(
      insurers: List.unmodifiable(insurers),
      packages: List.unmodifiable([for (final i in insurers) ...i.packages]),
      dataLength: _dataLength(data),
    );
  }

  /// MC: flat `$.results.data[:]` packages plus `$.results.total`.
  factory PackageSearchResult.fromMcJson(dynamic json) {
    final data = resultsData(json);
    return PackageSearchResult(
      insurers: const [],
      packages: List.unmodifiable(parseDataList(json, InsurancePackage.fromJson)),
      total: jsonInt(jsonAt(jsonAt(json, 'results'), 'total')),
      dataLength: _dataLength(data),
    );
  }

  /// Car/EV insurer groups (empty for MC).
  final List<InsurerGroup> insurers;

  /// All packages flattened in API order (insurer by insurer) — the shared
  /// index FF used for every package-level `search*` list.
  final List<InsurancePackage> packages;

  /// MC only: `$.results.total` (getter `total`); FF showed
  /// 'ไม่พบข้อมูลประกัน' when it was 0.
  final int? total;

  /// `TelePackageSearchAPICall.data(json)!.length` — number of top-level
  /// entries in `$.results.data` (0 when missing; FF threw there). Spec 04
  /// shows 'ไม่พบข้อมูลบริษัทประกัน' when it is <= 0.
  final int dataLength;

  static int _dataLength(dynamic data) =>
      data is List ? data.length : (data == null ? 0 : 1); // JSONPath wraps a lone value
}
