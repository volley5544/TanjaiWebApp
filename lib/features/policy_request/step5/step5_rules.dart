import '../../../core/config/app_environment.dart';
import '../../search_package/product_type.dart';
import '../models/request_variant.dart';
import 'step5_data.dart';

/// Product / work-type differences of step 5 (FF InsuranceInfoPage5).
/// Motor, EV and MC show the same page (FF had no EV / MC branch); CMI and
/// House rules are listed where cheap — those flows are not ported.
abstract class Step5Rules {
  factory Step5Rules.of(RequestVariant v) => switch (v.product) {
        RequestProduct.ev => EvStep5Rules(v),
        RequestProduct.mc => McStep5Rules(v),
        RequestProduct.cmi => CmiStep5Rules(v),
        // not ported: House (fire customer card, app_detail_house values).
        _ => MotorStep5Rules(v),
      };

  RequestVariant get variant;

  /// 'ราคาเบี้ย' / 'ราคาเบี้ยจ่ายล่วงหน้า (รวม พ.ร.บ. ถ้ามี)' blocks.
  bool get showsPremiumBlocks;

  /// 'ราคา พ.ร.บ. (ถ้ามี)' block.
  bool get showsActBlock;

  /// 'ใบตรวจสภาพรถ' downloads (not for House).
  bool get hasInspectionSheets;

  /// 'ทำรายการใหม่' target. FF opened SearchInsurancePage with
  /// `fromIcon: 'page5'` (which fell into its EV branch); the web has one
  /// search page per product → the quotation's own product.
  ProductType get newRequestProduct;
}

class MotorStep5Rules implements Step5Rules {
  const MotorStep5Rules(this.variant);

  @override
  final RequestVariant variant;

  @override
  bool get showsPremiumBlocks => true;

  @override
  bool get showsActBlock => true;

  @override
  bool get hasInspectionSheets => true;

  @override
  ProductType get newRequestProduct => ProductType.motor;
}

class EvStep5Rules extends MotorStep5Rules {
  const EvStep5Rules(super.variant);

  @override
  ProductType get newRequestProduct => ProductType.ev;
}

class McStep5Rules extends MotorStep5Rules {
  const McStep5Rules(super.variant);

  @override
  ProductType get newRequestProduct => ProductType.mc;
}

/// CMI (stand-alone พ.ร.บ.) — not ported (InfomationCustomerAct card and
/// the role-gated 'บันทึก พ.ร.บ.' / SaveContractCMI sheet are missing).
class CmiStep5Rules extends MotorStep5Rules {
  const CmiStep5Rules(super.variant);

  @override
  bool get showsPremiumBlocks => false;

  @override
  bool get showsActBlock => false;
}

// ---- data-driven rules (same for every product) -----------------------------

/// 'ยกเลิก' visible: auto (`quotations.quotation_type`, as FF page 5 read
/// it) AND (approved today OR car inspection pending).
bool step5CanCancel(Step5Data d) =>
    d.quotationType == 'auto' &&
    ((d.status == 'อนุมัติ' && d.completedToday) || d.status == 'อยู่ระหว่างตรวจสอบสภาพรถ');

/// 'ราคาเบี้ย' (summary card): auto rounds to 2 decimals, others truncate.
bool step5PremiumRounds(Step5Data d) => d.quotationType == 'auto';

/// 'ทำรายการใหม่' visible — the on-load policy status (FF `_model.getPolicy`).
bool step5ShowsNewRequest(Step5Data d) =>
    d.onLoadPolicyStatus == 'ไม่อนุมัติ' || d.onLoadPolicyStatus == 'ยกเลิก';

/// FF 'การ์ดค่างวด' URL (prod / dev by environment, FF `isProduction`).
///
/// Both FF URLs are plain **http** (dev is a bare IP) — the web only opens
/// https links (pentest rule), so the button is hidden while this returns a
/// non-https URL. Open question for the user (https endpoint?).
String step5InstalmentCardUrl(String contNo) => AppEnvironment.current.isProduction
    ? 'http://ssw-api.srisawadpower.com/api/v1/prod/gec_arcard?server=VL&comcode=S14&contno=$contNo'
    : 'http://49.229.60.115/api/v1/dev/gec_arcard?server=VL&comcode=S14&contno=$contNo';

/// One row of the Step5DocumentDownload sheet.
class Step5DocLink {
  const Step5DocLink(this.text, this.url);

  final String text;
  final String url;
}

const _sswSheetUrl =
    'https://firebasestorage.googleapis.com/v0/b/sawad-new-ibs.appspot.com/o/filePDF%2F%E0%B9%83%E0%B8%9A%E0%B8%95%E0%B8%A3%E0%B8%A7%E0%B8%88%E0%B8%AA%E0%B8%A0%E0%B8%B2%E0%B8%9E%E0%B8%A3%E0%B8%96_ssw.pdf?alt=media&token=a4e63a2e-c74b-4c06-8b87-fb7abc80b128&_gl=1*1jny086*_ga*MTI5MzM2MTI1My4xNjkzODIzNjI0*_ga_CW55HF8NVT*MTY5NjM5OTc2OC4yMi4xLjE2OTYzOTk4NjMuMzUuMC4w';
const _allianzSheetUrl =
    'https://firebasestorage.googleapis.com/v0/b/sawad-new-ibs.appspot.com/o/filePDF%2F8.%E0%B9%83%E0%B8%9A%E0%B8%95%E0%B8%A3%E0%B8%A7%E0%B8%88%E0%B8%AA%E0%B8%A0%E0%B8%B2%E0%B8%9E%E0%B8%A3%E0%B8%96%20%E0%B8%AD%E0%B8%A5%E0%B8%B4%E0%B8%AD%E0%B8%B1%E0%B8%A5.pdf?alt=media&token=e906aa74-2472-4195-a1a8-4f34a5d294e8';
const _loanFormUrl =
    'https://firebasestorage.googleapis.com/v0/b/sawad-new-ibs.appspot.com/o/filePDF%2F%E0%B9%83%E0%B8%9A%E0%B8%84%E0%B8%B3%E0%B8%82%E0%B8%AD%E0%B8%AA%E0%B8%B4%E0%B8%99%E0%B9%80%E0%B8%8A%E0%B8%B7%E0%B9%88%E0%B8%AD%20%E0%B9%80%E0%B8%9B%E0%B9%89%E0%B8%B2%20%E0%B8%87%20%E0%B8%9B%E0%B8%A3%E0%B8%B1%E0%B8%9A%E0%B9%81%E0%B8%81%E0%B9%89%E0%B9%84%E0%B8%82%2024.11.2023.pdf?alt=media&token=5b740c1a-0082-4a31-8927-299103cbd1c8';

/// Rows of the Step5DocumentDownload sheet (FF visibility rules, spec
/// shared §1.5). The three static PDFs live in the prod bucket
/// `sawad-new-ibs` for both environments (as FF).
List<Step5DocLink> step5DocumentLinks(Step5Data d, Step5Rules rules) {
  final auto = d.quotationTypeBak == 'auto';
  final allianz = d.insurerShortName == 'Allianz';
  return [
    if ((auto || !allianz) && rules.hasInspectionSheets)
      const Step5DocLink('ดาวน์โหลดเอกสาร ใบตรวจสภาพรถ SSW', _sswSheetUrl),
    if (!auto && allianz && rules.hasInspectionSheets)
      const Step5DocLink('ดาวน์โหลดเอกสาร ใบตรวจสภาพรถ อลิอันซ์', _allianzSheetUrl),
    Step5DocLink('ดาวน์โหลดเอกสาร ใบคำขอเอาประกัน', d.fileApplication),
    const Step5DocLink('ดาวน์โหลดเอกสาร ใบคำขอสินเชื่อเป้า ง', _loanFormUrl),
  ];
}
