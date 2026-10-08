import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart' as ff;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../router/app_router.dart';
import '../models/insurance_package.dart';
import '../product_type.dart';
import '../state/search_package_state.dart';
import 'detail_shared.dart';

/// Port of FF `DetailsInsurancePage` (spec 06): read-only details of
/// `state.selectedPackage` with two CTAs to AddCustomerName.
///
/// FF passed ~60 query params; here they are the package's fields plus the
/// search criteria in state (brand/model name, year CE, driver flag, idCard).
/// The `InsurerConfig2Record` param (only used for the 'ชำระเต็มจำนวนเท่านั้น'
/// label) is read from Firestore on open, together with the weekend flag.
///
/// FF wrapped this page in `NavBarPage` (the mobile app's bottom navigation
/// bar); that bar belongs to the host app and is not reproduced. FF's
/// `PopScope(canPop: false)` is not ported — browser back is allowed.
class PackageDetailPage extends StatefulWidget {
  const PackageDetailPage({super.key, required this.product});

  final ProductType product;

  @override
  State<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends State<PackageDetailPage> {
  late final SearchPackageState _state = SearchPackageState.of(widget.product);
  late final Future<DetailFlags> _flags = DetailFlags.load();

  /// FF `currentDate` = `getCurrentTimestamp.toString()` at navigation time.
  final String _currentDate = DateTime.now().toString();

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_state.selectedPackage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.search(widget.product));
      });
    }
  }

  /// Informational only — FF continued to navigate after the dialog.
  bool _needsPolicyFileAlert(InsurancePackage p) =>
      p.inspectionExceptPolicyFile != 'Y' && p.coverType == 'VMI1';

  Future<void> _onQuotation(InsurancePackage p) async {
    if (_needsPolicyFileAlert(p)) await showAlert(context, kPolicyFileAlert);
    if (!mounted) return;
    context.push(AppRoutes.customer(widget.product, fromPage: 'detail', fromBtn: 'quotationBtn'));
  }

  Future<void> _onSave(InsurancePackage p, DetailFlags flags) async {
    if (_busy) return;
    _busy = true;
    try {
      final ok = await passesWeekendRule(
        context,
        enabled: flags.disableWorkWeekend,
        coverTypeThai: ff.showCoverTypeThai(p.coverType),
      );
      if (!ok || !mounted) return;
      if (_needsPolicyFileAlert(p)) await showAlert(context, kPolicyFileAlert);
      if (!mounted) return;
      context.push(AppRoutes.customer(widget.product, fromPage: 'detail', fromBtn: 'saveBtn'));
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _state.selectedPackage;
    return UnfocusOnTap(
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: detailAppBar(context, widget.product),
        body: SafeArea(
          bottom: false,
          child: p == null
              ? const SizedBox.shrink()
              : FutureBuilder<DetailFlags>(
                  future: _flags,
                  builder: (context, snap) {
                    if (!snap.hasData) return const DetailLoading();
                    return _content(p, snap.data!);
                  },
                ),
        ),
      ),
    );
  }

  Widget _content(InsurancePackage p, DetailFlags flags) {
    final c = _state.criteria;
    const divider = Divider(thickness: 1, color: AppColors.borderGrey);
    final discount = p.discountFlg == '1';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(p, flags),
          divider,
          DetailRow('วันที่ขอข้อมูล', ff.showDateBE(_currentDate)),
          // FF: `insurerCondition != ''` (null counted as shown with '-').
          if (p.insurerCondition != '') ...[
            divider,
            const DetailSectionHeader('เงื่อนไขบริษัทประกัน'),
            DetailSectionText(p.insurerCondition),
          ],
          if (p.motorAddOn != '') ...[
            divider,
            const DetailSectionHeader('ประกันภัยเสริมรถยนต์ Motor Add-on'),
            DetailSectionText(p.motorAddOn),
          ],
          divider,
          const DetailSectionHeader('รายละเอียด'),
          DetailRow('ยี่ห้อรถ', nv(c?.brandName)),
          divider,
          DetailRow('รุ่นรถ', nv(c?.modelName)),
          divider,
          DetailRow('ปีจดทะเบียน พ.ศ.', yearBEText(c?.yearCE)),
          divider,
          DetailRow('ระบุผู้ขับขี่', nv(c?.driverFlag)),
          divider,
          // 'ราคาเบี้ย' row is `if (false)` in FF — not rendered.
          DetailRow('ทุนประกัน', _money(p.sumInsured)),
          divider,
          DetailRow('ค่าเสียหายส่วนเเรก', _money(p.deductible), valueColor: AppColors.error),
          divider,
          DetailRow('ความรับผิดต่อบุคคลภายนอก', _money(p.tpbiAccident)),
          divider,
          DetailRow('อุบัติเหตุส่วนบุคคล', _money(p.pa)),
          divider,
          DetailRow('สูญหายไฟไหม้', _money(p.carLost)),
          divider,
          DetailRow('ค่าเบี้ยไม่รวม พ.ร.บ', _money(p.grossTotal)),
          divider,
          // 'เปอร์เซ็นต์ส่วนลด' is `discountFlg == '1' && false` in FF — hidden.
          if (discount) ...[
            DetailRow('ราคาส่วนลด', _money(p.discountOther)),
            divider,
            DetailRow('ค่าเบี้ยรวมส่วนลด', _money(p.grossTotalDiscount)),
            divider,
          ],
          DetailRow('ค่าเบี้ยรวม พ.ร.บ', _money(p.grossTotalNet)),
          divider,
          // 'ราคานี้ใช้ใด้ถึงวันที่' is `if (false)` in FF — not rendered.
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: AppButton(
                      text: 'ออกใบเสนอราคา',
                      height: 50,
                      color: AppColors.lightOrange,
                      textColor: AppColors.brandOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      radius: 14,
                      onPressed: () => _onQuotation(p),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: AppButton(
                      text: 'ตกลงทำประกัน',
                      height: 50,
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
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _header(InsurancePackage p, DetailFlags flags) {
    return Padding(
      padding: const EdgeInsets.only(top: 17, bottom: 10),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: InsurerLogo(p.logoOrPlaceholder, width: 59, height: 60),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FF header shows the `insurerFullName` param = cnr(serial_name).
                  Text(
                    ff.checkNullValueAndReturn(p.serialName),
                    style: AppText.style(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  if (flags.fullPaymentOnly(p.shortName))
                    Text(
                      'ชำระเต็มจำนวนเท่านั้น',
                      style: AppText.style(fontWeight: FontWeight.bold, color: AppColors.alternate),
                    ),
                  DetailHeaderInfo('ประเภทประกัน ', ff.showCoverTypeThai(p.coverType)),
                  DetailHeaderInfo('ประเภทซ่อม', ff.showGarageType(p.garageType)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// FF MONEY(x): `x == '-' ? '-' : '${showNumberWithComma(x)} บาท'`. The FF
  /// discount/net rows had no '-' guard; a null/empty value (which would have
  /// printed 'null บาท' / ' บาท') is shown as '-' for every row here.
  static String _money(String v) {
    final s = nv(v);
    return s == '-' ? '-' : '${ff.showNumberWithComma(s)} บาท';
  }
}
