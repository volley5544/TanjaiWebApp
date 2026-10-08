// Embedded PDF view + "open in new tab" helper for the Quotation page.
// Web renders an `<iframe>`; other platforms (tests / VM) get a stub.
export 'pdf_frame_stub.dart' if (dart.library.js_interop) 'pdf_frame_web.dart';

/// Only plain `https://` URLs with a host are shown or opened — never
/// `javascript:`, `data:`, `http:` or the literal `'null'` FF could append.
bool isSafePdfUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}
