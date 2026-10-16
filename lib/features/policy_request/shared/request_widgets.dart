import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/env_version_tag.dart';
import '../../../router/app_router.dart';
import '../models/request_variant.dart';
import '../state/policy_request_state.dart';

/// Shared building blocks of the request-policy step pages (FF
/// `in_package_insurance`). Colours / sizes are the FF values from the specs.

const kRequestOrange = Color(0xFFD9761A);
const kRequestLightOrange = Color(0xFFFCEFE4);
const kRequestNavy = Color(0xFF003063);
const kRequestBorder = Color(0xFFE6E6E6);
const kRequestGrey = Color(0xFFB3B3B3);
const kRequestTagRed = Color(0xFFFB0606);
const kRequestPlaceholder = Color(0xFF9F9F9F);
const kRequestChevron = Color(0xFF474747);

/// FF NO_IMG (insurer logo fallback).
const kRequestNoImageUrl =
    'https://firebasestorage.googleapis.com/v0/b/sawad-new-ibs.appspot.com/o/No_image_available.png?alt=media&token=15ea426e-3ea2-4b15-8f1b-947dc2daef37';

/// Step-page AppBar: white, elevation 2, centred title #003063 18 w600,
/// back `arrow_back_rounded` #DB771A 30 (hidden when [onBack] is null).
PreferredSizeWidget requestAppBar({
  required String title,
  VoidCallback? onBack,
  List<Widget> actions = const [],
}) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    automaticallyImplyLeading: false,
    centerTitle: true,
    elevation: 2,
    shadowColor: const Color(0x33000000),
    leading: onBack == null
        ? null
        : IconButton(
            onPressed: onBack,
            splashRadius: 30,
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.brandOrange, size: 30),
          ),
    title: Text(title, style: AppText.style(fontSize: 18, color: kRequestNavy)),
    actions: [...actions, const EnvVersionTag()],
  );
}

/// The 1–5 circles under the summary card (FF inline row, spec shared §1.6).
class RequestStepIndicator extends StatelessWidget {
  const RequestStepIndicator({super.key, required this.current});

  /// 1…5 (P1 = 1, P2 = 2, P3 = 3, P4 / 4.1 / 4.2 = 4, P5 = 5).
  final int current;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final d = size.width * 0.11;
    Widget circle(int n) {
      final done = n <= current;
      return Container(
        width: d,
        height: d,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? kRequestOrange : AppColors.secondaryBackground,
          border: Border.all(color: done && n == 1 ? const Color(0xFFFAFAFA) : kRequestGrey),
        ),
        child: Text('$n', style: AppText.style(fontSize: 15, color: done ? const Color(0xFFFAFAFA) : kRequestGrey)),
      );
    }

    Widget line(int nextStep) => SizedBox(
          width: size.width * 0.06,
          child: Center(
            child: SizedBox(
              width: 32,
              child: Divider(thickness: 1, color: nextStep <= current ? kRequestOrange : kRequestGrey),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          height: size.height * 0.10,
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kRequestBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                circle(1),
                for (var n = 2; n <= 5; n++) ...[line(n), circle(n)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// FF `InfomationCustomer` (motor / EV / MC) — the card at the top of every
/// step. Reads [PolicyRequestState.summary]. (CMI / House cards: not ported.)
class RequestSummaryCard extends StatelessWidget {
  const RequestSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = PolicyRequestState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final s = state.summary;
        final width = MediaQuery.sizeOf(context).width;
        final base = AppText.style(fontSize: 15, fontWeight: FontWeight.normal);
        final strong = AppText.style(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryText);
        Widget row(String label, String value, {bool bold = false}) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: width * 0.20, child: Text(label, style: base)),
                SizedBox(width: 10, child: Text(':', style: AppText.style(fontWeight: FontWeight.normal))),
                Expanded(child: Text(value, style: bold ? strong : base)),
              ],
            );
        String baht(String v) => '${showNumberWithComma(v)} บาท';
        final logo = s.insurerLogo.isNotEmpty ? s.insurerLogo : kRequestNoImageUrl;
        return Material(
          elevation: 1,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kRequestBorder),
            ),
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: width * 0.65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      row('ใบเสนอราคา', s.quotationId),
                      row('ชื่อลูกค้า', '${s.firstName}  ${s.lastName}'),
                      row('เบอร์โทร', s.phone),
                      row('การซ่อม', s.garageType),
                      row('ประกัน', s.coverType),
                      row('ราคาเบี้ย', baht(s.netPremiumTotal), bold: true),
                      if (s.actFlag == '1') row('ราคา พ.ร.บ', baht(s.actAmount), bold: true),
                      if (s.discountFlg == '1') row('ราคาที่ลด', baht(s.discountOther), bold: true),
                      if (s.actFlag == '1' || s.discountFlg == '1') row('ราคารวม', baht(s.grossTotalNet), bold: true),
                      row('ขอเบี้ย', s.quotationTypeBakName, bold: true),
                      row('แจ้งงาน', s.quotationTypeName, bold: true),
                      row('ผลิตภัณฑ์', s.subProductName, bold: true),
                    ],
                  ),
                ),
                Flexible(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: SizedBox(
                      height: 75,
                      child: RequestNetworkImage(url: logo, width: 300, height: 200),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Network image (https only) with the FF `error_image.png` fallback.
class RequestNetworkImage extends StatelessWidget {
  const RequestNetworkImage({super.key, required this.url, this.width, this.height, this.fit = BoxFit.cover});

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  static bool isHttps(String url) {
    final u = Uri.tryParse(url.trim());
    return u != null && u.scheme == 'https' && u.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset('assets/images/error_image.png', width: width, height: height, fit: fit);
    if (!isHttps(url)) return fallback;
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

/// FF field label row: label 15 w500 + optional red tag 12 (10 px gap).
class RequestFieldLabel extends StatelessWidget {
  const RequestFieldLabel(this.label, {super.key, this.tag = '', this.padding = const EdgeInsets.symmetric(horizontal: 12)});

  final String label;

  /// e.g. '(บังคับกรอก)' / '(บังคับเลือก)'.
  final String tag;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label, style: AppText.style(fontSize: 15, fontWeight: FontWeight.w500)),
          if (tag.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(tag, style: AppText.style(fontSize: 12, color: kRequestTagRed)),
            ),
        ],
      ),
    );
  }
}

/// FF field box: 60 high, white, radius 8, border #B3B3B3.
class RequestBox extends StatelessWidget {
  const RequestBox({super.key, required this.child, this.color = AppColors.secondaryBackground, this.height = 60});

  final Widget child;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kRequestGrey),
      ),
      child: child,
    );
  }
}

/// FF picker row (ListTile in a [RequestBox]): title 15 w600, grey #9F9F9F
/// when [isPlaceholder], chevron `arrow_forward_ios` #474747 20.
class RequestPickerTile extends StatelessWidget {
  const RequestPickerTile({super.key, required this.text, required this.isPlaceholder, required this.onTap});

  final String text;
  final bool isPlaceholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RequestBox(
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.style(fontSize: 15, color: isPlaceholder ? kRequestPlaceholder : Colors.black),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: kRequestChevron, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labelled block: [RequestFieldLabel] above [child], FF top padding 5.
class RequestField extends StatelessWidget {
  const RequestField({super.key, required this.label, required this.child, this.tag = '', this.top = 5});

  final String label;
  final String tag;
  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RequestFieldLabel(label, tag: tag),
          Padding(padding: const EdgeInsets.only(top: 5), child: child),
        ],
      ),
    );
  }
}

/// The FF 'บันทึกเตรียมข้อมูล' (light) + 'ถัดไป' (orange) pair, each 45 % wide,
/// 60 high, radius 16; [onNext] null hides 'ถัดไป' (shown only after a save).
class RequestSaveNextButtons extends StatelessWidget {
  const RequestSaveNextButtons({
    super.key,
    required this.onSave,
    required this.onNext,
    this.saveText = 'บันทึกเตรียมข้อมูล',
    this.nextText = 'ถัดไป',
  });

  final VoidCallback? onSave;
  final VoidCallback? onNext;
  final String saveText;
  final String nextText;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width * 0.45;
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppButton(
            text: saveText,
            onPressed: onSave,
            width: w,
            color: kRequestLightOrange,
            textColor: kRequestOrange,
            borderColor: kRequestLightOrange,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          if (onNext != null)
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: AppButton(
                text: nextText,
                onPressed: onNext,
                width: w,
                color: kRequestOrange,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
        ],
      ),
    );
  }
}

/// FF `ShowImageComponent` in its 70 % black bottom sheet: ✕ + one image.
Future<void> showRequestImage(BuildContext context, String url) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: const Color(0xB3000000),
    builder: (ctx) {
      final h = MediaQuery.sizeOf(ctx).height;
      return SizedBox(
        height: h,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: h * 0.10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: IconButton(
                icon: const Icon(Icons.close_outlined, color: Colors.white, size: 40),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: h * 0.70,
              width: double.infinity,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: RequestNetworkImage(url: url, width: double.infinity, fit: BoxFit.contain),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// FF `ShowImageListComponent`: horizontal pages of images + dots.
Future<void> showRequestImageList(BuildContext context, List<String> urls) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: const Color(0xB3000000),
    builder: (ctx) => _ImageListSheet(urls: urls),
  );
}

class _ImageListSheet extends StatefulWidget {
  const _ImageListSheet({required this.urls});

  final List<String> urls;

  @override
  State<_ImageListSheet> createState() => _ImageListSheetState();
}

class _ImageListSheetState extends State<_ImageListSheet> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: h * 0.10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: IconButton(
              icon: const Icon(Icons.close_outlined, color: Colors.white, size: 40),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: h * 0.70,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      for (final u in widget.urls)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: RequestNetworkImage(url: u, width: double.infinity, fit: BoxFit.contain),
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < widget.urls.length; i++)
                          GestureDetector(
                            onTap: () => _controller.animateToPage(i,
                                duration: const Duration(milliseconds: 500), curve: Curves.ease),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == _page ? 32 : 16,
                              height: 8,
                              decoration: BoxDecoration(
                                // FF ExpandingDots: accent1 / active primary (FF purple, kept).
                                color: i == _page ? AppColors.primary : AppColors.accent1,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                      ],
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
}

/// FF alert after an API failure: HTTP ≠ 200 → `พบข้อผิดพลาด (<status>)`;
/// else the body message. Returns true when [ok].
Future<bool> requestCheck(BuildContext context, {required int statusCode, required int? code, String? message}) async {
  if (statusCode != 200) {
    await showAlert(context, 'พบข้อผิดพลาด ($statusCode)');
    return false;
  }
  if (code != 200) {
    await showAlert(context, message ?? '');
    return false;
  }
  return true;
}

/// Leaves the flow to the work list (user, 2026-10-16: FF P1 back went to
/// LeadFollowUpPage and P5 used the bottom nav; neither is ported — the
/// quotation list is the nearest ported list).
void leaveRequestFlow(BuildContext context) {
  final fire = PolicyRequestState.instance.fromPage == 'FireInsurance' ||
      PolicyRequestState.instance.variant.product == RequestProduct.house;
  context.go(fire ? AppRoutes.fireQuotationList : AppRoutes.quotationList);
}

/// Redirects to the quotation list when a step page is opened without an
/// active flow (browser refresh / deep link). Call from `initState`.
bool redirectIfNoFlow(BuildContext context) {
  if (PolicyRequestState.instance.isActive) return false;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) context.go(AppRoutes.quotationList);
  });
  return true;
}

/// Temporary page for a step that isn't ported yet.
class RequestPlaceholderPage extends StatelessWidget {
  const RequestPlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: requestAppBar(title: title, onBack: () => context.canPop() ? context.pop() : leaveRequestFlow(context)),
      body: SafeArea(
        child: Center(child: Text('กำลังพัฒนา', style: AppText.style(fontSize: 16, color: kRequestGrey))),
      ),
    );
  }
}

/// Standard step-page scaffold: summary card, step indicator, then [children]
/// in a scrolling column (padding 12/15/12/0, 50 px end spacer), FF system
/// back disabled.
class RequestStepScaffold extends StatelessWidget {
  const RequestStepScaffold({
    super.key,
    required this.title,
    required this.step,
    required this.children,
    this.onBack,
    this.actions = const [],
    this.showSummary = true,
  });

  final String title;
  final int step;
  final List<Widget> children;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool showSummary;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: UnfocusOnTap(
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: requestAppBar(title: title, onBack: onBack, actions: actions),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 15, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSummary) const RequestSummaryCard(),
                  RequestStepIndicator(current: step),
                  ...children,
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
