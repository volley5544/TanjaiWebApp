import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/vertical_expanding_dots.dart';
import '../../../router/app_router.dart';
import '../../search_package/quotation/pdf_frame.dart';
import '../state/fire_search_state.dart';

/// Port of FF `FireQuotationPage` (ใบเสนอราคา): vertical pager over the saved
/// quotation PDFs with an expanding-dots indicator.
///
/// As in FF there is no back arrow (the save replaced the stack). Web notes:
/// each PDF is an `<iframe>`, which swallows pointer events, so FF's
/// long-press-to-open is also offered as an AppBar "open" button. FF's
/// long-press opened `insurarerQuotationPdf` (the motor flow's PDFs — a bug);
/// the port opens this page's PDF.
class FireQuotationPage extends StatefulWidget {
  const FireQuotationPage({super.key});

  @override
  State<FireQuotationPage> createState() => _FireQuotationPageState();
}

class _FireQuotationPageState extends State<FireQuotationPage> {
  final _state = FireSearchState.instance;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    if (_state.lastSave == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.fireSearch);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _open(String url) {
    if (isSafePdfUrl(url)) openUrlInNewTab(url);
  }

  int get _currentIndex => _pageController.hasClients ? (_pageController.page ?? 0).round() : 0;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.85;
    final pdfs = _state.lastSave?.pdfUrls ?? const <String>[];
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: tanjaiAppBar(
          title: 'ใบเสนอราคา',
          titleColor: const Color(0xFF003063),
          actions: [
            if (pdfs.isNotEmpty)
              IconButton(
                tooltip: 'เปิดในแท็บใหม่',
                icon: const Icon(Icons.open_in_new, color: AppColors.brandOrange),
                onPressed: () => _open(pdfs[math.min(_currentIndex, pdfs.length - 1)]),
              ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: pdfs.length,
                  itemBuilder: (context, i) => GestureDetector(
                    onLongPress: () => _open(pdfs[i]),
                    child: Container(
                      color: AppColors.secondaryBackground,
                      height: height,
                      child: isSafePdfUrl(pdfs[i]) ? PdfFrame(url: pdfs[i]) : const SizedBox.expand(),
                    ),
                  ),
                ),
                Align(
                  alignment: const AlignmentDirectional(0.9, -0.95),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 16),
                    child: VerticalExpandingDots(controller: _pageController, count: pdfs.length),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
