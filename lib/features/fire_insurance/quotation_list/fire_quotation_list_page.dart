import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/utils/tel_link.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../../router/app_router.dart';
import '../../quotation_list/list/quotation_list_page.dart' show NoDataBox, SearchNameBox, SlideUpOnLoad;
import '../../search_package/data/api_result.dart';
import '../data/fire_insurance_api.dart';
import '../models/fire_lead.dart';
import '../state/fire_quotation_list_state.dart';

/// FlutterFlow's `black600` theme colour (card text).
const _black600 = Color(0xFF090F13);

/// Port of FF `fireInsuranceListPage` (จำนวนลูกค้าทั้งหมด) — the fire
/// quotation list, opened from the home page's 'ประกันอัคคีภัย' →
/// 'ดูทั้งหมด'.
///
/// * On open: `house/leads/get`. HTTP≠200 → 'พบข้อผิดพลาดConnection (<code>)';
///   body code not 200/404 → 'พบข้อผิดพลาด (<code>)'; 404 → 'ไม่พบข้อมูลในระบบ'.
/// * Search filters on `first_name` (case-sensitive contains, as FF); the
///   refresh icon only clears the search (as FF).
/// * 'ทำประกัน' → confirm → MakeFireInsuranceListPage with that one lead.
///
/// Mobile-only parts left out: the build-version gate and the reset of the
/// motor search-form FFAppState fields.
class FireQuotationListPage extends StatefulWidget {
  const FireQuotationListPage({super.key});

  @override
  State<FireQuotationListPage> createState() => _FireQuotationListPageState();
}

class _FireQuotationListPageState extends State<FireQuotationListPage> {
  final _search = TextEditingController();
  bool _loading = true;
  ApiResult<List<FireLead>>? _result;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await FireInsuranceApi.instance.getLeads();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = r;
    });
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.statusCode})');
    } else if (r.code != 200 && r.code != 404) {
      await showAlert(context, 'พบข้อผิดพลาด (${r.code})');
    }
  }

  void _back() {
    // FF: goNamed(SuperAppPage).
    // TODO(bridge): hand control back to the host app instead of the web menu.
    context.go(AppRoutes.home);
  }

  bool _visible(FireLead lead) {
    final q = _search.text;
    return q.isEmpty || containWordinStringUrl(q, lead.firstName ?? '');
  }

  Future<void> _makeInsurance(FireLead lead) async {
    final ok = await showConfirm(context, 'ต้องการจะบันทึกเตรียมข้อมูลใช่หรือไม่?');
    if (!ok || !mounted) return;
    FireQuotationListState.instance.detailLeads = [lead];
    context.push(AppRoutes.fireQuotationDetail);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: UnfocusOnTap(
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: tanjaiAppBar(
            title: 'จำนวนลูกค้าทั้งหมด',
            titleColor: const Color(0xFF003063),
            backColor: AppColors.sheetButtonOrange,
            onBack: _back,
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 15, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: SearchNameBox(controller: _search),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          onTap: _search.clear,
                          child: Icon(
                            Icons.refresh_sharp,
                            color: _search.text.isEmpty ? const Color(0xFFB3B3B3) : Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _loading ? const PageLoadingView() : _body()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final r = _result;
    if (r == null || !r.isHttpOk) return const SizedBox.shrink();
    if (r.code == 404) return const NoDataBox();
    if (r.code != 200) return const SizedBox.shrink();
    final leads = r.data ?? const <FireLead>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: SlideUpOnLoad(
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 50),
          itemCount: leads.length,
          itemBuilder: (context, i) {
            final lead = leads[i];
            if (!_visible(lead)) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _FireLeadCard(lead: lead, onMakeInsurance: () => _makeInsurance(lead)),
            );
          },
        ),
      ),
    );
  }
}

class _FireLeadCard extends StatelessWidget {
  const _FireLeadCard({required this.lead, required this.onMakeInsurance});

  final FireLead lead;
  final VoidCallback onMakeInsurance;

  static final _text = AppText.style(fontSize: 15, color: _black600);

  /// FF `valueOrDefault(x, default)`: null or '' → [fallback]. The FF
  /// defaults ('sabaide', '40000') are kept.
  static String _or(String? v, String fallback) => v == null || v.isEmpty ? fallback : v;

  @override
  Widget build(BuildContext context) {
    final phone = lead.phoneNumber;
    // FF responsiveVisibility(tablet: false): hidden for 479 ≤ width < 767.
    final width = MediaQuery.sizeOf(context).width;
    final showPhone = phone != null && phone.isNotEmpty && !(width >= 479 && width < 767);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF95A1AC)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(
                      'ชื่อลูกค้า',
                      '${checkNullValueAndReturn(lead.firstName)} ${checkNullValueAndReturn(lead.lastName)}',
                      maxLines: 2,
                      rightPadding: 50,
                    ),
                    _row('ประเภทประกัน', _or(lead.insuranceType, 'ประกันอัคคีภัย')),
                    _row('เเผนประกัน', _or(lead.detail.raw('package_name'), 'sabaide')),
                    _row('ทุนประกัน', _or(lead.detail.raw('sum_insured_name'), '40000')),
                  ].expand((w) => [w, const SizedBox(height: 4)]).toList()..removeLast(),
                ),
              ),
              if (showPhone)
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, right: 10),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      onTap: () => launchTel(phone),
                      child: Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _black600)),
                        child: const Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Icon(Icons.phone_in_talk_outlined, color: _black600, size: 30),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: AppButton(
                    text: 'ทำประกัน',
                    onPressed: onMakeInsurance,
                    width: 110,
                    height: 35,
                    color: AppColors.sheetButtonOrange,
                    fontSize: 15,
                    radius: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {int? maxLines, double rightPadding = 0}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: Text(label, style: _text)),
        SizedBox(width: 10, child: Text(':', style: _text)),
        Expanded(
          flex: 6,
          child: Padding(
            padding: EdgeInsets.only(right: rightPadding),
            child: Text(value, maxLines: maxLines, style: _text),
          ),
        ),
      ],
    );
  }
}
