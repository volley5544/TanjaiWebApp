import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Triggers a download of [bytes] as [fileName] via a temporary blob: URL
/// (no network, nothing leaves the device).
Future<void> downloadPng(Uint8List bytes, String fileName) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'image/png'));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(a);
  a.click();
  a.remove();
  // Give the browser a moment to start the download before revoking.
  await Future<void>.delayed(const Duration(seconds: 1));
  web.URL.revokeObjectURL(url);
}
