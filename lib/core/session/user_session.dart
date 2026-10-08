import 'package:flutter/foundation.dart';

import 'url_cleaner.dart';

/// Who is using the web app — the values the Tanjai mobile app holds after
/// login (`FFAppState().accessToken`, `employeeID`, `profile*`).
///
/// For now the host passes them as launch query params; they are read once at
/// boot and then removed from the address bar (see [UrlCleaner]) so the token
/// doesn't linger in history, screenshots or a `Referer`. The JS bridge will
/// replace this hand-off later.
///
/// | query param  | mobile FFAppState field |
/// | ---          | ---                     |
/// | `token`      | accessToken             |
/// | `empId`      | employeeID              |
/// | `firstName`  | profileFirstName        |
/// | `lastName`   | profileLastName         |
/// | `phone`      | ProfilePhoneNumber      |
/// | `branchCode` | profileBranch           |
/// | `branchName` | profileUnitCodeName     |
class UserSession {
  UserSession._();

  static final UserSession instance = UserSession._();

  String accessToken = '';
  String employeeId = '';
  String firstName = '';
  String lastName = '';
  String phone = '';
  String branchCode = '';
  String branchName = '';

  bool get isSignedIn => accessToken.isNotEmpty && employeeId.isNotEmpty;

  /// Query params that carry user data. The router also strips these from
  /// every location (go_router re-reflects the initial URL after boot).
  static const launchParamNames = {'token', 'empId', 'firstName', 'lastName', 'phone', 'branchCode', 'branchName'};

  /// Reads the launch params from [uri] (normally `Uri.base`), keeping only
  /// values that pass a conservative shape check, then strips them from the
  /// visible URL.
  void loadFromLaunchUri(Uri uri) {
    final q = uri.queryParameters;
    accessToken = _clean(q['token'], _tokenPattern);
    employeeId = _clean(q['empId'], _idPattern);
    firstName = _clean(q['firstName'], _textPattern);
    lastName = _clean(q['lastName'], _textPattern);
    phone = _clean(q['phone'], _phonePattern);
    branchCode = _clean(q['branchCode'], _idPattern);
    branchName = _clean(q['branchName'], _textPattern);

    if (q.keys.any(launchParamNames.contains)) {
      UrlCleaner.removeQueryParams(launchParamNames);
    }
    if (kDebugMode) {
      // Never log the values themselves.
      debugPrint('[UserSession] signedIn=$isSignedIn');
    }
  }

  // JWT / opaque bearer tokens: base64url, dots, a few symbols.
  static final _tokenPattern = RegExp(r'^[A-Za-z0-9\-_.~+/=|]{1,4096}$');
  static final _idPattern = RegExp(r'^[A-Za-z0-9\-_]{1,32}$');
  static final _phonePattern = RegExp(r'^[0-9+\-]{0,20}$');
  // Names / branch names: letters (Thai + Latin), spaces, a few punctuation.
  static final _textPattern = RegExp(r'^[฀-๿A-Za-z0-9 .()\-/]{0,120}$');

  static String _clean(String? value, RegExp pattern) {
    final v = (value ?? '').trim();
    return pattern.hasMatch(v) ? v : '';
  }
}
