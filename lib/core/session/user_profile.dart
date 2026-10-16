import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_environment.dart';
import '../config/local_api_auth.dart';
import '../network/api_client.dart';
import 'user_session.dart';

/// Employee profile + insurance-broker licence of the logged-in user — the
/// values the mobile app loads at PIN login (`pin_code_page`):
///
/// * `GetUserProfileAPICall` (`LOCAL/api/user-profile`, `$.DataUserInfo[0]`)
///   → `profilePositionName`, `profileLevel`, `profileBranch`, `branchCode`,
///   `profileUnitCodeName` (BranchName), `profileFullName`, …
/// * `GetUserInsuranceLicenseCall` (`LOCAL/api/insurance/license-insurance-broker`)
///   → `profileIsHaveInsuranceCard` = `$.dataInfo.NonLifeInsurance.status == 200`.
///
/// Loaded once per session (user request 2026-10-16: call the APIs instead
/// of adding launch params). Failures leave the FF defaults (empty / false).
class UserProfile {
  UserProfile._({ApiClient? client}) : _client = client ?? ApiClient.instance;

  static final UserProfile instance = UserProfile._();

  final ApiClient _client;
  Future<void>? _loading;
  bool loaded = false;

  /// FF `profilePositionName` (`DataUserInfo[0].PositionName`).
  String positionName = '';

  /// FF `profileLevel` (`DataUserInfo[0].Level`), e.g. 'ภาค'.
  String level = '';

  /// FF `profileBranch` (`DataUserInfo[0].Branch`).
  String branch = '';

  /// FF `branchCode` (`DataUserInfo[0].BranchCode`).
  String branchCode = '';

  /// FF `profileUnitCodeName` (`DataUserInfo[0].BranchName`).
  String branchName = '';

  /// FF `profileFullName` (`DataUserInfo[0].fullName`).
  String fullName = '';

  /// FF `ProfilePhoneNumber` (`DataUserInfo[0].MobileNumber`).
  String phone = '';

  /// FF `profileIsHaveInsuranceCard`.
  bool haveInsuranceCard = false;

  /// FF `profileInsuranceLicenseLicenseNo` / `…ExpireDate`.
  String licenseNo = '';
  String licenseExpireDate = '';

  /// Loads both APIs once; later calls await the same load.
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final session = UserSession.instance;
    if (!session.isSignedIn) return;
    final base = AppEnvironment.current.localApiBase;
    final body = {'token': session.accessToken, 'api_url': base};
    const headers = {'Authorization': kLocalApiBasicAuth};

    final p = await _client.postJson('$base/api/user-profile', body, headers: headers);
    final info = _first(_at(p.json, 'DataUserInfo'));
    if (p.statusCode == 200 && info is Map) {
      String s(String k) => info[k] == null ? '' : '${info[k]}';
      positionName = s('PositionName');
      level = s('Level');
      branch = s('Branch');
      branchCode = s('BranchCode');
      branchName = s('BranchName');
      fullName = s('fullName');
      phone = s('MobileNumber');
    }

    final l = await _client.postJson('$base/api/insurance/license-insurance-broker', body, headers: headers);
    final nonLife = _at(_at(l.json, 'dataInfo'), 'NonLifeInsurance');
    if (l.statusCode == 200) {
      haveInsuranceCard = '${_at(nonLife, 'status')}' == '200';
      if (haveInsuranceCard) {
        final d = _first(_at(nonLife, 'data'));
        licenseNo = d is Map && d['LicenseNumber'] != null ? '${d['LicenseNumber']}' : '';
        licenseExpireDate = d is Map && d['ExpirationDate'] != null ? '${d['ExpirationDate']}' : '';
      }
    }
    loaded = true;
    // Never log the values (PII).
    if (kDebugMode) debugPrint('[UserProfile] loaded profile=${p.statusCode} license=${l.statusCode}');
  }

  static dynamic _at(dynamic json, String key) => json is Map ? json[key] : null;
  static dynamic _first(dynamic v) => v is List && v.isNotEmpty ? v.first : (v is Map ? v : null);
}
