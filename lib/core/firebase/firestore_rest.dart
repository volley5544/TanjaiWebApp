import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_environment.dart';

/// Minimal read-only Firestore client over the REST API — no Firebase SDK.
///
/// Requests are unauthenticated, so only collections whose rules say
/// `allow read: if true` are reachable (`dataList`, `Vehicle_Type_Dropdown`,
/// …). `hideInAppContent` needs `request.auth != null`; callers must handle a
/// null result (the JS bridge will supply a Firebase ID token later).
class FirestoreRest {
  FirestoreRest._();

  static final FirestoreRest instance = FirestoreRest._();

  /// Optional Firebase ID token for auth-only collections (set by the bridge).
  String? idToken;

  String get _base =>
      'https://firestore.googleapis.com/v1/projects/${AppEnvironment.firestoreProjectId}'
      '/databases/(default)/documents';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (idToken != null && idToken!.isNotEmpty) 'Authorization': 'Bearer $idToken',
      };

  /// One document by path (`collection/docId`), fields as plain Dart values.
  Future<Map<String, dynamic>?> getDocument(String path) async {
    try {
      final res = await http.get(Uri.parse('$_base/$path'), headers: _headers);
      if (res.statusCode != 200) return null;
      final doc = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return decodeFields(doc['fields']);
    } catch (e) {
      if (kDebugMode) debugPrint('[FirestoreRest] get $path failed: $e');
      return null;
    }
  }

  /// First document of [collection], optionally `where field == value`.
  /// Mirrors FlutterFlow's `queryXRecordOnce(singleRecord: true)`.
  Future<Map<String, dynamic>?> firstWhere(
    String collection, {
    String? field,
    String? equals,
  }) async {
    final query = <String, dynamic>{
      'from': [
        {'collectionId': collection},
      ],
      'limit': 1,
      if (field != null)
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': field},
            'op': 'EQUAL',
            'value': {'stringValue': equals},
          },
        },
    };
    try {
      final res = await http.post(
        Uri.parse('$_base:runQuery'),
        headers: _headers,
        body: jsonEncode({'structuredQuery': query}),
      );
      if (res.statusCode != 200) return null;
      final rows = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      for (final row in rows) {
        final doc = (row as Map)['document'];
        if (doc != null) return decodeFields((doc as Map)['fields']);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[FirestoreRest] query $collection failed: $e');
      return null;
    }
  }

  /// Firestore typed-value map → plain Dart map.
  static Map<String, dynamic> decodeFields(dynamic fields) {
    if (fields is! Map) return {};
    return fields.map((k, v) => MapEntry(k as String, decodeValue(v)));
  }

  static dynamic decodeValue(dynamic v) {
    if (v is! Map) return null;
    if (v.containsKey('stringValue')) return v['stringValue'];
    if (v.containsKey('booleanValue')) return v['booleanValue'];
    if (v.containsKey('integerValue')) return int.tryParse('${v['integerValue']}');
    if (v.containsKey('doubleValue')) return (v['doubleValue'] as num).toDouble();
    if (v.containsKey('timestampValue')) return v['timestampValue'];
    if (v.containsKey('referenceValue')) return v['referenceValue'];
    if (v.containsKey('arrayValue')) {
      return ((v['arrayValue'] as Map)['values'] as List? ?? []).map(decodeValue).toList();
    }
    if (v.containsKey('mapValue')) return decodeFields((v['mapValue'] as Map)['fields']);
    return null;
  }
}
