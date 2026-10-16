import '../models/request_variant.dart';

/// Product / work-type differences of step 4.2 (FF InsuranceInfoPage42 +
/// PaywithQRcode). Motor, EV and MC behave the same on this page (FF had no
/// EV / MC branch here); CMI (stand-alone พ.ร.บ.) and House (fire) are not
/// ported — their rules are listed where cheap.
abstract class PaymentRules {
  factory PaymentRules.of(RequestVariant v) => switch (v.product) {
        RequestProduct.ev => EvPaymentRules(v),
        RequestProduct.mc => McPaymentRules(v),
        RequestProduct.cmi => CmiPaymentRules(v),
        // not ported: House uses FireInsuranceInfoPage42 (separate FF page).
        _ => MotorPaymentRules(v),
      };

  RequestVariant get variant;

  /// 'ราคาเบี้ย' block (hidden for CMI).
  bool get showsNetPremium;

  /// 'ราคา พ.ร.บ (ถ้ามี)' block (hidden for CMI / House).
  bool get showsActTotal;

  /// QR page: the two red first-payment lines + 'คุณสามารถสแกน…' + the
  /// holiday note; CMI shows 'ใช้สำหรับชำระค่า พ.ร.บ เท่านั้น' instead.
  bool get qrShowsFirstPaymentNotes;

  /// 'ยืนยันทำประกัน': the insurer effective date is checked (CMI skips it).
  bool get checksInsureDate;

  /// Confirm button text (FF by `insuranceInfoApplicationType`).
  String get confirmText;
}

class MotorPaymentRules implements PaymentRules {
  const MotorPaymentRules(this.variant);

  @override
  final RequestVariant variant;

  @override
  bool get showsNetPremium => true;

  @override
  bool get showsActTotal => true;

  @override
  bool get qrShowsFirstPaymentNotes => true;

  @override
  bool get checksInsureDate => true;

  @override
  String get confirmText => variant.isAuto ? 'ยืนยันทำประกัน' : 'ส่งเรื่องให้บริษัทประกัน';
}

/// EV: same as motor on this page.
class EvPaymentRules extends MotorPaymentRules {
  const EvPaymentRules(super.variant);
}

/// MC: same as motor on this page (FF's MC texts were inside `if (false)`).
class McPaymentRules extends MotorPaymentRules {
  const McPaymentRules(super.variant);
}

/// CMI (stand-alone พ.ร.บ.) — not ported (summary card
/// `InfomationCustomerAct` missing); rules kept for when it is.
class CmiPaymentRules extends MotorPaymentRules {
  const CmiPaymentRules(super.variant);

  @override
  bool get showsNetPremium => false;

  @override
  bool get showsActTotal => false;

  @override
  bool get qrShowsFirstPaymentNotes => false;

  @override
  bool get checksInsureDate => false;
}

// ---- FF custom functions used by step 4.2 (null-safe ports, same names) ----

/// FF `genQRCodePayment`: Thai bill-payment payload with LF separators and a
/// trailing LF, amount × 100 as a Dart double string ('5901.26' →
/// '590126.0'). Kept byte-identical to FF (banks accept it). FF
/// `double.parse` crashed on ''/'null' → here null (caller shows no QR).
String? genQRCodePayment(String suffix, String ref1, String ref2, String amount, String taxId) {
  final value = double.tryParse(amount.trim());
  if (value == null) return null;
  final amount100 = (value * 100).toString();
  return '|$taxId$suffix\n$ref1\n$ref2\n$amount100\n';
}

/// FF `checkCurrentDateIsBeforeInputDate`: current ≤ input. FF crashed on
/// an empty / invalid date; the port returns false (→ re-pick the date).
bool checkCurrentDateIsBeforeInputDate(String currentDate, String inputDate) {
  final a = DateTime.tryParse(currentDate);
  final b = DateTime.tryParse(inputDate);
  if (a == null || b == null) return false;
  return !a.isAfter(b);
}

/// FF `checkDateBeforeAnotherDate`: [date] ≤ device now + [days] (FF used
/// the device clock, not the server's — kept).
bool checkDateBeforeAnotherDate(int days, DateTime date, {DateTime? now}) {
  final limit = (now ?? DateTime.now()).add(Duration(days: days));
  return !date.isAfter(limit);
}
