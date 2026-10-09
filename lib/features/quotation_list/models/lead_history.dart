import '../../search_package/models/json_read.dart';

/// One step of `get-history` `$.results[:]` (FF's NonePackageShowStatus
/// component). Values are `toString()`ed as FF did, so null → `'null'`.
class LeadHistoryEntry {
  const LeadHistoryEntry({
    required this.status,
    required this.updatedAt,
    required this.updaterName,
    required this.reasonName,
  });

  final String status;
  final String updatedAt;
  final String updaterName;
  final String reasonName;

  static List<LeadHistoryEntry> listFromJson(dynamic json) => [
        for (final e in jsonChildren(jsonAt(json, 'results')))
          if (e is Map)
            LeadHistoryEntry(
              status: jsonStrN(e['status']),
              updatedAt: jsonStrN(e['updated_at']),
              updaterName: jsonStrN(e['name_th']),
              reasonName: jsonStrN(e['reason_name']),
            ),
      ];
}
