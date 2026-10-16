import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../search_package/quotation/pdf_frame.dart';
import '../shared/request_widgets.dart';
import 'step5_data.dart';
import 'step5_rules.dart';

/// FF `Step5DocumentDownload` bottom sheet (50 % height, barrier #B3000000,
/// no drag), opened from the page-5 AppBar download icon.
Future<void> showStep5DocumentDownload(BuildContext context, Step5Data data, Step5Rules rules) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000),
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.5,
      child: Step5DocumentDownloadSheet(links: step5DocumentLinks(data, rules)),
    ),
  );
}

class Step5DocumentDownloadSheet extends StatelessWidget {
  const Step5DocumentDownloadSheet({super.key, required this.links});

  final List<Step5DocLink> links;

  /// FF `launchURL` → new tab with `noopener`; https only (the application
  /// form URL comes from the API and may be '' — then nothing opens).
  static void _open(String url) {
    if (isSafePdfUrl(url)) openUrlInNewTab(url);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text('ไฟล์เอกสาร', style: AppText.style(fontSize: 24, fontWeight: FontWeight.normal)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 0, 8),
                  child: Text('เอกสารต่างๆที่บริษัทประกันจะขอหากไม่ได้แนบ',
                      style: AppText.style(fontSize: 12, fontWeight: FontWeight.normal)),
                ),
                for (final l in links)
                  InkWell(
                    onTap: () => _open(l.url),
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.file_download_outlined, color: Color(0xFF090F13), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(l.text,
                                style: AppText.style(fontSize: 15, fontWeight: FontWeight.bold, color: kRequestNavy)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              iconSize: 40,
              icon: const Icon(Icons.close, color: Color(0xFFFF0000), size: 40),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
