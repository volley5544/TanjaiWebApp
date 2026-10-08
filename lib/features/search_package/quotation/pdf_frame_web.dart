import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// The FF `FlutterFlowPdfViewer` on web: the browser's own PDF viewer in an
/// `<iframe>`. Callers must pass a URL that passed `isSafePdfUrl`.
class PdfFrame extends StatelessWidget {
  const PdfFrame({super.key, required this.url});

  final String url;

  static final Set<String> _registered = {};

  static String _viewType(String url) {
    final type = 'quotation-pdf-${url.hashCode}-${url.length}';
    if (_registered.add(type)) {
      ui_web.platformViewRegistry.registerViewFactory(type, (int viewId) {
        final frame = web.HTMLIFrameElement()
          ..src = url
          ..referrerPolicy = 'no-referrer';
        frame.style
          ..border = 'none'
          ..width = '100%'
          ..height = '100%';
        return frame;
      });
    }
    return type;
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType(url));
}

/// FF `launchURL` on web: new tab, no opener access back to this app.
void openUrlInNewTab(String url) {
  web.window.open(url, '_blank', 'noopener,noreferrer');
}
