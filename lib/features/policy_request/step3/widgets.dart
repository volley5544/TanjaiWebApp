import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../manual_request/shared/photo_upload.dart';
import '../../search_package/quotation/pdf_frame.dart';
import '../shared/request_widgets.dart';

/// Upload rows shared by steps 3 and 4 (FF InsuranceInfoPage3 / 4 / UploadImgPage).

/// FF document-row snackbars.
const kPickOkText = 'เลือกรูปสำเร็จ!';
const kPickFailText = 'เลือกรูปล้มเหลว กรุณาลองอีกครั้ง';
const kUploadRequiredTag = 'บังคับอัพโหลดรูป';

const kViewIconColor = Color(0xFF354052);
const kUploadedCheckColor = Color(0xFF00FD76);
const kNotUploadedColor = Color(0xFFFC0A0A);

/// Pick + upload one photo (`pickAndUploadPhoto`: JPEG q50 ≤1920, Storage,
/// loading overlay) and show the FF snackbar. [onUrl] runs only when the
/// upload succeeded.
///
/// FF fix: FF wrote the field also when the picker was cancelled (wiping a
/// photo prefilled from the application); now only a successful upload
/// writes. The failure snackbar on cancel is kept (FF showed it).
Future<bool> uploadPhotoInto(
  BuildContext context,
  void Function(String url) onUrl, {
  String okText = kPickOkText,
  String failText = kPickFailText,
}) async {
  final url = await pickAndUploadPhoto(context);
  if (!context.mounted) return false;
  if (url == null || url.isEmpty) {
    showNpSnack(context, failText, clearFirst: false);
    return false;
  }
  onUrl(url);
  showNpSnack(context, okText);
  return true;
}

/// FF `launchURL` / `urlLauncherActionCopy`: new tab with `noopener`, https
/// only (FF crashed or opened garbage on '' / 'null'; those are ignored).
/// Returns whether the URL was opened.
bool openRequestDocument(String url) {
  if (!isSafePdfUrl(url)) return false;
  openUrlInNewTab(url.trim());
  return true;
}

/// FF document row: title (+ red tag) above an action row with the light
/// orange upload button, 'สถานะ :' + status, and view / ✓ or ✕ on the right.
class RequestUploadRow extends StatelessWidget {
  const RequestUploadRow({
    super.key,
    required this.title,
    required this.uploaded,
    required this.onUpload,
    this.onView,
    this.titleWidget,
    this.tag = '',
    this.tagColor = kRequestTagRed,
    this.tagPadding = 10,
    this.titleSize = 15,
    this.buttonText = 'อัพโหลดรูป',
    this.buttonIcon = Icons.file_upload_outlined,
    this.top = 10,
  });

  final String title;

  /// Replaces the title text (step 4 doc 5 header).
  final Widget? titleWidget;
  final String tag;
  final Color tagColor;
  final double tagPadding;
  final double titleSize;
  final bool uploaded;
  final VoidCallback onUpload;

  /// View icon tap (shown when [uploaded]).
  final VoidCallback? onView;
  final String buttonText;
  final IconData buttonIcon;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget ??
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(title, style: AppText.style(fontSize: titleSize, fontWeight: FontWeight.w500)),
                  if (tag.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: tagPadding),
                      child: Text(tag, style: AppText.style(fontSize: 12, fontWeight: FontWeight.normal, color: tagColor)),
                    ),
                ],
              ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: RequestUploadActionRow(
              uploaded: uploaded,
              onUpload: onUpload,
              onView: onView,
              buttonText: buttonText,
              buttonIcon: buttonIcon,
            ),
          ),
        ],
      ),
    );
  }
}

/// The 45-px action row of an upload row.
class RequestUploadActionRow extends StatelessWidget {
  const RequestUploadActionRow({
    super.key,
    required this.uploaded,
    required this.onUpload,
    this.onView,
    this.buttonText = 'อัพโหลดรูป',
    this.buttonIcon = Icons.file_upload_outlined,
    this.showViewIcon = true,
  });

  final bool uploaded;
  final VoidCallback onUpload;
  final VoidCallback? onView;
  final String buttonText;
  final IconData buttonIcon;
  final bool showViewIcon;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final status = AppText.style(fontSize: 14, fontWeight: FontWeight.normal);
    return SizedBox(
      height: 45,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                InkWell(
                  onTap: onUpload,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: w * 0.35,
                    height: 45,
                    padding: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(color: kRequestLightOrange, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Icon(buttonIcon, color: AppColors.primaryText, size: 24),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              buttonText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.style(fontSize: 16, fontWeight: FontWeight.normal, color: kRequestOrange),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(10, 0, 5, 0), child: Text('สถานะ :', style: status)),
                Flexible(
                  child: Text(uploaded ? 'อัพโหลดสำเร็จ' : 'ยังไม่อัพโหลด', maxLines: 2, style: status),
                ),
              ],
            ),
          ),
          UploadStateIcons(uploaded: uploaded, onView: showViewIcon ? onView : null),
        ],
      ),
    );
  }
}

/// View icon (when uploaded and [onView] given) + ✓ #00FD76 / ✕ #FC0A0A.
class UploadStateIcons extends StatelessWidget {
  const UploadStateIcons({
    super.key,
    required this.uploaded,
    this.onView,
    this.checkIcon = Icons.check_sharp,
    this.checkColor = kUploadedCheckColor,
    this.closeColor = kNotUploadedColor,
  });

  final bool uploaded;
  final VoidCallback? onView;
  final IconData checkIcon;
  final Color checkColor;
  final Color closeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (uploaded && onView != null)
          InkWell(
            onTap: onView,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.content_paste_search_rounded, color: kViewIconColor, size: 24),
            ),
          ),
        uploaded ? Icon(checkIcon, color: checkColor, size: 24) : Icon(Icons.close, color: closeColor, size: 24),
      ],
    );
  }
}

/// FF download link: `file_download_outlined` + navy bold underlined text.
class RequestDownloadLink extends StatelessWidget {
  const RequestDownloadLink({super.key, required this.text, required this.onTap, this.fontSize = 15, this.iconSize = 24, this.top = 10});

  final String text;
  final VoidCallback? onTap;
  final double fontSize;
  final double iconSize;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 33),
          child: Row(
            children: [
              Icon(Icons.file_download_outlined, color: AppColors.primaryText, size: iconSize),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Text(
                    text,
                    style: AppText.style(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: kRequestNavy,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
