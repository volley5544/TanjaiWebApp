import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../router/app_router.dart';
import '../../manual_request/shared/photo_upload.dart';
import '../data/policy_request_api.dart';
import '../shared/request_widgets.dart';
import '../state/policy_request_state.dart';
import 'inspection_map.dart';
import 'multi_photo_page.dart';
import 'step3_data.dart';
import 'step3_rules.dart';
import 'widgets.dart';

/// FF 'ดาวน์โหลดเอกสาร ใบตรวจสภาพรถ SSW' (public Storage PDF of the mobile project).
const kInspectionFormPdfUrl =
    'https://firebasestorage.googleapis.com/v0/b/sawad-new-ibs.appspot.com/o/filePDF%2F%E0%B9%83%E0%B8%9A%E0%B8%95%E0%B8%A3%E0%B8%A7%E0%B8%88%E0%B8%AA%E0%B8%A0%E0%B8%B2%E0%B8%9E%E0%B8%A3%E0%B8%96_ssw.pdf?alt=media&token=a4e63a2e-c74b-4c06-8b87-fb7abc80b128&_gl=1*1jny086*_ga*MTI5MzM2MTI1My4xNjkzODIzNjI0*_ga_CW55HF8NVT*MTY5NjM5OTc2OC4yMi4xLjE2OTYzOTk4NjMuMzUuMC4w';

/// 3. เอกสารประกอบ — FF InsuranceInfoPage3 (auto work type): documents,
/// optional extra photos, the 9-photo vehicle inspection, consents, save
/// draft step 3, then 'ถัดไป' → step 4.
///
/// Product differences live in [Step3Rules]. Nothing is loaded on open (FF:
/// everything comes from the detail loaded by step 1).
///
/// FF fixes: a cancelled picker no longer clears a prefilled photo; the
/// failure snackbar of photos 1 / 7 / 8 no longer reads '#B2000000'; the
/// old-policy view icon shows the old policy (FF: the ID card); the
/// 'สถานะ :' / 'ยังไม่อัพโหลด' taps of 'รูปเอกสารอื่นๆ' (null-check crash on an
/// empty list) are dropped; the multi-photo rows' status follows the stored
/// photos (FF used session lists that were never reset); the CMI 'ถัดไป' no
/// longer leaves the loading sheet up on an error.
class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final _state = PolicyRequestState.instance;
  final _consents = Step3Consents();
  bool _noFlow = false;

  Step3Data get _d => _state.step3;
  Step3Rules get _rules => Step3Rules.of(_state.variant);

  @override
  void initState() {
    super.initState();
    _noFlow = redirectIfNoFlow(context);
  }

  String get _leadDtlId {
    final s = _state.summary.leadDetailId;
    return s.isNotEmpty ? s : '${_state.leadDtlId ?? ''}';
  }

  Future<void> _upload(void Function(String url) write, {String okText = kPickOkText, String failText = kPickFailText}) async {
    await uploadPhotoInto(context, (url) => setState(() => write(url)), okText: okText, failText: failText);
  }

  Future<void> _takeInspectionPhoto(InspectionPhoto p) async {
    final yes = await showConfirm(context, 'คุณต้องการถ่ายรูปที่ ${p.number} ใช่หรือไม่', cancelText: 'ไม่', confirmText: 'ใช่');
    if (!yes || !mounted) return;
    await _upload((url) => _d.photos[p] = url, okText: uploadOkText, failText: uploadFailText);
  }

  Future<void> _openMulti(MultiPhotoKind kind) async {
    final urls = await MultiPhotoPage.open(context, kind);
    if (urls == null || !mounted) return;
    setState(() => _d.setMulti(kind, urls));
  }

  void _viewMulti(MultiPhotoKind kind) {
    final urls = _d.multi(kind);
    if (urls.length == 1) {
      showRequestImage(context, urls.first);
    } else if (urls.isNotEmpty) {
      showRequestImageList(context, urls);
    }
  }

  Future<void> _save() async {
    final msg = _rules.validate(_d, _consents);
    if (msg != null) {
      await showAlert(context, msg);
      return;
    }
    final fields = _rules.saveFields(_d, _consents, quotationId: _state.quotationId, leadDtlId: _leadDtlId);
    final r = await withLoading(context, () => PolicyRequestApi.instance.saveApplication(step: '3', fields: fields));
    if (!mounted) return;
    if (!await requestCheck(context, statusCode: r.statusCode, code: r.code, message: r.message)) return;
    if (!mounted) return;
    await showAlert(context, 'บันทึกเตรียมข้อมูลขั้นตอนที่ 3 สำเร็จ');
    if (!mounted) return;
    setState(() {
      _d.saved = true;
      _d.pdfFileApplication = step3FileApplication(r.json);
    });
  }

  Future<void> _next() async {
    if (!_rules.nextSavesStep4) {
      context.push(AppRoutes.requestPaymentDocuments);
      return;
    }
    // CMI (not reachable yet — variant unsupported): FF saved step 4 with
    // 'จ่ายเต็ม' here and went straight to P4_2.
    final r = await withLoading(
      context,
      () => PolicyRequestApi.instance.saveApplication(step: '4', fields: {
        'quotation_id': _state.quotationId,
        'lead_dtl_id': _leadDtlId,
        'payment_type': 'จ่ายเต็ม',
        'image_application': '',
        'file_loan_application_register': '',
        'sub_product': _d.subProduct,
      }),
    );
    if (!mounted) return;
    if (!await requestCheck(context, statusCode: r.statusCode, code: r.code, message: r.message)) return;
    if (mounted) context.push(AppRoutes.requestPayment);
  }

  @override
  Widget build(BuildContext context) {
    if (_noFlow) return const Scaffold(backgroundColor: Colors.white);
    final d = _d;
    final rules = _rules;
    return RequestStepScaffold(
      title: '3. เอกสารประกอบ',
      step: 3,
      onBack: () => context.canPop() ? context.pop() : leaveRequestFlow(context),
      children: [
        if (rules.showsInspectionFormLink)
          RequestDownloadLink(
            text: 'ดาวน์โหลดเอกสาร ใบตรวจสภาพรถ SSW',
            onTap: () => openRequestDocument(kInspectionFormPdfUrl),
          ),
        if (rules.showsExamination(d))
          RequestUploadRow(
            title: 'ใบตรวจสภาพรถฟอร์มศรีสวัสดิ์',
            tag: rules.examinationRequired(d) ? kUploadRequiredTag : '',
            uploaded: d.examination.isNotEmpty,
            onUpload: () => _upload((u) => d.examination = u),
            onView: () => showRequestImage(context, d.examination),
          ),
        if (rules.showsBluebook(d))
          RequestUploadRow(
            title: 'รายการจดทะเบียนรถ',
            tag: kUploadRequiredTag,
            uploaded: d.bluebook.isNotEmpty,
            onUpload: () => _upload((u) => d.bluebook = u),
            onView: () => showRequestImage(context, d.bluebook),
          ),
        RequestUploadRow(
          title: 'สำเนาบัตรประชาชน',
          tag: kUploadRequiredTag,
          uploaded: d.idCard.isNotEmpty,
          onUpload: () => _upload((u) => d.idCard = u),
          onView: () => showRequestImage(context, d.idCard),
        ),
        if (rules.showsOldPolicy(d))
          RequestUploadRow(
            title: 'ตารางกรมธรรม์เดิมที่ยังไม่หมดอายุ',
            tag: kUploadRequiredTag,
            uploaded: d.oldVmi.isNotEmpty,
            onUpload: () => _upload((u) => d.oldVmi = u),
            // FF opened the ID card here.
            onView: () => showRequestImage(context, d.oldVmi),
          ),
        if (rules.showsMultiPhotos(d))
          for (final k in MultiPhotoKind.values)
            Padding(
              padding: EdgeInsets.only(bottom: k == MultiPhotoKind.accessories ? 20 : 0),
              child: RequestUploadRow(
                title: '${k.title} ถ้ามี',
                tag: '(ถ่ายได้ไม่เกิน ${k.max} รูป)',
                tagColor: Colors.black,
                uploaded: d.multi(k).isNotEmpty,
                buttonText: 'ถ่ายรูป',
                buttonIcon: Icons.photo_camera_outlined,
                onUpload: () => _openMulti(k),
                onView: () => _viewMulti(k),
              ),
            ),
        if (rules.showsInspection(d)) ...[
          Padding(padding: const EdgeInsets.only(top: 10), child: InspectionMap(onTap: _takeInspectionPhoto)),
          InspectionStatusList(photos: d.photos, onView: (u) => showRequestImage(context, u)),
        ],
        const Padding(padding: EdgeInsets.only(top: 10), child: Divider(height: 1, thickness: 1, color: AppColors.secondaryText)),
        _ConsentBlock(consents: _consents, onChanged: () => setState(() {})),
        const Divider(height: 1, thickness: 1, color: AppColors.secondaryText),
        _buttons(d),
      ],
    );
  }

  Widget _buttons(Step3Data d) {
    final w = MediaQuery.sizeOf(context).width * 0.45;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppButton(
            text: 'บันทึกเตรียมข้อมูล',
            onPressed: _save,
            width: w,
            color: kRequestLightOrange,
            textColor: kRequestOrange,
            borderColor: kRequestLightOrange,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          if (d.saved)
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: AppButton(
                text: 'ถัดไป',
                onPressed: _next,
                width: w,
                color: kRequestOrange,
                textColor: AppColors.primaryBtnText,
              ),
            ),
        ],
      ),
    );
  }
}

/// `$.results.data.app_document[:].file_application` of the save response.
/// FF stored `'${value}'` — 'null' when missing, '[a, b]' when several; the
/// port keeps the first non-empty URL.
String step3FileApplication(dynamic json) {
  final docs = jsonPathGet(json, 'results.data.app_document');
  final list = docs is List ? docs : (docs is Map ? [docs] : const []);
  for (final e in list) {
    if (e is Map) {
      final v = Step3Data.cleanUrl(e['file_application']);
      if (v.isNotEmpty) return v;
    }
  }
  return '';
}

/// FF 'รายละเอียดความยินยอม' block (texts verbatim, typos included).
class _ConsentBlock extends StatelessWidget {
  const _ConsentBlock({required this.consents, required this.onChanged});

  final Step3Consents consents;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = consents;
    final body = AppText.style(fontSize: 14, fontWeight: FontWeight.normal, height: 1.3);
    Widget box(bool value, String label, void Function(bool) set) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) {
                set(v ?? false);
                onChanged();
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: WidgetStateBorderSide.resolveWith((_) => const BorderSide(color: AppColors.secondaryText, width: 2)),
              activeColor: AppColors.primaryBtnText,
              checkColor: const Color(0xFF00B505),
            ),
            Text(label, style: body),
          ],
        );
    Widget item(String text, List<Widget> boxes) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: body),
              Wrap(spacing: 10, children: boxes),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Container(
        color: AppColors.secondaryBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text('รายละเอียดความยินยอม', style: AppText.style(fontSize: 16, fontWeight: FontWeight.normal))),
            Center(
              child: Text(
                '**ต้องอ่านให้ลูกค้าฟังอย่างครบถ้วนทีละข้อ**',
                textAlign: TextAlign.center,
                style: AppText.style(fontSize: 16, fontWeight: FontWeight.normal, color: const Color(0xFFFF0000)),
              ),
            ),
            item(' 1.การให้ความยินยอบในการเก็บรวบรวม ใช้และเปิดเผยข้อมูลส่วนบุคคล\nยินยอม', [
              box(c.sensitive, 'ยินยอม', (v) => c.sensitive = v),
            ]),
            item(
                ' 2.ผู้เอาประกันภัยและผู้รับประโยชน์/ ผู้ชำระเบี้ย ไม่มีความสับพันธ์ ไม่ว่าทางตรงหรือทางอ้อม กับประเทศอิหร่าน เกาหลีเหนือ รัสเซีย ซีเรีย ในทุก\nประการ',
                [box(c.sanction, 'ยินยอม', (v) => c.sanction = v)]),
            item(
                '3.ข้าพเจ้ายินยอมให้บริษัทจัดเก็บรวบรวม ใช้และเปิดเผยข้อมูลส่วนบุคคลของข้าพเจ้าเพื่อประชาสัมพันธ์ วิเคราะห์การตลาด และน่าเสนอหรือให้ข้อมูลที่เกี่ยวข้อง กับผลิตภัณฑ์ การให้บริการหรือสิทธิประโยชน์ต่างๆ ของบริษัท หรือบริษัทในเครือศรีสวัสดิ์ หรือคู่สัญญาของบริษัท',
                [
                  box(c.privacy, 'ยินยอม', c.setPrivacy),
                  box(c.privacyCancel, 'ไม่ยินยอม', c.setPrivacyCancel),
                ]),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(child: box(c.all, 'ยินยอมทั้งหมด', c.setAll)),
            ),
          ],
        ),
      ),
    );
  }
}
