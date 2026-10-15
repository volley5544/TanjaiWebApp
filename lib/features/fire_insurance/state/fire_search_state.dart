import 'package:flutter/foundation.dart';

import '../models/fire_package.dart';

/// Fire search-package flow state — replaces FF `FFAppState()
/// .fireInsuranceSearchPackageData` / `calEstimatedData` plus the values the
/// FF pages passed to each other as route params (kept here, never in the
/// URL). Reset when the search page opens, like FF's on-load reset.
class FireSearchState extends ChangeNotifier {
  FireSearchState._();

  static final FireSearchState instance = FireSearchState._();

  // FireInsuranceSearchPackageDataStruct ('' = FF null / unset).
  String houseTypeCode = '';
  String houseTypeName = '';

  /// `'01'` width × length, `'02'` square metres.
  String houseAreaType = '';
  String usableArea = '';
  String houseFloor = '';
  String sumInsureHouse = '';
  String sumInsureBuildin = '';
  String houseWidth = '';
  String houseLong = '';

  /// FF `calEstimatedData`; `estimatedPrice` is the building value.
  HouseEstimate estimate = const HouseEstimate();

  /// Set by the search button (FF fireInsurerListPage params). Null = no
  /// search yet: the result pages then send the user back to the search page.
  FireSearchCriteria? criteria;

  /// Package opened on the detail page (FF `packageData` param).
  FirePackage? selectedPackage;

  /// Last successful quotation save (PDF URLs for the quotation page; ids for
  /// the not-yet-ported InsuranceInfoPage1).
  FireQuotationSaveResult? lastSave;

  void reset() {
    houseTypeCode = '';
    houseTypeName = '';
    clearArea();
    estimate = const HouseEstimate();
    criteria = null;
    selectedPackage = null;
    lastSave = null;
  }

  /// FF area-type card tap: everything but the house type is cleared.
  void clearArea() {
    houseAreaType = '';
    usableArea = '';
    houseFloor = '';
    sumInsureHouse = '';
    sumInsureBuildin = '';
    houseWidth = '';
    houseLong = '';
  }

  void notify() => notifyListeners();
}

/// What the insurer list searches with (FF route params).
class FireSearchCriteria {
  const FireSearchCriteria({
    required this.yearMin,
    required this.yearMax,
    required this.sumInsured,
    required this.sumInsureHouse,
    required this.sumInsureBuilding,
  });

  final String yearMin;
  final String yearMax;

  /// sumInsureHouse + sumInsureBuilding.
  final String sumInsured;
  final String sumInsureHouse;
  final String sumInsureBuilding;
}
