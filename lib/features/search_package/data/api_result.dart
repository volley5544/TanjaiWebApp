/// Outcome of one search-package API call, carrying what the FF pages checked:
///
/// ```dart
/// if (r.statusCode != 200) showAlert('พบข้อผิดพลาด (${r.statusCode})');
/// else if (r.code != 200) showAlert(r.message);
/// else use(r.data!);
/// ```
///
/// [statusCode] is the HTTP status, or -1 when no response arrived.
/// [code] is the body's `$.code` (`$.status` for getdate-time); [message] is
/// `$.message.toString()`. [data] is parsed whenever a JSON body arrived (even
/// with a non-200 code), and is null otherwise.
class ApiResult<T> {
  const ApiResult({required this.statusCode, this.code, this.message, this.data});

  final int statusCode;
  final int? code;
  final String? message;
  final T? data;

  bool get isHttpOk => statusCode == 200;

  /// HTTP 200 and body code 200.
  bool get isOk => statusCode == 200 && code == 200;
}
