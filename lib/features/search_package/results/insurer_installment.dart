import '../../../core/firebase/firestore_rest.dart';

/// Firestore `InsurerConfig2.InsurerInstallment` — insurer short names whose
/// result cards show 'ชำระเต็มจำนวนเท่านั้น' (FF read it via a single-record
/// StreamBuilder).
///
/// The collection requires auth, so on web the read returns null until the
/// JS bridge supplies a Firebase token. FF showed the label on EVERY card when
/// the record was null (`?? true`) and rendered an empty page while it was
/// missing; here a failed read is treated as an empty list (no label) so the
/// page still renders and doesn't claim "full payment only" for everyone.
abstract final class InsurerInstallment {
  static Future<List<String>>? _cache;

  static Future<List<String>> load() => _cache ??= _fetch();

  static Future<List<String>> _fetch() async {
    final doc = await FirestoreRest.instance.firstWhere('InsurerConfig2');
    final list = doc?['InsurerInstallment'];
    if (doc == null) _cache = null; // retry next time (e.g. once auth exists)
    return list is List ? list.map((e) => '$e').toList() : const [];
  }
}
