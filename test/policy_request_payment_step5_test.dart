import 'package:flutter_test/flutter_test.dart';
import 'package:tanjai_web_app/features/policy_request/models/application_detail.dart';
import 'package:tanjai_web_app/features/policy_request/models/request_variant.dart';
import 'package:tanjai_web_app/features/policy_request/payment/effective_date_picker.dart';
import 'package:tanjai_web_app/features/policy_request/payment/payment_data.dart';
import 'package:tanjai_web_app/features/policy_request/payment/payment_rules.dart';
import 'package:tanjai_web_app/features/policy_request/step5/step5_data.dart';
import 'package:tanjai_web_app/features/policy_request/step5/step5_rules.dart';
import 'package:tanjai_web_app/features/search_package/product_type.dart';

Map<String, dynamic> _detail({
  String status = 'รอชำระเงิน',
  String paymentType = 'ผ่อนชำระ',
  dynamic tenor = '6',
  String quotationType = 'auto',
}) =>
    {
      'code': 200,
      'results': {
        'data': {
          'quotations': {
            'quotation_id': 'Q1',
            'quotation_status': status,
            'quotation_type': quotationType,
            'quotation_type_bak': 'auto',
          },
          'first_name_th': 'สมชาย',
          'last_name_th': 'ใจดี',
          'mobile1': '0811111111',
          'act_flg': '1',
          'application_no': 'APP1',
          'quotation_type_name': 'ในเรท',
          'quotation_type_bak_name': 'auto',
          'sub_product_name': 'ประกันรถยนต์',
          'leads': [
            {'sub_product': 'Motor', 'vehicle_code': '110', 'phone_number': null, 'ev_flag': 'N'},
          ],
          'leads_detail': [
            {'lead_dtl_id': 1, 'insurer_short_name': 'X', 'cover_type_code': 'VMI1'},
            {
              'lead_dtl_id': 7,
              'insurer_short_name': 'TNI',
              'cover_type_code': 'VMI1',
              'cover_type_name': 'ชั้น 1',
              'garage_type_name': 'ซ่อมอู่',
              'discount_flg': '0',
              'insurer_logo': 'https://x/logo.png',
            },
          ],
          'app_detail': [
            {
              'gross_total_net': '20000.50',
              'act_total': '645.21',
              'net_premium_total': '19355.29',
              'work_type': 'auto',
              'installment_first_due': '3000',
              'installment_last_due': '3100',
              'effective_date_insure': '2026-10-20',
              'effective_date_act': '2026-10-21',
              'expiry_date_insure': '2027-10-20',
            },
          ],
          'app_document': [
            {'file_application': 'https://files/app.pdf'},
          ],
          'payments': [
            {'payment_type': paymentType, 'payment_channel': 'QR', 'payment_status': 'รอชำระเงิน', 'tenor': tenor, 'amount': '6000'},
          ],
          'app_installment': [
            {'tenor_first_due': '2'},
          ],
        },
      },
    };

void main() {
  group('PaymentData', () {
    test('loads payment fields from the detail (null → empty)', () {
      final p = PaymentData()..loadFromDetail(ApplicationDetail(_detail(tenor: null), leadDtlId: 7));
      expect(p.status, 'รอชำระเงิน');
      expect(p.isInstallment, isTrue);
      expect(p.selectTenor, ''); // FF stored 'null'
      expect(p.insurerShortName, 'TNI');
      expect(p.grossTotal, '20000.50');
      expect(p.actTotal, '645.21');
      expect(p.tenorOverSelect, '2');
      expect(p.tenorFirstDueFromApi, '2');
      expect(p.checkSavePaymentBtn, isTrue);
      expect(p.effectiveDateInsure, '2026-10-20');
    });

    test('instalment calc + pickers + save body', () {
      final p = PaymentData()..loadFromDetail(ApplicationDetail(_detail(), leadDtlId: 7));
      final options = InstallmentOption.listFrom({
        'results': {
          'data': {
            'calculate': {
              'installment': [
                {
                  'tenor': '3',
                  'payment_first': '7000',
                  'installment_first_due': '7000',
                  'installment_last_due': '6000',
                  'tenor_first_due': ['1', '2'],
                  'tenor_first_due_default': ['1'],
                },
                {
                  'tenor': '6',
                  'payment_first': '3500',
                  'installment_first_due': '3500',
                  'installment_last_due': '3400',
                  'tenor_first_due': ['1', '2', '3'],
                  'tenor_first_due_default': ['2'],
                },
              ],
            },
          },
        },
      });
      p.applyInstallments(options);
      expect(p.tenorOverList, ['1', '2', '3']);
      expect(p.tenorDefault, '2');
      expect(p.tenorOverLabel('1'), '1   งวด   (รออนุมัติ)');
      expect(p.tenorOverLabel('3'), '3   งวด   (ไม่ต้องรออนุมัติ)');

      p.selectInstallment(0);
      expect(p.selectTenor, '3');
      expect(p.selectFirstDue, '7000');
      expect(p.tenorOverSelect, '1');
      expect(p.checkSavePaymentBtn, isFalse); // differs from the saved plan

      p.selectInstallment(1);
      p.selectTenorOver(1); // '2' = saved
      expect(p.checkSavePaymentBtn, isTrue);
      p.selectTenorOver(0);
      expect(p.tenorOverBelowDefault, isTrue);

      final f = p.savePaymentFields(quotationId: 'Q1', leadDtlId: '7');
      expect(f['tenor'], '6');
      expect(f['tenor_first_due'], '1');
      expect(f['installment_first_due'], '3500');
      expect(f['act_total'], '645.21');
      expect(f['lead_dtl_id'], '7');
    });

    test('saved tenor missing from the calc list does not crash', () {
      final p = PaymentData()..loadFromDetail(ApplicationDetail(_detail(tenor: '12'), leadDtlId: 7));
      p.applyInstallments(const []);
      expect(p.tenorOverList, isEmpty);
      expect(p.tenorDefault, '');
    });

    test('full payment save body sends zeros', () {
      final p = PaymentData()..loadFromDetail(ApplicationDetail(_detail(paymentType: 'จ่ายเต็ม'), leadDtlId: 7));
      final f = p.savePaymentFields(quotationId: 'Q1', leadDtlId: '7');
      expect(f['tenor'], '0');
      expect(f['installment_first_due'], '0');
      expect(f['installment_last_due'], '0');
    });

    test('QR refs + payload (byte-identical to FF)', () {
      final p = PaymentData()
        ..applyQr({
          'results': {
            'data': {
              'payments': [
                {'ref1': 'R1', 'ref2': 'R2', 'suffix': '01', 'tax_id': '0105', 'amount': '5901.26'},
              ],
            },
          },
        });
      expect(genQRCodePayment(p.qrSuffix, p.qrRef1, p.qrRef2, p.qrAmount, p.qrTaxId),
          '|010501\nR1\nR2\n${5901.26 * 100}\n');
      expect(genQRCodePayment('a', 'b', 'c', '', 'd'), isNull);
      expect(genQRCodePayment('a', 'b', 'c', '100', 'd'), '|da\nb\nc\n10000.0\n');
    });
  });

  group('payment rules / dates', () {
    test('variants', () {
      final motor = PaymentRules.of(const RequestVariant(RequestProduct.motor, RequestWorkType.auto));
      expect(motor.confirmText, 'ยืนยันทำประกัน');
      expect(motor.showsActTotal, isTrue);
      expect(PaymentRules.of(const RequestVariant(RequestProduct.ev, RequestWorkType.auto)), isA<EvPaymentRules>());
      expect(PaymentRules.of(const RequestVariant(RequestProduct.mc, RequestWorkType.auto)), isA<McPaymentRules>());
      expect(PaymentRules.of(const RequestVariant(RequestProduct.cmi, RequestWorkType.auto)).checksInsureDate, isFalse);
      expect(PaymentRules.of(const RequestVariant(RequestProduct.motor, RequestWorkType.manual)).confirmText,
          'ส่งเรื่องให้บริษัทประกัน');
    });

    test('date helpers are null-safe', () {
      expect(checkCurrentDateIsBeforeInputDate('2026-10-16', '2026-10-16'), isTrue);
      expect(checkCurrentDateIsBeforeInputDate('2026-10-17', '2026-10-16'), isFalse);
      expect(checkCurrentDateIsBeforeInputDate('2026-10-16', ''), isFalse);
      final now = DateTime(2026, 10, 16, 9);
      expect(checkDateBeforeAnotherDate(30, DateTime(2026, 11, 15), now: now), isTrue);
      expect(checkDateBeforeAnotherDate(30, DateTime(2026, 11, 16), now: now), isFalse);
    });

    test('effective-date sheet cases and messages', () {
      expect(EffectiveDateCase.of(insurerFlag: false, actDateFlag: true, actFlag: false), EffectiveDateCase.insureOnly);
      expect(EffectiveDateCase.of(insurerFlag: true, actDateFlag: false, actFlag: true), EffectiveDateCase.actOnly);
      expect(EffectiveDateCase.of(insurerFlag: false, actDateFlag: true, actFlag: true), EffectiveDateCase.insureOnly180);
      expect(EffectiveDateCase.of(insurerFlag: false, actDateFlag: false, actFlag: true), EffectiveDateCase.both);

      const cfg = EffectiveDayConfig(insureDays: 30, actDays: 60);
      final now = DateTime(2026, 10, 16, 9);
      String? v(EffectiveDateCase c, DateTime? d1, DateTime? d2) =>
          validateEffectiveDates(c: c, d1: d1, d2: d2, currentDate: '2026-10-16', config: cfg, now: now);
      expect(v(EffectiveDateCase.insureOnly, null, null), 'กรุณาเลือกวันที่คุ้มครองประกัน');
      expect(v(EffectiveDateCase.insureOnly, DateTime(2026, 10, 15), null), 'ไม่สามารถเลือกวันที่คุ้มครองประกันย้อนหลังได้');
      expect(v(EffectiveDateCase.insureOnly, DateTime(2026, 12, 1), null), 'ไม่สามารถเลือกวันเกิน  30  วันได้กรุณาเลือกใหม่');
      expect(v(EffectiveDateCase.insureOnly, DateTime(2026, 10, 16), null), isNull);
      expect(v(EffectiveDateCase.insureOnly180, DateTime(2027, 6, 1), null), 'ไม่สามารถเลือกวันเกิน 180 วันได้กรุณาเลือกใหม่');
      expect(v(EffectiveDateCase.both, DateTime(2026, 10, 20), null), 'กรุณาเลือกวันที่คุ้มครอง พ.ร.บ.');
      expect(v(EffectiveDateCase.both, DateTime(2026, 10, 20), DateTime(2027, 1, 1)),
          'ไม่สามารถเลือกวันเกิน  60  วันได้กรุณาเลือกใหม่');
    });
  });

  group('Step5Data', () {
    Map<String, dynamic> policy({String status = 'อนุมัติ', dynamic complete = '2026-10-16 10:05:03'}) => {
          'code': 200,
          'results': {
            'data': {
              'quotation_status': status,
              'cancel_reason_name': 'ลูกค้ายกเลิก',
              'VMI': {'VMI_contractId': 'C1', 'VMI_policyNumber': '', 'VMI_errorMessage': 'vmi err', 'VMI_documentUrl': 'https://doc/vmi.pdf'},
              'CMI': {'CMI_documentUrl': null},
              'api_send_date': '2026-10-15 08:00:00',
              'api_complete_date': complete,
              'payments': [
                {'payment_status': 'ชำระแล้ว', 'payment_type': 'จ่ายเต็ม', 'payment_channel': null, 'tenor': ''},
              ],
              'app_detail': [
                {'net_premium_total': '19355.289', 'act_total': '645.21', 'gross_total_net': '20000.50'},
              ],
            },
          },
        };

    test('detail + on-load policy', () {
      final d = Step5Data()..loadFromDetail(ApplicationDetail(_detail(status: 'อนุมัติ'), leadDtlId: 7));
      d.dateNow = '2026-10-16';
      expect(d.phone, '0811111111'); // phone_number null → mobile1
      expect(d.fileApplication, 'https://files/app.pdf');
      expect(d.oldVmiExpDateText, '20/10/2570');
      d.applyPolicy(policy(status: 'ส่งเรื่องให้บริษัทประกันพิจารณา'), refresh: false);
      expect(d.status, 'อนุมัติ'); // on load: the detail's status
      expect(d.onLoadPolicyStatus, 'ส่งเรื่องให้บริษัทประกันพิจารณา');
      expect(d.createdDate, '2569-10-15 08:00:00');
      expect(d.completedDate, '2569-10-16 10:05:03');
      expect(d.contractId, 'C1');
      expect(d.vmiPolicyNo, '-');
      expect(d.reason, 'ลูกค้ายกเลิก');
      expect(d.paymentChannel, '-');
      expect(d.tenor, '-');
      expect(d.cmiDocUrl, '-');
      expect(d.completedToday, isTrue);
      expect(step5CanCancel(d), isTrue);
      expect(step5PremiumRounds(d), isTrue);
      expect(step5ShowsNewRequest(d), isFalse);
    });

    test('refresh uses the policy status and skips cancel_reason_name', () {
      final d = Step5Data()..loadFromDetail(ApplicationDetail(_detail(status: 'อนุมัติ'), leadDtlId: 7));
      d.applyPolicy(policy(status: 'ยกเลิก'), refresh: false);
      d.applyPolicy(policy(status: 'ไม่อนุมัติ', complete: null), refresh: true);
      expect(d.status, 'ไม่อนุมัติ');
      expect(d.onLoadPolicyStatus, 'ยกเลิก');
      expect(step5ShowsNewRequest(d), isTrue);
      expect(d.reason, 'vmi err');
      expect(d.completedDate, '-');
      expect(d.completedToday, isFalse); // FF crashed on '-'
    });

    test('cancel rules + date helpers', () {
      expect(checkDatePage5('2569-10-16 10:00:00', '2026-10-16'), isTrue);
      expect(checkDatePage5('2569-10-15 10:00:00', '2026-10-16'), isFalse);
      expect(checkDatePage5('-', ''), isFalse);
      expect(convertToBDYearAndTime('bad'), isNull);
      final d = Step5Data()
        ..quotationType = 'auto'
        ..status = 'อยู่ระหว่างตรวจสอบสภาพรถ';
      expect(step5CanCancel(d), isTrue);
      d.quotationType = 'manual';
      expect(step5CanCancel(d), isFalse);
    });

    test('rules: new-request target and document rows', () {
      expect(Step5Rules.of(const RequestVariant(RequestProduct.ev, RequestWorkType.auto)).newRequestProduct, ProductType.ev);
      expect(Step5Rules.of(const RequestVariant(RequestProduct.mc, RequestWorkType.auto)).newRequestProduct, ProductType.mc);
      final motor = Step5Rules.of(const RequestVariant(RequestProduct.motor, RequestWorkType.auto));
      expect(motor.newRequestProduct, ProductType.motor);
      expect(Step5Rules.of(const RequestVariant(RequestProduct.cmi, RequestWorkType.auto)).showsPremiumBlocks, isFalse);

      final d = Step5Data()
        ..quotationTypeBak = 'auto'
        ..insurerShortName = 'Allianz'
        ..fileApplication = 'https://files/app.pdf';
      var rows = step5DocumentLinks(d, motor).map((e) => e.text).toList();
      expect(rows, [
        'ดาวน์โหลดเอกสาร ใบตรวจสภาพรถ SSW',
        'ดาวน์โหลดเอกสาร ใบคำขอเอาประกัน',
        'ดาวน์โหลดเอกสาร ใบคำขอสินเชื่อเป้า ง',
      ]);
      d.quotationTypeBak = 'manual';
      rows = step5DocumentLinks(d, motor).map((e) => e.text).toList();
      expect(rows.first, 'ดาวน์โหลดเอกสาร ใบตรวจสภาพรถ อลิอันซ์');
      expect(step5InstalmentCardUrl('123').startsWith('http://'), isTrue); // hidden on web (https only)
    });
  });
}
