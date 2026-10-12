import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_environment.dart';
import 'firebase_auth_rest.dart';

/// FF `uploadData` over the Storage REST API: uploads to
/// `users/<uid>/uploads/<microsecondsSinceEpoch>.<ext>` (the mobile app's
/// path pattern) and returns the same kind of token download URL that
/// `getDownloadURL()` gives, or null on any failure.
class FirebaseStorageRest {
  FirebaseStorageRest._();

  static Future<String?> uploadImage(Uint8List bytes, {String ext = 'jpg', String contentType = 'image/jpeg'}) async {
    if (bytes.isEmpty) return null;
    final token = await FirebaseAuthRest.idToken();
    final uid = FirebaseAuthRest.uid;
    if (token == null || uid == null || uid.isEmpty) return null;

    final bucket = AppEnvironment.current.storageBucket;
    final path = 'users/$uid/uploads/${DateTime.now().microsecondsSinceEpoch}.$ext';
    try {
      final res = await http
          .post(
            Uri.parse('https://firebasestorage.googleapis.com/v0/b/$bucket/o'
                '?uploadType=media&name=${Uri.encodeQueryComponent(path)}'),
            headers: {'Authorization': 'Firebase $token', 'Content-Type': contentType},
            body: bytes,
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('[FirebaseStorageRest] upload failed (HTTP ${res.statusCode})');
        return null;
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final downloadToken = '${json['downloadTokens'] ?? ''}'.split(',').first;
      if (downloadToken.isEmpty) return null;
      return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path)}'
          '?alt=media&token=$downloadToken';
    } catch (e) {
      if (kDebugMode) debugPrint('[FirebaseStorageRest] upload error: $e');
      return null;
    }
  }
}
