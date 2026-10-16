import 'package:flutter_test/flutter_test.dart';
import 'package:tanjai_web_app/features/policy_request/models/application_detail.dart';
import 'package:tanjai_web_app/features/policy_request/models/request_variant.dart';
import 'package:tanjai_web_app/features/policy_request/step1/step1_data.dart';
import 'package:tanjai_web_app/features/policy_request/step1/step1_rules.dart';
import 'package:tanjai_web_app/features/policy_request/step1/step1_widgets.dart';
import 'package:tanjai_web_app/router/app_router.dart';

Map<String, dynamic> _detail({List<Map<String, dynamic>>? addresses, Map<String, dynamic> extra = const {}}) => {
      'code': 200,
      'results': {
        'data': {
          'id_type_id': '2',
          'gender': 'MALE',
          'title_th': 'นาย',
          'first_name_th': '',
          'last_name_th': 'ใจดี',
          'national_thai_id': null,
          'birth_day': '1990-05-01',
          'age': '35',
          'mobile1': '',
          'mobile2': null,
          'email1': 'a@b.co',
          'occupation_name': 'พนักงาน',
          'occupation_code': 'JB001',
          'occupation_subname': 'ธุรการ',
          'occupation_subcode': 'S01',
          'quotations': {'quotation_type_bak': 'auto'},
          'leads': [
            {
              'sub_product': 'Motor',
              'customer_type': 'บุคคลธรรมดา',
              'id_number': '1101700230708',
              'first_name': 'สมชาย',
              'phone_number': '0812345678',
              'employee_code_license': '12345',
              'employee_firstname_license': 'ก',
              'employee_licenseid_license': 'L-1',
            }
          ],
          'leads_detail': [
            {'lead_dtl_id': 7},
            {'lead_dtl_id': 8},
          ],
          'app_address': addresses ??
              [
                {'address_type': 'CURRENT', 'keyword': 'doc-kw', 'address_line1': 'doc 1', 'province_id': 10},
                {'address_type': 'REGISTER', 'keyword': 'id-kw', 'address_line1': 'id 1', 'zip_code': '10110'},
              ],
          ...extra,
        },
      },
    };

Step1Data _loaded([Map<String, dynamic>? json]) {
  final d = Step1Data()
    ..occupations = const [
      OccupationRow(code: 'JB001', name: 'พนักงาน', subCode: 'S01', subName: 'ธุรการ'),
      OccupationRow(code: 'JB001', name: 'พนักงาน', subCode: 'S02', subName: 'บัญชี'),
      OccupationRow(code: 'JB999', name: 'อื่นๆ', subCode: 'S99', subName: 'อื่นๆ'),
    ];
  d.loadFromDetail(ApplicationDetail(json ?? _detail(), leadDtlId: 8));
  return d;
}

const _okForm = Step1Form(
  idCard: '1-1017-00230-70-8',
  firstName: 'สมชาย',
  lastName: 'ใจดี',
  phone: '081-234-5678',
  age: '35',
  licenseCode: '12345',
  idCardFlag: 'N',
);

void main() {
  group('Step1Data.loadFromDetail', () {
    test('reads the step-1 fields with lead fallbacks and null as empty', () {
      final d = _loaded();
      expect(d.cardType, '1'); // not corporate → forced '1'
      expect(d.idCard, '1101700230708'); // national_thai_id null → leads id_number
      expect(d.firstName, 'สมชาย'); // '' → leads first_name
      expect(d.lastName, 'ใจดี');
      expect(d.phone, '0812345678');
      expect(d.otherPhone, ''); // FF would have 'null'
      expect(d.gender, 'MALE');
      expect(d.isMale, isTrue);
      expect(d.occupationGroup, 'พนักงาน');
      expect(d.occupationSubNames, ['ธุรการ', 'บัญชี']);
      expect(d.occupationSubCodes, ['S01', 'S02']); // FF B6: built on load too
      expect(d.licenseEmployeeId, '12345');
      expect(d.haveLicense, isTrue);
      expect(d.saved, isFalse);
    });

    test('addresses are matched by address_type (FF took last / first)', () {
      final d = _loaded();
      expect(d.idCardAddress.keyword, 'id-kw');
      expect(d.idCardAddress.zipCode, '10110');
      expect(d.docAddress.keyword, 'doc-kw');
      expect(d.docAddress.provinceId, '10');
    });

    test('without address_type: REGISTER = last, CURRENT = first', () {
      final d = _loaded(_detail(addresses: [
        {'keyword': 'first'},
        {'keyword': 'last'},
      ]));
      expect(d.idCardAddress.keyword, 'last');
      expect(d.docAddress.keyword, 'first');
    });

    test('no address keeps the FF placeholder; flags reset', () {
      final d = Step1Data()
        ..docSameAsIdCard = true
        ..saved = true;
      d.loadFromDetail(ApplicationDetail(_detail(addresses: []), leadDtlId: 8));
      expect(d.idCardAddress.keyword, kStep1AddressPh);
      expect(d.docSameAsIdCard, isFalse);
      expect(d.saved, isFalse);
    });
  });

  group('occupation pickers', () {
    test('group selection takes the group code and clears the job', () {
      final d = _loaded()..selectOccupationGroup('อื่นๆ');
      expect(d.occupationCode, 'JB999');
      expect(d.occupationSubName, '');
      expect(d.occupationSubCode, '');
      expect(d.isFreeTextOccupation, isTrue);
      d.copyFreeTextOccupation('ช่างไม้');
      expect(d.occupationSubName, 'ช่างไม้');
      expect(d.occupationGroups, ['พนักงาน', 'อื่นๆ']);
    });

    test('job selection', () {
      final d = _loaded()..selectOccupation(1);
      expect(d.occupationSubName, 'บัญชี');
      expect(d.occupationSubCode, 'S02');
    });
  });

  group('Step1Rules', () {
    test('variant → rules', () {
      expect(Step1Rules.of(const RequestVariant(RequestProduct.motor, RequestWorkType.auto)), isA<MotorStep1Rules>());
      expect(Step1Rules.of(const RequestVariant(RequestProduct.ev, RequestWorkType.auto)), isA<EvStep1Rules>());
      expect(Step1Rules.of(const RequestVariant(RequestProduct.mc, RequestWorkType.auto)), isA<McStep1Rules>());
      expect(const HouseStep1Rules().nextRoute, AppRoutes.notPorted('FireInsuranceInfoPage2'));
      expect(const MotorStep1Rules().nextRoute, AppRoutes.requestVehicle);
      expect(const CmiStep1Rules().showsLicence, isFalse);
    });

    test('blacklist id type: FF B3 fixed ("1" → "1")', () {
      const r = MotorStep1Rules();
      expect(r.blacklistIdTypeId('1'), '1');
      expect(r.blacklistIdTypeId('บัตรประชาชน'), '1');
      expect(r.blacklistIdTypeId('Passport'), '2');
    });

    test('motor validation order and messages', () {
      const r = MotorStep1Rules();
      final d = _loaded();
      expect(r.validate(d, _okForm), isNull);
      expect(r.validate(d, const Step1Form()), 'บังคับกรอกเลขผู้มีบัตรนายหน้าประกัน');
      expect(
        r.validate(d, const Step1Form(licenseCode: '1', firstName: 'x')),
        'บังคับกรอกเลขบัตร',
      );
      d.title = kStep1TitlePh;
      expect(r.validate(d, _okForm), 'บังคับเลือกคำนำหน้า');
      d.title = 'นาย';
      d.docAddress.keyword = kStep1AddressPh;
      expect(r.validate(d, _okForm), 'บังคับเลือกที่อยู่');
      d.docAddress.keyword = 'x';
      expect(
        r.validate(d, const Step1Form(idCard: '1', firstName: 'a', lastName: 'b', phone: '1', age: '1', licenseCode: '1')),
        'กรุณากดตรวจสอบเลขบัตร',
      );
      expect(
        r.validate(d, const Step1Form(
            idCard: '1', firstName: 'a', lastName: 'b', phone: '1', age: '1', licenseCode: '1', idCardFlag: 'N', email: 'bad')),
        'กรุณากรอกอีเมลให้ถูกต้อง',
      );
    });
  });

  group('save body', () {
    test('step-1 fields', () {
      final d = _loaded()..birthDatePicked = DateTime(1991, 2, 3);
      d.applyForm(_okForm);
      final f = d.saveFields(
        idTypeId: const MotorStep1Rules().saveIdTypeId(d),
        quotationId: 'Q1',
        leadDetailId: '8',
        applicationType: 'auto',
        actType: 'Motor',
      );
      expect(f['id_type_id'], '1');
      expect(f['national_thai_id'], '1101700230708');
      expect(f['gender'], 'MALE');
      expect(f['birth_day'], '1991-02-03');
      expect(f['mobile1'], '0812345678');
      expect(f['occupation_name'], 'พนักงาน');
      expect(f['employee_code_license'], '12345');
      expect(f['quotation_type'], 'auto');
      final addr = f['address'] as List;
      expect(addr[0]['address_type'], 'REGISTER');
      expect(addr[0]['keyword'], 'id-kw');
      expect(addr[1]['address_type'], 'CURRENT');
      expect(addr[1]['keyword'], 'doc-kw');
      expect((addr[0] as Map).containsKey('address_line2'), isFalse);
    });

    test('CURRENT = REGISTER when the ID-card address is used for documents', () {
      final d = _loaded()..docSameAsIdCard = true;
      final addr = d.addressJson();
      expect(addr[1]['keyword'], 'id-kw');
      expect(addr[1]['address_type'], 'CURRENT');
    });

    test('CMI extras', () {
      final d = _loaded();
      expect(const CmiStep1Rules().extraSaveFields(d), {'birth_day': '', 'customer_type': 'บุลคลธรรมดา'});
    });
  });

  group('helpers', () {
    test('age', () {
      expect(step1AgeFrom(DateTime(2000, 6, 15), now: DateTime(2026, 6, 14)), 25);
      expect(step1AgeFrom(DateTime(2000, 6, 15), now: DateTime(2026, 6, 15)), 26);
    });

    test('email', () {
      expect(step1ValidateEmail('a.b@c.co'), isTrue);
      expect(step1ValidateEmail('a@b'), isFalse);
    });

    test('id mask', () {
      expect(IdCardMaskFormatter.format('1101700230708'), '1-1017-00230-70-8');
      expect(IdCardMaskFormatter.format('11017'), '1-1017');
    });

    test('masters per row', () {
      final l = LicenseRow.listFrom({
        'results': {
          'data': [
            {'employee_id': '1', 'firstname': 'a', 'lastName': 'b', 'title': null},
          ],
        },
      });
      expect(l.single.lastName, 'b');
      expect(l.single.title, '');
      final a = AddressMasterRow.listFrom({
        'results': {
          'data': [
            {'keyword': 'k', 'subdistrict_id': 5, 'district_id': 6},
          ],
        },
      });
      expect(a.single.subdistrictId, '5');
    });
  });
}
