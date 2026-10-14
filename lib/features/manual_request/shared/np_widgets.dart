import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../state/none_package_state.dart';

const npTitleNavy = Color(0xFF003063);
const npSectionNavy = Color(0xFF002D5E);
const npOrange = Color(0xFFDB771A);
const npRequiredRed = Color(0xFFFB0606);
const npBorderGrey = Color(0xFFB3B3B3);
const npPanelGrey = Color(0xFFFAFAFA);
const npCheckGreen = Color(0xFF2EDD78);

/// FF AppBar of the none-package pages: white, elevation 2, navy 18 title,
/// orange rounded back arrow.
PreferredSizeWidget npAppBar(String title, {required VoidCallback onBack, Color titleColor = npTitleNavy}) =>
    tanjaiAppBar(title: title, titleColor: titleColor, backColor: npOrange, onBack: onBack);

/// Title by work type (FF: transfer → งานโอนโค้ด, renew → งานต่ออายุ).
String npTitle(String workType, {bool flagRenew = false}) {
  if (workType == 'transfer') return 'งานโอนโค้ด';
  if (workType == 'renew' || flagRenew) return 'งานต่ออายุ';
  return 'งานนอกเรท';
}

/// Label row: text 15 w500 + optional extras + red required tag (12 w600).
class NpLabel extends StatelessWidget {
  const NpLabel(this.text, {super.key, this.tag, this.tagColor = npRequiredRed, this.extras = const []});

  final String text;
  final String? tag;
  final Color tagColor;
  final List<Widget> extras;

  @override
  Widget build(BuildContext context) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(text, style: AppText.style(fontSize: 15, fontWeight: FontWeight.w500)),
          ...extras,
          if (tag != null)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(tag!, style: AppText.style(fontSize: 12, color: tagColor)),
            ),
        ],
      );
}

/// 'เดิม' — w800 underlined (renew labels).
Widget npOldWord() => Text('เดิม',
    style: AppText.style(fontSize: 15, fontWeight: FontWeight.w800, decoration: TextDecoration.underline));

/// Section wrapper: Padding(20, 5, 20, [bottom]) + label + child.
class NpSection extends StatelessWidget {
  const NpSection({super.key, this.label, required this.child, this.bottom = 0});

  final Widget? label;
  final Widget child;
  final double bottom;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 5, 20, bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [?label, child],
        ),
      );
}

/// The h60 white bordered box.
BoxDecoration npBoxDecoration({Color? color = Colors.white}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: npBorderGrey),
    );

/// Picker box: value (black, or grey when [placeholder]) + trailing icon.
class NpPickerBox extends StatelessWidget {
  const NpPickerBox({
    super.key,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.icon = Icons.navigate_next,
  });

  final String value;
  final bool placeholder;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            onTap();
          },
          child: Container(
            height: 60,
            decoration: npBoxDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.style(fontSize: 15, color: placeholder ? npBorderGrey : Colors.black),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(icon, color: npBorderGrey, size: 24),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Text box: borderless field in the h60 box.
class NpTextBox extends StatelessWidget {
  const NpTextBox({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.fill = true,
    this.textColor = Colors.black,
    this.onChanged,
    this.textInputAction,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<dynamic>? inputFormatters;
  final bool fill;
  final Color textColor;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final int? maxLength;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          decoration: npBoxDecoration(color: fill ? Colors.white : null),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters?.cast(),
            textInputAction: textInputAction,
            onChanged: onChanged,
            maxLength: maxLength,
            style: AppText.style(fontSize: 15, color: textColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.style(fontSize: 15, fontWeight: FontWeight.w500, color: npBorderGrey),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterText: '',
              isDense: true,
            ),
          ),
        ),
      );
}

/// 25×25 selection circle: white/grey border, or green with a tick.
class NpSelectCircle extends StatelessWidget {
  const NpSelectCircle(this.selected, {super.key, this.size = 25});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected ? AppColors.success : Colors.white,
          shape: BoxShape.circle,
          border: selected ? null : Border.all(color: const Color(0xFF9F9F9F)),
        ),
        child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      );
}

/// Toggle box: label (grey off / black on) + selection circle.
class NpToggleBox extends StatelessWidget {
  const NpToggleBox({super.key, required this.text, required this.on, required this.onTap});

  final String text;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
            onTap();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Container(
            height: 60,
            decoration: npBoxDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(text, style: AppText.style(fontSize: 15, color: on ? Colors.black : npBorderGrey)),
                  ),
                ),
                Padding(padding: const EdgeInsets.only(right: 10), child: NpSelectCircle(on)),
              ],
            ),
          ),
        ),
      );
}

/// Full-width orange bottom button (h60, radius 16).
class NpBottomButton extends StatelessWidget {
  const NpBottomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = const Color(0xFFDB771B),
    this.padding = const EdgeInsets.fromLTRB(12, 16, 12, 24),
  });

  final String text;
  final VoidCallback onPressed;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: padding,
        child: AppButton(text: text, onPressed: onPressed, color: color, fontSize: 16),
      );
}

/// Read-only grey value box of the edit pages (h60 `#F0F0F0`, border `#737373`).
class NpReadBox extends StatelessWidget {
  const NpReadBox(this.text, {super.key, this.color = const Color(0xFFF0F0F0), this.textColor = const Color(0xFF565656)});

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
        height: 60,
        width: double.infinity,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF737373)),
        ),
        child: Text(text, style: AppText.style(fontSize: 15, color: textColor)),
      );
}

/// "See image" icon of an upload row: the photo uploaded in this flow
/// ([url]) or, on edit pages before a re-upload, the one already on the
/// request ([existingUrl]). Hidden when there is neither.
Widget? npSeeImageIcon(BuildContext context, String url, {String existingUrl = '', double size = 24}) {
  final show = url.isNotEmpty ? url : existingUrl;
  if (show.isEmpty) return null;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: NpViewIcon(onTap: () => showNpImages(context, [show]), size: size),
  );
}

/// Status icon of upload rows: green tick / red cross.
Widget npStatusIcon(bool done, {double size = 24, Color fail = const Color(0xFFFC0A0A)}) =>
    Icon(done ? Icons.check : Icons.close, color: done ? npCheckGreen : fail, size: size);

/// Image2 / EditPage3 upload row: 'ถ่ายรูป' (125×45) + status + icons.
class NpPhotoRow extends StatelessWidget {
  const NpPhotoRow({super.key, required this.url, required this.onTap, this.existingUrl = ''});

  /// Photo uploaded in this flow ('' = not yet).
  final String url;

  /// Edit pages: photo already on the request.
  final String existingUrl;
  final VoidCallback onTap;

  bool get done => url.isNotEmpty;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: onTap,
              child: Container(
                width: 125,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.lightOrange, borderRadius: BorderRadius.circular(12)),
                child: Text('ถ่ายรูป', style: AppText.style(fontSize: 15, color: npOrange)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(done ? 'สถานะ : อัพโหลดแล้ว' : 'สถานะ : ยังไม่อัพโหลด', style: AppText.bodyMedium),
            ),
            ?npSeeImageIcon(context, url, existingUrl: existingUrl),
            npStatusIcon(done),
          ],
        ),
      );
}

/// Title row of an upload slot (Image2 / EditPage3): title + 'บังคับถ่ายรูป'.
class NpPhotoTitle extends StatelessWidget {
  const NpPhotoTitle(this.text, {super.key, this.required = false, this.trailing});

  final String text;
  final bool required;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        child: Row(
          children: [
            Flexible(child: Text(text, style: AppText.bodyMedium)),
            if (required)
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Text('บังคับถ่ายรูป',
                    style: AppText.style(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFFFC0D0D))),
              ),
            ?trailing,
          ],
        ),
      );
}

/// Transfer / renew document row ('แนบไฟล์' button, h80 grey card).
class NpAttachRow extends StatelessWidget {
  const NpAttachRow({
    super.key,
    required this.title,
    required this.url,
    required this.onTap,
    this.tag,
    this.titleExtras = const [],
    this.existingUrl = '',
  });

  final String title;
  final String? tag;
  final List<Widget> titleExtras;
  /// Photo uploaded in this flow ('' = not yet).
  final String url;

  /// Edit pages: photo already on the request.
  final String existingUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final done = url.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        height: 80,
        color: npPanelGrey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: AppText.style(fontSize: 15, fontWeight: FontWeight.w500)),
                if (tag != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(tag!, style: AppText.style(fontSize: 12, color: npRequiredRed)),
                  ),
                ...titleExtras,
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: SizedBox(
                height: 45,
                child: Row(
                  children: [
                    SizedBox(
                      width: w * 0.35,
                      height: 40,
                      child: AppButton(
                        text: 'แนบไฟล์',
                        onPressed: onTap,
                        height: 40,
                        color: AppColors.lightOrange,
                        textColor: AppColors.sheetButtonOrange,
                        fontSize: 16,
                        radius: 8,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
                      child: Text('สถานะ :', style: AppText.bodyMedium),
                    ),
                    Expanded(child: Text(done ? 'อัพโหลดแล้ว' : 'ยังไม่อัพโหลด', style: AppText.bodyMedium)),
                    ?npSeeImageIcon(context, url, existingUrl: existingUrl),
                    npStatusIcon(done),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `content_paste_search_rounded` icon that opens an existing image.
class NpViewIcon extends StatelessWidget {
  const NpViewIcon({super.key, required this.onTap, this.size = 24});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Icon(Icons.content_paste_search_rounded, color: const Color(0xFF354052), size: size),
      );
}

bool _safeImageUrl(String url) {
  final u = Uri.tryParse(url);
  return u != null && u.scheme == 'https' && u.host.isNotEmpty;
}

/// FF ShowImageComponent / ShowImageListComponent: dark sheet with a white ✕
/// and the image(s) (paged when several).
Future<void> showNpImages(BuildContext context, List<String> urls) {
  final safe = urls.where(_safeImageUrl).toList();
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
          children: [
            SizedBox(height: h * 0.1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_outlined, color: Colors.white, size: 40),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: h * 0.7,
              child: PageView(
                children: [
                  for (final u in safe)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          u,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Hotspot of the vehicle diagram (FF Align(x, y) + transparent w×h box).
class DiagramSpot {
  const DiagramSpot(this.slot, this.x, this.y, this.w, this.h, this.number);

  final CarSlot slot;
  final double x;
  final double y;
  final double w;
  final double h;
  final int number;
}

/// FF photo diagram: image (full width, cover) in a fixed 303-px stack with
/// invisible tap spots over the printed numbers.
///
/// Web: the stack height follows the image aspect on wide screens (FF fixed
/// it at 303 px, which clipped the image above ~420 px wide); the spots keep
/// FF's Align coordinates.
class VehicleDiagram extends StatelessWidget {
  const VehicleDiagram({super.key, required this.asset, required this.aspect, required this.spots, required this.onTap});

  final String asset;

  /// height / width of the image.
  final double aspect;
  final List<DiagramSpot> spots;
  final void Function(DiagramSpot) onTap;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.only(top: 12),
        child: LayoutBuilder(
          builder: (context, c) {
            final h = (c.maxWidth * aspect).clamp(303.0, 1000.0);
            return SizedBox(
              height: h,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Image.asset(asset, width: double.infinity, fit: BoxFit.cover),
                  for (final s in spots)
                    Align(
                      alignment: Alignment(s.x, s.y),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        onTap: () => onTap(s),
                        child: SizedBox(width: s.w, height: s.h),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
}

/// Status card under a diagram: 'ถ่ายรูปทรัพย์สิน' + n rows of
/// 'n.สถานะ : อัพโหลดเรียบร้อย' / 'ยังไม่อัพโหลด' with ✓ / ✕.
class PhotoStatusCard extends StatelessWidget {
  const PhotoStatusCard({super.key, required this.urls, this.subtitle, this.existing});

  /// Photo uploaded in this flow per row (1-based order; '' = not yet).
  final List<String> urls;
  final String? subtitle;

  /// Edit pages: photo already on the request per row.
  final List<String>? existing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(left: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 15, 12, 0),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('ถ่ายรูปทรัพย์สิน', style: AppText.style(fontSize: 18, color: npSectionNavy)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(subtitle!,
                            style: AppText.style(fontWeight: FontWeight.w500, color: AppColors.error)),
                      ),
                  ],
                ),
              ),
              for (var i = 0; i < urls.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 12 : 4),
                  child: SizedBox(
                    height: 20,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                '${i + 1}.สถานะ : ${urls[i].isNotEmpty ? 'อัพโหลดเรียบร้อย' : 'ยังไม่อัพโหลด'}',
                                style: AppText.style(fontSize: 12),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ?npSeeImageIcon(context, urls[i], existingUrl: existing?[i] ?? '', size: 18),
                                npStatusIcon(urls[i].isNotEmpty, size: 18, fail: const Color(0xFFFF2B2B)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

/// FF car / truck / trailer diagram spots (create + edit pages share them;
/// the edit page's FF coordinates differ slightly — passed separately).
const carSpotsCreate = [
  DiagramSpot(CarSlot.front, -0.98, 0.01, 100, 70, 1),
  DiagramSpot(CarSlot.rightFront, -0.95, -0.71, 110, 80, 2),
  DiagramSpot(CarSlot.right, 0.0, -0.8, 110, 80, 3),
  DiagramSpot(CarSlot.rightRear, 0.72, -0.71, 110, 80, 4),
  DiagramSpot(CarSlot.rear, 1.02, 0.14, 110, 70, 5),
  DiagramSpot(CarSlot.leftRear, 0.87, 1.0, 100, 80, 6),
  DiagramSpot(CarSlot.left, 0.03, 1.18, 100, 80, 7),
  DiagramSpot(CarSlot.leftFront, -0.83, 0.99, 100, 80, 8),
  DiagramSpot(CarSlot.roof, 0.0, 0.0, 160, 70, 9),
];
const trailerSpotsCreate = [
  DiagramSpot(CarSlot.trailerFront, -0.98, 0.01, 100, 70, 1),
  DiagramSpot(CarSlot.trailerRightFront, -0.95, -0.71, 110, 80, 2),
  DiagramSpot(CarSlot.trailerRight, 0.0, -0.8, 110, 80, 3),
  DiagramSpot(CarSlot.trailerRightRear, 0.8, -0.62, 110, 60, 4),
  DiagramSpot(CarSlot.trailerRear, 1.0, 0.06, 110, 60, 5),
  DiagramSpot(CarSlot.trailerLeftRear, 0.88, 0.93, 100, 80, 6),
  DiagramSpot(CarSlot.trailerLeft, 0.0, 1.03, 100, 80, 7),
  DiagramSpot(CarSlot.trailerLeftFront, -0.88, 0.94, 100, 80, 8),
];
const carSpotsEdit = [
  DiagramSpot(CarSlot.front, -0.98, 0.01, 100, 70, 1),
  DiagramSpot(CarSlot.rightFront, -0.95, -0.71, 110, 80, 2),
  DiagramSpot(CarSlot.right, 0.0, -0.8, 110, 80, 3),
  DiagramSpot(CarSlot.rightRear, 0.72, -0.61, 110, 80, 4),
  DiagramSpot(CarSlot.rear, 1.03, 0.21, 110, 70, 5),
  DiagramSpot(CarSlot.leftRear, 0.91, 0.96, 100, 80, 6),
  DiagramSpot(CarSlot.left, 0.05, 1.22, 100, 80, 7),
  DiagramSpot(CarSlot.leftFront, -0.82, 0.94, 100, 80, 8),
  DiagramSpot(CarSlot.roof, 0.0, 0.0, 160, 70, 9),
];
const trailerSpotsEdit = [
  DiagramSpot(CarSlot.trailerFront, -0.98, 0.01, 100, 70, 1),
  DiagramSpot(CarSlot.trailerRightFront, -0.95, -0.71, 110, 80, 2),
  DiagramSpot(CarSlot.trailerRight, 0.0, -0.8, 110, 80, 3),
  DiagramSpot(CarSlot.trailerRightRear, 0.72, -0.58, 110, 60, 4),
  DiagramSpot(CarSlot.trailerRear, 1.0, 0.06, 110, 60, 5),
  DiagramSpot(CarSlot.trailerLeftRear, 0.84, 0.88, 100, 80, 6),
  DiagramSpot(CarSlot.trailerLeft, 0.01, 1.21, 100, 80, 7),
  DiagramSpot(CarSlot.trailerLeftFront, -0.85, 0.94, 100, 80, 8),
];

const diagramCarAsset = 'assets/images/diagram_car.jpg'; // 764×550
const diagramTruckAsset = 'assets/images/diagram_truck_head.jpg'; // 752×565
const diagramTrailerAsset = 'assets/images/diagram_trailer.jpg'; // 758×575
const diagramCarAspect = 550 / 764;
const diagramTruckAspect = 565 / 752;
const diagramTrailerAspect = 575 / 758;

/// FF confirm text — only photo 1 has a space before 'ใช่หรือไม่' (kept).
String photoConfirmText(int n) => n == 1 ? 'คุณต้องการถ่ายรูปที่ 1 ใช่หรือไม่' : 'คุณต้องการถ่ายรูปที่ $nใช่หรือไม่';
