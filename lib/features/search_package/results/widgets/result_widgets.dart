import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ff_functions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/env_version_tag.dart';
import '../../models/insurance_package.dart';

/// Shared pieces of InsurerOverallPage (spec 04) and InsurerListPage (spec 05).

/// FF theme `grayIcon`.
const kGrayIcon = Color(0xFF95A1AC);

/// FF `#9EFF6500` semi-transparent orange of the 'รายละเอียด' buttons.
const kDetailButtonColor = Color(0x9EFF6500);

const kCardShadow = [BoxShadow(blurRadius: 4, color: Color(0x33000000), offset: Offset(0, 2))];

/// AppBar of the result pages: white, elevation 2, orange rounded back arrow.
PreferredSizeWidget resultAppBar({required String title, required VoidCallback onBack}) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    automaticallyImplyLeading: false,
    centerTitle: true,
    elevation: 2,
    shadowColor: const Color(0x33000000),
    leading: IconButton(
      onPressed: onBack,
      splashRadius: 30,
      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.brandOrange, size: 30),
    ),
    title: Text(title, style: AppText.style(fontSize: 18, color: const Color(0xFF003063))),
    actions: const [EnvVersionTag()],
  );
}

/// Insurer logo, 40×40 `BoxFit.contain`, falling back to the no-image URL.
class InsurerLogo extends StatelessWidget {
  const InsurerLogo({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      color: AppColors.secondaryBackground,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, _, _) => Image.network(
          kNoImageUrl,
          fit: BoxFit.contain,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// The h30 'รายละเอียด' FFButton (auto width, padding H24, radius 10).
class DetailButton extends StatelessWidget {
  const DetailButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kDetailButtonColor,
          foregroundColor: Colors.white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text('รายละเอียด', style: AppText.style(fontSize: 12, color: Colors.white)),
      ),
    );
  }
}

/// Label row above the filter box + the h40 tappable filter box.
class ResultFilterBox extends StatelessWidget {
  const ResultFilterBox({
    super.key,
    required this.text,
    required this.onTap,
    this.onClear,
    this.extraLabel,
  });

  final String text;
  final VoidCallback onTap;

  /// When set, a cancel icon replaces the chevron (spec 04 §4.3).
  final VoidCallback? onClear;

  /// Spec 05: red '(เลือกเปรียบเทียบสูงสุด 3 รายการเท่านั้น)' after the label.
  final String? extraLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 4),
                child: Text('ค้นหาชื่อบริษัทประกัน ', style: AppText.style(color: kGrayIcon)),
              ),
              if (extraLabel != null)
                Flexible(child: Text(extraLabel!, style: AppText.style(fontSize: 12, color: AppColors.error))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kGrayIcon),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.style(color: AppColors.secondaryText),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: onClear != null
                          ? InkWell(
                              onTap: onClear,
                              child: const Icon(Icons.cancel_outlined, color: AppColors.secondaryText, size: 18),
                            )
                          : const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The two "ราคาเบี้ย / ทุนประกัน ต่ำสุด–สูงสุด" text rows.
class RangeSummaryRows extends StatelessWidget {
  const RangeSummaryRows({
    super.key,
    required this.minGross,
    required this.maxGross,
    required this.minSum,
    required this.maxSum,
    this.firstTopPadding = 4,
  });

  final double minGross;
  final double maxGross;
  final double minSum;
  final double maxSum;
  final double firstTopPadding;

  // '$v' (not toStringAsFixed) so showNumberWithComma truncates like FF did.
  static String _fmt(double v) => showNumberWithComma('$v');

  Widget _row(String a, String b, double top) => Padding(
        padding: EdgeInsets.fromLTRB(24, top, 24, 0),
        child: Row(
          children: [
            Expanded(child: Text(a, style: AppText.style(fontSize: 12))),
            Expanded(child: Text(b, style: AppText.style(fontSize: 12))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('ราคาเบี้ยต่ำสุด:${_fmt(minGross)}', 'ราคาเบี้ยสูงสุด:${_fmt(maxGross)}', firstTopPadding),
        _row('ทุนประกันต่ำสุด:${_fmt(minSum)}', 'ทุนประกันสูงสุด:${_fmt(maxSum)}', 4),
      ],
    );
  }
}

/// Empty-state box ('ไม่พบข้อมูล…').
class ResultEmptyBox extends StatelessWidget {
  const ResultEmptyBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: MediaQuery.sizeOf(context).height * 0.53,
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(blurRadius: 1, color: Color(0x33000000))],
        ),
        alignment: Alignment.center,
        child: Text(text, style: AppText.style(fontSize: 20, color: kGrayIcon)),
      ),
    );
  }
}

/// The "งานนอกเรท" row with its 'นอกเรท' button.
class NonRateRow extends StatelessWidget {
  const NonRateRow({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Container(
        width: double.infinity,
        height: 45,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.secondaryText),
          boxShadow: kCardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryText),
                    ),
                    alignment: Alignment.center,
                    // FF: FaIcon(FontAwesomeIcons.carSide); no icon package here, closest Material glyph.
                    child: const Icon(Icons.directions_car_filled, color: Color(0xFF7A848E), size: 24),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text('งานนอกเรท', textAlign: TextAlign.center, style: AppText.style(fontSize: 16)),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AppButton(
                  text: 'นอกเรท',
                  onPressed: onPressed,
                  height: 30,
                  padding: EdgeInsets.zero,
                  color: const Color(0xFFD9D9D9),
                  textColor: const Color(0xFF090F13),
                  fontSize: 16,
                  radius: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `label … value` row of a result card (Padding B3, spaceBetween, value
/// padded R20).
class CardInfoRow extends StatelessWidget {
  const CardInfoRow({super.key, required this.label, this.value, this.trailing});

  final Text label;
  final Text? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final right = trailing ?? value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: label),
          if (right != null) Padding(padding: const EdgeInsets.only(right: 20), child: right),
        ],
      ),
    );
  }
}
