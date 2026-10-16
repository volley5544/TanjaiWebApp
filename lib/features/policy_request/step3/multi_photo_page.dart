import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/env_version_tag.dart';
import '../../manual_request/shared/photo_upload.dart';
import '../shared/request_widgets.dart';
import 'step3_data.dart';
import 'widgets.dart';

/// FF UploadImgPage — up to 5 ('รูปเอกสารอื่นๆ') or 6 ('รูปรอยแผล',
/// 'รูปอุปกรณ์เสริม') photos; row N+1 appears once row N has a photo.
/// Pops with the URLs (consecutive rows from row 1) on 'ตกลง'; the caller
/// replaces its list (FF: lists replaced, page starts empty every time).
///
/// Web differences: each photo is compressed and uploaded when picked
/// (`pickAndUploadPhoto`, inside the loading overlay) instead of FF's upload
/// of all rows on 'ตกลง' without any progress UI — so 'อัพโหลดสำเร็จ' now
/// means uploaded; the view icon of a filled row shows its photo (FF rows
/// 2–6 had a decorative icon, row 1 none). `fromPage` (unused in FF) and
/// `insuranceInfoCheckUploadImgBoolList` (unused) are dropped.
class MultiPhotoPage extends StatefulWidget {
  const MultiPhotoPage({super.key, required this.kind});

  final MultiPhotoKind kind;

  static Future<List<String>?> open(BuildContext context, MultiPhotoKind kind) =>
      Navigator.of(context).push<List<String>>(MaterialPageRoute(builder: (_) => MultiPhotoPage(kind: kind)));

  @override
  State<MultiPhotoPage> createState() => _MultiPhotoPageState();
}

class _MultiPhotoPageState extends State<MultiPhotoPage> {
  late final List<String> _urls = List.filled(widget.kind.max, '');

  Future<void> _pick(int i) async {
    final url = await pickAndUploadPhoto(context);
    if (!mounted) return;
    if (url == null || url.isEmpty) {
      // FF: a cancel showed the failure snackbar only when the row was empty.
      if (_urls[i].isEmpty) showNpSnack(context, kPickFailText, clearFirst: false);
      return;
    }
    setState(() => _urls[i] = url);
    showNpSnack(context, kPickOkText);
  }

  Future<void> _confirm() async {
    if (_urls.first.isEmpty) {
      await showAlert(context, 'กรุณาถ่ายรูป');
      return;
    }
    // FF createFileUploadedListCopy: consecutive rows from row 1.
    final result = <String>[];
    for (final u in _urls) {
      if (u.isEmpty) break;
      result.add(u);
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < _urls.length; i++) {
      if (i > 0 && _urls[i - 1].isEmpty) break;
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 12),
        child: RequestUploadActionRow(
          uploaded: _urls[i].isNotEmpty,
          onUpload: () => _pick(i),
          onView: () => showRequestImage(context, _urls[i]),
          buttonText: 'ถ่ายรูป',
          buttonIcon: Icons.photo_camera_outlined,
        ),
      ));
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.backIconOrange, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(widget.kind.title, style: AppText.style(fontSize: 16, color: AppColors.titleNavy)),
          actions: const [EnvVersionTag()],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.kind.label, style: AppText.style(fontSize: 15, fontWeight: FontWeight.w500)),
                        ...rows,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: AppColors.secondaryBackground,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AppButton(text: 'ตกลง', onPressed: _confirm, fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
