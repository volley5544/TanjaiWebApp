// Clean path URLs on web (`/motor` instead of `/#/motor`); no-op off-web.
export 'url_strategy_stub.dart' if (dart.library.js_interop) 'url_strategy_web.dart';
