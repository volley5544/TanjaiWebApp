// Photo compression before upload: fit within [maxSide]×[maxSide] (never
// upscaled) and re-encode as JPEG [quality] — PNG / WebP / large photos
// included. Web uses an offscreen canvas; other platforms (tests) pass the
// bytes through.
export 'image_compress_stub.dart' if (dart.library.js_interop) 'image_compress_web.dart';
