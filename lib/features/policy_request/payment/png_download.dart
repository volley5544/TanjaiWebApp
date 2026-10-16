// Saves PNG bytes as a browser download (web) — the web stand-in for FF
// `capQrCode`'s gallery save. Non-web builds (tests / VM) get a no-op stub.
export 'png_download_stub.dart' if (dart.library.js_interop) 'png_download_web.dart';
