import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Draws the picked image ([blobUrl], from image_picker on web) on a canvas
/// scaled to fit [maxSide]×[maxSide] and encodes it as JPEG [quality].
/// Transparent areas (PNG) become white. EXIF orientation is applied by the
/// browser when decoding. Returns null when the image can't be decoded.
Future<Uint8List?> compressToJpeg(String blobUrl, Uint8List original, {int maxSide = 1920, double quality = 0.5}) async {
  final img = web.HTMLImageElement();
  final loaded = Completer<bool>();
  img.onLoad.listen((_) => loaded.complete(true));
  img.onError.listen((_) => loaded.complete(false));
  img.src = blobUrl;
  if (!await loaded.future) return null;

  final w = img.naturalWidth;
  final h = img.naturalHeight;
  if (w == 0 || h == 0) return null;
  final scale = math.min(1.0, maxSide / math.max(w, h));
  final cw = math.max(1, (w * scale).round());
  final ch = math.max(1, (h * scale).round());

  final canvas = web.HTMLCanvasElement()
    ..width = cw
    ..height = ch;
  canvas.context2D
    ..fillStyle = 'white'.toJS
    ..fillRect(0, 0, cw, ch)
    ..drawImage(img, 0, 0, cw.toDouble(), ch.toDouble());

  final blobDone = Completer<web.Blob?>();
  canvas.toBlob(((web.Blob? b) => blobDone.complete(b)).toJS, 'image/jpeg', quality.toJS);
  final blob = await blobDone.future;
  if (blob == null) return null;
  final buffer = await blob.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}
