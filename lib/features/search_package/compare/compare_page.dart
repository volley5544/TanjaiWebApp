import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart' as ff;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../router/app_router.dart';
import '../detail/detail_shared.dart';
import '../models/insurance_package.dart';
import '../product_type.dart';
import '../state/search_package_state.dart';

/// Port of FF `CompareInsurancePage` (spec 07): up to 3 insurer logo tabs over
/// `state.comparePackages`; the block below shows the package at
/// `state.compareIndex` (FF `indexDataCompare`). AddCustomerName reads the
/// whole compare list plus that index from state (FF passed all lists +
/// `indexPage`).
///
/// FF wrapped this page in `NavBarPage` (the mobile app's bottom navigation
/// bar); that bar belongs to the host app and is not reproduced. FF's
/// `PopScope(canPop: false)` is not ported — browser back is allowed.
class ComparePage extends StatefulWidget {
  const ComparePage({super.key, required this.product});

  final ProductType product;

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  static const _grey = Color(0xFFE5E5E5);
  static const _divider = Divider(thickness: 1, color: AppColors.borderLight);

  late final SearchPackageState _state = SearchPackageState.of(widget.product);
  late final Future<DetailFlags> _flags = DetailFlags.load();

  /// FF `currentDate` = `getCurrentTimestamp.toString()` at navigation time.
  final String _currentDate = DateTime.now().toString();

  bool _busy = false;

  /// FF showed `insurerFullName.take(3)` tabs, so the index is 0..2.
  List<InsurancePackage> get _packages => _state.comparePackages.take(3).toList();

  @override
  void initState() {
    super.initState();
    if (_state.comparePackages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.search(widget.product));
      });
    } else if (_state.compareIndex < 0 || _state.compareIndex >= _packages.length) {
      _state.compareIndex = 0;
    }
  }

  void _selectTab(int k) {
    _state.compareIndex = k;
    _state.notify();
  }

  // Policy-file alerts: FF's compare conditions were broken —
  //   ออกใบเสนอราคา: policyFileList.contains(inspectionExceptList.contains("N").toString())
  //                  && coverTypeCodeList.contains("Y")
  //   ตกลงทำประกัน:  policyFileList.contains("N") && coverTypeCodeList.contains("Y")
  // A cover-type code is never "Y", so the alert never showed on this page
  // (and it did not block navigation anyway). Kept as-is: no alert here.

  void _onQuotation() {
    // FF passed fromBtn: '' from the compare page.
    context.push(AppRoutes.customer(widget.product, fromPage: 'compare', fromBtn: ''));
  }

  Future<void> _onSave(InsurancePackage p, DetailFlags flags) async {
    if (_busy) return;
    _busy = true;
    try {
      // FF compared the mapped name `coverTypeCodeToName([code])` with 'ชั้น 1'.
      final ok = await passesWeekendRule(
        context,
        enabled: flags.disableWorkWeekend,
        coverTypeThai: nv(ff.coverTypeCodeToName([p.coverType]).first),
      );
      if (!ok || !mounted) return;
      context.push(AppRoutes.customer(widget.product, fromPage: 'compare', fromBtn: 'saveBtn'));
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnfocusOnTap(
      child: Scaffold(
        backgroundColor: _grey,
        appBar: detailAppBar(context, widget.product),
        body: SafeArea(
          bottom: false,
          child: _state.comparePackages.isEmpty
              ? const SizedBox.shrink()
              : FutureBuilder<DetailFlags>(
                  future: _flags,
                  builder: (context, snap) {
                    if (!snap.hasData) return const DetailLoading();
                    // Rebuild on tab change and when quotationSaved flips
                    // (FF context.watch<FFAppState>()).
                    return ListenableBuilder(
                      listenable: _state,
                      builder: (context, _) => _content(snap.data!),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _content(DetailFlags flags) {
    final packages = _packages;
    final index = _state.compareIndex.clamp(0, packages.length - 1);
    final p = packages[index];
    final c = _state.criteria;
    final discount = p.discountFlg == '1';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: double.infinity, height: 16, color: AppColors.primaryBackground),
          _tabs(packages, index),
          const Divider(thickness: 1, color: _grey),
          Container(
            width: double.infinity,
            color: _grey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(p, flags),
                _divider,
                DetailRow('วันที่ขอข้อมูล', ff.showDateBE(_currentDate)),
                // FF: `(insurerCondition[i] ?? '-') != ''` / `motorAddOn[i] != ''`.
                if (p.insurerCondition != '') ...[
                  _divider,
                  const DetailSectionHeader('เงื่อนไขบริษัทประกัน'),
                  DetailSectionText(p.insurerCondition),
                ],
                if (p.motorAddOn != '') ...[
                  _divider,
                  const DetailSectionHeader('ประกันภัยเสริมรถยนต์ Motor Add-on'),
                  DetailSectionText(p.motorAddOn),
                ],
                _divider,
                const DetailSectionHeader('รายละเอียด'),
                DetailRow('ยี่ห้อรถ', nv(c?.brandName)),
                _divider,
                DetailRow('รุ่นรถ', nv(c?.modelName)),
                _divider,
                DetailRow('ปีจดทะเบียน พ.ศ.', yearBEText(c?.yearCE)),
                _divider,
                DetailRow('ระบุผู้ขับขี่', nv(c?.driverFlag)),
                _divider,
                // 'ราคาเบี้ย' row is `if (false)` in FF — not rendered.
                // Amounts here have no ' บาท' suffix (unlike the detail page).
                DetailRow('ทุนประกัน', _num(p.sumInsured)),
                _divider,
                DetailRow('ค่าเสียหายส่วนเเรก', _num(p.deductible), valueColor: AppColors.error),
                _divider,
                DetailRow('ความรับผิดต่อบุคคลภายนอก', _num(p.tpbiAccident)),
                _divider,
                DetailRow('อุบัติเหตุส่วนบุคคล', _num(p.pa)),
                _divider,
                DetailRow('สูญหายไฟไหม้', _num(p.carLost)),
                _divider,
                DetailRow('ค่าเบี้ยไม่รวม พ.ร.บ', _num(p.grossTotal)),
                _divider,
                // 'เปอร์เซ็นต์ส่วนลด' is `discountFlg == '1' && false` — hidden.
                if (discount) ...[
                  DetailRow('ราคาส่วนลด', _baht(p.discountOther)),
                  _divider,
                  DetailRow('ค่าเบี้ยรวมส่วนลด', _baht(p.grossTotalDiscount)),
                  _divider,
                ],
                DetailRow('ค่าเบี้ยรวม พ.ร.บ', _baht(p.grossTotalNet)),
                _divider,
                // 'ราคานี้ใช้ใด้ถึงวันที่' is `if (false)` in FF — not rendered.
                _buttons(p, flags),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _tabs(List<InsurancePackage> packages, int index) {
    return Container(
      width: double.infinity,
      height: 160,
      color: AppColors.primaryBackground,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: packages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, k) => InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          onTap: () => _selectTab(k),
          // FF set height 122, but a horizontal ListView forces its children
          // to the full 160 cross-axis extent, so the tab rendered 130×160.
          child: Container(
            width: 130,
            decoration: BoxDecoration(
              color: index == k ? _grey : Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            alignment: Alignment.center,
            child: InsurerLogo(packages[k].logoOrPlaceholder, height: 100),
          ),
        ),
      ),
    );
  }

  Widget _header(InsurancePackage p, DetailFlags flags) {
    return Container(
      width: double.infinity,
      // FF: fixed height 108; minHeight here so a long name can't overflow.
      constraints: const BoxConstraints(minHeight: 108),
      color: _grey,
      padding: const EdgeInsets.only(top: 17, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: InsurerLogo(p.logoOrPlaceholder, width: 59, height: 60, fit: BoxFit.contain),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nv(p.serialName),
                    style: AppText.style(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  if (flags.fullPaymentOnly(p.shortName))
                    Text(
                      'ชำระเต็มจำนวนเท่านั้น',
                      style: AppText.style(fontWeight: FontWeight.bold, color: AppColors.alternate),
                    ),
                  DetailHeaderInfo('ประเภทประกัน ', nv(ff.coverTypeCodeToName([p.coverType]).first)),
                  DetailHeaderInfo('ประเภทซ่อม', nv(ff.garageTypeCodeToName([p.garageType]).first)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttons(InsurancePackage p, DetailFlags flags) {
    final saved = _state.quotationSaved;
    return Container(
      width: double.infinity,
      color: AppColors.secondaryBackground,
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        children: [
          _divider,
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: AppButton(
                      // FF addCustomerQuotationSaveSuccess toggles this button.
                      text: saved ? 'ดูใบเสนอราคา' : 'ออกใบเสนอราคา',
                      height: 60,
                      color: AppColors.lightOrange,
                      textColor: AppColors.brandOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      radius: 14,
                      onPressed: saved ? () => context.push(AppRoutes.quotation(widget.product)) : _onQuotation,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: AppButton(
                      text: 'ตกลงทำประกัน',
                      height: 60,
                      color: const Color(0xFFD37319),
                      textColor: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      radius: 14,
                      onPressed: () => _onSave(p, flags),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// FF NUM(v): '-' when null/'-', else `showNumberWithComma(v)` (no suffix).
  static String _num(String v) {
    final s = nv(v);
    return s == '-' ? '-' : ff.showNumberWithComma(s);
  }

  /// FF `'${showNumberWithComma(v) ?? '-'} บาท'` (null → '- บาท').
  static String _baht(String v) {
    final s = nv(v);
    return '${s == '-' ? '-' : ff.showNumberWithComma(s)} บาท';
  }
}
