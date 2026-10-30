import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanjai_web_app/features/policy_request/state/policy_request_state.dart';
import 'package:tanjai_web_app/features/policy_request/models/application_detail.dart';
import 'package:tanjai_web_app/features/policy_request/models/request_variant.dart';
import 'package:tanjai_web_app/features/policy_request/step3/documents_page.dart';
import 'package:tanjai_web_app/features/policy_request/step3/step3_data.dart';
import 'package:tanjai_web_app/features/policy_request/step3/step3_rules.dart';
import 'package:tanjai_web_app/features/policy_request/step4/step4_data.dart';
import 'package:tanjai_web_app/features/policy_request/step4/step4_rules.dart';

ApplicationDetail _detail({
  String cover = 'ชั้น 1',
  String except = 'N',
  String policyFile = 'N',
  String workType = 'งานใหม่',
  String subProduct = 'Motor',
  Map<String, dynamic> doc = const {},
  Map<String, dynamic> appDetail = const {},
  Map<String, dynamic> lead = const {},
}) =>
    ApplicationDetail({
      'code': 200,
      'results': {
        'data': {
          'leads': [
            {'sub_product': subProduct, ...lead},
          ],
          'leads_detail': [
            {'lead_dtl_id': 7, 'cover_type_name': 'ชั้น 3'},
            {
              'lead_dtl_id': 8,
              'cover_type_name': cover,
              'inspection_except': except,
              'inspection_except_policy_file': policyFile,
            },
          ],
          'app_detail': [
            {'work_type': workType, ...appDetail},
          ],
          'app_document': [doc],
        },
      },
    }, leadDtlId: 8);

const _motor = RequestVariant(RequestProduct.motor, RequestWorkType.auto);
const _mc = RequestVariant(RequestProduct.mc, RequestWorkType.auto);

Step3Data _filled({String cover = 'ชั้น 1', String except = 'N', String policyFile = 'N', String sub = 'Motor', String workType = 'งานใหม่'}) {
  final d = Step3Data()
    ..loadFromDetail(_detail(cover: cover, except: except, policyFile: policyFile, subProduct: sub, workType: workType));
  d.examination = 'https://x/e';
  d.bluebook = 'https://x/b';
  d.idCard = 'https://x/i';
  for (final p in InspectionPhoto.values) {
    d.photos[p] = 'https://x/${p.name}';
  }
  return d;
}

Step3Consents _allConsents() => Step3Consents()..setAll(true);

void main() {
  group('Step3Data.loadFromDetail', () {
    test('reads the selected lead detail and app_document, null → empty', () {
      final d = Step3Data()
        ..loadFromDetail(_detail(
          doc: {
            'image_examination': 'https://x/exam',
            'image_bluebook': null,
            'image_idcard': 'null',
            'image_other': 'https://x/o1,https://x/o2',
            'image_wound1': 'https://x/w1',
            'image_wound2': '',
            'image_wound3': null,
            'image_wound4': 'https://x/w4',
            'image_accessories1': 'https://x/a1',
            'image_front': 'https://x/f',
            'image_rear': 'https://x/r',
            'old_VMI_image': '',
          },
          lead: {'old_VMI_image': 'https://x/old'},
        ));
      expect(d.coverType, 'ชั้น 1');
      expect(d.inspectionExcept, 'N');
      expect(d.workType, 'งานใหม่');
      expect(d.subProduct, 'Motor');
      expect(d.examination, 'https://x/exam');
      expect(d.bluebook, '');
      expect(d.idCard, '');
      expect(d.otherList, ['https://x/o1', 'https://x/o2']);
      expect(d.wound, ['https://x/w1', 'https://x/w4']);
      expect(d.accessories, ['https://x/a1']);
      expect(d.photos[InspectionPhoto.front], 'https://x/f');
      expect(d.photos[InspectionPhoto.rear], 'https://x/r');
      expect(d.photos[InspectionPhoto.roof], '');
      expect(d.oldVmi, 'https://x/old');
    });

    test('setMulti replaces lists; other is comma-joined', () {
      final d = Step3Data();
      d.setMulti(MultiPhotoKind.other, ['a', 'b']);
      d.setMulti(MultiPhotoKind.wound, ['w']);
      expect(d.other, 'a,b');
      expect(d.multi(MultiPhotoKind.wound), ['w']);
      expect(Step3Data().otherList, isEmpty);
    });
  });

  group('Step3Consents', () {
    test('all / privacy exclusivity / ok', () {
      final c = Step3Consents();
      expect(c.ok, isFalse);
      c.setAll(true);
      expect(c.ok, isTrue);
      c.setPrivacyCancel(true);
      expect(c.privacy, isFalse);
      expect(c.ok, isTrue);
      c.setAll(false);
      expect(c.ok, isFalse);
      expect(c.privacyCancel, isTrue); // untouched on uncheck (FF)
      expect(c.toFields(), {'sensitive_consent': '0', 'privacy_consent': '0', 'sanction_consent': '0'});
    });
  });

  group('Step3Rules', () {
    test('motor ชั้น 1 not waived → VIM1: 9 photos required and sent', () {
      final r = Step3Rules.of(_motor);
      final d = _filled();
      expect(r.saveKind(d), Step3SaveKind.vim1);
      expect(r.showsInspection(d), isTrue);
      expect(r.showsOldPolicy(d), isTrue);
      expect(r.validate(d, Step3Consents()), kStep3MissingConsent);
      d.photos[InspectionPhoto.roof] = '';
      expect(r.validate(d, _allConsents()), kStep3MissingPhotos);
      d.photos[InspectionPhoto.roof] = 'https://x/roof';
      expect(r.validate(d, _allConsents()), isNull);
      final f = r.saveFields(d, _allConsents(), quotationId: 'Q1', leadDtlId: '8');
      expect(f['quotation_id'], 'Q1');
      expect(f['lead_dtl_id'], '8');
      expect(f['image_front'], 'https://x/front');
      expect(f['image_roof'], 'https://x/roof');
      expect(f['image_examination'], 'https://x/e');
      expect(f['sensitive_consent'], '1');
      expect(f.containsKey('old_VMI_image'), isFalse);
      expect(f.containsKey('sub_product'), isFalse);
    });

    test('motor ชั้น 3 → OtherVIM: exam optional, old policy checked, no photos', () {
      final r = Step3Rules.of(_motor);
      final d = _filled(cover: 'ชั้น 3')..examination = '';
      expect(r.saveKind(d), Step3SaveKind.otherVim);
      expect(r.showsInspection(d), isFalse);
      expect(r.showsOldPolicy(d), isFalse);
      expect(r.examinationRequired(d), isFalse);
      expect(r.validate(d, _allConsents()), kStep3MissingOldPolicy);
      d.oldVmi = 'https://x/old';
      expect(r.validate(d, _allConsents()), isNull);
      final f = r.saveFields(d, _allConsents(), quotationId: 'Q', leadDtlId: '8');
      expect(f['old_VMI_image'], 'https://x/old');
      expect(f.containsKey('image_front'), isFalse);
    });

    test('motor ชั้น 1 with inspection waived → OtherVIM; policy file waived skips old policy', () {
      final r = Step3Rules.of(const RequestVariant(RequestProduct.ev, RequestWorkType.auto));
      final d = _filled(except: 'Y', policyFile: 'Y');
      expect(r.saveKind(d), Step3SaveKind.otherVim);
      expect(r.validate(d, _allConsents()), isNull);
    });

    test('renewal → renew button, ID only', () {
      final r = Step3Rules.of(_motor);
      final d = _filled(workType: 'งานต่ออายุ')..bluebook = '';
      expect(r.saveKind(d), Step3SaveKind.renew);
      expect(r.showsBluebook(d), isFalse);
      expect(r.showsMultiPhotos(d), isFalse);
      expect(r.validate(d, _allConsents()), isNull);
      final f = r.saveFields(d, _allConsents(), quotationId: 'Q', leadDtlId: '8');
      expect(f['sub_product'], 'Motor');
      expect(f['image_bluebook'], '');
    });

    test('MC → renew button: blue book required and sent', () {
      final r = Step3Rules.of(_mc);
      final d = _filled(sub: 'MC')..bluebook = '';
      expect(r.saveKind(d), Step3SaveKind.renew);
      expect(r.showsExamination(d), isFalse);
      expect(r.showsInspectionFormLink, isFalse);
      expect(r.validate(d, _allConsents()), kStep3MissingPhotos);
      d.bluebook = 'https://x/b';
      expect(r.validate(d, _allConsents()), isNull);
      final f = r.saveFields(d, _allConsents(), quotationId: 'Q', leadDtlId: '8');
      expect(f['sub_product'], 'MC');
      expect(f['image_bluebook'], 'https://x/b');
      expect(f['image_idcard'], 'https://x/i');
    });

    test('CMI sends the blue book and saves step 4 on next', () {
      final r = Step3Rules.of(const RequestVariant(RequestProduct.cmi, RequestWorkType.auto));
      final d = _filled(sub: 'CMI');
      expect(r.saveFields(d, _allConsents(), quotationId: 'Q', leadDtlId: '8')['image_bluebook'], 'https://x/b');
      expect(r.nextSavesStep4, isTrue);
      expect(r.showsInspection(d), isFalse);
    });

    test('file_application from the save response', () {
      expect(
        step3FileApplication({
          'results': {
            'data': {
              'app_document': [
                {'file_application': null},
                {'file_application': 'https://x/app.pdf'},
              ],
            },
          },
        }),
        'https://x/app.pdf',
      );
      expect(step3FileApplication({'code': 200}), '');
    });
  });

  group('Step4', () {
    test('loadFromDetail: documents, flagRenew fallback, null → empty', () {
      final d = Step4Data()
        ..loadFromDetail(_detail(
          doc: {
            'image_application': 'https://x/a',
            'file_loan_application_register': 'null',
            'file_cancel_loan': 'https://x/c',
            'power_of_attorney': null,
            'id_card_power_of_attorney': 'https://x/id',
            'image_application_2': 'https://x/a2',
          },
          lead: {'flg_renew': '0'},
        ));
      expect(d.flagRenew, '0');
      expect(d.doc(PaymentDocument.application), 'https://x/a');
      expect(d.doc(PaymentDocument.loanApplication), '');
      expect(d.doc(PaymentDocument.powerOfAttorney), '');
      expect(d.imageApplication2, 'https://x/a2');

      final renew = Step4Data()..loadFromDetail(_detail(appDetail: {'flg_renew': '1'}, lead: {'flg_renew': '0'}));
      expect(renew.flagRenew, '1');
    });

    test('validate order and messages', () {
      const r = MotorStep4Rules();
      final d = Step4Data()..flagRenew = '0';
      expect(r.validate(d), kStep4MissingApplication);
      d.flagRenew = '1';
      expect(r.showsApplicationForm(d), isFalse);
      expect(r.validate(d), kStep4MissingLoanApplication);
      d.docs[PaymentDocument.loanApplication] = 'u';
      expect(r.validate(d), kStep4MissingDocument);
      d.docs[PaymentDocument.cancelLoan] = 'u';
      d.docs[PaymentDocument.powerOfAttorney] = 'u';
      expect(r.validate(d), kStep4MissingDocument);
      d.docs[PaymentDocument.idCardPowerOfAttorney] = 'u';
      expect(r.validate(d), isNull);
      // flagRenew neither '0' nor '1': row shown because it is required.
      d.flagRenew = '';
      expect(r.showsApplicationForm(d), isTrue);
      expect(r.validate(d), kStep4MissingApplication);
    });

    test('form name per product', () {
      expect(Step4Rules.of(_motor).installmentFormName, 'CTV');
      expect(Step4Rules.of(const RequestVariant(RequestProduct.ev, RequestWorkType.auto)).installmentFormName, 'CTV');
      expect(Step4Rules.of(_mc).installmentFormName, 'Motor');
    });

    test('save fields', () {
      final d = Step4Data()
        ..docs[PaymentDocument.application] = 'a'
        ..docs[PaymentDocument.loanApplication] = 'l'
        ..docs[PaymentDocument.cancelLoan] = 'c'
        ..docs[PaymentDocument.powerOfAttorney] = 'p'
        ..docs[PaymentDocument.idCardPowerOfAttorney] = 'i'
        ..imageApplication2 = 'a2';
      final f = const MotorStep4Rules()
          .saveFields(d, fullPayment: false, quotationId: 'Q', leadDtlId: '8', subProduct: 'Motor');
      expect(f, {
        'quotation_id': 'Q',
        'lead_dtl_id': '8',
        'payment_type': 'ผ่อนชำระ',
        'image_application': 'a',
        'file_loan_application_register': 'l',
        'file_cancel_loan': 'c',
        'power_of_attorney': 'p',
        'id_card_power_of_attorney': 'i',
        'image_application_2': 'a2',
        'sub_product': 'Motor',
      });
      expect(
        const MotorStep4Rules()
            .saveFields(d, fullPayment: true, quotationId: 'Q', leadDtlId: '8', subProduct: 'Motor')['payment_type'],
        'จ่ายเต็ม',
      );
    });

    test('InsurerConfig2 payment options', () {
      final c = InsurerPaymentConfig.fromFirestore({
        'InsurerFullPayment': ['TNI'],
        'InsurerInstallment': ['AXA'],
        'renewInstallment': true,
        'canInstallmentList': ['Programmer'],
        'canInstallmentListEmployee': ['12345'],
        'canInstallmentLevel': ['สาขา'],
        'checkInstallmentVmi1': ['VIRIYAH'],
        'checkInstallmentVmi3': ['DEVES'],
      });
      expect(c.showsFullPayment('TNI'), isFalse);
      expect(c.showsFullPayment('VIRIYAH'), isTrue);
      bool inst({String insurer = 'VIRIYAH', String renew = '0', String code = 'VMI1', String pos = '', String emp = '', String level = ''}) =>
          c.showsInstallment(insurer: insurer, flagRenew: renew, coverTypeCode: code, positionName: pos, employeeId: emp, level: level);
      expect(inst(), isFalse); // no permission
      expect(inst(pos: 'Programmer'), isTrue);
      expect(inst(emp: '12345'), isTrue);
      expect(inst(level: 'สาขา'), isTrue);
      expect(inst(level: 'สาขา', code: 'VMI3'), isFalse); // insurer not in the VMI3 list
      expect(inst(level: 'สาขา', code: 'CMI'), isTrue); // other codes → true
      expect(inst(insurer: 'AXA', level: 'สาขา', code: 'CMI'), isFalse);
      expect(inst(renew: '1', code: 'VMI3'), isTrue); // renew + renewInstallment: only InsurerInstallment
      expect(inst(insurer: 'AXA', renew: '1'), isFalse);
      // Empty config (unreadable): full payment shown, installment needs permission.
      const empty = InsurerPaymentConfig();
      expect(empty.showsFullPayment('X'), isTrue);
      expect(
        empty.showsInstallment(insurer: 'X', flagRenew: '0', coverTypeCode: 'VMI1', positionName: 'p', employeeId: 'e', level: 'l'),
        isFalse,
      );
    });

    test('save result', () {
      final r = Step4SaveResult.fromJson({
        'code': 200,
        'results': {
          'data': {
            'payment': {
              'payment_type': 'ผ่อนชำระ',
              'net_premium_total': 1000,
              'installment': [
                {'tenor': '3'},
              ],
            },
          },
        },
      });
      expect(r.paymentType, 'ผ่อนชำระ');
      expect(r.netPremiumTotal, '1000');
      expect(r.status, '');
      expect(r.installments.single['tenor'], '3');
    });
  });

  testWidgets('DocumentsPage renders motor ชั้น 1 (map, consents, no next before save)', (tester) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = PolicyRequestState.instance..start(quotationId: 'Q1', leadDtlId: 8);
    state.step3.loadFromDetail(_detail());
    await tester.pumpWidget(const MaterialApp(home: DocumentsPage()));
    await tester.pump();
    expect(find.text('3. เอกสารประกอบ'), findsOneWidget);
    expect(find.text('ใบตรวจสภาพรถฟอร์มศรีสวัสดิ์'), findsOneWidget);
    expect(find.text('ถ่ายรูปทรัพย์สิน'), findsOneWidget);
    expect(find.text('ยินยอมทั้งหมด'), findsOneWidget);
    expect(find.text('ถัดไป'), findsNothing);
  });
}
