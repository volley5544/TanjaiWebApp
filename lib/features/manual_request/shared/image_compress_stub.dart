import 'dart:typed_data';

/// Non-web stand-in: returns the bytes unchanged.
Future<Uint8List?> compressToJpeg(String blobUrl, Uint8List original, {int maxSide = 1920, double quality = 0.5}) async =>
    original;
