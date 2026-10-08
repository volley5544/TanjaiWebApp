import 'package:flutter_test/flutter_test.dart';
import 'package:tanjai_web_app/core/session/user_session.dart';
import 'package:tanjai_web_app/core/utils/ff_functions.dart';

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
}
