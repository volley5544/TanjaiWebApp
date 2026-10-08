import 'package:flutter_web_plugins/url_strategy.dart';

/// Firebase Hosting rewrites every path to index.html, so deep links work.
void configureUrlStrategy() => usePathUrlStrategy();
