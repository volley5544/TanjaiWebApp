import 'package:web/web.dart' as web;

import 'tel_link.dart';

void launchTel(String phone) {
  final digits = telDigits(phone);
  if (digits.isEmpty) return;
  web.window.location.href = 'tel:$digits';
}
