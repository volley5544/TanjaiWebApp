import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_environment.dart';

/// Anonymous Firebase Auth over the Identity Toolkit REST API (no SDK) —
/// same approach as sawadLoanUniversal's `FirebaseAuthRest`.
///
/// Why: the mobile app uploads request photos to Storage under
/// `users/<uid>/uploads/`, and the Storage rules only let `uid` write there.
/// The mobile app gets its uid by signing every employee in as
/// `<empId>@srisawadinsurance.com` with one shared hard-coded password — a
/// security finding the web build must not copy. An anonymous identity gives
/// the web its own uid (and makes auth-only Firestore docs readable).
///
/// Requires Authentication → Sign-in method → **Anonymous** to be enabled in
/// the `sawad-new-ibs` project; until then [idToken] returns null and callers
/// show their normal failure message.
class FirebaseAuthRest {
  FirebaseAuthRest._();

  static const _signUpUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp';
  static const _renewMargin = Duration(minutes: 5);

  static String? _idToken;
  static DateTime? _expiresAt;
  static Future<String?>? _inFlight;

  /// The anonymous uid, once signed in.
  static String? uid;

  /// A valid ID token, signing in (once, shared by concurrent callers) when
  /// needed. Never throws; null when sign-in isn't possible.
  static Future<String?> idToken() {
    final cached = _idToken;
    final expiry = _expiresAt;
    if (cached != null && expiry != null && DateTime.now().isBefore(expiry.subtract(_renewMargin))) {
      return Future.value(cached);
    }
    return _inFlight ??= _signIn().whenComplete(() => _inFlight = null);
  }

  static Future<String?> _signIn() async {
    try {
      final res = await http
          .post(
            Uri.parse('$_signUpUrl?key=${AppEnvironment.firebaseApiKey}'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'returnSecureToken': true}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        // Usually ADMIN_ONLY_OPERATION = anonymous sign-in disabled.
        if (kDebugMode) debugPrint('[FirebaseAuthRest] sign-in failed (HTTP ${res.statusCode})');
        return null;
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final token = '${json['idToken'] ?? ''}';
      if (token.isEmpty) return null;
      _idToken = token;
      _expiresAt = DateTime.now().add(Duration(seconds: int.tryParse('${json['expiresIn']}') ?? 3600));
      uid = '${json['localId'] ?? ''}';
      return token;
    } catch (e) {
      if (kDebugMode) debugPrint('[FirebaseAuthRest] sign-in error: $e');
      return null;
    }
  }
}
