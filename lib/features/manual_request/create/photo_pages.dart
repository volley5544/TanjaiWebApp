import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../router/app_router.dart';
import '../shared/np_widgets.dart';
import '../shared/photo_upload.dart';
import '../state/none_package_state.dart';

/// Guard shared by the create-flow pages: no active flow → home.
void _guard(State s) {
  if (!NonePackageState.instance.active) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (s.mounted) s.context.go(AppRoutes.home);
    });
  }
}

/// Port of FF `NonePackageBasicImage1Page` — vehicle photos: tap a number on
/// the diagram, confirm, pick, upload. 9 car photos (8 for a truck head) and,
/// for a truck with trailer, 8 trailer photos.
class BasicImage1Page extends StatefulWidget {
  const BasicImage1Page({super.key});

  @override
  State<BasicImage1Page> createState() => _BasicImage1PageState();
}

class _BasicImage1PageState extends State<BasicImage1Page> {
  final _s = NonePackageState.instance;

  @override
  void initState() {
    super.initState();
    _guard(this);
  }

  Future<void> _onSpot(DiagramSpot spot) async {
    final ok = await showConfirm(context, photoConfirmText(spot.number), cancelText: 'ไม่', confirmText: 'ใช่');
    if (!ok || !mounted) return;
    await uploadSlot(context, (url) => _s.carPhotos[spot.slot] = url);
    _s.notify();
  }

  Future<void> _next() async {
    final carSlots = _s.isTruck ? CarSlot.car.take(8) : CarSlot.car;
    if (!carSlots.every((c) => _s.carPhoto(c).isNotEmpty)) {
      await showAlert(context, _s.isTruck ? 'กรุณาอัพโหลดรูปรถทั้ง 8 รูป' : 'กรุณาอัพโหลดรูปรถทั้ง 9 รูป');
      return;
    }
    if (_s.hasTrailer && !CarSlot.trailer.every((c) => _s.carPhoto(c).isNotEmpty)) {
      if (mounted) await showAlert(context, 'กรุณาอัพโหลดรูปหางพ่วงทั้ง 8 รูป');
      return;
    }
    if (mounted) context.push(AppRoutes.manualDocuments);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final s = _s;
        final carSlots = s.isTruck ? CarSlot.car.take(8).toList() : CarSlot.car;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: npAppBar(npTitle(s.workType), onBack: () => context.pop()),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 10,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: npPanelGrey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 15, 12, 0),
                                child: Text('ถ่ายรูปสินทรัพย์', style: AppText.style(fontSize: 20)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('*** กรุณากดที่แต่ละตำแหน่งของรถเพื่อถ่ายรูป ***',
                                    style: AppText.style(color: const Color(0xFFC33D5E))),
                              ),
                              VehicleDiagram(
                                asset: s.isTruck ? diagramTruckAsset : diagramCarAsset,
                                aspect: s.isTruck ? diagramTruckAspect : diagramCarAspect,
                                spots: [for (final sp in carSpotsCreate) if (!(s.isTruck && sp.slot == CarSlot.roof)) sp],
                                onTap: _onSpot,
                              ),
                            ],
                          ),
                        ),
                        PhotoStatusCard(
                          subtitle: s.isTruck ? 'บังคับถ่ายรูปให้ครบ 8 รูป' : 'บังคับถ่ายรูปให้ครบ 9 รูป',
                          urls: [for (final c in carSlots) s.carPhoto(c)],
                        ),
                        if (s.hasTrailer) ...[
                          VehicleDiagram(
                            asset: diagramTrailerAsset,
                            aspect: diagramTrailerAspect,
                            spots: trailerSpotsCreate,
                            onTap: _onSpot,
                          ),
                          PhotoStatusCard(urls: [for (final c in CarSlot.trailer) s.carPhoto(c)]),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: AppButton(text: 'ถัดไป', onPressed: _next, color: npOrange, fontSize: 16),
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

/// Port of FF `NonePackageBasicImage2Page` — documents (vehicle book, ID
/// card, up to 5 others) and the three consents.
///
/// Web fix: FF drove the row status from page-local values, so coming back
/// to the page showed every photo as not uploaded (while the next button
/// still passed); here status comes from the flow state.
class BasicImage2Page extends StatefulWidget {
  const BasicImage2Page({super.key});

  @override
  State<BasicImage2Page> createState() => _BasicImage2PageState();
}

class _BasicImage2PageState extends State<BasicImage2Page> {
  final _s = NonePackageState.instance;
  final _consent = [false, false, false];
  bool _consentAll = false;

  static const _consentText =
      '1.ข้าพเจ้ารับทราบว่า ข้อมูลส่วนบุคคลของข้าพเจ้าได้รับการเก็บรวบรวม ใช้ และเปิดเผย ตามคำชี้แจงเกี่ยวกับข้อมูลส่วนบุคคลของบริษัท\n\n'
      '2.ผู้เอาประกันภัยและผู้รับประโยชน์/ ผู้ชำระเบี้ย ไม่มีความสัมพันธ์ ไม่ว่าทางตรงหรือทางอ้อม กับประเทศอิหร่าน เกาหลีเหนือ รัสเซีย ซีเรีย ในทุกประการ\n\n'
      '3.ข้าพเจ้ายินยอมให้บริษัทจัดเก็บรวบรวม ใช้และเปิดเผยข้อมูลส่วนบุคคลของข้าพเจ้าเพื่อประชาสัมพันธ์ วิเคราะห์การตลาด และนำเสนอหรือให้ข้อมูลที่เกี่ยวข้องกับผลิตภัณฑ์ การให้บริการหรือสิทธิประโยชน์ต่างๆ ของบริษัทหรือบริษัทในกลุ่มอลิอันซ์ หรือคู่สัญญาของบริษัท';

  @override
  void initState() {
    super.initState();
    _guard(this);
  }

  Future<void> _upload(void Function(String) store) async {
    await uploadSlot(context, store);
    _s.notify();
  }

  Future<void> _next() async {
    if (_s.blueBookUrl.isEmpty) {
      await showAlert(context, 'กรุณาอัพโหลดรูปหน้าเล่มรถ');
      return;
    }
    if (_s.workType == 'ev' && !_s.flagRenew && _s.idCardUrl.isEmpty) {
      if (mounted) await showAlert(context, 'กรุณาอัพโหลดรูปสำเนาบัตรประชาชนผู้เอาประกัน');
      return;
    }
    // FF checked the three boxes, not 'ยินยอมทั้งหมด'.
    if (!_consent.every((c) => c)) {
      if (mounted) await showAlert(context, 'กรุณาเลือกยินยอม');
      return;
    }
    if (mounted) context.push(AppRoutes.manualInsurers);
  }

  Widget _checkbox(bool value, ValueChanged<bool> onChanged) => Checkbox(
        value: value,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(width: 2, color: npBorderGrey),
        activeColor: Colors.white,
        checkColor: const Color(0xFF00B505),
        onChanged: (v) => onChanged(v ?? false),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final s = _s;
        final others = s.otherPhotos;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: npAppBar(npTitle(s.workType), onBack: () => context.pop()),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    color: npPanelGrey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: Text('ถ่ายรูปเอกสารเพิ่มเติม', style: AppText.style(fontSize: 16, color: npSectionNavy)),
                          ),
                          const NpPhotoTitle('1. หน้าเล่มรถ รายการจดทะเบียนล่าสุด', required: true),
                          NpPhotoRow(url: s.blueBookUrl, onTap: () => _upload((u) => s.blueBookUrl = u)),
                          NpPhotoTitle('2.สำเนาบัตรประชาชนผู้เอาประกัน', required: s.workType == 'ev' && !s.flagRenew),
                          NpPhotoRow(url: s.idCardUrl, onTap: () => _upload((u) => s.idCardUrl = u)),
                          NpPhotoTitle(
                            '3. เอกสารอื่นๆ เช่น เล่มรถหางพ่วง',
                            trailing: Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Text('(ถ่ายได้ไม่เกิน 5 รูป)', style: AppText.bodyMedium),
                            ),
                          ),
                          for (var i = 0; i < 5; i++)
                            if (i == 0 || others[i - 1].isNotEmpty)
                              NpPhotoRow(url: others[i], onTap: () => _upload((u) => s.otherPhotos[i] = u)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                            child: Container(
                              color: Colors.white,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text('รายละเอียดความยินยอม', style: AppText.style(fontSize: 16)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('**ต้องอ่านให้ลูกค้าฟังอย่างครบถ้วนทีละข้อ**',
                                        textAlign: TextAlign.center,
                                        style: AppText.style(fontSize: 16, color: const Color(0xFFFF0000))),
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 250,
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 10),
                                            child: Column(
                                              children: [
                                                for (var i = 0; i < 3; i++)
                                                  Padding(
                                                    padding: EdgeInsets.only(top: i == 0 ? 0 : 40),
                                                    child: _checkbox(_consent[i], (v) => setState(() => _consent[i] = v)),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 10,
                                        child: Text(_consentText, style: AppText.style(height: 1.3)),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _checkbox(_consentAll, (v) {
                                          setState(() {
                                            _consentAll = v;
                                            for (var i = 0; i < 3; i++) {
                                              _consent[i] = v;
                                            }
                                          });
                                        }),
                                        Text('ยินยอมทั้งหมด', style: AppText.bodyMedium),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                        ],
                      ),
                    ),
                  ),
                ),
                NpBottomButton(text: 'ถัดไป', onPressed: _next),
              ],
            ),
          ),
        );
      },
    );
  }
}
