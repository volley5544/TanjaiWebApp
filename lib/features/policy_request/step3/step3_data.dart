import '../models/application_detail.dart';

/// The 9 vehicle-inspection photos of FF InsuranceInfoPage3, in the order of
/// the tap map / status list (1 = front … 9 = roof).
enum InspectionPhoto {
  front(1, 'image_front'),
  rightFront(2, 'image_rightfront'),
  right(3, 'image_right'),
  rightRear(4, 'image_rightrear'),
  rear(5, 'image_rear'),
  leftRear(6, 'image_leftrear'),
  left(7, 'image_left'),
  leftFront(8, 'image_leftfront'),
  roof(9, 'image_roof');

  const InspectionPhoto(this.number, this.apiKey);

  /// 1…9 as printed on the diagram.
  final int number;

  /// Key in the detail `app_document` and in the save body.
  final String apiKey;
}

/// The multi-photo rows (FF UploadImgPage `titleText`).
enum MultiPhotoKind {
  other('รูปเอกสารอื่นๆ', 'รูปเอกสารอื่นๆ (ถ่ายได้ไม่เกิน 5 รูป)', 5),
  wound('รูปรอยแผล', 'รูปรอยแผล (ถ่ายได้ไม่เกิน 6 รูป)', 6),
  accessories('รูปอุปกรณ์เสริม', 'รูปอุปกรณ์เสริม (ถ่ายได้ไม่เกิน 6 รูป)', 6);

  const MultiPhotoKind(this.title, this.label, this.max);

  final String title;
  final String label;

  /// FF enforced the count with the number of rows (row 6 hidden for 'รูปเอกสารอื่นๆ').
  final int max;
}

/// The three consents (FF page-local `…ConsentValue`: not persisted — every
/// visit starts unchecked, like FF).
class Step3Consents {
  bool sensitive = false;
  bool sanction = false;
  bool privacy = false;
  bool privacyCancel = false;
  bool all = false;

  /// FF: `sensitive && sanction && (privacy || privacyCancel)`.
  bool get ok => sensitive && sanction && (privacy || privacyCancel);

  /// 'ยินยอมทั้งหมด': check → the three "ยินยอม" on, 'ไม่ยินยอม' off;
  /// uncheck → the three off ('ไม่ยินยอม' untouched). FF did not update
  /// [all] from the individual boxes — kept.
  void setAll(bool v) {
    all = v;
    sensitive = v;
    sanction = v;
    privacy = v;
    if (v) privacyCancel = false;
  }

  /// Item 3 'ยินยอม' / 'ไม่ยินยอม' are mutually exclusive.
  void setPrivacy(bool v) {
    privacy = v;
    if (v) privacyCancel = false;
  }

  void setPrivacyCancel(bool v) {
    privacyCancel = v;
    if (v) privacy = false;
  }

  String _flag(bool v) => v ? '1' : '0';

  /// `sensitive_consent` / `privacy_consent` / `sanction_consent`.
  Map<String, String> toFields() => {
        'sensitive_consent': _flag(sensitive),
        'privacy_consent': _flag(privacy),
        'sanction_consent': _flag(sanction),
      };
}

/// Step 3 (document / vehicle photos, consents) — replaces FF
/// `insuranceInfoPage3Image*`, `insuranceinfoOldVMIimage`,
/// `insuranceInfoPage3SaveDataCheckBool`, `insuranceinfoPage3PdfFileapplication`.
///
/// Filled from the application detail by [loadFromDetail] (FF page 1
/// prefilled the photo URLs, so a resumed application shows ✓ already).
class Step3Data {
  /// `leads[0].sub_product` (FF insuranceinfoActType) — sent as `sub_product`
  /// by the renew / MC / CMI save.
  String subProduct = '';

  /// `leads_detail[LD].cover_type_name` (FF insuranceInfocoverType), e.g. 'ชั้น 1'.
  String coverType = '';

  /// `leads_detail[LD].inspection_except` — 'Y' = 9-photo inspection waived.
  String inspectionExcept = '';

  /// `leads_detail[LD].inspection_except_policy_file` — 'Y' = old policy not needed.
  String inspectionExceptPolicyFile = '';

  /// `app_detail[0].work_type` (FF nonePackageWorkType) — 'งานต่ออายุ' = renewal.
  String workType = '';

  String examination = '';
  String bluebook = '';
  String idCard = '';

  /// FF insuranceinfoOldVMIimage (old, unexpired policy schedule).
  String oldVmi = '';

  /// FF insuranceInfoPage3ImageOther — comma-joined URLs.
  String other = '';
  List<String> wound = [];
  List<String> accessories = [];
  final Map<InspectionPhoto, String> photos = {for (final p in InspectionPhoto.values) p: ''};

  /// FF insuranceInfoPage3SaveDataCheckBool — shows 'ถัดไป'.
  bool saved = false;

  /// FF insuranceinfoPage3PdfFileapplication — the generated application
  /// form (P4 'ดาวน์โหลดเอกสารใบคำขอเอาประกัน').
  String pdfFileApplication = '';

  bool get isRenewal => workType == 'งานต่ออายุ';

  /// FF `splitStringToList(ImageOther)` (empty string → no items).
  List<String> get otherList => [
        for (final u in other.split(','))
          if (u.trim().isNotEmpty) u.trim(),
      ];

  List<String> multi(MultiPhotoKind k) => switch (k) {
        MultiPhotoKind.other => otherList,
        MultiPhotoKind.wound => wound,
        MultiPhotoKind.accessories => accessories,
      };

  /// FF UploadImgPage confirm: lists are replaced, not appended.
  void setMulti(MultiPhotoKind k, List<String> urls) {
    switch (k) {
      case MultiPhotoKind.other:
        other = urls.join(','); // FF imgFirebaseListToString (no spaces)
      case MultiPhotoKind.wound:
        wound = List.of(urls);
      case MultiPhotoKind.accessories:
        accessories = List.of(urls);
    }
  }

  void reset() {
    subProduct = coverType = inspectionExcept = inspectionExceptPolicyFile = workType = '';
    examination = bluebook = idCard = oldVmi = other = '';
    wound = [];
    accessories = [];
    for (final p in InspectionPhoto.values) {
      photos[p] = '';
    }
    saved = false;
    pdfFileApplication = '';
  }

  /// FF page 1 §3.3 "Documents". FF read with `'${x}'` (a JSON null became
  /// the text 'null' and counted as uploaded); the port treats null / 'null'
  /// as empty.
  void loadFromDetail(ApplicationDetail d) {
    final doc = d.appDocument;
    final ld = d.leadDetail;
    String img(Map<String, dynamic> m, String k) => cleanUrl(m[k]);

    subProduct = d.subProduct;
    coverType = ApplicationDetail.sOf(ld, 'cover_type_name');
    inspectionExcept = ApplicationDetail.sOf(ld, 'inspection_except');
    inspectionExceptPolicyFile = ApplicationDetail.sOf(ld, 'inspection_except_policy_file');
    workType = ApplicationDetail.sOf(d.appDetail, 'work_type');

    examination = img(doc, 'image_examination');
    bluebook = img(doc, 'image_bluebook');
    idCard = img(doc, 'image_idcard');
    final docOld = img(doc, 'old_VMI_image');
    oldVmi = docOld.isNotEmpty ? docOld : img(d.lead, 'old_VMI_image');
    other = img(doc, 'image_other');
    // FF addImgUrlToList(image_wound1..6) — crashed on a null; nulls skipped here.
    wound = [
      for (var i = 1; i <= 6; i++)
        if (img(doc, 'image_wound$i').isNotEmpty) img(doc, 'image_wound$i'),
    ];
    accessories = [
      for (var i = 1; i <= 6; i++)
        if (img(doc, 'image_accessories$i').isNotEmpty) img(doc, 'image_accessories$i'),
    ];
    for (final p in InspectionPhoto.values) {
      photos[p] = img(doc, p.apiKey);
    }
  }

  /// `'null'` / null → ''.
  static String cleanUrl(dynamic v) {
    if (v == null) return '';
    final s = '$v'.trim();
    return s == 'null' ? '' : s;
  }
}
