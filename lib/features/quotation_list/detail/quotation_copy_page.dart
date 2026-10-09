import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../router/app_router.dart';
import '../../search_package/quotation/pdf_frame.dart';
import '../state/quotation_list_state.dart';

const _black600 = Color(0xFF090F13);

/// Port of FF `QuotationCopy` ('ใบเสนอราคา' from MakeInsuranceListPage's
/// 'ดูใบเสนอราคา'): one document at a time out of the item's `pdf_quotation`
/// URLs, with 'ก่อนหน้า' / 'ถัดไป' and 'ดาวน์โหลด PDF' (shown when the URL
/// contains 'pdf'). A `.pdf` URL is embedded; anything else is shown as an
/// image, as in FF.
///
/// FF's PageView only ever held the first URL and swapped what that page
/// showed by `indexPdfQuotation`; here the index drives the view directly
/// (same result). Web: the PDF is an `<iframe>`, https only.
class QuotationCopyPage extends StatefulWidget {
  const QuotationCopyPage({super.key});

  @override
  State<QuotationCopyPage> createState() => _QuotationCopyPageState();
}

class _QuotationCopyPageState extends State<QuotationCopyPage> {
  final _state = QuotationListState.instance;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (_state.quotationCopyUrls == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.quotationList);
      });
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.quotationList);
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = _state.quotationCopyUrls ?? const <String>[];
    final current = _index < urls.length ? urls[_index] : '';
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: tanjaiAppBar(
        title: 'ใบเสนอราคา',
        titleColor: const Color(0xFF003063),
        backColor: AppColors.brandOrange,
        onBack: _back,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_index != 0)
                      _nav(
                        onTap: () => setState(() => _index--),
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Icon(Icons.arrow_back, color: _black600, size: 24),
                          ),
                          Text('ก่อนหน้า', style: AppText.bodyMedium),
                        ],
                      ),
                    if (_index == 0) const Spacer(),
                    if (containWordinStringUrl('pdf', current))
                      AppButton(
                        text: 'ดาวน์โหลด PDF',
                        onPressed: () {
                          if (isSafePdfUrl(current)) openUrlInNewTab(current);
                        },
                        width: 130,
                        height: 40,
                        color: AppColors.primary,
                        radius: 15,
                        fontSize: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    if (_index >= urls.length - 1) const Spacer(),
                    if (_index < urls.length - 1)
                      _nav(
                        onTap: () => setState(() => _index++),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text('ถัดไป', style: AppText.bodyMedium),
                          ),
                          const Icon(Icons.arrow_forward, color: _black600, size: 24),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.secondaryBackground,
                child: current.isEmpty
                    ? const SizedBox.shrink()
                    : containWordinStringUrl('.pdf', current)
                        ? Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              height: size.height * 0.85,
                              child: isSafePdfUrl(current) ? PdfFrame(url: current) : const SizedBox.expand(),
                            ),
                          )
                        : _image(current),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(String url) {
    if (!isSafePdfUrl(url)) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _nav({required VoidCallback onTap, required List<Widget> children}) => InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: SizedBox(
          width: 100,
          height: 100,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: children),
        ),
      );
}
