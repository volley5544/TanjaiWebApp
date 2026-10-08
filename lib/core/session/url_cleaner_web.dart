import 'package:web/web.dart' as web;

class UrlCleaner {
  /// `history.replaceState` with [names] dropped from the query string.
  static void removeQueryParams(Set<String> names) {
    final current = Uri.parse(web.window.location.href);
    final kept = Map.of(current.queryParameters)..removeWhere((k, _) => names.contains(k));
    final cleaned = current.replace(queryParameters: kept.isEmpty ? null : kept);
    var href = cleaned.toString();
    if (kept.isEmpty && href.endsWith('?')) href = href.substring(0, href.length - 1);
    web.window.history.replaceState(null, '', href);
  }
}
