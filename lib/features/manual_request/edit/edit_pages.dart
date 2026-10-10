import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../router/app_router.dart';
import '../../quotation_list/state/quotation_list_state.dart';
import '../data/manual_request_api.dart';
import '../models/lead_detail.dart';
import '../shared/branch_and_sample_pages.dart';
import '../shared/np_widgets.dart';
import '../shared/photo_upload.dart';
import '../state/none_package_state.dart';

const _labelNavy = Color(0xFF002D5E);

/// Guard shared by the edit pages: no loaded lead → quotation list.
bool _guard(State s) {
  if (NonePackageState.instance.editActive && NonePackageState.instance.lead != null) return true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (s.mounted) s.context.go(AppRoutes.quotationList);
  });
  return false;
}

/// The insurer row being edited (FF `nonePackageInsurerOutputIndex`).
LeadDetailInsurer? _insurer(NonePackageState s) {
  final d = s.lead?.details ?? const [];
  return s.insurerIndex < d.length ? d[s.insurerIndex] : null;
}

/// Existing image of the edited insurer for an API field ('' when none).
/// FF showed the view icon for `null != ''` too and then crashed on tap;
/// here it shows only for a real value.
String _existing(NonePackageState s, String field) => _insurer(s)?.images[field] ?? '';

Text _label(String t) => Text(t, style: AppText.style(fontSize: 16, color: _labelNavy));

// ───────────────────────────────────────────────────────────────────────────

/// Port of FF `NonePackageEditPage1` ('แก้ไขรูปถ่าย'): branch (some users),
/// customer, cover type, and the ONE insurer whose photos are edited.
class EditPage1 extends StatefulWidget {
  const EditPage1({super.key});

  @override
  State<EditPage1> createState() => _EditPage1State();
}

class _EditPage1State extends State<EditPage1> {
  final _s = NonePackageState.instance;
  bool _ok = false;

  bool get _showBranch => UserSession.instance.branchCode.length > 2;

  @override
  void initState() {
    super.initState();
    _ok = _guard(this);
    if (_ok) _s.insurerSelected = List.filled(_s.lead!.details.length, false);
  }

  Future<void> _next() async {
    final s = _s;
    if (_showBranch && !(s.branchCode.isNotEmpty && s.branchName.isNotEmpty && s.branchCode.length <= 2)) {
      await showAlert(context, 'กรุณาเลือกสาขาที่จะลงผลงาน');
      return;
    }
    final idx = s.insurerSelected.indexOf(true);
    if (idx < 0) {
      if (mounted) await showAlert(context, 'กรุณาเลือกบริษัทประกันอย่างน้อย 1 บริษัท');
      return;
    }
    s
      ..insurerIndex = idx
      ..insurerDisplayOutput = s.lead!.details[idx].insurerName
      ..notify();
    if (mounted) context.push(s.flagRenew || s.editEvFlag ? AppRoutes.manualEditDocuments : AppRoutes.manualEditPhotos);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ok) return const Scaffold(backgroundColor: Colors.white);
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final s = _s;
        final details = s.lead!.details;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: npAppBar('แก้ไขรูปถ่าย', onBack: () => context.go(AppRoutes.quotationList)),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                if (_showBranch)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
                    child: NpBranchSelector(state: s, labelColor: _labelNavy, boxColor: const Color(0xFFF0F0F0)),
                  ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: npPanelGrey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 0), child: _label('ชื่อลูกค้า')),
                        // FF: an editable field whose value was never used → display only.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                          child: NpReadBox(s.cusFullname == '-' ? '' : s.cusFullname, textColor: AppColors.primaryText),
                        ),
                        Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 0), child: _label('ประเภทชั้นประกัน')),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                          child: NpReadBox(s.coverTypeName == '-' ? '' : s.coverTypeName, textColor: AppColors.primaryText),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 19, 24, 0),
                          child: _label('บริษัทประกันที่ต้องการแก้ไขรูปถ่าย'),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: details.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  s.insurerSelected = [for (var k = 0; k < details.length; k++) k == i];
                                  s.notify();
                                },
                                child: Container(
                                  height: 60,
                                  decoration: npBoxDecoration(),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: Text(details[i].insurerName,
                                              style: AppText.style(fontSize: 15, color: npBorderGrey)),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 10),
                                        child: NpSelectCircle(s.insurerSelected[i]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => context.push(AppRoutes.manualEditDetail),
                          child: Container(
                            height: 69,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(blurRadius: 5, color: Color(0x34111417), offset: Offset(0, 2))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF636366)),
                                    ),
                                    child: const Icon(Icons.edit_document, color: Color(0xFF7A848E), size: 24),
                                  ),
                                ),
                                Text('ตรวจสอบรายละเอียดการขอประกัน', style: AppText.style(fontSize: 16, color: _labelNavy)),
                                const Padding(
                                  padding: EdgeInsets.only(right: 13),
                                  child: Icon(Icons.arrow_forward_ios, color: Color(0xFF636366), size: 24),
                                ),
                              ],
                            ),
                          ),
                        ),
                        NpBottomButton(text: 'ถัดไป', onPressed: _next),
                      ],
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

// ───────────────────────────────────────────────────────────────────────────

/// Port of FF `NonePackageEditDetailPage` ('งานนอกเรท'): read-only summary.
/// Web fix: '-' / unparsable year or date show '-' (FF crashed the build).
class EditDetailPage extends StatefulWidget {
  const EditDetailPage({super.key});

  @override
  State<EditDetailPage> createState() => _EditDetailPageState();
}

class _EditDetailPageState extends State<EditDetailPage> {
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    _ok = _guard(this);
  }

  Widget _field(String label, String value, {double top = 5}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, top, 24, 0),
            child: Text(label,
                style: AppText.style(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF565656))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
            child: NpReadBox(value, color: const Color(0xFFE5E5E5)),
          ),
        ],
      );

  Widget _check(String label, bool on) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 15, 12, 0),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E5E5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF737373)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppText.style(fontSize: 15, color: const Color(0xFF565656)))),
              NpSelectCircle(on),
            ],
          ),
        ),
      );

  static String _num(String v) => showNumberWithCommaWithoutDot(v);

  Widget _customerCard(String label, IconData icon, bool selected, {bool shadow = false}) {
    final card = Container(
      height: 120,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFD9D9D9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all()),
                child: Icon(icon, color: const Color(0xFF354052), size: 28),
              ),
            ),
          ),
          Expanded(child: Text(label, style: AppText.style(fontSize: 16, color: const Color(0xFF204A77)))),
        ],
      ),
    );
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(10),
        // FF: only the first card had a shadow (kept).
        child: shadow ? Material(elevation: 1, borderRadius: BorderRadius.circular(16), child: card) : card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ok) return const Scaffold(backgroundColor: Colors.white);
    final s = NonePackageState.instance;
    final isTruck = s.vehicleType == truck;
    final isPickup = s.vehicleType == pickup;
    final year = int.tryParse(s.year);
    final expDate = DateTime.tryParse(s.oldVmiExpDate) == null ? '-' : showDateBE(s.oldVmiExpDate);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: npAppBar('งานนอกเรท', onBack: () => context.pop()),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: npPanelGrey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
                        child: Row(
                          children: [
                            _customerCard('บุคคลธรรมดา', Icons.person_2_sharp, s.customerType == 'บุคคลธรรมดา', shadow: true),
                            _customerCard('นิติบุคคล', Icons.business, s.customerType == 'นิติบุคคล'),
                          ],
                        ),
                      ),
                      _field('ประเภทรถ', s.vehicleType, top: 12),
                      if (isTruck) ...[
                        _field('ส่วนของรถบรรทุก', s.truckPart == '1' ? truckWithTrailer : 'เฉพาะหัวลาก', top: 12),
                        _field('ประเภทลูกค้า', s.cusMembership == '1' ? 'ลูกค้าสินเชื่อ' : 'ลูกค้านอก', top: 12),
                        _field('รถใช้บรรทุกอะไร', s.truckCarryPurpose, top: 12),
                        _field('ราคาซื้อขายปัจจุบัน', _num(s.truckCurrentPrice), top: 12),
                      ],
                      if (isPickup) _check('ติดตู้เหล็กหรือไม่', s.flagCarrier),
                      if (isPickup && s.flagCarrier) ...[
                        _check('ใช้วิ่งร่วมกับบริษัทขนส่งเอกชนหรือไม่', s.flagCoop),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 15, 12, 0),
                          child: NpReadBox(s.carrierType, color: const Color(0xFFE5E5E5)),
                        ),
                        if (s.carrierType == 'ตู้เย็น') _field('ราคาตู้ + เครื่องทำความเย็น', _num(s.carrierPrice)),
                      ],
                      _field('ยี่ห้อรถ', s.brandName),
                      _field('รุ่นรถ', s.modelName),
                      if (s.flagRenew) ...[
                        _field('เลขกรมธรรม์เดิม', s.oldVmi),
                        _field('วันหมดอายุกรมธรรม์เดิม', expDate),
                      ],
                      _field('ปีจดทะเบียน พ.ศ.', year == null ? '-' : '${year + 543}'),
                      // FF concatenated code and name without a separator (kept).
                      _field('ลักษณะการใช้รถ', '${s.usedTypeCode}${s.usedTypeName}'),
                      _field('ประเภทชั้นประกัน', s.coverTypeName),
                      _field('ประเภทการซ่อม', s.garageTypeName),
                      _field('ชื่อลูกค้า', s.cusFullname),
                      _field('เบอร์โทรศัพท์', s.cusPhone),
                      _field('ทะเบียนรถ', s.plate),
                      if (isTruck && s.truckPart == '1') _field('ทะเบียนหางพ่วง', s.plateAdditional, top: 12),
                      _field('จังหวัดจดทะเบียนรถ', s.province),
                      _field('ทุนประกันที่ลูกค้าต้องการ', _num(s.sumInsured)),
                      if (isTruck && s.truckPart == '1') _field('ทุนประกันหางพ่วงที่ลูกค้าต้องการ', _num(s.trailerSumInsured)),
                      _field('หมายเหตุ', s.remark),
                      _check('ขอเบี้ย พ.ร.บ. หรือไม่', s.flagAct),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: AppButton(text: 'ปิด', onPressed: () => context.pop(), color: npOrange, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────

/// Port of FF `NonePackageEditPage2`: re-take any car / trailer photo of the
/// chosen insurer (optional). Status shows this session's new uploads; the
/// view icon opens the photo already on the request.
class EditPage2 extends StatefulWidget {
  const EditPage2({super.key});

  @override
  State<EditPage2> createState() => _EditPage2State();
}

class _EditPage2State extends State<EditPage2> {
  final _s = NonePackageState.instance;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    _ok = _guard(this);
  }

  Future<void> _onSpot(DiagramSpot spot) async {
    final ok = await showConfirm(context, photoConfirmText(spot.number), cancelText: 'ไม่', confirmText: 'ใช่');
    if (!ok || !mounted) return;
    await uploadSlot(context, (url) => _s.carPhotos[spot.slot] = url);
    _s.notify();
  }

  List<VoidCallback?> _viewers(List<CarSlot> slots) => [
        for (final c in slots)
          _existing(_s, c.field).isEmpty ? null : () => showNpImages(context, [_existing(_s, c.field)]),
      ];

  @override
  Widget build(BuildContext context) {
    if (!_ok) return const Scaffold(backgroundColor: Colors.white);
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final s = _s;
        final isTruck = s.vehicleType == truck;
        final trailer = isTruck && s.truckPart == '1';
        final carSlots = isTruck ? CarSlot.car.take(8).toList() : CarSlot.car;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: npAppBar('แก้ไขรูปถ่าย', onBack: () => context.pop()),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: npPanelGrey,
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                                child: _label('บริษัทประกันที่ต้องการแก้ไขรูปถ่าย'),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                child: NpReadBox(s.insurerDisplayOutput),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 15, 12, 0),
                                child: Text('ถ่ายรูปสินทรัพย์', style: AppText.style(fontSize: 20)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('*** กรุณากดที่แต่ละตำแหน่งของรถเพื่อถ่ายรูป ***',
                                    style: AppText.style(color: const Color(0xFFC33D5E))),
                              ),
                            ],
                          ),
                        ),
                        VehicleDiagram(
                          asset: isTruck ? diagramTruckAsset : diagramCarAsset,
                          aspect: isTruck ? diagramTruckAspect : diagramCarAspect,
                          spots: [for (final sp in carSpotsEdit) if (!(isTruck && sp.slot == CarSlot.roof)) sp],
                          onTap: _onSpot,
                        ),
                        PhotoStatusCard(
                          done: [for (final c in carSlots) s.carPhoto(c).isNotEmpty],
                          viewers: _viewers(carSlots),
                        ),
                        if (trailer) ...[
                          VehicleDiagram(
                            asset: diagramTrailerAsset,
                            aspect: diagramTrailerAspect,
                            spots: trailerSpotsEdit,
                            onTap: _onSpot,
                          ),
                          PhotoStatusCard(
                            done: [for (final c in CarSlot.trailer) s.carPhoto(c).isNotEmpty],
                            viewers: _viewers(CarSlot.trailer),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  child: AppButton(
                    text: 'ถัดไป',
                    onPressed: () => context.push(AppRoutes.manualEditDocuments),
                    color: npOrange,
                    fontSize: 16,
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

// ───────────────────────────────────────────────────────────────────────────

/// Port of FF `NonePackageEditPage3`: documents + 'บันทึก'
/// (`/api/manual-insurance/edit`). 'บังคับถ่ายรูป' is a label only (FF
/// enforced nothing here). Web fix: status comes from the flow state (FF's
/// page-local status reset when coming back).
class EditPage3 extends StatefulWidget {
  const EditPage3({super.key});

  @override
  State<EditPage3> createState() => _EditPage3State();
}

class _EditPage3State extends State<EditPage3> {
  final _s = NonePackageState.instance;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    _ok = _guard(this);
  }

  Future<void> _upload(void Function(String) store) async {
    await uploadSlot(context, store);
    _s.notify();
  }

  Widget? _view(String field) {
    final url = _existing(_s, field);
    return url.isEmpty ? null : NpViewIcon(onTap: () => showNpImages(context, [url]));
  }

  Map<String, String> _body() {
    final s = _s;
    final session = UserSession.instance;
    final ownBranch = session.branchCode.length <= 2;
    final ins = _insurer(s);
    return {
      'lead_id': s.lead!.leadId,
      'lead_no': s.lead!.leadNo,
      for (final c in CarSlot.values) c.field: s.carPhoto(c),
      'image_idcard': s.idCardUrl,
      'image_bluebook': s.blueBookUrl,
      for (var i = 0; i < 5; i++) 'image_other${i + 1}': s.otherPhotos[i],
      'insurer_short_name': ?ins?.insurerShortName,
      'image_other_name': ?ins?.imageOtherName,
      'old_VMI_image': s.oldVmiImageUrl,
      'image_company_book': s.companyBookUrl,
      'check_edit': 'edit',
      'branch_code': ownBranch ? session.branchCode : s.branchCode,
      'branch_name': ownBranch ? session.branchName : s.branchName,
      'api_url': AppEnvironment.current.insuranceApiBase,
    };
  }

  Future<void> _save() async {
    final r = await withLoading(context, () => ManualRequestApi.instance.editRequest(_body()));
    if (!mounted) return;
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.httpStatus})');
      return;
    }
    if (r.status2 != 201) {
      if (r.status2 == 500) {
        context.go(AppRoutes.manualUnsuccess);
      } else {
        await showAlert(context, r.message2 ?? httpErrorText(r.httpStatus));
      }
      return;
    }
    await showAlert(context, r.message2 ?? '');
    if (!mounted) return;
    _s.reset();
    QuotationListState.instance.requestReload();
    context.go(AppRoutes.quotationList);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ok) return const Scaffold(backgroundColor: Colors.white);
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final s = _s;
        final ins = _insurer(s);
        final oldOthers = ins?.imageOther ?? const <String>[];
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: npAppBar('แก้ไขรูปถ่าย', onBack: () => context.pop()),
          body: SafeArea(
            child: Column(
              children: [
                if (s.flagRenew && s.oldVmiFlag) _sectionA(),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: npPanelGrey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: Text('ถ่ายรูปเอกสารเพิ่มเติม', style: AppText.style(fontSize: 16, color: _labelNavy)),
                          ),
                          const NpPhotoTitle('1. หน้าเล่มรถ รายการจดทะเบียนล่าสุด', required: true),
                          NpPhotoRow(
                            done: s.blueBookUrl.isNotEmpty,
                            viewIcon: _view('image_bluebook'),
                            onTap: () => _upload((u) => s.blueBookUrl = u),
                          ),
                          const NpPhotoTitle('2.สำเนาบัตรประชาชนผู้เอาประกัน', required: true),
                          NpPhotoRow(
                            done: s.idCardUrl.isNotEmpty,
                            viewIcon: _view('image_idcard'),
                            onTap: () => _upload((u) => s.idCardUrl = u),
                          ),
                          NpPhotoTitle(
                            '3. เอกสารอื่นๆ เช่น เล่มรถหางพ่วง',
                            trailing: Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Text('(ถ่ายได้ไม่เกิน 5 รูป)', style: AppText.bodyMedium),
                            ),
                          ),
                          if (oldOthers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Text('รูปภาพอื่นๆที่เคยอัพโหลดแล้ว', style: AppText.bodyMedium),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 24),
                                    child: NpViewIcon(onTap: () => showNpImages(context, oldOthers)),
                                  ),
                                ],
                              ),
                            ),
                          for (var i = 0; i < 5; i++)
                            if (i == 0 || s.otherPhotos[i - 1].isNotEmpty)
                              NpPhotoRow(
                                done: s.otherPhotos[i].isNotEmpty,
                                onTap: () => _upload((u) => s.otherPhotos[i] = u),
                              ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                NpBottomButton(text: 'บันทึก', onPressed: _save),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionA() {
    final s = _s;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: SizedBox(
                height: 33,
                child: Row(
                  children: [
                    Text('เอกสารเพิ่มเติม', style: AppText.style(fontSize: 15, color: npTitleNavy)),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text('(งานโอนโค้ด)', style: AppText.style(fontSize: 12, color: npRequiredRed)),
                    ),
                  ],
                ),
              ),
            ),
            NpAttachRow(
              title: '1. ตารางกรมธรรม์เดิม',
              done: s.oldVmiImageUrl.isNotEmpty,
              viewIcon: _view('old_VMI_image'),
              onTap: () => _upload((u) => s.oldVmiImageUrl = u),
            ),
            NpAttachRow(
              title: '2. สำเนาบัตรประชาชน',
              titleExtras: [
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Icon(Icons.content_paste_search_rounded, color: Color(0xFF354052), size: 24),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: InkWell(
                    onTap: () => SampleIdCardPage.open(context),
                    child: Text('ดูตัวอย่าง',
                        style: AppText.style(fontSize: 15, fontWeight: FontWeight.w500, decoration: TextDecoration.underline)),
                  ),
                ),
              ],
              done: s.idCardUrl.isNotEmpty,
              viewIcon: _view('image_idcard'),
              onTap: () => _upload((u) => s.idCardUrl = u),
            ),
            if (s.buttonCorporation)
              NpAttachRow(
                title: '3. หนังสือจดทะเบียนบริษัท',
                done: s.companyBookUrl.isNotEmpty,
                onTap: () => _upload((u) => s.companyBookUrl = u),
              ),
          ],
        ),
      ),
    );
  }
}
