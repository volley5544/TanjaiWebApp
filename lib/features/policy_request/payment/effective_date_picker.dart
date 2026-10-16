import 'package:flutter/material.dart';

import '../../../core/firebase/firebase_auth_rest.dart';
import '../../../core/firebase/firestore_rest.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../shared/request_widgets.dart';
import 'payment_rules.dart';

/// Dates chosen in the sheet (yyyy-MM-dd); null = not re-picked.
class EffectiveDates {
  const EffectiveDates({this.insure, this.act});

  final String? insure;
  final String? act;
}

/// Firestore `effectiveDayConfig` (single doc).
class EffectiveDayConfig {
  const EffectiveDayConfig({required this.insureDays, required this.actDays});

  final int insureDays;
  final int actDays;

  /// Reads with the anonymous Firebase token (the mobile app read it signed
  /// in; whether the rules allow unauthenticated reads is unknown).
  static Future<EffectiveDayConfig?> load() async {
    final token = await FirebaseAuthRest.idToken();
    if (token != null) FirestoreRest.instance.idToken = token;
    final doc = await FirestoreRest.instance.firstWhere('effectiveDayConfig');
    if (doc == null) return null;
    int n(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0);
    return EffectiveDayConfig(insureDays: n(doc['effective_days_insure']), actDays: n(doc['effective_days_act']));
  }
}

/// FF `EffectiveDatePickerComponent` in its bottom sheet (height 250,
/// barrier #BD000000, not dismissible). Pops with [EffectiveDates] after a
/// valid 'ตกลง', or null.
Future<EffectiveDates?> showEffectiveDatePicker(
  BuildContext context, {
  required bool insurerFlag,
  required bool actDateFlag,
  required bool actFlag,
  required String currentDate,
}) {
  return showModalBottomSheet<EffectiveDates>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xBD000000),
    builder: (_) => SizedBox(
      height: 250,
      child: EffectiveDatePickerSheet(
        insurerFlag: insurerFlag,
        actDateFlag: actDateFlag,
        actFlag: actFlag,
        currentDate: currentDate,
      ),
    ),
  );
}

/// Which dates the sheet asks for (FF case split; order matters).
enum EffectiveDateCase {
  /// `!insurerFlag && !actFlag` — insurer date only.
  insureOnly,

  /// `actFlag && insurerFlag && !actDateFlag` — พ.ร.บ. date only.
  actOnly,

  /// `actFlag && !insurerFlag && actDateFlag` — insurer date only, 180-day
  /// limit hard-coded in FF (kept).
  insureOnly180,

  /// both dates.
  both;

  static EffectiveDateCase of({required bool insurerFlag, required bool actDateFlag, required bool actFlag}) {
    if (!insurerFlag && !actFlag) return insureOnly;
    if (actFlag && insurerFlag && !actDateFlag) return actOnly;
    if (actFlag && !insurerFlag && actDateFlag) return insureOnly180;
    return both;
  }
}

/// FF validation of 'ตกลง' — returns the first failing alert text, or null.
/// [d1] = insurer date, [d2] = พ.ร.บ. date.
String? validateEffectiveDates({
  required EffectiveDateCase c,
  required DateTime? d1,
  required DateTime? d2,
  required String currentDate,
  required EffectiveDayConfig config,
  DateTime? now,
}) {
  bool notPast(DateTime d) => checkCurrentDateIsBeforeInputDate(currentDate, getDateFormat(d));
  String overLimit(int n) => 'ไม่สามารถเลือกวันเกิน  $n  วันได้กรุณาเลือกใหม่';
  switch (c) {
    case EffectiveDateCase.insureOnly:
      if (d1 == null) return 'กรุณาเลือกวันที่คุ้มครองประกัน';
      if (!notPast(d1)) return 'ไม่สามารถเลือกวันที่คุ้มครองประกันย้อนหลังได้';
      if (!checkDateBeforeAnotherDate(config.insureDays, d1, now: now)) return overLimit(config.insureDays);
    case EffectiveDateCase.actOnly:
      if (d2 == null) return 'กรุณาเลือกวันที่คุ้มครอง พ.ร.บ.';
      if (!notPast(d2)) return 'ไม่สามารถเลือกวันที่คุ้มครอง พ.ร.บ. ย้อนหลังได้';
      if (!checkDateBeforeAnotherDate(config.actDays, d2, now: now)) return overLimit(config.actDays);
    case EffectiveDateCase.insureOnly180:
      if (d1 == null) return 'กรุณาเลือกวันที่คุ้มครองประกัน';
      if (!notPast(d1)) return 'ไม่สามารถเลือกวันที่คุ้มครองประกันย้อนหลังได้';
      // FF: hard-coded 180 and single spaces (kept).
      if (!checkDateBeforeAnotherDate(180, d1, now: now)) return 'ไม่สามารถเลือกวันเกิน 180 วันได้กรุณาเลือกใหม่';
    case EffectiveDateCase.both:
      if (d1 == null) return 'กรุณาเลือกวันที่คุ้มครองประกัน';
      if (!notPast(d1)) return 'ไม่สามารถเลือกวันที่คุ้มครองประกันย้อนหลังได้';
      if (d2 == null) return 'กรุณาเลือกวันที่คุ้มครอง พ.ร.บ.';
      if (!notPast(d2)) return 'ไม่สามารถเลือกวันที่คุ้มครอง พ.ร.บ. ย้อนหลังได้';
      if (!checkDateBeforeAnotherDate(config.insureDays, d1, now: now)) return overLimit(config.insureDays);
      if (!checkDateBeforeAnotherDate(config.actDays, d2, now: now)) return overLimit(config.actDays);
  }
  return null;
}

class EffectiveDatePickerSheet extends StatefulWidget {
  const EffectiveDatePickerSheet({
    super.key,
    required this.insurerFlag,
    required this.actDateFlag,
    required this.actFlag,
    required this.currentDate,
  });

  /// true = the insurer effective date is still valid (no re-pick).
  final bool insurerFlag;

  /// true = the พ.ร.บ. effective date is still valid.
  final bool actDateFlag;

  /// the quotation includes พ.ร.บ.
  final bool actFlag;

  /// server date, yyyy-MM-dd.
  final String currentDate;

  @override
  State<EffectiveDatePickerSheet> createState() => _EffectiveDatePickerSheetState();
}

class _EffectiveDatePickerSheetState extends State<EffectiveDatePickerSheet> {
  late final Future<EffectiveDayConfig?> _config = EffectiveDayConfig.load();
  DateTime? _d1;
  DateTime? _d2;

  EffectiveDateCase get _case => EffectiveDateCase.of(
        insurerFlag: widget.insurerFlag,
        actDateFlag: widget.actDateFlag,
        actFlag: widget.actFlag,
      );

  DateTime get _current {
    final d = DateTime.tryParse(widget.currentDate) ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  bool _ok(DateTime? d) => d != null && checkCurrentDateIsBeforeInputDate(widget.currentDate, getDateFormat(d));

  /// FF: 'ตกลง' only when the relevant picked date(s) are today or later.
  bool get _showConfirm => switch (_case) {
        EffectiveDateCase.insureOnly || EffectiveDateCase.insureOnly180 => _ok(_d1),
        EffectiveDateCase.actOnly => _ok(_d2),
        EffectiveDateCase.both => _ok(_d1) && _ok(_d2),
      };

  Future<DateTime?> _pick(DateTime? previous) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _current,
      firstDate: _current,
      lastDate: DateTime(2050), // FF DateTime(2050) = 2050-01-01
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) return DateTime(picked.year, picked.month, picked.day);
    // FF quirk (kept): cancelling after an earlier pick resets it to today.
    return previous != null ? _current : null;
  }

  Future<void> _confirm(EffectiveDayConfig config) async {
    final error = validateEffectiveDates(
      c: _case,
      d1: _d1,
      d2: _d2,
      currentDate: widget.currentDate,
      config: config,
    );
    if (error != null) {
      await showAlert(context, error);
      return;
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      switch (_case) {
        EffectiveDateCase.insureOnly || EffectiveDateCase.insureOnly180 => EffectiveDates(insure: getDateFormat(_d1!)),
        EffectiveDateCase.actOnly => EffectiveDates(act: getDateFormat(_d2!)),
        EffectiveDateCase.both => EffectiveDates(insure: getDateFormat(_d1!), act: getDateFormat(_d2!)),
      },
    );
  }

  Widget _row(String label, DateTime? value, Future<void> Function() onTap, {double bottom = 0}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.style(fontWeight: FontWeight.normal))),
          Expanded(
            child: AppButton(
              text: value != null ? showDateBE(getDateFormat(value)) : 'เลือกวันคุ้มครอง',
              onPressed: onTap,
              height: 40,
              radius: 8,
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: FutureBuilder<EffectiveDayConfig?>(
        future: _config,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: SizedBox(width: 50, height: 50, child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          final config = snap.data;
          if (config == null) {
            // FF rendered an empty, non-dismissible sheet when the config
            // doc was missing (user stuck). The port offers a close button;
            // the caller then shows its 'กรุณาเลือกวันที่…' alert.
            return Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Color(0xFFFF0000), size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            );
          }
          return Column(
            children: [
              const SizedBox(height: 24),
              if (!widget.insurerFlag)
                _row('เลือกวันคุ้มครองประกัน', _d1, () async {
                  final d = await _pick(_d1);
                  if (mounted) setState(() => _d1 = d);
                }, bottom: 24),
              if (widget.actFlag && !widget.actDateFlag)
                _row('เลือกวันคุ้มครอง พ.ร.บ.', _d2, () async {
                  final d = await _pick(_d2);
                  if (mounted) setState(() => _d2 = d);
                }),
              const Spacer(),
              if (_showConfirm)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AppButton(
                    text: 'ตกลง',
                    onPressed: () => _confirm(config),
                    height: 50,
                    radius: 8,
                    color: kRequestOrange,
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
