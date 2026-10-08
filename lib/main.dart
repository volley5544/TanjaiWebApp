import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'core/session/user_session.dart';
import 'router/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorHandlers();
  configureUrlStrategy();
  await initializeDateFormatting('th_TH');

  // Logged in release too so a stale cached build is visible in the WebView
  // console. Contains no user data.
  // ignore: avoid_print
  print('[TanjaiWeb] env=${AppEnvironment.current.name} webVersion=$kWebVersion');

  // Launch params from the host app; stripped from the address bar inside.
  UserSession.instance.loadFromLaunchUri(Uri.base);

  runApp(const TanjaiWebApp());
}

/// Release builds must never show stack traces or exception text to users
/// (pentest: information disclosure). Debug keeps Flutter's default red box.
void _installErrorHandlers() {
  if (kDebugMode) return;
  FlutterError.onError = (details) {
    // ignore: avoid_print
    print('[TanjaiWeb] ui error: ${details.exception.runtimeType}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    // ignore: avoid_print
    print('[TanjaiWeb] async error: ${error.runtimeType}');
    return true;
  };
  ErrorWidget.builder = (_) => const Material(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง', textAlign: TextAlign.center),
          ),
        ),
      );
}
