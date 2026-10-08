import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/firebase/firestore_rest.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart' as ff;
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../data/search_package_api.dart';
import '../models/insurance_package.dart';
import '../product_type.dart';
import '../../../router/app_router.dart';

// Shared by PackageDetailPage (FF DetailsInsurancePage, spec 06) and
// ComparePage (FF CompareInsurancePage, spec 07): Firestore flags, the weekend
// rule, the app bar and the row / section templates.

/// Firestore values both pages read on open.
class DetailFlags {
  const DetailFlags({required this.disableWorkWeekend, required this.insurerInstallment});

  /// `hideInAppContent` where content_name == 'disable_work_weekend' →
  /// `isShowContent`. FF rendered a blank body when the doc was missing; on
  /// web the read needs auth and returns null → false (its prod value).
  final bool disableWorkWeekend;

  /// `InsurerConfig2.InsurerInstallment` (insurer short names), or null when
  /// unreadable (web without a Firebase token).
  final List<String>? insurerInstallment;

  /// FF: `insurerConfig?.insurerInstallment?.contains(shortName) ?? true`.
  /// In FF the config was never null here (the insurer list rendered nothing
  /// without it). When it is unreadable on web we hide the label instead of
  /// claiming "full payment only" for every insurer.
  bool fullPaymentOnly(String shortName) => insurerInstallment?.contains(shortName) ?? false;

  static Future<DetailFlags> load() async {
    final results = await Future.wait([
      FirestoreRest.instance.firstWhere('hideInAppContent', field: 'content_name', equals: 'disable_work_weekend'),
      FirestoreRest.instance.firstWhere('InsurerConfig2'),
    ]);
    final installment = results[1]?['InsurerInstallment'];
    return DetailFlags(
      disableWorkWeekend: results[0]?['isShowContent'] == true,
      insurerInstallment: installment is List ? installment.map((e) => '$e').toList() : null,
    );
  }
}

/// The "ตกลงทำประกัน" weekend restriction. Returns false when navigation must
/// stop (ชั้น 1 on a weekend). A date-API failure shows the FF error dialog
/// and does NOT block (FF behaviour).
Future<bool> passesWeekendRule(
  BuildContext context, {
  required bool enabled,
  required String coverTypeThai,
}) async {
  if (!enabled) return true;
  final r = await SearchPackageApi.instance.getServerDateTime();
  if (!context.mounted) return false;
  if (r.statusCode == 200 && r.code == 200) {
    final ymd = r.data?.dateYmd;
    // FF force-unwrapped a missing date (crash); treat it as not a weekend.
    final weekend = ymd != null && DateTime.tryParse(ymd) != null && ff.checkWeekendDate(ymd);
    if (weekend && coverTypeThai == 'ชั้น 1') {
      await showAlert(
        context,
        'วันเสาร์ / วันอาทิตย์ และวันหยุดนักขัตฤกษ์ ขายประกันรถยนต์ชั้น 2+,2, 3+ และ 3ในเรทเท่านั้น',
      );
      return false;
    }
  } else {
    await showAlert(context, 'พบข้อผิดพลาด (${r.statusCode}), (${r.code})get date');
  }
  return context.mounted;
}

const String kPolicyFileAlert = 'แพ็กเกจที่เลือกบังคับอัปโหลดไฟล์ตารางกรมธรรม์เดิมที่ยังไม่หมดอายุ';

/// Details/compare AppBar (bg #F1F4F8, navy 19 title, orange back arrow).
/// Back = FF `safePop`: pop, or go to the product's search page.
PreferredSizeWidget detailAppBar(BuildContext context, ProductType product) => tanjaiAppBar(
      title: product == ProductType.mc ? 'รายละเอียดประกันมอเตอร์ไซค์' : 'รายละเอียดประกันรถยนต์',
      backgroundColor: const Color(0xFFF1F4F8),
      titleColor: AppColors.navy,
      backColor: AppColors.brandOrange,
      titleSize: 19,
      onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.search(product)),
    );

/// FF FutureBuilder loading state: 50×50 spinner in theme.primary.
class DetailLoading extends StatelessWidget {
  const DetailLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
        ),
      );
}

/// ROW(label, value): Padding(20,10,20,10), label w500 #646464, value bold #222424.
class DetailRow extends StatelessWidget {
  const DetailRow(this.label, this.value, {super.key, this.valueColor = AppColors.textDark});

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.style(fontWeight: FontWeight.w500, color: AppColors.textGrey)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppText.style(fontWeight: FontWeight.bold, color: valueColor),
              ),
            ),
          ],
        ),
      );
}

/// SECTION_HEADER: orange vertical bar + bold navy 15 title.
class DetailSectionHeader extends StatelessWidget {
  const DetailSectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          children: [
            const SizedBox(height: 18, child: VerticalDivider(thickness: 3, color: Color(0xFFEDBB8D))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(text, style: AppText.style(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy)),
              ),
            ),
          ],
        ),
      );
}

/// Section body text (condition / motor add-on): Padding(left 30), plain bodyMedium.
class DetailSectionText extends StatelessWidget {
  const DetailSectionText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 30, right: 20),
        child: Text(text, textAlign: TextAlign.start, style: AppText.bodyMedium),
      );
}

/// Header grey info line: `label` | `value`, w500 #646464 13.
class DetailHeaderInfo extends StatelessWidget {
  const DetailHeaderInfo(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = AppText.style(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textGrey);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Flexible(child: Text(value, textAlign: TextAlign.end, style: style)),
      ],
    );
  }
}

/// Insurer logo with the no-image fallback (cross-origin logos rendered via
/// an <img> element so missing CORS headers don't break them).
class InsurerLogo extends StatelessWidget {
  const InsurerLogo(this.url, {super.key, this.width, this.height, this.fit = BoxFit.cover});

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, _, _) => Image.network(
          kNoImageUrl,
          width: width,
          height: height,
          fit: fit,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (_, _, _) => SizedBox(width: width, height: height),
        ),
      );
}

/// Registration year CE → BE string, '-' when missing (FF int.parse crash
/// on non-numeric input replaced with '-').
String yearBEText(String? yearCE) {
  final v = ff.checkNullValueAndReturn(yearCE);
  if (v == '-' || v.isEmpty) return '-';
  final y = int.tryParse(v);
  return y == null ? '-' : '${y + 543}';
}

/// `cnr(v)`, also mapping '' to '-'.
String nv(String? v) {
  final s = ff.checkNullValueAndReturn(v);
  return s.isEmpty ? '-' : s;
}
