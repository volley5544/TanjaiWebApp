// Defensive JSON readers shared by the search-package models.
//
// The FlutterFlow getters hard-cast (`value as String`) and threw when the
// server sent a number where a String was declared; these coerce instead.

/// Any JSON value as a String; JSON null → `''`.
String jsonStr(dynamic v) => '${v ?? ''}';

/// Like [jsonStr] but JSON null → the literal `'null'`.
///
/// Used for fields the pages pass through `checkNullValueAndReturn` (which
/// turns `'null'` into `'-'`) and for fields FlutterFlow read with a raw
/// `getJsonField(...).map((e) => e.toString())`, which also produced `'null'`.
String jsonStrN(dynamic v) => '$v';

/// Any JSON value as an int (int, integral double, or numeric string).
int? jsonInt(dynamic v) {
  if (v is int) return v;
  if (v is num && v == v.toInt()) return v.toInt();
  return int.tryParse('${v ?? ''}');
}

/// The elements of a JSON list, or the values of a JSON object; otherwise
/// empty. Mirrors JSONPath `[*]`, which matches both.
Iterable<dynamic> jsonChildren(dynamic v) {
  if (v is List) return v;
  if (v is Map) return v.values;
  return const [];
}

/// `json[key]` when [json] is an object, else null.
dynamic jsonAt(dynamic json, String key) => json is Map ? json[key] : null;

/// `$.results.data` of the insurance API envelope.
dynamic resultsData(dynamic json) => jsonAt(jsonAt(json, 'results'), 'data');

/// `$.results.data[:]` objects, parsed with [parse].
List<T> parseDataList<T>(dynamic json, T Function(Map<String, dynamic>) parse) => [
      for (final e in jsonChildren(resultsData(json)))
        if (e is Map) parse(Map<String, dynamic>.from(e)),
    ];
