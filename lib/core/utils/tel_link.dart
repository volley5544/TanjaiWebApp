// FF `launchUrl(Uri(scheme: 'tel', path: phone))` on web. Web navigates the
// current window to `tel:` (browsers hand it to the dialer and stay on the
// page; a host WebView can intercept it in shouldOverrideUrlLoading).
export 'tel_link_stub.dart' if (dart.library.js_interop) 'tel_link_web.dart';

/// Digits and a leading `+` only — nothing else from the API reaches the URL.
String telDigits(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');
