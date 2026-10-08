import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../router/app_router.dart';
import '../product_type.dart';
import '../state/search_package_state.dart';
import 'pdf_frame.dart';

/// Port of FF `Quotation` (ใบเสนอราคา, spec 09): vertical pager over the
/// saved quotation PDFs (`state.quotationPdfs`: per-package PDFs, then the
/// comparison PDF) with an expanding-dots indicator.
///
/// Web notes: each PDF is an `<iframe>`, which swallows pointer events, so
/// FF's long-press-to-open is also offered as an AppBar "open" button and
/// the dots switch pages (as in FF). The FF `fromPage` param was unused.
class QuotationPage extends StatefulWidget {
  const QuotationPage({super.key, required this.product});

  final ProductType product;

  @override
  State<QuotationPage> createState() => _QuotationPageState();
}

class _QuotationPageState extends State<QuotationPage> {
  late final SearchPackageState _state = SearchPackageState.of(widget.product);
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    if (_state.result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.search(widget.product));
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

  int get _currentIndex =>
      _pageController.hasClients ? (_pageController.page ?? 0).round() : 0;

  void _back() {
    // FF safePop: pop, or go to the initial route.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.search(widget.product));
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.85;
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final pdfs = _state.quotationPdfs;
        return UnfocusOnTap(
          child: Scaffold(
            backgroundColor: AppColors.primaryBackground,
            appBar: tanjaiAppBar(
              title: 'ใบเสนอราคา',
              titleColor: const Color(0xFF003063),
              backColor: AppColors.brandOrange,
              onBack: _back,
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
                          child: isSafePdfUrl(pdfs[i])
                              ? PdfFrame(url: pdfs[i])
                              // e.g. FF's literal 'null' compare URL: FF
                              // showed a broken page; show it empty instead.
                              : const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const AlignmentDirectional(0.9, -0.95),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 16),
                        child: _VerticalExpandingDots(
                          controller: _pageController,
                          count: pdfs.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// SmoothPageIndicator(axisDirection vertical, ExpandingDotsEffect(
/// expansionFactor 2, spacing 8, radius 16, dotWidth 16, dotHeight 8,
/// dotColor lineColor, activeDotColor tertiary)). Vertical rotates the dots,
/// so each is 8 wide and 16 (active up to 32) tall. Tap → animate to page.
class _VerticalExpandingDots extends StatelessWidget {
  const _VerticalExpandingDots({required this.controller, required this.count});

  final PageController controller;
  final int count;

  static const _dotLength = 16.0;
  static const _dotThickness = 8.0;
  static const _expansion = 2.0;
  static const _spacing = 8.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.hasClients && controller.position.haveDimensions
            ? (controller.page ?? 0)
            : controller.initialPage.toDouble();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              _dot(i, (1 - (page - i).abs()).clamp(0.0, 1.0)),
          ],
        );
      },
    );
  }

  Widget _dot(int i, double t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _spacing / 2),
      child: GestureDetector(
        onTap: () => controller.animateToPage(i,
            duration: const Duration(milliseconds: 500), curve: Curves.ease),
        child: Container(
          width: _dotThickness,
          height: _dotLength + _dotLength * (_expansion - 1) * t,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.lineColor, AppColors.tertiary, t),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
