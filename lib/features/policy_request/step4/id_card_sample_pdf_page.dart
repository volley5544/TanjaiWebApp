import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/env_version_tag.dart';
import '../../search_package/quotation/pdf_frame.dart';

/// FF SampleIDcard with `fromPage: 'Step4'`: 'ตัวอย่างสำเนาบัตรประชาชน' showing
/// the `urlLinkStorage` 'idcard' PDF in a 300-px viewer (web: the browser's
/// viewer in an iframe, as the quotation PDF page). FF's unused
/// `insurance_request_api_url` Firestore read is dropped; a missing / non-https
/// URL shows an empty card (FF `imageUrl!` crashed on null).
class IdCardSamplePdfPage extends StatelessWidget {
  const IdCardSamplePdfPage({super.key, required this.url});

  final String url;

  static Future<void> open(BuildContext context, String url) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => IdCardSamplePdfPage(url: url)));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.brandOrange, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('ตัวอย่างสำเนาบัตรประชาชน', style: AppText.style(fontSize: 18, color: AppColors.navy)),
          actions: const [EnvVersionTag()],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Material(
              elevation: 1,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE6E6E6)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                child: SizedBox(
                  height: 300,
                  child: isSafePdfUrl(url) ? PdfFrame(url: url.trim()) : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
