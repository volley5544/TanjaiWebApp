import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'step3_data.dart';
import 'widgets.dart';

/// FF InsuranceInfoPage3 car diagram (`messageImage_1694485563447.jpg`,
/// 682×564 — heading, red hint, car with 9 numbered positions, tips box)
/// with invisible tap zones.
const kInspectionMapAsset = 'assets/images/request/inspection_map.jpg';

/// One FF tap zone: `AlignmentDirectional(x, y)`, w×h px.
class InspectionZone {
  const InspectionZone(this.photo, this.x, this.y, this.w, this.h);

  final InspectionPhoto photo;
  final double x;
  final double y;
  final double w;
  final double h;
}

/// FF coordinates, unchanged.
const kInspectionZones = [
  InspectionZone(InspectionPhoto.front, -1.04, 0.25, 100, 70),
  InspectionZone(InspectionPhoto.rightFront, -0.81, -0.45, 100, 70),
  InspectionZone(InspectionPhoto.right, 0.04, -0.34, 100, 70),
  InspectionZone(InspectionPhoto.rightRear, 0.79, -0.25, 100, 70),
  InspectionZone(InspectionPhoto.rear, 1.1, 0.47, 100, 70),
  InspectionZone(InspectionPhoto.leftRear, 0.8, 0.97, 100, 70),
  InspectionZone(InspectionPhoto.left, 0.02, 0.99, 100, 70),
  InspectionZone(InspectionPhoto.leftFront, -0.74, 0.95, 100, 70),
  InspectionZone(InspectionPhoto.roof, -0.04, 0.32, 157, 70),
];

/// FF: a 320-px box, full width, image `BoxFit.contain`, zones aligned to the
/// box. Web: the box is at most 387 px wide (320 × 682/564 — the width at
/// which the image fills the box) and centred, so on wide screens the zones
/// stay on the printed numbers as on a phone (FF's full-width box drifted).
class InspectionMap extends StatelessWidget {
  const InspectionMap({super.key, required this.onTap});

  final void Function(InspectionPhoto photo) onTap;

  static const _height = 320.0;
  static const _maxWidth = _height * 682 / 564;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      color: AppColors.secondaryBackground,
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, c) => SizedBox(
          width: c.maxWidth.clamp(0.0, _maxWidth),
          height: _height,
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset(kInspectionMapAsset, fit: BoxFit.contain)),
              for (final z in kInspectionZones)
                Align(
                  alignment: Alignment(z.x, z.y),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onTap: () => onTap(z.photo),
                    child: SizedBox(width: z.w, height: z.h),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 'ถ่ายรูปทรัพย์สิน' + 'บังคับถ่ายรูปให้ครบ 9 รูป' and the 9 status rows.
class InspectionStatusList extends StatelessWidget {
  const InspectionStatusList({super.key, required this.photos, required this.onView});

  final Map<InspectionPhoto, String> photos;
  final void Function(String url) onView;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final text = AppText.style(fontSize: 14, fontWeight: FontWeight.normal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 33),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('ถ่ายรูปทรัพย์สิน', style: AppText.style(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF003063))),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text('บังคับถ่ายรูปให้ครบ 9 รูป',
                      style: AppText.style(fontSize: 12, fontWeight: FontWeight.normal, color: const Color(0xFFFB0606))),
                ),
              ],
            ),
          ),
        ),
        for (final p in InspectionPhoto.values)
          SizedBox(
            width: w * 0.90,
            height: 35,
            child: Row(
              children: [
                Text('${p.number}.', style: text),
                Padding(padding: const EdgeInsets.fromLTRB(5, 0, 5, 0), child: Text('สถานะ :', style: text)),
                Expanded(child: Text(photos[p]!.isNotEmpty ? 'อัพโหลดสำเร็จ' : 'ยังไม่อัพโหลด', style: text)),
                UploadStateIcons(
                  uploaded: photos[p]!.isNotEmpty,
                  onView: () => onView(photos[p]!),
                  // FF: row 1 check_sharp `success` / ✕ #FC0A0A; rows 2–9
                  // check_rounded #00B505 / ✕ theme error.
                  checkIcon: p.number == 1 ? Icons.check_sharp : Icons.check_rounded,
                  checkColor: p.number == 1 ? AppColors.success : const Color(0xFF00B505),
                  closeColor: p.number == 1 ? kNotUploadedColor : AppColors.error,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
