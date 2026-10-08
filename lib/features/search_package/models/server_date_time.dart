import 'json_read.dart';

/// Body of `check-in/getdate-time` (GetDateTimeAPICall).
///
/// Unlike the insurance APIs the envelope is `{status, message, info: {…}}`;
/// `status` is surfaced as `ApiResult.code`.
class ServerDateTime {
  const ServerDateTime({this.date, this.time, this.dateYmd});

  factory ServerDateTime.fromJson(dynamic json) {
    final info = jsonAt(json, 'info');
    String? s(String k) => jsonAt(info, k)?.toString();
    return ServerDateTime(date: s('Date'), time: s('Time'), dateYmd: s('DateYMD'));
  }

  /// FF getter `currentDate` — `$.info.Date`.
  final String? date;

  /// FF getter `currentTime` — `$.info.Time`.
  final String? time;

  /// FF getter `currentDateYMD` — `$.info.DateYMD` (`yyyy-MM-dd`, fed to
  /// `checkWeekendDate`).
  final String? dateYmd;
}
