import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart' as ff;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../router/app_router.dart';
import '../../search_package/detail/detail_shared.dart' show InsurerLogo;
import '../../search_package/models/insurance_package.dart' show kNoImageUrl;
import '../models/fire_package.dart';
import '../state/fire_search_state.dart';

const _divider = Divider(height: 1, thickness: 1, color: AppColors.borderGrey);

/// Port of FF `detailsFireInsurancePage` (รายละเอียดประกันอัคคีภัย): the chosen
/// package's cover, limits and premium, with 'ออกใบเสนอราคา' / 'ตกลงทำประกัน'
/// → AddFireCustomerName.
class FirePackageDetailPage extends StatefulWidget {
  const FirePackageDetailPage({super.key});

  @override
  State<FirePackageDetailPage> createState() => _FirePackageDetailPageState();
}

class _FirePackageDetailPageState extends State<FirePackageDetailPage> {
  final _state = FireSearchState.instance;

  @override
  void initState() {
    super.initState();
    if (_state.selectedPackage == null || _state.criteria == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.fireSearch);
      });
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.fireSearch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _state.selectedPackage;
    final criteria = _state.criteria;
    return PopScope(
      canPop: false,
      child: UnfocusOnTap(
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: tanjaiAppBar(
            title: 'รายละเอียดประกันอัคคีภัย',
            titleSize: 19,
            titleColor: AppColors.navy,
            backgroundColor: const Color(0xFFF1F4F8),
            backColor: AppColors.brandOrange,
            onBack: _back,
          ),
          body: p == null || criteria == null
              ? const SizedBox.shrink()
              : SafeArea(child: SingleChildScrollView(child: _body(p, criteria))),
        ),
      ),
    );
  }

  /// FF `valueOrDefault(showNumberWithComma(x), '0')`.
  static String _comma(String? v) {
    final s = ff.showNumberWithComma(v ?? '');
    return s.isEmpty ? '0' : s;
  }

  /// FF `valueOrDefault(returnNumberWithComma2Decimal(x), 'sum_insure_buildin')`
  /// — an empty value really showed the text 'sum_insure_buildin' (kept).
  static String _comma2(String? v) {
    final s = ff.returnNumberWithComma2Decimal(v ?? '');
    return s.isEmpty ? 'sum_insure_buildin' : s;
  }

  Widget _body(FirePackage p, FireSearchCriteria criteria) {
    final logo = p.logo ?? '';
    return Column(
      children: [
        // Header: logo, company, type, plan.
        Padding(
          padding: const EdgeInsets.only(top: 17, bottom: 10),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: InsurerLogo(logo.isEmpty ? kNoImageUrl : logo, width: 59, height: 60),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _orDash(p.serialName),
                          style: AppText.style(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
                        ),
                      ),
                      _headerRow('ประเภทประกัน ', 'ประกันอัคคีภัย'),
                      _headerRow('แผนประกัน', _orDash(p.packageName)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _divider,
        _ValueRow('วันที่ขอข้อมูล', ff.showDateBE(DateTime.now().toString())),
        _divider,
        const _SectionTitle('รายละเอียด', withBar: true),
        _ValueRow('ราคาเบี้ยประกัน/ปี', '${_comma(p.netPremium)} บาท'),
        _divider,
        _ValueRow('ทุนประกันภัย', '${_comma(p.sumInsured)} บาท'),
        _divider,
        _ValueRow('สิ่งปลูกสร้าง (ไม่รวมฐานราก)', '${ff.returnNumberWithComma2Decimal(criteria.sumInsureHouse)} บาท'),
        _divider,
        _ValueRow('ทรัพย์สินภายในสิ่งปลูกสร้าง', '${_comma2(criteria.sumInsureBuilding)} บาท'),
        _divider,
        // Fire and additional perils.
        _SectionTitle(
          'การประกันภัยอัคคีภัยและภัยเพิ่มเติม',
          trailing: [
            _InfoIcon(size: 24, text: _additionalPerilsNotice),
            _coverIcon('assets/images/fire/cover_fire.png'),
            _coverIcon('assets/images/fire/cover_flood.png'),
          ],
        ),
        _ValueRow('· ภัยลมพายุ วงเงินคุ้มครองไม่เกิน', '${_comma2(p.naturalDisaster)} บาท'),
        // FF showed these two labels without a value.
        const _ValueRow('· ภัยแผ่นดินไหว หรือภูเขาไฟระเบิด \nหรือคลื่นใต้น้ำ หรือสึนามิ \nวงเงินคุ้มครองไม่เกิน', null),
        const _ValueRow('· ภัยจากลูกเห็บ วงเงินคุ้มครองไม่เกิน', null),
        _divider,
        _ValueRow(
          'ภัยจากการนัดหยุดงาน การจลาจล หรือ\nการกระทำอันมีเจตนาร้าย (ยกเว้นการกระทำ\nเพื่อผลทางการเมือง ศาสนา หรือลัทธินิยม) \nวงเงินคุ้มครองไม่เกิน',
          '${_comma(p.strikeAndRiot)} บาท',
        ),
        _divider,
        _ValueRow('ภัยต่อเครื่องอุปกรณ์ไฟฟ้า \nวงเงินคุ้มครองไม่เกิน', '${_comma(p.electricalAppliance)} บาท'),
        _divider,
        _ValueRow('ภัยจากน้ำท่วม วงเงินคุ้มครองไม่เกิน', '${_comma(p.flood)} บาท'),
        _divider,
        const _NoteRow('หมายเหตุ :', _replacementCostNotice),
        const _NoteRow('ความคุ้มครองเพิ่มเติม :   ', _extraCoverNotice),
        _divider,
        // Burglary.
        const _SectionTitle('การประกันภัยโจรกรรมที่ปรากฎร่องรอยการงัดแงะ'),
        _ValueRow('ทรัพย์สินภายในสิ่งปลูกสร้าง', '${_comma2(p.thief)} บาท'),
        _divider,
        _ValueRow('· ค่าใช้จ่ายซ่อมแซมสิ่งปลูกสร้าง \nประตูหน้าต่างเนื่องจากโจรกรรม', '${_comma2(p.buildingRepairs)} บาท'),
        _divider,
        _ValueRow('· ค่าใช้จ่ายจัดหาดแทนให้ใหม่สำหรับ\nตัวล็อกและกุญแจเนื่องจากโจรกรรม', '${_comma2(p.lockRepairs)} บาท'),
        _divider,
        // Glass.
        _SectionTitle('การประกันภัยกระจก', trailing: [_coverIcon('assets/images/fire/cover_glass.png')]),
        _ValueRow('จำนวนเงินจำกัดความรับผิด', '${_comma2(p.mirrorDamage)} บาท'),
        _divider,
        // Third-party liability.
        _SectionTitle(
          'ความรับผิดตามกฎหมายต่อบุคคลภายนอก',
          trailing: [_coverIcon('assets/images/fire/cover_third_party.png')],
        ),
        _ValueRow(
          'จำนวนเงินจำกัดความรับผิด ต่อครั้งและ\nตลอดระยะเวลาเอาประกันภัย\n·  ความรับผิดตามกฏหมายในฐานะ\n   นายจ้างต่อคนรับใช้',
          '${_comma2(p.tppd)} บาท',
        ),
        _divider,
        // Personal accident.
        const _SectionTitle('การประกันภัยอุบัติเหตุส่วนบุคคล'),
        _ValueRow('·  การเสียชีวิต การสูญเสียอวัยวะ \n   เนื่องจากอัคคีภัยหรือโจรกรรม', '${_comma2(p.dieFire)} บาท'),
        _divider,
        _ValueRow(
          '·  ค่ารักษาพยาบาลอันเนื่องจากอัคคีภัย\n   และโจรกรรม',
          // Non-numeric values (e.g. 'ไม่คุ้มครอง') are shown as-is.
          ff.checkIsDouble(p.medicalTreat) ? '${_comma2(p.medicalTreat)} บาท' : '${p.medicalTreat}',
        ),
        _divider,
        const _ValueRow('·  จำนวนสมาชิกที่เอาประกันภัย', '1 คน'),
        _divider,
        // Premium. FF labels: 'อากร' shows `vat`, 'ภาษีมูลค่าเพิ่ม' shows `stamp`
        // (swapped in the mobile app; kept as-is).
        const _SectionTitle('เบี้ยประกันภัย'),
        _ValueRow('สุทธิ', '${_comma(p.netPremium)} บาท'),
        _divider,
        _ValueRow('อากร', '${_comma(p.vat)} บาท'),
        _divider,
        _ValueRow('ภาษีมูลค่าเพิ่ม', '${_comma(p.stamp)} บาท'),
        _divider,
        _ValueRow('รวม', '${_comma(p.grossTotal)} บาท'),
        _divider,
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: AppButton(
                    text: 'ออกใบเสนอราคา',
                    height: 50,
                    radius: 14,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightOrange,
                    textColor: AppColors.brandOrange,
                    onPressed: () => context.push(AppRoutes.fireCustomer(doInsurance: false)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: AppButton(
                    text: 'ตกลงทำประกัน',
                    height: 50,
                    radius: 14,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFD37319),
                    onPressed: () => context.push(AppRoutes.fireCustomer(doInsurance: true)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  static String _orDash(String? v) => v == null || v.isEmpty ? '-' : v;

  Widget _headerRow(String label, String value) {
    final style = AppText.style(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textGrey);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: style)),
      ],
    );
  }

  static Widget _coverIcon(String asset) => Padding(
        padding: const EdgeInsets.only(left: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(asset, height: 30, fit: BoxFit.cover),
        ),
      );
}

const _additionalPerilsNotice =
    'ความคุ้มครองภัยเพิ่มเติม : คุ้มครองความสูญเสียหรือเสียหายอันเกิดกับทรัพย์สินที่เอาประกันภัยอันมีสาเหตุเนื่องมาจาก  ไฟไหม้ ฟ้าผ่า (รวมถึงความเสียหายต่อเครื่องไฟฟ้าและอุปกรณ์ไฟฟ้าที่เกิดจากการลัดวงจรจากฟ้าผ่า) ภัยระเบิด ภัยจากการเฉี่ยวหรือการชนขอยวดยานพาหนะ ภัยอากาศยาน ภัยเนื่องจากน้ำ (ไม่รวมน้ำท่วม)  และขยายความคุ้มครองถึง';

const _replacementCostNotice =
    'หมายเหตุ : กรมธรรม์ฉบับนี้ประกันแบบการชดใช้ตามมูลค่าในการจัดการทดแทนทรัพย์สิน (Replacement Cost Value) ';

/// FF custom function `getString()`.
const _extraCoverNotice = 'ความคุ้มครองเพิ่มเติม :\n'
    '1. ค่าเช่าที่อยู่อาศัยชั่วคราว / สูญเสียค่าเช่า (วงเงิน 2,500 ต่อวัน / ไม่เกิน 30 วัน)\n'
    '2. ค่าใช้จ่ายในการดับเพลิง (วงเงิน 10,000 บาทต่อครั้ง และไม่เกิน 50,000 บาทตลอดระยะเวลาเอาประกันภัย)\n'
    '3. ค่าใช้จ่ายในการขนย้ายซากทรัพย์สิน (วงเงิน 10,000 บาทต่อครั้ง และไม่เกิน 50,000 บาทตลอดระยะเวลาเอาประกันภัย)\n'
    '4. ค่าใช้จ่ายค่าวิชาชีพ (วงเงิน 10,000 บาทต่อครั้ง และไม่เกิน 50,000 บาทตลอดระยะเวลาเอาประกันภัย)\n'
    '5. ค่าใช้จ่ายของตัวล็อกและกุญแจที่จัดหามาทดแทน และค่าใช้จ่ายในการติดตั้งต่อประตูและหรือหน้าต่างด้านนอก (วงเงิน 5,000 บาทต่อครั้งและตลอดระยะเลาเอาประกันภัย)\n'
    '6. ค่าใช้จ่ายเพื่อการทดแทนอาหารและเครื่องดื่มที่เน่าเปื่อยหรือเสียหาย (วงเงิน 5,000 บาทต่อครั้งและตลอดระยะเลาเอาประกันภัย)\n'
    '7. ค่าใช้จ่ายการตกแต่งภูมิทัศน์ (วงเงิน 5,000 บาทต่อต้น ไม่เกิน 100,000 บาทต่อครั้งและตลอดระยะเลาเอาประกันภัย)';

/// Label (grey w500) ↔ value (dark bold) row, padding 20/10. A null value
/// shows the label only.
class _ValueRow extends StatelessWidget {
  const _ValueRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: AppText.style(fontWeight: FontWeight.w500, color: AppColors.textGrey)),
          ),
          if (value != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(value!, style: AppText.style(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ),
        ],
      ),
    );
  }
}

/// Navy bold 15 section title, optionally after the beige bar and with
/// trailing icons.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.withBar = false, this.trailing = const []});

  final String title;
  final bool withBar;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          if (withBar)
            const SizedBox(height: 18, child: VerticalDivider(thickness: 3, color: Color(0xFFEDBB8D))),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                title,
                style: AppText.style(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
              ),
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

/// 'หมายเหตุ :' style small bold label + info icon (no vertical padding).
class _NoteRow extends StatelessWidget {
  const _NoteRow(this.label, this.notice);

  final String label;
  final String notice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(label, style: AppText.style(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: _InfoIcon(size: 20, text: notice),
          ),
        ],
      ),
    );
  }
}

/// ⓘ icon that opens [showNoticeText].
class _InfoIcon extends StatelessWidget {
  const _InfoIcon({required this.size, required this.text});

  final double size;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: size == 24 ? 10 : 0),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        onTap: () => showNoticeText(context, text),
        child: Icon(Icons.error_outline, color: AppColors.primaryText, size: size),
      ),
    );
  }
}

/// Port of FF `NoticeText` shown as a full-screen dialog: white rounded card
/// (inset 16, bottom 16) with a close button and the justified text.
Future<void> showNoticeText(BuildContext context, String text) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lineColor),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBackground, width: 2),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close_rounded, color: AppColors.secondaryText, size: 24),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 2, color: AppColors.primaryBackground),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    text.isEmpty ? '-' : text,
                    textAlign: TextAlign.justify,
                    style: AppText.style(fontSize: 12, fontWeight: FontWeight.w500),
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
