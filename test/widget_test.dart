import 'package:flutter_test/flutter_test.dart';
import 'package:tanjai_web_app/core/session/user_session.dart';
import 'package:tanjai_web_app/core/utils/ff_functions.dart';
import 'package:tanjai_web_app/core/utils/tel_link.dart';
import 'package:tanjai_web_app/features/quotation_list/models/lead_detail_item.dart';
import 'package:tanjai_web_app/features/quotation_list/models/lead_history.dart';
import 'package:tanjai_web_app/features/quotation_list/models/quotation_lead.dart';

void main() {
  group('ff_functions', () {
    test('showNumberWithComma truncates to 2 decimals like FF', () {
      expect(showNumberWithComma('1234'), '1,234.00');
      expect(showNumberWithComma('1234.5'), '1,234.50');
      expect(showNumberWithComma('1234567.899'), '1,234,567.89');
      expect(showNumberWithComma('abc'), 'abc');
      expect(showNumberWithComma(''), '');
    });

    test('checkIdCard validates the Thai ID checksum', () {
      expect(checkIdCard('1101700230708'), isTrue);
      expect(checkIdCard('1101700230704'), isFalse);
      expect(checkIdCard('123'), isFalse);
    });

    test('showDateBE converts to Buddhist year', () {
      expect(showDateBE('2026-10-08'), '08/10/2569');
    });

    test('generateInsuranceVehicleTypeDropdown keeps FF format', () {
      expect(generateInsuranceVehicleTypeDropdown(['110'], ['A'], ['เก๋ง']), ['110 A-เก๋ง']);
    });

    test('createGarageTypeCodeList maps names to codes', () {
      expect(createGarageTypeCodeList(['ซ่อมอู่', 'ซ่อมห้าง']), ['COMPANY', 'DEALER']);
    });
  });

  group('UserSession', () {
    test('accepts well-formed launch params and rejects injected values', () {
      final s = UserSession.instance;
      s.loadFromLaunchUri(Uri.parse(
        'https://x.web.app/motor?token=abc.def-123&empId=E001&firstName=%E0%B8%AA%E0%B8%A1%E0%B8%8A%E0%B8%B2%E0%B8%A2'
        '&phone=0812345678&branchName=%3Cscript%3E',
      ));
      expect(s.accessToken, 'abc.def-123');
      expect(s.employeeId, 'E001');
      expect(s.firstName, 'สมชาย');
      expect(s.phone, '0812345678');
      expect(s.branchName, ''); // rejected: contains < >
      expect(s.isSignedIn, isTrue);
    });
  });

  group('quotation list models', () {
    test('QuotationLead reads each card from its own object (nulls stay null)', () {
      final list = QuotationLeadList.fromJson({
        'statusCode': 200,
        'results': {
          'statusCode': 200,
          'info': [
            {'lead_id': 84, 'first_name': 'สมชาย', 'last_name': null, 'flag_expired': 0, 'ref_renew_id': null},
            {'lead_id': '85', 'first_name': null, 'phone_number': '0812345678', 'flag_expired': '1'},
          ],
        },
      });
      expect(list.leads.length, 2);
      expect(list.leads[0].leadId, 84);
      expect(list.leads[0].lastName, isNull);
      expect(checkNullValueAndReturn(list.leads[0].lastName), '-');
      expect(list.leads[0].flagExpired, 0);
      expect(list.leads[1].leadId, 85);
      expect(list.leads[1].phoneNumber, '0812345678');
      expect(list.leads[1].flagExpired, 1);
    });

    test('LeadByIdResult parses watingInfo and the waiting-info count', () {
      final r = LeadByIdResult.fromJson({
        'results': {
          'statusCode': 200,
          'counting': {'status_waiting_info': 1},
          'info': {
            'watingInfo': [
              {
                'quotation_id': 320,
                'lead_dtl_id': 825,
                'sub_product': 'Motor',
                'pdf_quotation': 'https://x.test/q.pdf',
                'payment_status_check': false,
                'insurer_status': null,
                'video_url': '',
              },
            ],
          },
        },
      });
      expect(r.waitingInfoCount, 1);
      final item = r.waitingInfo.single;
      expect(item.quotationId, '320');
      expect(item.leadDtlId, 825);
      expect(item.insurerStatus, 'null'); // FF getJsonField(...).toString()
      expect(item.pdfQuotationList, ['https://x.test/q.pdf']);
      expect(item.isCmi, isFalse);
      expect(r.videoUrls, ['']);
    });

    test('LeadByIdResult without watingInfo is empty', () {
      final r = LeadByIdResult.fromJson({
        'results': {
          'counting': {'status_waiting_info': 0},
          'info': {'payments': []},
        },
      });
      expect(r.waitingInfoCount, 0);
      expect(r.waitingInfo, isEmpty);
    });

    test('pdf_quotation list / null', () {
      expect(const LeadDetailItem({'pdf_quotation': ['a', 'b']}).pdfQuotationList, ['a', 'b']);
      expect(const LeadDetailItem({}).pdfQuotationList, isEmpty);
      expect(const LeadDetailItem({}).pdfQuotationText, 'null');
    });

    test('LeadHistoryEntry keeps FF toString of nulls', () {
      final h = LeadHistoryEntry.listFromJson({
        'results': [
          {'status': 'ส่งเรื่องขอใบเสนอราคา', 'updated_at': '2026-10-01 10:05:00', 'name_th': 'ก', 'reason_name': null},
        ],
      });
      expect(h.single.reasonName, 'null');
      expect(h.single.status, 'ส่งเรื่องขอใบเสนอราคา');
    });

    test('telDigits keeps only digits and +', () {
      expect(telDigits('081-234 5678'), '0812345678');
      expect(telDigits('javascript:alert(1)'), '1');
    });
  });
}
