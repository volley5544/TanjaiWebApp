// Removes launch params from the address bar without a reload.
// Conditional import keeps the project compiling off-web (tests / VM).
export 'url_cleaner_stub.dart' if (dart.library.js_interop) 'url_cleaner_web.dart';
