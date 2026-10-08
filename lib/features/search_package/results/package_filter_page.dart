import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/selector_tile.dart';
import '../product_type.dart';
import '../shared/searchable_list_page.dart';
import '../state/search_package_state.dart';
import 'widgets/range_slider_filter.dart';

/// Filter page of the result lists (FF `PackageFilterPage`, spec 12).
///
/// * `SearchPackage2` (from [InsurerOverallPage]): insurer picker + Page2 ranges.
/// * `SearchPackage3` (from [InsurerListPage]): cover / garage pickers + Page3 ranges.
///
/// Everything is written to [SearchPackageState] live (no apply / cancel):
/// back and ค้นหา behave identically.
class PackageFilterPage extends StatefulWidget {
  const PackageFilterPage({super.key, required this.product, required this.fromPage});

  final ProductType product;
  final String fromPage;

  @override
  State<PackageFilterPage> createState() => _PackageFilterPageState();
}

class _PackageFilterPageState extends State<PackageFilterPage> {
  late final SearchPackageState _state = SearchPackageState.of(widget.product);

  bool get _p2 => widget.fromPage == 'SearchPackage2';
  bool get _p3 => widget.fromPage == 'SearchPackage3';

  @override
  void initState() {
    super.initState();
    // FF on-load: picker filters are cleared every time the page opens
    // (SearchPackage3 keeps the insurer chosen upstream); ranges are kept.
    if (!_p3) _state.filterInsurers = [];
    _state
      ..filterCoverTypes = []
      ..filterGarageTypes = [];
    // Notify after this frame: the caller page underneath listens to state.
    WidgetsBinding.instance.addPostFrameCallback((_) => _state.notify());
  }

  void _close() {
    _state
      ..compareSelection = createFalseListByItemNumber(false, _state.packages.length)
      ..notify();
    context.pop();
  }

  Future<List<String>?> _pick({
    required String title,
    required String searchLabel,
    required List<String> source,
    List<String> Function(List<String>)? labels,
  }) async {
    final items = removeDupeInList(source);
    final picked = await SearchableListPage.open(
      context,
      titleText: title,
      searchLabel: searchLabel,
      items: items,
      labels: labels?.call(items),
      multiSelect: true,
    );
    if (picked == null) return null;
    return [for (final i in picked) items[i]];
  }

  Future<void> _pickInsurers() async {
    final v = await _pick(
      title: 'ค้นหาเปรียบเทียบบริษัทประกัน',
      searchLabel: 'ระบุชื่อบริษัทประกัน',
      source: _state.packages.map((p) => p.serialName).toList(),
    );
    if (v == null || !mounted) return;
    setState(() => _state.filterInsurers = v);
    _state.notify();
  }

  Future<void> _pickCoverTypes() async {
    final v = await _pick(
      title: 'ค้นหาเปรียบเทียบชั้นประกัน',
      searchLabel: 'ระบุประเภทชั้นประกัน',
      source: _state.packages.map((p) => p.coverType).toList(),
      labels: coverTypeCodeToName,
    );
    if (v == null || !mounted) return;
    setState(() => _state.filterCoverTypes = v);
    _state.notify();
  }

  Future<void> _pickGarageTypes() async {
    final v = await _pick(
      title: 'ค้นหาเปรียบเทียบประเภทการซ่อม',
      searchLabel: 'ระบุประเภทการซ่อม',
      source: _state.packages.map((p) => p.garageType).toList(),
      labels: garageTypeCodeToName,
    );
    if (v == null || !mounted) return;
    setState(() => _state.filterGarageTypes = v);
    _state.notify();
  }

  /// FF RangeSliderWidget only wrote app state for SearchPackage1/2/3.
  void Function(double, double)? _writer(RangeFilter Function() target) {
    if (!_p2 && !_p3) return null;
    return (start, end) {
      target()
        ..currentMin = start
        ..currentMax = end;
      _state.notify();
    };
  }

  @override
  Widget build(BuildContext context) {
    final gross = _p2 ? _state.grossPage2 : _state.grossPage3;
    final sum = _p2 ? _state.sumInsuredPage2 : _state.sumInsuredPage3;
    return UnfocusOnTap(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Scaffold(
          backgroundColor: AppColors.secondaryBackground,
          appBar: tanjaiAppBar(title: _p2 ? 'ค้นหาบริษัทประกัน' : 'ค้นหาประกันรถ', onBack: _close),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  flex: 10,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        if (_p2) ...[
                          const FieldLabel(label: 'บริษัทประกัน', note: '(บังคับเลือก)'),
                          _PickerBox(
                            text: _state.filterInsurers.isEmpty
                                ? 'เลือกบริษัทประกัน'
                                : combineStringFromList(_state.filterInsurers),
                            onTap: _pickInsurers,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_p3) ...[
                          // Unbalanced ')' is verbatim from the app.
                          const FieldLabel(label: 'ประเภทชั้นประกัน', note: '(บังคับเลือก) สามารถเลือกได้มากกว่า 1)'),
                          _PickerBox(
                            text: _state.filterCoverTypes.isNotEmpty
                                ? combineStringFromList(_state.filterCoverTypes)
                                : 'กรุณาเลือกประเภทชั้นประกัน',
                            onTap: _pickCoverTypes,
                          ),
                          const SizedBox(height: 8),
                          const FieldLabel(
                            label: 'ประเภทการซ่อม',
                            note: '(บังคับเลือก สามารถเลือกได้มากกว่า 1)',
                            labelColor: Color(0xFF424242),
                          ),
                          _PickerBox(
                            text: _state.filterGarageTypes.isNotEmpty
                                ? combineStringFromList(_state.filterGarageTypes)
                                : 'กรุณาเลือกประเภทการซ่อม',
                            chevronColor: const Color(0xFF143678),
                            onTap: _pickGarageTypes,
                          ),
                          const SizedBox(height: 8),
                        ],
                        const FieldLabel(
                          label: 'เลือกราคาเบี้ยประกันต่ำสุด - สูงสุด',
                          labelColor: Color(0xFF424242),
                        ),
                        SizedBox(
                          height: 150,
                          child: RangeSliderFilter(
                            min: gross.boundMin,
                            max: gross.boundMax,
                            currentMin: gross.currentMin,
                            currentMax: gross.currentMax,
                            step: 20,
                            typeName: 'ราคาเบี้ย',
                            onChanged: _writer(() => _p2 ? _state.grossPage2 : _state.grossPage3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: FieldLabel(
                            label: 'เลือกราคาทุนประกันต่ำสุด - สูงสุด',
                            labelColor: Color(0xFF424242),
                          ),
                        ),
                        SizedBox(
                          height: 150,
                          child: RangeSliderFilter(
                            min: sum.boundMin,
                            max: sum.boundMax,
                            currentMin: sum.currentMin,
                            currentMax: sum.currentMax,
                            step: 100,
                            typeName: 'ทุนประกัน',
                            onChanged: _writer(() => _p2 ? _state.sumInsuredPage2 : _state.sumInsuredPage3),
                          ),
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    color: AppColors.secondaryBackground,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: AppButton(text: 'ค้นหา', onPressed: _close),
                        ),
                      ],
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

/// FF picker box: h50, radius 10, 0.5px border, ListTile with grey w600 15
/// text and a trailing chevron.
class _PickerBox extends StatelessWidget {
  const _PickerBox({required this.text, required this.onTap, this.chevronColor = AppColors.chevronGrey});

  final String text;
  final VoidCallback onTap;
  final Color chevronColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 0.5),
          ),
          padding: const EdgeInsets.only(left: 20, right: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.style(fontSize: 15, color: AppColors.placeholderGrey),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: chevronColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
