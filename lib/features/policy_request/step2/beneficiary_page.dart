import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../data/policy_request_api.dart';
import '../shared/request_widgets.dart';
import 'step2_data.dart';
import 'widgets.dart';

/// Finance companies (`GetFinanceCall` → `results.data[].beneficiary_name`)
/// followed by FF's extra 'อื่นๆ' option.
List<String> financeOptions(dynamic financeJson) => [
      for (final e in (jsonPathGet(financeJson, 'results.data') as List?) ?? const [])
        if (e is Map && e['beneficiary_name'] != null) '${e['beneficiary_name']}',
      'อื่นๆ',
    ];

/// FF `Homepage_Request_2_3` — ผู้รับผลประโยชน์ (motor / EV / MC).
///
/// As in FF, the checkbox and the dropdown write
/// [Step2Data.beneficiaryName] at once (so back keeps them); 'ตกลง' only
/// copies the 'อื่นๆ' text and pops `true`. No validation here — page 2
/// requires a name.
class BeneficiaryPage extends StatefulWidget {
  const BeneficiaryPage({super.key, required this.data, required this.insuredName});

  final Step2Data data;

  /// `'<insuranceInfoFirstName> <insuranceInfoLastName>'`.
  final String insuredName;

  static Future<bool?> open(BuildContext context, Step2Data data, {required String insuredName}) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BeneficiaryPage(data: data, insuredName: insuredName)),
    );
  }

  @override
  State<BeneficiaryPage> createState() => _BeneficiaryPageState();
}

class _BeneficiaryPageState extends State<BeneficiaryPage> {
  final _other = TextEditingController();
  bool _loading = true;
  List<String> _finance = const [];

  /// FF: ticked whenever a name is set (any name, a finance company included).
  late bool _insured = widget.data.beneficiaryName.isNotEmpty;
  String? _dropDown;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await PolicyRequestApi.instance.getFinance();
    if (!mounted) return;
    setState(() => _loading = false);
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาด (${r.statusCode})');
    } else if (r.code != 200) {
      await showAlert(context, 'พบข้อผิดพลาด (${r.code})');
    } else {
      setState(() => _finance = financeOptions(r.json));
    }
  }

  void _ok() {
    if (_dropDown == 'อื่นๆ') widget.data.beneficiaryName = _other.text;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return PopScope(
      canPop: false,
      child: UnfocusOnTap(
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: step2SubAppBar(context, 'ผู้รับผลประโยชน์'),
          body: _loading
              ? const PageLoadingView()
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              const Step2SubLabel('ชื่อผู้รับผลประโยชน์', tag: '(บังคับเลือก)'),
                              const SizedBox(height: 5),
                              Step2OptionBox(
                                label: 'ผู้รับประโยชน์เป็นผู้เอาประกัน',
                                value: _insured,
                                activeColor: AppColors.success,
                                // FF: tapping the box only hides the keyboard.
                                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                                onChanged: (v) => setState(() {
                                  _insured = v;
                                  d.beneficiaryName = v ? widget.insuredName : '';
                                }),
                              ),
                              if (!_insured) ...[
                                const SizedBox(height: 15),
                                const Step2SubLabel(
                                  'ผู้รับผลประโยชน์',
                                  tag: '(บังคับเลือกอื่น ๆ)',
                                  color: AppColors.primaryText,
                                ),
                                const SizedBox(height: 5),
                                Step2SearchDropdown(
                                  options: _finance,
                                  value: _dropDown,
                                  hint: 'เลือกผู้รับผลประโยชน์',
                                  onChanged: (v) => setState(() {
                                    _dropDown = v;
                                    d.beneficiaryName = v;
                                  }),
                                ),
                              ],
                              if (_insured || _dropDown != 'อื่นๆ') ...[
                                const SizedBox(height: 15),
                                const Step2SubLabel('ผู้รับผลประโยชน์', color: AppColors.primaryText),
                                const SizedBox(height: 5),
                                RequestBox(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      d.beneficiaryName,
                                      style: AppText.style(fontSize: 15, color: Colors.black),
                                    ),
                                  ),
                                ),
                              ],
                              if (_dropDown == 'อื่นๆ') ...[
                                const SizedBox(height: 15),
                                Step2SubLabel(
                                  'กรณีเลือกอื่น ๆ',
                                  tag: _insured ? '' : '(บังคับกรอก)',
                                  color: AppColors.primaryText,
                                ),
                                const SizedBox(height: 5),
                                RequestBox(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: TextField(
                                      controller: _other,
                                      autofocus: true,
                                      style: AppText.style(fontSize: 15, color: Colors.black),
                                      decoration: InputDecoration(
                                        hintText: 'ระบุชื่อผู้รับผลประโยชน์',
                                        hintStyle: AppText.style(fontSize: 15, color: kRequestGrey),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
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
      ),
    );
  }
}
