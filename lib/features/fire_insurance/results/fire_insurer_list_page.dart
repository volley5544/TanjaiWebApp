import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart' as ff;
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../../router/app_router.dart';
import '../../search_package/models/insurance_package.dart' show kNoImageUrl;
import '../../search_package/results/widgets/result_widgets.dart';
import '../data/fire_insurance_api.dart';
import '../models/fire_package.dart';
import '../state/fire_search_state.dart';

/// Port of FF `fireInsurerListPage` (ค้นหาประกันอัคคีภัย): loads the packages
/// for the total sum insured, one card per package, and a toggle that
/// reverses the list order ('ราคาเบี้ย น้อย -> มาก' / 'มาก -> น้อย' — FF only
/// reversed the API order, it never sorted).
class FireInsurerListPage extends StatefulWidget {
  const FireInsurerListPage({super.key});

  @override
  State<FireInsurerListPage> createState() => _FireInsurerListPageState();
}

class _FireInsurerListPageState extends State<FireInsurerListPage> {
  final _state = FireSearchState.instance;
  List<FirePackage> _packages = const [];
  bool _loading = true;

  /// FF `textBool` (starts false → 'น้อย -> มาก').
  bool _descending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.fireSearch);
    }
  }

  Future<void> _load() async {
    final criteria = _state.criteria;
    // Opened without a search (e.g. browser refresh) → back to the search.
    if (criteria == null) {
      context.go(AppRoutes.fireSearch);
      return;
    }
    final r = await FireInsuranceApi.instance.getPackages(
      yearCoverMin: criteria.yearMin,
      yearCoverMax: criteria.yearMax,
      sumInsured: criteria.sumInsured,
    );
    if (!mounted) return;
    // FF: alert, then leave the page.
    if (r.statusCode != 200) {
      await showAlert(context, 'พบข้อผิดพลาด connection (${r.statusCode})');
      if (mounted) _back();
      return;
    }
    if (r.code != 200) {
      await showAlert(context, '${r.message}');
      if (mounted) _back();
      return;
    }
    setState(() {
      _packages = r.data ?? const [];
      _loading = false;
    });
  }

  void _reverse() {
    setState(() {
      _packages = _packages.reversed.toList();
      _descending = !_descending;
    });
  }

  void _openDetail(FirePackage p) {
    _state.selectedPackage = p;
    context.push(AppRoutes.fireDetail);
  }

  @override
  Widget build(BuildContext context) {
    final criteria = _state.criteria;
    return PopScope(
      canPop: false,
      child: UnfocusOnTap(
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: resultAppBar(title: 'ค้นหาประกันอัคคีภัย', onBack: _back),
          body: SafeArea(
            child: _loading || criteria == null
                ? const PageLoadingView(message: 'กำลังค้นหาแผนประกัน')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _descending ? 'ราคาเบี้ย มาก -> น้อย' : 'ราคาเบี้ย น้อย -> มาก',
                                style: AppText.style(fontSize: 16),
                              ),
                            ),
                            _SortButton(onTap: _reverse),
                          ],
                        ),
                      ),
                      const Divider(thickness: 2),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _packages.isEmpty
                              ? const _EmptyBox()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
                                  itemCount: _packages.length,
                                  itemBuilder: (context, i) => Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                                    child: _PackageCard(
                                      package: _packages[i],
                                      sumInsureHouse: criteria.sumInsureHouse,
                                      sumInsureBuilding: criteria.sumInsureBuilding,
                                      onDetail: () => _openDetail(_packages[i]),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// The grey pill 'เรียงราคาเบี้ยประกัน/ปี' with up/down arrows (190×40).
class _SortButton extends StatelessWidget {
  const _SortButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        width: 190,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: const Color(0x3EA6A6A6), borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 25,
              child: Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional(-1, 0),
                    child: Icon(Icons.arrow_upward, color: AppColors.primaryText, size: 18),
                  ),
                  Align(
                    alignment: AlignmentDirectional(1, 0),
                    child: Icon(Icons.arrow_downward, color: AppColors.primaryText, size: 18),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('เรียงราคาเบี้ยประกัน/ปี', style: AppText.style(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: size.width,
          height: size.height * 0.53,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            boxShadow: const [BoxShadow(blurRadius: 1, color: Color(0x33000000))],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('ไม่พบข้อมูลรายการประกัน', style: AppText.style(fontSize: 20, color: kGrayIcon)),
        ),
      ),
    );
  }
}

/// One package card: logo, company, rows, premium/year and 'รายละเอียด'.
class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.sumInsureHouse,
    required this.sumInsureBuilding,
    required this.onDetail,
  });

  final FirePackage package;
  final String sumInsureHouse;
  final String sumInsureBuilding;
  final VoidCallback onDetail;

  /// FF `valueOrDefault(showNumberWithComma(x), '0')`.
  static String _amount(String? v) {
    final s = ff.showNumberWithComma(v ?? '');
    return s.isEmpty ? '0' : s;
  }

  Widget _row(String label, String value, {bool small = false}) {
    final style = small
        ? AppText.style(fontSize: 10, color: AppColors.secondaryText)
        : AppText.style(fontSize: 11);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 20),
            child: Text(value, style: style),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logo = package.logo ?? '';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBtnText,
        boxShadow: kCardShadow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.only(left: 6, top: 4),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 15, 30),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: InsurerLogo(url: logo.isEmpty || logo == 'null' ? kNoImageUrl : logo),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('${package.serialName}', style: AppText.style(fontSize: 11)),
                    ),
                    _row('ประเภทประกัน', 'ประกันอัคคีภัย'),
                    _row('แผนประกัน', '${package.packageName}'),
                    _row('ทุนประกันภัย', _amount(package.sumInsured), small: true),
                    _row('สิ่งปลูกสร้าง (ไม่รวมฐานราก)', _amount(sumInsureHouse), small: true),
                    _row('ทรัพย์สินภายในสิ่งปลูกสร้าง', _amount(sumInsureBuilding), small: true),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ราคาเบี้ยประกัน/ปี', style: AppText.style(fontSize: 10, color: AppColors.secondaryText)),
                    Text('${_amount(package.grossTotal)} บาท', style: AppText.style(fontSize: 11)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20, bottom: 10),
                child: DetailButton(onPressed: onDetail),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
