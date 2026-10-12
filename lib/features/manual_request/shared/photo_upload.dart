import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firebase_storage_rest.dart';
import '../../../core/widgets/loading_scene.dart';

/// FF upload snackbars: white text on 70 % black, 3 s.
void showNpSnack(BuildContext context, String message, {bool clearFirst = true}) {
  final m = ScaffoldMessenger.of(context);
  if (clearFirst) m.clearSnackBars();
  m.showSnackBar(SnackBar(
    content: Text(message, style: const TextStyle(color: Colors.white)),
    backgroundColor: const Color(0xB2000000),
    duration: const Duration(milliseconds: 3000),
  ));
}

const uploadOkText = 'อัพโหลดรูปภาพสำเร็จ';
const uploadFailText = 'อัพโหลดรูปภาพล้มเหลว กรุณาลองอีกครั้ง';

/// FF `selectMediaWithSourceBottomSheet(allowPhoto: true)`
/// + `uploadData` to Storage. Returns the download URL, or null when the user
/// cancelled or the upload failed.
///
/// Web: the source sheet offers Gallery and Camera like FF mobile (FF's web
/// build only had Gallery; this app runs in the mobile WebView, where Camera
/// maps to `<input capture>`). Images are scaled to fit 1920×1920 px (never
/// upscaled) and re-encoded as JPEG quality 50 (user's choice; FF used 30).
Future<String?> pickAndUploadPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: const Color(0xFFF5F5F5),
    builder: (ctx) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: ListTile(
              title: Text(
                'Choose Source',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xA6111417)),
              ),
            ),
          ),
          const Divider(),
          _sourceTile(ctx, 'Gallery', ImageSource.gallery),
          const Divider(),
          _sourceTile(ctx, 'Camera', ImageSource.camera),
          const Divider(),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  final XFile? file;
  try {
    file = await ImagePicker().pickImage(source: source, imageQuality: 50, maxWidth: 1920, maxHeight: 1920);
  } catch (_) {
    return null;
  }
  if (file == null || !context.mounted) return null;
  final picked = file;
  return withLoading(context, () async {
    final List<int> raw;
    try {
      raw = await picked.readAsBytes(); // web: fetches a blob: URL (CSP connect-src blob:)
    } catch (_) {
      return null;
    }
    final bytes = Uint8List.fromList(raw);
    final mime = picked.mimeType ?? '';
    final isPng = mime == 'image/png';
    return FirebaseStorageRest.uploadImage(
      bytes,
      ext: isPng ? 'png' : 'jpg',
      contentType: isPng ? 'image/png' : 'image/jpeg',
    );
  });
}

Widget _sourceTile(BuildContext ctx, String label, ImageSource source) => ListTile(
      tileColor: const Color(0xFFF5F5F5),
      title: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111417)),
      ),
      onTap: () => Navigator.pop(ctx, source),
    );

/// Pick + upload + FF snackbars, for one slot. [onUrl] stores the URL.
/// FF showed the failure snackbar also when the picker was cancelled; kept.
/// (FF re-showed the success snackbar on cancel when the slot was already
/// filled — dropped: cancel now never reports success.)
Future<bool> uploadSlot(BuildContext context, void Function(String url) onUrl) async {
  final url = await pickAndUploadPhoto(context);
  if (!context.mounted) return false;
  if (url == null || url.isEmpty) {
    showNpSnack(context, uploadFailText, clearFirst: false);
    return false;
  }
  onUrl(url);
  showNpSnack(context, uploadOkText);
  return true;
}
