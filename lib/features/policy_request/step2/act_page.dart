import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../shared/request_widgets.dart';
import 'step2_data.dart';
import 'step2_rules.dart';
import 'widgets.dart';

/// FF `Homepage_Request_2_2` — พ.ร.บ. (motor / EV): 'ราคาไม่รวม พ.ร.บ' /
/// 'ราคารวม พ.ร.บ'; with 'ราคารวม' the พ.ร.บ. start date. The picked date is
/// written to [Step2Data.effectiveDateAct] at once (FF); 'ตกลง' validates,
/// writes [Step2Data.actOfLegislation] and pops `true`. No API — the price
/// effect is computed by the server on the step-2 save.
///
/// [effectiveDaysAct] = Firestore `effectiveDayConfig.effective_days_act`,
/// already read by page 2 (FF re-queried it here and blanked the page when
/// the collection was empty; null here = no day limit).
class ActPage extends StatefulWidget {
  const ActPage({super.key, required this.data, required this.actFlag, required this.effectiveDaysAct});

  final Step2Data data;

  /// FF insuranceInfoActFlag (detail `act_flg`).
  final String actFlag;
  final int? effectiveDaysAct;

  static Future<bool?> open(BuildContext context, Step2Data data, {required String actFlag, required int? days}) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ActPage(data: data, actFlag: actFlag, effectiveDaysAct: days)),
    );
  }

  @override
  State<ActPage> createState() => _ActPageState();
}

class _ActPageState extends State<ActPage> {
  Step2Data get _d => widget.data;

  // FF initial values (both may start ticked — kept).
  late bool _noSum = (_d.actOfLegislation != Step2Data.kActIncluded && _d.actOfLegislation != '') ||
      widget.actFlag == '0';
  late bool _sum = _d.actOfLegislation == Step2Data.kActIncluded || widget.actFlag == '1';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var start = today;
    if (_d.workType == 'งานต่ออายุ' || _d.workType == 'งานโอนโค้ด') {
      // FF: old expiry + 1 day (crashed when the date was not parseable —
      // falls back to today).
      final old = DateTime.tryParse(_d.oldVmiExpDate);
      if (old != null) start = DateTime(old.year, old.month, old.day + 1);
    }
    final last = DateTime(2050);
    if (start.isAfter(last)) start = last;
    final picked = await showDatePicker(context: context, initialDate: start, firstDate: start, lastDate: last);
    if (!mounted || picked == null) return;
    if (isWithinEffectiveDays(picked, widget.effectiveDaysAct)) {
      setState(() => _d.effectiveDateAct = getDateFormat(picked));
    } else {
      await showAlert(context, 'ไม่สามารถเลือกวันเกิน ${widget.effectiveDaysAct} วันได้กรุณาเลือกใหม่');
    }
  }

  Future<void> _ok() async {
    if (!_noSum && !_sum) {
      await showAlert(context, 'กรุณาเลือกราคารวมหรือไม่รวม พ.ร.บ');
      return;
    }
    if (_sum && _d.effectiveDateAct.isEmpty) {
      await showAlert(context, 'บังคับเลือกวันคุ้มครอง พ.ร.บ');
      return;
    }
    // FF: choosing 'ไม่รวม' keeps an earlier act date (still sent) — kept.
    _d.actOfLegislation = _noSum ? Step2Data.kActExcluded : Step2Data.kActIncluded;
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = _d.effectiveDateAct.isNotEmpty;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: step2SubAppBar(context, 'พ.ร.บ.'),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Step2SubLabel('พ.ร.บ.', tag: '(บังคับเลือก)'),
                      const SizedBox(height: 5),
                      Step2OptionBox(
                        label: 'ราคาไม่รวม พ.ร.บ',
                        value: _noSum,
                        onTap: () => setState(() {
                          _noSum = true;
                          _sum = false;
                        }),
                        onChanged: (v) => setState(() {
                          _noSum = v;
                          if (v) _sum = false;
                        }),
                      ),
                      const SizedBox(height: 25),
                      Step2OptionBox(
                        label: 'ราคารวม พ.ร.บ',
                        value: _sum,
                        onTap: () => setState(() {
                          _noSum = false;
                          _sum = true;
                        }),
                        onChanged: (v) => setState(() {
                          _sum = v;
                          if (v) _noSum = false;
                        }),
                      ),
                      if (_sum) ...[
                        const SizedBox(height: 20),
                        const Step2SubLabel('วันที่ต้องการเริ่มคุ้มครอง พ.ร.บ', tag: '(บังคับเลือก)'),
                        const SizedBox(height: 5),
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          onTap: _pickDate,
                          child: RequestBox(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      // FF placeholder text says '…ประกัน' (kept).
                                      hasDate
                                          ? showDateBESafe(_d.effectiveDateAct)
                                          : 'กรุณาเลือกวันที่ต้องการเริ่มคุ้มครองประกัน',
                                      style: AppText.style(
                                        fontSize: 15,
                                        color: hasDate ? Colors.black : kRequestPlaceholder,
                                      ),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: Icon(Icons.edit_calendar_outlined, color: AppColors.secondaryText, size: 24),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Step2OkButton(onPressed: _ok),
            ],
          ),
        ),
      ),
    );
  }
}
