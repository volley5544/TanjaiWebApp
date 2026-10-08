import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../../router/app_router.dart';
import '../data/api_result.dart';
import '../data/search_package_api.dart';
import '../models/insurer_group.dart';
import '../product_type.dart';
import '../state/search_package_state.dart';
import 'insurer_installment.dart';
import 'widgets/result_widgets.dart';

/// Step 2 of the car / EV package search — one card per insurer
/// (FF `InsurerListOverallPage`, spec 04). Calls `get_package` once and keeps
/// the result in [SearchPackageState.result] for [InsurerListPage].
class InsurerOverallPage extends StatefulWidget {
  const InsurerOverallPage({super.key, required this.product});

  final ProductType product;

  @override
  State<InsurerOverallPage> createState() => _InsurerOverallPageState();
}

class _InsurerOverallPageState extends State<InsurerOverallPage> {
  late final SearchPackageState _state = SearchPackageState.of(widget.product);

  /// FF `packageAPIOutput` (page-local: gates the list / empty state).
  ApiResult<PackageSearchResult>? _response;
  List<String> _installment = const [];

  /// Initial `get_package` call in progress: white page + spinner.
  bool _loading = true;

  // FF defaults of `listType1` / `listNonType1`.
  static const _listType1 = ['VMI1'];
  static const _listNonType1 = <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_state.criteria == null) {
        context.go(AppRoutes.search(widget.product)); // opened without a search (refresh)
        return;
      }
      _load();
    });
    InsurerInstallment.load().then((v) {
      if (mounted) setState(() => _installment = v);
    });
  }

  Future<void> _load() async {
    final c = _state.criteria!;
    final r = await SearchPackageApi.instance.searchPackages(
      brandCode: c.brandCode,
      modelCode: c.modelCode,
      year: c.yearCE,
      vehicleUsage: c.vehicleUsage,
      coverTypeList: c.coverType,
      garageTypeList: c.garageType,
      province: c.province,
      driverBehaviorList: c.driverBehaviorScoreList,
      driver: c.driverFlag,
      nationalThaiId: c.idCard,
      customerType: c.customerType,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _response = r;
    });
    if (r.statusCode != 200) {
      await showAlert(context, httpErrorText(r.statusCode));
      return;
    }
    if (r.code != 200) {
      await showAlert(context, r.message ?? '');
      return;
    }
    final data = r.data;
    // FF popped here to leave, but the pop only closed the loading sheet:
    // the user stays on this (empty) page. Kept.
    if (data == null || data.dataLength <= 0 || data.insurers.isEmpty) {
      await showAlert(context, 'ไม่พบข้อมูลบริษัทประกัน');
      return;
    }

    _state.result = data;
    // Bounds from the insurer-level min/max (the filter compares package values).
    double bound(List<String> l, String type) => double.tryParse(getMinMaxValueFromList(l, type)) ?? 0;
    _state.grossPage2 = RangeFilter(
      boundMin: bound(data.insurers.map((i) => i.minGrossTotal).toList(), 'min'),
      boundMax: bound(data.insurers.map((i) => i.maxGrossTotal).toList(), 'max'),
    );
    _state.sumInsuredPage2 = RangeFilter(
      boundMin: bound(data.insurers.map((i) => i.minSumInsured).toList(), 'min'),
      boundMax: bound(data.insurers.map((i) => i.maxSumInsured).toList(), 'max'),
    );
    _state.notify();
  }

  bool get _listOk => _response != null && _response!.isOk && (_response!.data?.dataLength ?? 0) > 0;

  /// FF VISIBLE_RULE: insurer filter + "at least one package of this insurer
  /// (same class-1 group) in range" for price and, independently, sum insured.
  bool _visible(InsurerGroup ins) {
    final s = _state;
    if (s.filterInsurers.isNotEmpty && !s.filterInsurers.contains(ins.insurerCode)) return false;
    final pk = s.packages;
    final shortNames = pk.map((p) => p.shortName).toList();
    final coverTypes = pk.map((p) => p.coverType).toList();
    final priceOk = checkPackageInRangePage2Copy(
      shortNames,
      pk.map((p) => p.grossTotal).toList(),
      ins.insurerShortName,
      '${s.grossPage2.currentMin}',
      '${s.grossPage2.currentMax}',
      ins.coverTypeList,
      coverTypes,
    );
    if (!priceOk) return false;
    return checkPackageInRangePage2Copy(
      shortNames,
      pk.map((p) => p.sumInsured).toList(),
      ins.insurerShortName,
      '${s.sumInsuredPage2.currentMin}',
      '${s.sumInsuredPage2.currentMax}',
      ins.coverTypeList,
      coverTypes,
    );
  }

  Future<void> _openFilter() async {
    final r = _response;
    if (r == null || r.data == null || r.data!.dataLength <= 0) {
      await showAlert(context, 'ไม่พบบริษัทประกัน');
      return;
    }
    await context.push(AppRoutes.filter(widget.product, 'SearchPackage2'));
    if (mounted) setState(() {});
  }

  void _openInsurer(InsurerGroup ins) {
    _state
      ..quotationSaved = false
      ..filterInsurers = [ins.insurerCode]
      ..filterCoverTypes = List.of(containWordinStringUrl('1', ins.coverTypeList) ? _listType1 : _listNonType1)
      ..notify();
    context.push(AppRoutes.packages(widget.product));
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
          if (!didPop) context.pop();
        },
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: resultAppBar(title: 'ค้นหาบริษัทประกัน', onBack: () => context.pop()),
          body: _loading
              ? const PageLoadingView(message: 'กำลังค้นหาแพ็กเกจประกัน...')
              : SafeArea(
                  child: ListenableBuilder(
                    listenable: _state,
                    builder: (context, _) {
                      final s = _state;
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ResultFilterBox(
                              text: s.filterInsurers.isNotEmpty ? s.filterInsurers.first : 'ค้นหาบริษัทประกัน',
                              onTap: _openFilter,
                              onClear: s.filterInsurers.isEmpty
                                  ? null
                                  : () => s
                                      ..filterInsurers = []
                                      ..notify(),
                            ),
                            RangeSummaryRows(
                              minGross: s.grossPage2.currentMin,
                              maxGross: s.grossPage2.currentMax,
                              minSum: s.sumInsuredPage2.currentMin,
                              maxSum: s.sumInsuredPage2.currentMax,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SizedBox(
                                height: screenH * 0.58,
                                child: Column(
                                  children: [
                                    if (_listOk)
                                      Expanded(
                                        child: ListView.builder(
                                          padding: const EdgeInsets.only(top: 4),
                                          itemCount: s.insurers.length,
                                          itemBuilder: (context, i) {
                                            final ins = s.insurers[i];
                                            if (!_visible(ins)) return const SizedBox.shrink();
                                            return _InsurerCard(
                                              insurer: ins,
                                              installment: _installment,
                                              onDetail: () => _openInsurer(ins),
                                            );
                                          },
                                        ),
                                      ),
                                    if (_response?.data != null && _response!.data!.dataLength == 0)
                                      const ResultEmptyBox(text: 'ไม่พบข้อมูลบริษัทประกัน'),
                                  ],
                                ),
                              ),
                            ),
                            NonRateRow(onPressed: _openNonRate),
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

class _InsurerCard extends StatelessWidget {
  const _InsurerCard({required this.insurer, required this.installment, required this.onDetail});

  final InsurerGroup insurer;
  final List<String> installment;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    // FF sized the card with the PACKAGE-level searchShortName[i] (insurer
    // index i — an index mix-up); the insurer's own short name is used here,
    // matching the label condition. Min height (not fixed) avoids clipping.
    final fullPayOnly = installment.contains(insurer.insurerShortName);
    final grey = AppText.style(fontSize: 10, color: AppColors.secondaryText);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        constraints: BoxConstraints(minHeight: fullPayOnly ? 160 : 140),
        decoration: BoxDecoration(
          color: AppColors.primaryBtnText,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kCardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 15, 30),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: InsurerLogo(url: insurer.logoOrPlaceholder),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CardInfoRow(label: Text(insurer.insurerCode, style: AppText.style(fontSize: 11))),
                        if (fullPayOnly)
                          CardInfoRow(
                            label: Text(
                              'ชำระเต็มจำนวนเท่านั้น',
                              style: AppText.style(fontSize: 12, color: AppColors.alternate),
                            ),
                          ),
                        CardInfoRow(
                          label: Text('ประเภทประกัน', style: AppText.style(fontSize: 11)),
                          value: Text(
                            insurer.coverTypeList.isEmpty ? '-' : addCoverType(insurer.coverTypeList),
                            style: AppText.style(fontSize: 11),
                          ),
                        ),
                        // Raw values, no comma formatting (as FF).
                        CardInfoRow(
                          label: Text('ราคาเบี้ยเริ่มต้น', style: grey),
                          value: Text(insurer.minGrossTotal, style: grey),
                        ),
                        CardInfoRow(
                          label: Text('ทุนประกันสูงสุด', style: grey),
                          value: Text(insurer.maxSumInsured, style: grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: DetailButton(onPressed: onDetail),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
