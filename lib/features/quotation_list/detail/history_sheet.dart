import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../models/lead_history.dart';

const _green = Color(0xFF24D200);

/// Port of FF `NonePackageShowStatusComponent` ('ติดตามงาน' bottom sheet,
/// 70 % high): a green timeline of the earlier statuses (status, 'โดย : …',
/// time, B.E. date, 'เหตุผล : …') and the latest status at the bottom.
///
/// FF quirks kept: each earlier step's thin bar gets a random colour; the
/// latest step is an ExpandablePanel whose collapsed and expanded bodies are
/// identical, so expanding only flips the arrow.
class HistorySheet extends StatefulWidget {
  const HistorySheet({super.key, required this.entries});

  final List<LeadHistoryEntry> entries;

  static Future<void> show(BuildContext context, List<LeadHistoryEntry> entries) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: HistorySheet(entries: entries),
        ),
      );

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
  final _random = math.Random();
  late final List<Color> _barColors = [
    for (var i = 0; i < widget.entries.length; i++)
      Color.fromARGB(255, _random.nextInt(256), _random.nextInt(256), _random.nextInt(256)),
  ];
  bool _expanded = false;

  /// FF `dateTimeFormat("Hm", parseStringToDatetime(x))` (24-hour HH:mm).
  static String _time(String s) {
    try {
      return DateFormat('Hm').format(DateTime.parse(s));
    } catch (_) {
      return '';
    }
  }

  static String _date(String s) {
    try {
      return showDateBE(s);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    // FF removeLastIndexList: every step but the latest.
    final earlier = entries.isEmpty ? const <LeadHistoryEntry>[] : entries.sublist(0, entries.length - 1);
    final last = entries.isEmpty ? null : entries.last;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.secondaryBackground,
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_sharp, color: Colors.black, size: 35),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < earlier.length; i++) _earlierStep(earlier[i], _barColors[i]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: _lastStep(last),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _earlierStep(LeadHistoryEntry e, Color barColor) {
    final black = AppText.style(color: Colors.black);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 25, height: 25, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
            Container(width: 5, height: 150, color: _green),
          ],
        ),
        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.7,
          child: Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(width: 3, height: 150, color: barColor),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.status.isEmpty ? '[call_status]' : e.status,
                            style: AppText.style(fontSize: 18, color: Colors.black)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text('โดย : ${e.updaterName}',
                                  style: AppText.style(fontSize: 15, color: Colors.black)),
                            ),
                            Column(
                              children: [
                                Text(_time(e.updatedAt), style: AppText.style(fontSize: 12, color: Colors.black)),
                                Text(_orDate(e.updatedAt), style: AppText.style(fontSize: 12, color: Colors.black)),
                              ],
                            ),
                          ],
                        ),
                        Text('เหตุผล : ${e.reasonName}', style: black),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// FF `valueOrDefault(showDateBE(x), 'date')`.
  String _orDate(String s) {
    final d = _date(s);
    return d.isEmpty ? 'date' : d;
  }

  Widget _lastStep(LeadHistoryEntry? e) {
    const grey = Color(0x8A000000);
    final updatedAt = e?.updatedAt ?? '';
    final body = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('โดย : ${e?.updaterName}', style: AppText.style(fontSize: 15, color: grey)),
          ),
        ),
        Column(
          children: [
            Text(_time(updatedAt), style: AppText.style(fontSize: 12, color: grey)),
            Text(_orDate(updatedAt), style: AppText.style(fontSize: 12, color: grey)),
          ],
        ),
      ],
    );
    final status = e?.status ?? '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 25, height: 25, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.7,
          child: Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(width: 3, height: 100, color: AppColors.tertiary),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _expanded = !_expanded),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(status.isEmpty ? 'status' : status,
                                      style: AppText.style(fontSize: 18, color: Colors.black)),
                                ),
                                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                              ],
                            ),
                          ),
                          body,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
