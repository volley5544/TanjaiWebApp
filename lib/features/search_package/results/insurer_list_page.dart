import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../router/app_router.dart';
import '../data/search_package_api.dart';
import '../models/insurance_package.dart';
import '../product_type.dart';
import '../state/search_package_state.dart';
import 'insurer_installment.dart';
import 'widgets/result_widgets.dart';

/// Package-level result list with compare check-boxes (FF `InsurerListPage`,
/// spec 05).
///
/// * MC: opened from the search page; calls `get_package_mc` itself.
/// * Car / EV: opened from [InsurerOverallPage]; reuses its result (FF's
///   `if (true)` branch — no API call), pre-filtered to the chosen insurer.
class InsurerListPage extends StatefulWidget {
  const InsurerListPage({super.key, required this.product});

  final ProductType product;

  @override
  State<InsurerListPage> createState() => _InsurerListPageState();
}

class _InsurerListPageState extends State<InsurerListPage> {
  late final SearchPackageState _state = SearchPackageState.of(widget.product);
  late final bool _isMc = widget.product == ProductType.mc;

  /// MC success check of LIST_OK (`total != 0 && code == 200 && status == 200`).
  bool _mcOk = false;
  List<String> _installment = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final missing = _isMc ? _state.criteria == null : _state.result == null;
      if (missing) {
        context.go(AppRoutes.search(widget.product)); // opened without a search (refresh)
        return;
      }
      _isMc ? _loadMc() : _initFromOverall();
    });
    InsurerInstallment.load().then((v) {
      if (mounted) setState(() => _installment = v);
    });
  }

  void _initFromOverall() {
    final s = _state;
    s
      ..compareSelection = createFalseListByItemNumber(false, s.packages.length)
      ..quotationSaved = false
      ..grossPage3 = s.grossPage2.copy()
      ..sumInsuredPage3 = s.sumInsuredPage2.copy()
      ..notify();
  }

  Future<void> _loadMc() async {
    final s = _state;
    final c = s.criteria!;
    s
      ..result = null // FF cleared every search* list first
      ..compareSelection = []
      ..quotationSaved = false
      ..grossPage3 = RangeFilter(boundMin: 1000, boundMax: 10000)
      ..sumInsuredPage3 = RangeFilter(boundMin: 0, boundMax: 1000000)
      ..filterCoverTypes = []
      ..filterGarageTypes = []
      ..notify();

    final r = await withLoading(
      context,
      () => SearchPackageApi.instance.searchPackagesMc(
        brandCode: c.brandCode,
        year: c.yearCE,
        modelCode: c.modelCode,
        province: c.province,
        vehicleUsage: c.vehicleUsage,
        coverTypeList: c.coverType,
        garageTypeList: c.garageType,
        nationalThaiId: c.idCard,
        customerType: c.customerType,
      ),
    );
    if (!mounted) return;
    if (r.statusCode != 200) {
      await showAlert(context, httpErrorText(r.statusCode));
      return;
    }
    if (r.code != 200) {
      await showAlert(context, r.message ?? '');
      return;
    }
    final data = r.data;
    // FF's pop here only closed the loading sheet; the user stays on the page.
    if (data == null || data.total == 0) {
      await showAlert(context, 'ไม่พบข้อมูลประกัน');
      return;
    }

    double bound(List<String> l, String type) => double.tryParse(getMinMaxValueFromList(l, type)) ?? 0;
    final gross = data.packages.map((p) => p.grossTotal).toList();
    final sum = data.packages.map((p) => p.sumInsured).toList();
    setState(() => _mcOk = true);
    s
      ..result = data
      ..compareSelection = createFalseListByItemNumber(false, data.packages.length)
      ..quotationSaved = false
      ..grossPage3 = RangeFilter(boundMin: bound(gross, 'min'), boundMax: bound(gross, 'max'))
      ..sumInsuredPage3 = RangeFilter(boundMin: bound(sum, 'min'), boundMax: bound(sum, 'max'))
      ..notify();
  }

  bool get _listOk => _isMc ? _mcOk : _state.insurers.isNotEmpty;

  int get _selectedCount => countTrueInBoolList(_state.compareSelection);

  bool _isSelected(int i) => i < _state.compareSelection.length && _state.compareSelection[i];

  /// FF VISIBLE_RULE. Note the insurer filter is matched against the
  /// package's serial_name (which the API fills with the insurer code — the
  /// value page 04 / the filter page put in filterInsurers), kept as in FF.
  bool _visible(InsurancePackage p) {
    final s = _state;
    if (s.filterInsurers.isNotEmpty && !s.filterInsurers.contains(p.serialName)) return false;
    if (s.filterCoverTypes.isNotEmpty && !s.filterCoverTypes.contains(p.coverType)) return false;
    if (s.filterGarageTypes.isNotEmpty && !s.filterGarageTypes.contains(p.garageType)) return false;
    return checkPackageInRangePage3(p.grossTotal, '${s.grossPage3.currentMin}', '${s.grossPage3.currentMax}') &&
        checkPackageInRangePage3(p.sumInsured, '${s.sumInsuredPage3.currentMin}', '${s.sumInsuredPage3.currentMax}');
  }

  void _toggle(int i) {
    final sel = _state.compareSelection;
    if (i >= sel.length) return;
    if (_selectedCount > 2 && !sel[i]) return; // already 3 ticked: ignored silently
    sel[i] = !sel[i];
    _state.notify();
  }

  void _openDetail(InsurancePackage p) {
    _state.selectedPackage = p;
    context.push(AppRoutes.detail(widget.product));
    _state
      ..quotationSaved = false
      ..notify();
  }

  void _openCompare() {
    // Ticked packages in index order — including ones the current filter
    // hides (FF behaviour).
    final s = _state;
    s
      ..comparePackages = [
        for (var i = 0; i < s.packages.length; i++)
          if (_isSelected(i)) s.packages[i],
      ]
      ..compareIndex = 0;
    context.push(AppRoutes.compare(widget.product));
    s
      ..quotationSaved = false
      ..notify();
  }

  Future<void> _openFilter() async {
    // FF's 'ไม่พบข้อมูลรายการประกัน' guard tested an always-null response, so
    // the filter always opens.
    await context.push(AppRoutes.filter(widget.product, 'SearchPackage3'));
    if (mounted) setState(() {});
  }

  void _back() {
    _state
      ..filterInsurers = []
      ..notify();
    context.pop();
  }

  void _openNonRate() {
    // FF reset ~160 nonePackage* fields and pre-filled them from the search
    // form before opening SelectReasonPage(workType: EV ? 'ev' : 'manual').
    // That flow isn't ported, so the resets are skipped.
    context.push(AppRoutes.notPorted('SelectReasonPage'));
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    return UnfocusOnTap(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: resultAppBar(title: _isMc ? 'ค้นหาประกันมอเตอร์ไซค์' : 'ค้นหาประกันรถ', onBack: _back),
          body: SafeArea(
            child: ListenableBuilder(
              listenable: _state,
              builder: (context, _) {
                final s = _state;
                final listOk = _listOk;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fixed text: does not show the selected filter, no clear icon.
                      ResultFilterBox(
                        text: 'ค้นหาเปรียบเทียบบริษัทประกัน',
                        extraLabel: '(เลือกเปรียบเทียบสูงสุด 3 รายการเท่านั้น)',
                        onTap: _openFilter,
                      ),
                      RangeSummaryRows(
                        firstTopPadding: 0,
                        minGross: s.grossPage3.currentMin,
                        maxGross: s.grossPage3.currentMax,
                        minSum: s.sumInsuredPage3.currentMin,
                        maxSum: s.sumInsuredPage3.currentMax,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 25),
                              child: Text('เลือกได้สูงสุด 3 รายการ', style: AppText.style()),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Text('($_selectedCount/ 3)', style: AppText.style(color: AppColors.error)),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Text(
                          '*หากไม่ขึ้นการ์ดแพ็คเกจ หมายถึงไม่มีแพ็คเกจจากค่าที่ฟิลเตอร์*',
                          style: AppText.style(color: AppColors.error),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          height: screenH * 0.55,
                          child: listOk
                              ? ListView.builder(
                                  padding: const EdgeInsets.only(top: 4),
                                  itemCount: s.packages.length,
                                  itemBuilder: (context, i) {
                                    final p = s.packages[i];
                                    if (!_visible(p)) return const SizedBox.shrink();
                                    return _PackageCard(
                                      package: p,
                                      selected: _isSelected(i),
                                      installment: _installment,
                                      onToggle: () => _toggle(i),
                                      onDetail: () => _openDetail(p),
                                    );
                                  },
                                )
                              : const Align(
                                  alignment: Alignment.topCenter,
                                  child: ResultEmptyBox(text: 'ไม่พบข้อมูลรายการประกัน'),
                                ),
                        ),
                      ),
                      if (listOk && _selectedCount >= 2) _CompareBar(onTap: _openCompare),
                      if (!_isMc) NonRateRow(onPressed: _openNonRate),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareBar extends StatelessWidget {
  const _CompareBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF5CC2BC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.secondaryText),
            boxShadow: kCardShadow,
          ),
          alignment: Alignment.center,
          child: Text('เปรียบเทียบ', style: AppText.style(fontSize: 16, color: AppColors.primaryBtnText)),
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.selected,
    required this.installment,
    required this.onToggle,
    required this.onDetail,
  });

  final InsurancePackage package;
  final bool selected;
  final List<String> installment;
  final VoidCallback onToggle;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final p = package;
    final s11 = AppText.style(fontSize: 11);
    final grey10 = AppText.style(fontSize: 10, color: AppColors.secondaryText);
    final red10 = AppText.style(fontSize: 10, color: AppColors.error);
    final alt12 = AppText.style(fontSize: 12, color: AppColors.alternate);
    final discounted = p.discountFlg == '1';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryBtnText,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kCardShadow,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Compare check-box column.
              Expanded(
                child: InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Center(
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBtnText,
                          border: Border.all(color: AppColors.primaryText),
                        ),
                        child: selected ? const Icon(Icons.check, color: AppColors.success, size: 12) : null,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 0, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 4, 15, 30),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: InsurerLogo(url: p.logoOrPlaceholder),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CardInfoRow(label: Text(p.serialName, style: s11)),
                                if (p.inspectionExcept == 'Y' && p.coverType == 'VMI1')
                                  CardInfoRow(label: Text('ไม่ต้องถ่ายรูปรถ', style: alt12)),
                                if (installment.contains(p.shortName))
                                  CardInfoRow(label: Text('ชำระเต็มจำนวนเท่านั้น', style: alt12)),
                                CardInfoRow(
                                  label: Text('ประเภทประกัน', style: s11),
                                  value: Text(showCoverTypeThai(p.coverType), style: s11),
                                ),
                                CardInfoRow(
                                  label: Text('ทุนประกัน', style: grey10),
                                  value: Text(showNumberWithComma(p.sumInsured), style: grey10),
                                ),
                                CardInfoRow(
                                  label: Text('ประเภทซ่อม', style: grey10),
                                  value: Text(showGarageType(p.garageType), style: grey10),
                                ),
                                // FF quirk: this "loss / fire" row shows sum_insured, not car_lost.
                                if (p.sumInsured != '')
                                  CardInfoRow(
                                    label: Text('สูญหายไฟไหม้', style: grey10),
                                    value: Text(showNumberWithComma(p.sumInsured), style: grey10),
                                  ),
                                if (p.motorAddOn != '')
                                  CardInfoRow(
                                    label: Text('ประกันภัยเสริมรถยนต์ Motor Add-on',
                                        style: AppText.style(fontSize: 10, color: AppColors.primary)),
                                    trailing: const Icon(Icons.check_circle, color: AppColors.secondary, size: 16),
                                  ),
                                if (p.deductible != '0')
                                  CardInfoRow(
                                    label: Text('ค่าเสียหายส่วนเเรก', style: red10), // 'เเรก' verbatim
                                    value: Text(showNumberWithComma(p.deductible), style: red10),
                                  ),
                                if (discounted)
                                  CardInfoRow(
                                    label: Text('ราคาส่วนลด', style: red10),
                                    value: Text('${showNumberWithComma(p.discountOther)} บาท', style: red10),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(discounted ? 'ราคาเบี้ยร่วมส่วนลด' : 'ราคาเบี้ย', style: grey10),
                                  Text(
                                    '${showNumberWithComma(discounted ? p.grossTotalDiscount : p.grossTotal)} บาท',
                                    style: s11,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 20, 10),
                            child: DetailButton(onPressed: onDetail),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
