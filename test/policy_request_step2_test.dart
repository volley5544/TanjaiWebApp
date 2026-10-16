import 'package:flutter_test/flutter_test.dart';
import 'package:tanjai_web_app/features/policy_request/models/application_detail.dart';
import 'package:tanjai_web_app/features/policy_request/models/request_variant.dart';
import 'package:tanjai_web_app/features/policy_request/step2/beneficiary_page.dart';
import 'package:tanjai_web_app/features/policy_request/step2/step2_data.dart';
import 'package:tanjai_web_app/features/policy_request/step2/step2_rules.dart';
import 'package:tanjai_web_app/router/app_router.dart';

const motor = RequestVariant(RequestProduct.motor, RequestWorkType.auto);
const ev = RequestVariant(RequestProduct.ev, RequestWorkType.auto);
const mc = RequestVariant(RequestProduct.mc, RequestWorkType.auto);

Map<String, dynamic> detailJson({String evFlag = '', Object? appBattery, Object? appDriver}) => {
      'code': 200,
      'results': {
        'data': {
          'car_registration': '1กข1234',
          'body_number': 'MR0ABC',
          'engine_number': '2GD123',
          'seat': null,
          'cc': '',
          'horsepower': '150.00',
          'weight': '1500.00',
          'make_year': '2020',
          'registration_code': '',
          'registration_province': null,
          'beneficiary_name': 'ธนาคาร ก',
          'driver_type': '',
          'accessory_flg': '1',
          'act_flg': '0',
          'ev_flag': evFlag,
          'car_motor': ['M1', 'M2'],
          'app_battery': appBattery,
          'app_driver': appDriver,
          'leads': [
            {
              'car_type': 'รถเก๋ง',
              'car_type_detail': 'รถเก๋ง',
              'car_brand_name': 'TOYOTA',
              'car_brand_id': '10',
              'car_model_name': 'YARIS',
              'car_model_id': '99',
              'car_registration_year': '2019',
              'car_province_code': '10',
              'car_province_name': 'กรุงเทพมหานคร',
              'vehicle_id': 1,
              'vehicle_code': '110',
              'vehicle_name': 'รถยนต์นั่งส่วนบุคคล',
              'driver_type': '0',
              'flg_renew': '0',
              'old_VMI_policyNumber': null,
              'old_VMI_expriedDate': '',
              'customer_type': 'บุคคลธรรมดา',
              'sub_product': 'Motor',
            },
          ],
          'app_detail': [
            {
              'seat': '5',
              'effective_date_insure': '2026-11-01',
              'effective_date_act': '',
              'branch_code': 'B01',
              'branch_name': 'สาขา 1',
              'flg_renew': '',
              'work_type': 'งานใหม่',
            },
          ],
          'leads_detail': [
            {'lead_dtl_id': 7, 'cc': '1497.00', 'accessory_total': '20000'},
            {'lead_dtl_id': 8, 'cc': '999', 'accessory_total': '1'},
          ],
        },
      },
    };

Step2Data loaded({String evFlag = '', Object? appBattery, Object? appDriver}) => Step2Data()
  ..loadFromDetail(ApplicationDetail(detailJson(evFlag: evFlag, appBattery: appBattery, appDriver: appDriver), leadDtlId: 7));

const fullForm = Step2Form(
  plate: '1กข-1234',
  chassis: 'mr0-abc',
  engine: '2gd 123',
  seats: '5',
  size: '1497',
  weight: '1500',
);

Map<String, dynamic> fieldsOf(Step2Rules r, Step2Data d, {bool branchRequired = false}) => r.saveFields(
      d,
      quotationId: 'Q1',
      leadDtlId: '7',
      subProduct: 'Motor',
      ownBranchCode: 'OWN',
      ownBranchName: 'สาขาตัวเอง',
      branchRequired: branchRequired,
    );

void main() {
  group('Step2Data.loadFromDetail', () {
    test('reads the vehicle / choice / branch fields like FF step 1', () {
      final d = loaded();
      expect(d.vehicleType, 'รถเก๋ง');
      expect(d.brandName, 'TOYOTA');
      expect(d.modelId, '99');
      expect(d.carRegis, '1กข1234');
      expect(d.carSeat, '5'); // app_detail seat first
      expect(d.sizeCar, '1497.00'); // data cc '' → leads_detail[LD].cc
      expect(d.regisYear, '2019');
      expect(d.productYear, '2020');
      expect(d.provinceCode, '10');
      expect(d.provinceName, 'กรุงเทพมหานคร');
      expect(d.vehicleUsage, '110 รถยนต์นั่งส่วนบุคคล');
      expect(d.vehicleId, '1');
      expect(d.accessory, '20000');
      expect(d.accessoryProtect, Step2Data.kAccessoryProtect);
      expect(d.actOfLegislation, Step2Data.kActExcluded);
      expect(d.driverType, '0'); // data '' → leads[0]
      expect(d.effectiveDateInsure, '2026-11-01');
      expect(d.branchCode, 'B01');
      expect(d.flagRenew, '0');
      expect(d.leadFlagRenew, isFalse);
      expect(d.oldVmi, ''); // null → '' (FF 'null')
      expect(d.workType, 'งานใหม่');
      expect(d.carMotor, isEmpty); // non-EV
      expect(d.drivers, [Step2Data.emptyDriver()]);
      expect(d.batteries, [Step2Data.emptyBattery()]);
      expect(d.saved, isFalse);
    });

    test('EV: motors and batteries (values stringified)', () {
      final d = loaded(evFlag: 'Y', appBattery: [
        {'battery_id': 3, 'battery_number': 'B1', 'battery_price': null},
      ]);
      expect(d.carMotor, ['M1', 'M2']);
      expect(d.batteries, [
        {'battery_id': '3', 'battery_number': 'B1'},
      ]);
    });

    test('first driver completeness', () {
      final d = loaded(appDriver: [
        {
          'first_name_th': 'ก',
          'last_name_th': 'ข',
          'birth_day': '1990-01-01',
          'national_thai_id': '1',
          'license_no': '2',
          'image_idcard': 'https://x/a.jpg',
          'image_license_no': 'https://x/b.jpg',
        },
      ]);
      expect(d.firstDriverComplete, isTrue);
      expect(loaded().firstDriverComplete, isFalse);
    });

    test('keepAfterReload keeps entered values, takes work type / renew flag', () {
      final d = loaded()..regisYear = '2018';
      final before = Step2Data()..copyFrom(d);
      d.loadFromDetail(ApplicationDetail(detailJson()..['results']['data']['app_detail'][0]['work_type'] = 'งานต่ออายุ',
          leadDtlId: 7));
      d.keepAfterReload(before);
      expect(d.regisYear, '2018');
      expect(d.workType, 'งานต่ออายุ');
    });
  });

  group('rules', () {
    test('titles / rows per product', () {
      expect(Step2Rules.of(motor).title, '2. ข้อมูลรถยนต์');
      expect(Step2Rules.of(ev).title, '2. ข้อมูลรถยนต์');
      expect(Step2Rules.of(mc).title, '2. ข้อมูลมอเตอร์ไซค์');
      expect(Step2Rules.of(mc).showsAccessory, isFalse);
      expect(Step2Rules.of(mc).showsAct, isFalse);
      expect(Step2Rules.of(mc).showsDriver, isFalse);
      expect(Step2Rules.of(mc).showsBeneficiary, isTrue);
      expect(Step2Rules.of(ev).sizeLabel, 'แรงม้า');
      expect(Step2Rules.of(motor).sizeLabel, 'cc');
    });

    test('motor save validation order', () {
      final r = Step2Rules.of(motor);
      final d = loaded();
      expect(r.validateSave(d, fullForm, branchRequired: false), isNull);
      expect(r.validateSave(d..branchCode = '', fullForm, branchRequired: true), 'กรุณาเลือกสาขาที่จะลงผลงาน');
      d.branchCode = 'B01';
      expect(r.validateSave(d, const Step2Form(), branchRequired: false), 'บังคับกรอกเลขทะเบียนรถ');
      d.effectiveDateInsure = '';
      expect(r.validateSave(d, fullForm, branchRequired: false), 'บังคับกรอกวันที่เริ่มคุ้มครองประกัน');
      d.effectiveDateInsure = '2026-11-01';
      Step2Form withSize(String s) => Step2Form(
            plate: fullForm.plate,
            chassis: fullForm.chassis,
            engine: fullForm.engine,
            seats: fullForm.seats,
            size: s,
            weight: fullForm.weight,
          );
      expect(r.validateSave(d, withSize(''), branchRequired: false), 'บังคับกรอกขนาด');
      expect(r.validateSave(d, withSize('abc'), branchRequired: false), 'สูบ (cc) ไม่ถูกต้องกรุณากรอกใหม่');
      expect(r.validateSave(d, withSize('500'), branchRequired: false), 'สูบ (cc) ไม่ถูกต้องกรุณากรอกใหม่');
      expect(r.validateSave(d, withSize('0.5'), branchRequired: false), isNull);
      // Truck: size not checked.
      expect(r.validateSave(d..vehicleType = MotorStep2Rules.truck, withSize(''), branchRequired: false), isNull);
      d.vehicleType = 'รถเก๋ง';
      expect(r.validateSave(d..accessoryProtect = '', fullForm, branchRequired: false), 'บังคับเลือกอุปกรณ์เสริม');
      d.accessoryProtect = Step2Data.kAccessoryNoProtect;
      expect(r.validateSave(d..actOfLegislation = '', fullForm, branchRequired: false), 'บังคับเลือก พ.ร.บ');
      d.actOfLegislation = Step2Data.kActIncluded;
      expect(r.validateSave(d..productYear = '', fullForm, branchRequired: false), 'กรุณาเลือกปีที่ผลิต');
      d.productYear = '2020';
      const longPlate = Step2Form(plate: '12345678901', chassis: 'a', engine: 'b', seats: '1', size: '1000', weight: '1');
      expect(r.validateSave(d, longPlate, branchRequired: false), 'ทะเบียนรถเกิน 10 ตัว กรุณากรอกใหม่');
      expect(r.validateSave(d..regisYear = '', fullForm, branchRequired: false), 'กรุณากรอกปีจดทะเบียน');
    });

    test('EV: horsepower checks', () {
      final r = Step2Rules.of(ev);
      final d = loaded(evFlag: 'Y');
      const f = Step2Form(plate: 'a', chassis: 'b', engine: 'c', seats: '5', size: '', weight: '1');
      expect(r.validateSave(d, f, branchRequired: false), 'บังคับกรอกแรงม้า');
      const bad = Step2Form(plate: 'a', chassis: 'b', engine: 'c', seats: '5', size: '-1', weight: '1');
      expect(r.validateSave(d, bad, branchRequired: false), 'แรงม้า ไม่ถูกต้องกรุณากรอกใหม่');
      const ok = Step2Form(plate: 'a', chassis: 'b', engine: 'c', seats: '5', size: '150', weight: '1');
      expect(r.validateSave(d, ok, branchRequired: false), isNull);
    });

    test('MC: no accessory / พ.ร.บ. / production year / numeric size checks', () {
      final r = Step2Rules.of(mc);
      final d = loaded()
        ..accessoryProtect = ''
        ..actOfLegislation = ''
        ..productYear = '';
      const f = Step2Form(plate: 'a', chassis: 'b', engine: 'c', seats: '2', size: 'abc', weight: '100');
      expect(r.validateSave(d, f, branchRequired: false), isNull);
      expect(r.validateSave(d..beneficiaryName = '', f, branchRequired: false), 'บังคับเลือกผู้รับผลประโยชน์');
    });

    test('next validation + write-back is cleaned', () {
      final r = Step2Rules.of(motor);
      final d = loaded();
      expect(r.validateNext(d, const Step2Form(plate: 'a')), 'บังคับกรอกเลขตัวถัง');
      expect(r.validateNext(d, fullForm), isNull);
      d.applyNextTexts(fullForm);
      expect(d.carRegis, '1กข1234');
      expect(d.bodyNumber, 'MR0ABC');
      expect(d.engineNumber, '2GD123');
    });

    test('next route', () {
      expect(Step2Rules.of(motor).nextRoute, AppRoutes.requestDocuments);
      expect(
        Step2Rules.of(const RequestVariant(RequestProduct.motor, RequestWorkType.manual)).nextRoute,
        AppRoutes.notPorted('InsuranceInfoPage31'),
      );
    });
  });

  group('save fields', () {
    test('motor', () {
      final r = Step2Rules.of(motor);
      final d = loaded();
      r.applyForm(d, fullForm);
      final f = fieldsOf(r, d);
      expect(f['car_registration'], '1กข1234');
      expect(f['body_number'], 'MR0ABC');
      expect(f['engine_number'], '2GD123');
      expect(f['cc'], '1497');
      expect(f['horsepower'], '0');
      expect(f['accessory_flg'], '1');
      expect(f['accessory_total'], '20000');
      expect(f['act_flg'], '0');
      expect(f['branch_code'], 'OWN');
      expect(f['branch_name'], 'สาขาตัวเอง');
      expect(f['registration_province'], 'กรุงเทพมหานคร');
      expect(f['car_province_code'], '10');
      expect(f['registration_year'], '2019');
      expect(f['make_year'], '2020');
      expect(f['flg_renew'], '0');
      expect(f['sub_product'], 'Motor');
      expect(f['app_driver'], [Step2Data.emptyDriver()]);
      expect(f.containsKey('app_battery'), isFalse); // template {} kept
      expect(f['battery_number_2'], '');
      expect(f['car_motor'], isEmpty);
      expect(fieldsOf(r, d, branchRequired: true)['branch_code'], 'B01');
    });

    test('EV', () {
      final r = Step2Rules.of(ev);
      final d = loaded(evFlag: 'Y');
      r.applyForm(d, fullForm);
      final f = fieldsOf(r, d);
      expect(f['cc'], '0');
      expect(f['horsepower'], '1497');
      expect(f['app_battery'], [Step2Data.emptyBattery()]);
      expect(f['car_motor'], ['M1', 'M2']);
      expect(f['battery_number'], '');
    });

    test('MC: accessory_flg 0', () {
      final r = Step2Rules.of(mc);
      final d = loaded();
      r.applyForm(d, fullForm);
      expect(fieldsOf(r, d)['accessory_flg'], '0');
    });
  });

  group('helpers', () {
    test('years', () {
      final now = DateTime(2026, 10, 16);
      expect(currentYearBE(now), 2569);
      expect(regisYearItems(now).first, '2569');
      expect(regisYearItems(now).last, '2500');
      expect(productYearItems(now).first, '2026');
      expect(productYearItems(now).last, '1957');
      expect(regisYearText('2019'), '2562');
      expect(regisYearText('null'), 'null');
    });

    test('effective days', () {
      final now = DateTime(2026, 10, 16, 9);
      expect(isWithinEffectiveDays(DateTime(2026, 10, 26), 10, now), isTrue);
      expect(isWithinEffectiveDays(DateTime(2026, 10, 27), 10, now), isFalse);
      expect(isWithinEffectiveDays(DateTime(2099), null, now), isTrue);
      expect(effectiveDaysFrom({'effective_days_insure': 360, 'effective_days_act': 9999}), (insure: 360, act: 9999));
      expect(effectiveDaysFrom(null), (insure: null, act: null));
    });

    test('misc', () {
      expect(removeDotInString('1497.00'), '1497');
      expect(removeDotInString('abc'), 'abc');
      expect(showDateBESafe('2026-11-01'), '01/11/2569');
      expect(showDateBESafe('x'), 'x');
      expect(carTypeImage('รถเก๋ง').width, 90);
      expect(carTypeImage('กระบะต่อเติมไม่เกินหัวเก๋ง').url, '-');
      expect(carTypeImage('???').width, 0);
      expect(
        financeOptions({
          'results': {
            'data': [
              {'beneficiary_name': 'A'},
              {'beneficiary_name': null},
              {'beneficiary_name': 'B'},
            ],
          },
        }),
        ['A', 'B', 'อื่นๆ'],
      );
    });
  });
}
