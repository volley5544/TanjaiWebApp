import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/firebase/firebase_auth_rest.dart';
import '../../../core/firebase/firestore_rest.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../../router/app_router.dart';
import '../shared/request_widgets.dart';
import '../state/policy_request_state.dart';
import '../step3/widgets.dart';
import 'id_card_sample_pdf_page.dart';
import 'step4_data.dart';
import 'step4_rules.dart';

/// One Firestore `urlLinkStorage` document (`title`, `url_link`).
class UrlLinkDoc {
  const UrlLinkDoc(this.title, this.url);

  final String title;
  final String url;
}

/// The `urlLinkStorage.url_name`s page 4 reads, with the title used when the
/// document is missing (FF defaults for 'power_of_attorney' / 'idcard'; the
/// prod titles for the others — FF showed a blank page instead).
const kStep4LinkFallbackTitles = {
  'cancel_loan': 'หนังสือขอบอกเลิกสัญญาประกันภัย',
  'CTV': 'คําขอแบ่งชําระค่าเบี้ยประกันภัยฯ',
  'Motor': 'คําขอแบ่งชําระค่าเบี้ยประกันภัยฯ',
  'power_of_attorney': 'หนังสือมอบอํานาจยกเลิกกรมธรรม์แทนลูกค้า',
  'idcard': '5.สำเนาบัตรประชาชนสำหรับมอบอำนาจ',
};

/// 4. ดำเนินงาน/ชำระเงิน — FF InsuranceInfoPage4: download the blank forms
/// (Firestore `urlLinkStorage`), upload the 4–5 signed documents, then
/// 'ชำระเงิน' → 4.1 payment type. Nothing is sent to the API here.
///
/// FF fixes: a cancelled picker no longer clears a prefilled document; the
/// status text follows the stored document like ✓ / ✕ (FF used the
/// page-local upload, so a resumed application read 'ยังไม่อัพโหลด' next to
/// ✓); a missing `urlLinkStorage` document no longer blanks the page (its
/// link is hidden, the title falls back); doc 1 is shown whenever it is
/// required (see [Step4Rules.showsApplicationForm]); doc 5's view icon opens
/// the sample (FF: decorative). The dead per-insurer application-form block
/// (`&& false`) is not ported.
class PaymentDocumentsPage extends StatefulWidget {
  const PaymentDocumentsPage({super.key});

  @override
  State<PaymentDocumentsPage> createState() => _PaymentDocumentsPageState();
}

class _PaymentDocumentsPageState extends State<PaymentDocumentsPage> {
  final _state = PolicyRequestState.instance;
  bool _noFlow = false;
  bool _loading = true;
  final Map<String, UrlLinkDoc?> _links = {};

  Step4Data get _d => _state.step4;
  Step4Rules get _rules => Step4Rules.of(_state.variant);

  @override
  void initState() {
    super.initState();
    _noFlow = redirectIfNoFlow(context);
    if (!_noFlow) _load();
  }

  Future<void> _load() async {
    // FF read as a signed-in user; use the anonymous identity when available.
    final token = await FirebaseAuthRest.idToken();
    if (token != null) FirestoreRest.instance.idToken = token;
    final names = ['cancel_loan', _rules.installmentFormName, 'power_of_attorney', 'idcard'];
    final docs = await Future.wait(
      names.map((n) => FirestoreRest.instance.firstWhere('urlLinkStorage', field: 'url_name', equals: n)),
    );
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < names.length; i++) {
        final doc = docs[i];
        _links[names[i]] = doc == null
            ? null
            : UrlLinkDoc('${doc['title'] ?? ''}', '${doc['url_link'] ?? ''}');
      }
      _loading = false;
    });
  }

  String _title(String name) {
    final t = _links[name]?.title ?? '';
    return t.isNotEmpty ? t : kStep4LinkFallbackTitles[name]!;
  }

  String _url(String name) => _links[name]?.url ?? '';

  Future<void> _upload(PaymentDocument doc) =>
      uploadPhotoInto(context, (url) => setState(() => _d.docs[doc] = url));

  Future<void> _pay() async {
    final msg = _rules.validate(_d);
    if (msg != null) {
      await showAlert(context, msg);
      return;
    }
    context.push(AppRoutes.requestPaymentType);
  }

  @override
  Widget build(BuildContext context) {
    if (_noFlow) return const Scaffold(backgroundColor: Colors.white);
    void back() => context.canPop() ? context.pop() : leaveRequestFlow(context);
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: requestAppBar(title: '4. ดำเนินงาน/ชำระเงิน', onBack: back),
        body: const PageLoadingView(),
      );
    }
    final d = _d;
    final rules = _rules;
    final form = rules.installmentFormName;
    return RequestStepScaffold(
      title: '4. ดำเนินงาน/ชำระเงิน',
      step: 4,
      onBack: back,
      children: [
        if (rules.showsApplicationForm(d)) ...[
          RequestDownloadLink(
            text: 'ดาวน์โหลดเอกสารใบคำขอเอาประกัน',
            fontSize: 14,
            iconSize: 22,
            onTap: () => openRequestDocument(_state.step3.pdfFileApplication),
          ),
          _docRow(PaymentDocument.application, '1. ใบคำขอเอาประกัน'),
        ],
        _link(form, top: 14),
        _docRow(PaymentDocument.loanApplication, '2.${_title(form)}'),
        _link('cancel_loan'),
        _docRow(PaymentDocument.cancelLoan, '3.${_title('cancel_loan')}', tagPadding: 5),
        _link('power_of_attorney'),
        _docRow(PaymentDocument.powerOfAttorney, '4.${_title('power_of_attorney')}', tagPadding: 5),
        _idCardRow(),
        _payButton(),
      ],
    );
  }

  /// 'ดาวน์โหลดเอกสาร' + title (FF: two texts, no space). Hidden when the
  /// Firestore document is missing.
  Widget _link(String name, {double top = 14}) {
    if (!isHttpsUrl(_url(name))) return const SizedBox.shrink();
    return RequestDownloadLink(
      text: 'ดาวน์โหลดเอกสาร${_title(name)}',
      fontSize: 14,
      iconSize: 22,
      top: top,
      onTap: () => openRequestDocument(_url(name)),
    );
  }

  Widget _docRow(PaymentDocument doc, String title, {double tagPadding = 10}) {
    final url = _d.doc(doc);
    return RequestUploadRow(
      title: title,
      titleSize: 14,
      tag: kUploadRequiredTag,
      tagPadding: tagPadding,
      uploaded: url.isNotEmpty,
      onUpload: () => _upload(doc),
      onView: () => showRequestImage(context, url),
    );
  }

  Widget _idCardRow() {
    final url = _d.doc(PaymentDocument.idCardPowerOfAttorney);
    final sample = _url('idcard');
    void openSample() => IdCardSamplePdfPage.open(context, sample);
    return Container(
      color: const Color(0xFFFAFAFA),
      child: RequestUploadRow(
        title: '',
        titleWidget: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(_title('idcard'), style: AppText.style(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Text(kUploadRequiredTag,
                        style: AppText.style(fontSize: 12, fontWeight: FontWeight.normal, color: kRequestTagRed)),
                  ),
                  InkWell(
                    onTap: openSample,
                    child: const Icon(Icons.content_paste_search_rounded, color: kViewIconColor, size: 24),
                  ),
                  Flexible(
                    child: InkWell(
                      onTap: openSample,
                      child: Text(
                        'ดูตัวอย่าง',
                        style: AppText.style(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        uploaded: url.isNotEmpty,
        onUpload: () => _upload(PaymentDocument.idCardPowerOfAttorney),
        onView: () => showRequestImage(context, url),
      ),
    );
  }

  Widget _payButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Material(
        color: kRequestOrange,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _pay,
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white)),
                      child: const Icon(Icons.payment, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(-0.3, 0),
                  child: Text('ชำระเงิน', style: AppText.style(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool isHttpsUrl(String url) => RequestNetworkImage.isHttps(url);
