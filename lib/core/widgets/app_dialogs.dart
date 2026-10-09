import 'package:flutter/material.dart';

/// The FF pages' alert: plain `AlertDialog(content: Text(msg))` with one
/// 'Ok' button. Messages shown to users must never contain raw exceptions or
/// server internals — pass a Thai user-facing message.
Future<void> showAlert(BuildContext context, String message, {String title = ''}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: title.isEmpty ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Ok'),
        ),
      ],
    ),
  );
}

/// Two-button confirm in the same plain style; resolves true on [confirmText].
Future<bool> showConfirm(
  BuildContext context,
  String message, {
  String title = '',
  String cancelText = 'ยกเลิก',
  String confirmText = 'ยืนยัน',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: title.isEmpty ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(cancelText)),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(confirmText)),
      ],
    ),
  );
  return result ?? false;
}

/// FF's generic HTTP-failure text: `พบข้อผิดพลาด (<status>)`.
String httpErrorText(int statusCode) => 'พบข้อผิดพลาด ($statusCode)';
