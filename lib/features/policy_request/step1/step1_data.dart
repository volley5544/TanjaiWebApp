import 'package:intl/intl.dart';

import '../../../core/utils/ff_functions.dart';
import '../data/policy_request_api.dart';
import '../models/application_detail.dart';

/// FF placeholder defaults of the step-1 FFAppState fields.
const kStep1CardTypePh = 'เลือกประเภทบัตร';
const kStep1GenderPh = 'เลือกเพศ';
const kStep1TitlePh = 'เลือกคำนำหน้าชื่อ';
const kStep1OccupationGroupPh = 'เลือกกลุ่มอาชีพ';
const kStep1AddressPh = 'กรุณากรอกที่อยู่';

/// FF blank avatar (licence photo fallback).
const kStep1BlankProfileUrl =
    'https://firebasestorage.googleapis.com/v0/b/sawad-new-ibs.appspot.com/o/blank-profile-picture-gc19a78ed8_1280.png?alt=media&token=a4b9142c-c774-492a-a5a4-caa39f16ec3c';

/// FF gender list (`FFAppState().gender`).
const kStep1Genders = ['ชาย', 'หญิง'];

bool step1IsIdCardType(String cardType) => cardType == 'บัตรประชาชน' || cardType == '1';
bool step1IsPassportType(String cardType) => cardType == 'Passport' || cardType == '2';
bool step1IsTaxIdType(String cardType) => cardType == 'TAXID' || cardType == '5';

/// '' / the FF placeholder → "no address".
bool step1HasAddressText(String v) => v.isNotEmpty && v != kStep1AddressPh;

/// FF `calculateAgeFromDatetime` (whole years, birthday-aware).
int step1AgeFrom(DateTime birth, {DateTime? now}) {
  final n = now ?? DateTime.now();
  var age = n.year - birth.year;
  if (n.month < birth.month || (n.month == birth.month && n.day < birth.day)) age--;
  return age;
}

/// FF `validateEmail`.
bool step1ValidateEmail(String email) => RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(email);

/// `results.data[]` of a master API as maps.
List<Map<String, dynamic>> _rows(dynamic json) {
  final v = jsonPathGet(json, 'results.data');
  return [
    if (v is List)
      for (final e in v)
        if (e is Map) Map<String, dynamic>.from(e),
  ];
}

String _s(Map<String, dynamic> m, String k) => m[k] == null ? '' : '${m[k]}';

/// One row of GetLicenseListCall (FF read 8 parallel `[:]` lists with
/// `withoutNulls` — a null shifted a column; the port reads each row).
class LicenseRow {
  const LicenseRow({
    required this.employeeId,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.licenseId,
    required this.expiredDate,
    required this.mobilePhone,
    required this.branchCode,
  });

  final String employeeId, title, firstName, lastName, licenseId, expiredDate, mobilePhone, branchCode;

  factory LicenseRow.fromJson(Map<String, dynamic> m) => LicenseRow(
        employeeId: _s(m, 'employee_id'),
        title: _s(m, 'title'),
        firstName: _s(m, 'firstname'),
        lastName: _s(m, 'lastName'),
        licenseId: _s(m, 'license_id'),
        expiredDate: _s(m, 'expired_date'),
        mobilePhone: _s(m, 'mobile_phone'),
        branchCode: _s(m, 'branch_code'),
      );

  static List<LicenseRow> listFrom(dynamic json) => _rows(json).map(LicenseRow.fromJson).toList();
}

/// One row of GetOccupationCall.
class OccupationRow {
  const OccupationRow({required this.code, required this.name, required this.subCode, required this.subName});

  final String code, name, subCode, subName;

  factory OccupationRow.fromJson(Map<String, dynamic> m) => OccupationRow(
        code: _s(m, 'occupation_code'),
        name: _s(m, 'occupation_name'),
        subCode: _s(m, 'occupation_subcode'),
        subName: _s(m, 'occupation_subname'),
      );

  static List<OccupationRow> listFrom(dynamic json) => _rows(json).map(OccupationRow.fromJson).toList();
}

/// One row of GetAddressMasterCall (AddAddress).
class AddressMasterRow {
  const AddressMasterRow({
    required this.keyword,
    required this.zipCode,
    required this.subdistrictName,
    required this.subdistrictId,
    required this.districtName,
    required this.districtId,
    required this.provinceName,
    required this.provinceId,
  });

  final String keyword, zipCode, subdistrictName, subdistrictId, districtName, districtId, provinceName, provinceId;

  factory AddressMasterRow.fromJson(Map<String, dynamic> m) => AddressMasterRow(
        keyword: _s(m, 'keyword'),
        zipCode: _s(m, 'zip_code'),
        subdistrictName: _s(m, 'subdistrict_name'),
        subdistrictId: _s(m, 'subdistrict_id'),
        districtName: _s(m, 'district_name'),
        districtId: _s(m, 'district_id'),
        provinceName: _s(m, 'province_name'),
        provinceId: _s(m, 'province_id'),
      );

  static List<AddressMasterRow> listFrom(dynamic json) => _rows(json).map(AddressMasterRow.fromJson).toList();

  /// FF `addAddressCallAPI` + the 8 `addAddress*` master lists: loaded once
  /// per app session.
  static List<AddressMasterRow>? cache;
}

/// One address (FF `addAddressAtIdCard*` / `addAddressSelect*` = REGISTER,
/// `addAddressForDoc*` / `addAddressSelectDoc*` = CURRENT).
class Step1Address {
  /// Search keyword shown on the cards (FF `addAddressAtIdCard` /
  /// `addAddressForDoc`; also `…SelectKeyWord`, always the same value).
  String keyword = kStep1AddressPh;
  String line1 = kStep1AddressPh;
  String line2 = kStep1AddressPh;
  String provinceId = '', provinceName = '';
  String districtId = '', districtName = '';
  String subdistrictId = '', subdistrictName = '';
  String zipCode = '';

  void reset() {
    keyword = line1 = line2 = kStep1AddressPh;
    provinceId = provinceName = districtId = districtName = subdistrictId = subdistrictName = zipCode = '';
  }

  void loadFrom(Map<String, dynamic> m) {
    keyword = _s(m, 'keyword');
    line1 = _s(m, 'address_line1');
    line2 = _s(m, 'address_line2');
    provinceId = _s(m, 'province_id');
    provinceName = _s(m, 'province_name');
    districtId = _s(m, 'district_id');
    districtName = _s(m, 'district_name');
    subdistrictId = _s(m, 'subdistrict_id');
    subdistrictName = _s(m, 'subdistrict_name');
    zipCode = _s(m, 'zip_code');
  }

  /// FF picker 'ค้นหาที่อยู่' selection (A1 / A2).
  void pick(AddressMasterRow r) {
    keyword = r.keyword;
    provinceId = r.provinceId;
    provinceName = r.provinceName;
    districtId = r.districtId;
    districtName = r.districtName;
    subdistrictId = r.subdistrictId;
    subdistrictName = r.subdistrictName;
    zipCode = r.zipCode;
  }

  /// FF `sendJsonDataAddress` entry. `address_line2` was never sent (FF B12, kept).
  Map<String, String> toJson(String type) => {
        'address_type': type,
        'address_line1': line1,
        'subdistrict_id': subdistrictId,
        'subdistrict_name': subdistrictName,
        'district_id': districtId,
        'district_name': districtName,
        'province_id': provinceId,
        'province_name': provinceName,
        'zip_code': zipCode,
        'keyword': keyword,
      };
}

/// Text-field values at 'บันทึกเตรียมข้อมูล' time (FF controllers) + the
/// blacklist results, for [Step1Rules.validate] / [Step1Data.applyForm].
class Step1Form {
  const Step1Form({
    this.idCard = '',
    this.passport = '',
    this.taxId = '',
    this.firstName = '',
    this.lastName = '',
    this.occupation = '',
    this.phone = '',
    this.otherPhone = '',
    this.email = '',
    this.age = '',
    this.licenseCode = '',
    this.idCardFlag = '',
    this.passportFlag = '',
    this.taxIdFlag = '',
  });

  final String idCard, passport, taxId, firstName, lastName, occupation, phone, otherPhone, email, age, licenseCode;

  /// `$.results.data.blacklist_flag` of the last check per ID kind ('' = not checked).
  final String idCardFlag, passportFlag, taxIdFlag;
}

/// Step 1 (customer: card, name, occupation, phones, addresses, broker licence).
///
/// Owned by `step1/`. Filled from the application detail by [loadFromDetail]
/// (called by `PolicyRequestState.applyDetail`); edited by the step's pages.
/// Replaces the FF `insuranceInfo*` / `addAddress*` step-1 FFAppState fields.
class Step1Data {
  // ---- customer ------------------------------------------------------------
  /// '1' / 'บัตรประชาชน', '2' / 'Passport', '5' / 'TAXID'.
  String cardType = kStep1CardTypePh;
  String idCard = '';

  /// 'MALE' / 'FEMALE' from the API, 'ชาย' / 'หญิง' from the picker.
  String gender = kStep1GenderPh;
  String title = kStep1TitlePh;
  String firstName = '';
  String lastName = '';

  /// 'yyyy-MM-dd' (API) — [birthDatePicked] wins when set.
  String birthDate = '';
  DateTime? birthDatePicked;
  String age = '';
  String phone = '';
  String otherPhone = '';
  String email = '';

  /// FF `isCorporate` (CMI นิติบุคคล only).
  bool isCorporate = false;

  // ---- occupation ----------------------------------------------------------
  /// FF insuranceInfoOccupationGroup (sent as `occupation_name`).
  String occupationGroup = kStep1OccupationGroupPh;

  /// FF insuranceInfoSelectOccupationName / …Code (the chosen group).
  String occupationName = '';
  String occupationCode = '';

  /// FF insuranceInfoSelectOccupationSubName / …SubCode (the group's jobs).
  List<String> occupationSubNames = [];
  List<String> occupationSubCodes = [];

  /// FF insuranceInfoSelectOccupationSubNameChoose / …CodeChoose (the job).
  String occupationSubName = '';
  String occupationSubCode = '';

  // ---- addresses -----------------------------------------------------------
  final idCardAddress = Step1Address();
  final docAddress = Step1Address();

  /// FF addAddressAtIdCardBool ("doc address = ID-card address").
  bool docSameAsIdCard = false;

  /// FF addAddressForDocBool.
  bool docSeparate = false;

  // ---- licence -------------------------------------------------------------
  String licenseEmployeeId = '';
  String licenseTitle = '';
  String licenseFirstName = '';
  String licenseLastName = '';
  String licenseId = '';
  String licenseExpiredDate = '';
  String licenseMobilePhone = '';
  String licenseImg = '';
  String licenseBranch = '';

  /// FF insuranceInfoHaveLicenseBool.
  bool haveLicense = false;

  // ---- masters (loaded by the page) ----------------------------------------
  List<LicenseRow> licenses = [];
  List<OccupationRow> occupations = [];

  /// Firestore `dataList` first doc (FF `masterDataFirebase`, passed to step 2).
  Map<String, dynamic>? dataList;

  /// FF insuranceInfoPage1SaveDataCheckBool — shows 'ถัดไป'.
  bool saved = false;

  void reset() {
    cardType = kStep1CardTypePh;
    idCard = '';
    gender = kStep1GenderPh;
    title = kStep1TitlePh;
    firstName = lastName = birthDate = age = phone = otherPhone = email = '';
    birthDatePicked = null;
    isCorporate = false;
    occupationGroup = kStep1OccupationGroupPh;
    occupationName = occupationCode = occupationSubName = occupationSubCode = '';
    occupationSubNames = [];
    occupationSubCodes = [];
    idCardAddress.reset();
    docAddress.reset();
    // FF B9: these were not reset on load (a previous flow's choice decided
    // whether CURRENT = REGISTER); the port resets them.
    docSameAsIdCard = false;
    docSeparate = false;
    clearLicence();
    haveLicense = false;
    saved = false;
  }

  void clearLicence() {
    licenseEmployeeId = licenseTitle = licenseFirstName = licenseLastName = '';
    licenseId = licenseExpiredDate = licenseMobilePhone = licenseImg = licenseBranch = '';
  }

  /// FF P1 on-load reads (spec page1 §3.2 / 3.4), step-1 fields only.
  ///
  /// FF read most values with `'${x}'`, turning a JSON null into the text
  /// `'null'` (shown as "null", passing the required checks, crashing
  /// `showDateBE`). The port reads null as '' (deliberate, spec B1).
  void loadFromDetail(ApplicationDetail d) {
    reset();
    final lead = d.lead;
    String pick(String primary, String fallback) => primary.isNotEmpty ? primary : fallback;

    isCorporate = _s(lead, 'customer_type') == 'นิติบุคคล' && d.subProduct == 'CMI';
    cardType = isCorporate ? d.s('id_type_id') : '1';
    gender = d.s('gender');
    title = d.s('title_th');

    occupationGroup = occupationName = d.s('occupation_name');
    occupationCode = d.s('occupation_code');
    occupationSubName = d.s('occupation_subname');
    occupationSubCode = d.s('occupation_subcode');

    idCard = pick(d.s('national_thai_id'), _s(lead, 'id_number'));
    firstName = pick(d.s('first_name_th'), _s(lead, 'first_name'));
    lastName = pick(d.s('last_name_th'), _s(lead, 'last_name'));
    birthDate = d.s('birth_day');
    age = d.s('age');
    phone = pick(d.s('mobile1'), _s(lead, 'phone_number'));
    otherPhone = d.s('mobile2');
    email = d.s('email1');

    licenseFirstName = _s(lead, 'employee_firstname_license');
    licenseLastName = _s(lead, 'employee_lastname_license');
    licenseMobilePhone = _s(lead, 'employee_phone_number_license');
    licenseEmployeeId = _s(lead, 'employee_code_license');
    licenseImg = _s(lead, 'employee_licenseimg_license');
    licenseExpiredDate = _s(lead, 'employee_licenseexp_license');
    licenseId = _s(lead, 'employee_licenseid_license');
    haveLicense = licenseEmployeeId.isNotEmpty;

    // FF took REGISTER = last app_address[], CURRENT = first, while the save
    // sends [REGISTER, CURRENT] — the two could swap on reload (spec B11).
    // The port matches `address_type` and falls back to FF's last / first.
    // No address at all → the FF defaults stay ('กรุณากรอกที่อยู่').
    final addrs = d.addresses;
    if (addrs.isNotEmpty) {
      Map<String, dynamic>? byType(String t) {
        for (final a in addrs) {
          if (_s(a, 'address_type').toUpperCase() == t) return a;
        }
        return null;
      }

      idCardAddress.loadFrom(byType('REGISTER') ?? addrs.last);
      docAddress.loadFrom(byType('CURRENT') ?? addrs.first);
    }
    buildOccupationSubList();
  }

  /// FF §3.4: the chosen group's job list. FF rebuilt only the names (spec
  /// B6 — the 'อาชีพ' picker then read a stale code list); the port builds
  /// both. Needs [occupations] (no-op before the master is loaded).
  void buildOccupationSubList() {
    if (occupationName.isEmpty) return;
    final rows = occupations.where((o) => o.name == occupationName).toList();
    occupationSubNames = rows.map((o) => o.subName).toList();
    occupationSubCodes = rows.map((o) => o.subCode).toList();
  }

  /// FF picker P4 'กลุ่มอาชีพ' — distinct group names (first-seen order).
  List<String> get occupationGroups => removeDupeInList(occupations.map((o) => o.name).toList());

  /// FF P4 selection. FF took the code from `removeDupeInList(codes)[i]`
  /// (right only if codes and names are 1:1) and left the job code set (spec
  /// B7); the port takes the group's own code and clears the job code too.
  void selectOccupationGroup(String name) {
    occupationGroup = occupationName = name;
    final row = occupations.where((o) => o.name == name).firstOrNull;
    occupationCode = row?.code ?? '';
    final rows = occupations.where((o) => o.name == name).toList();
    occupationSubNames = rows.map((o) => o.subName).toList();
    occupationSubCodes = rows.map((o) => o.subCode).toList();
    occupationSubName = '';
    occupationSubCode = '';
  }

  /// FF P5 'อาชีพ' selection.
  void selectOccupation(int i) {
    occupationSubName = occupationSubNames[i];
    occupationSubCode = i < occupationSubCodes.length ? occupationSubCodes[i] : '';
  }

  /// FF P2 'เพศ' selection — resets the title.
  void selectGender(String g) {
    gender = g;
    title = kStep1TitlePh;
  }

  bool get isMale => gender == 'MALE' || gender == 'ชาย';

  /// Logged-in employee / typed code in the licence master.
  LicenseRow? licenceOf(String employeeId) =>
      employeeId.isEmpty ? null : licenses.where((l) => l.employeeId == employeeId).firstOrNull;

  /// FF: the 8 licence fields from the master row (image set separately).
  void applyLicence(LicenseRow r) {
    haveLicense = true;
    licenseEmployeeId = r.employeeId;
    licenseTitle = r.title;
    licenseFirstName = r.firstName;
    licenseLastName = r.lastName;
    licenseId = r.licenseId;
    licenseExpiredDate = r.expiredDate;
    licenseMobilePhone = r.mobilePhone;
    licenseBranch = r.branchCode;
  }

  /// FF group 'JB999' (อื่นๆ) = free-text job, copied in before validating.
  bool get isFreeTextOccupation => occupationCode == 'JB999';

  void copyFreeTextOccupation(String text) {
    if (isFreeTextOccupation) occupationSubName = text;
  }

  /// FF on save, after the validations: copy the text fields into the state.
  void applyForm(Step1Form f) {
    idCard = step1IsIdCardType(cardType)
        ? f.idCard
        : (step1IsTaxIdType(cardType) || isCorporate)
            ? f.taxId
            : f.passport;
    firstName = f.firstName;
    lastName = f.lastName;
    // FF sent the placeholder 'กรุณาเลือก วัน/เดือน/ปี เกิด' as birth_day when
    // there was no date (spec B14); the port sends ''.
    if (birthDatePicked != null) birthDate = DateFormat('yyyy-MM-dd').format(birthDatePicked!);
    phone = f.phone;
    otherPhone = f.otherPhone;
    email = f.email;
    age = f.age;
  }

  /// `gender` for the API.
  String get genderCode => switch (gender) {
        'ชาย' || 'MALE' => 'MALE',
        'หญิง' || 'FEMALE' => 'FEMALE',
        _ => '',
      };

  /// FF `sendJsonDataAddress([REGISTER, CURRENT], …)`.
  List<Map<String, String>> addressJson() => [
        idCardAddress.toJson('REGISTER'),
        (docSameAsIdCard ? idCardAddress : docAddress).toJson('CURRENT'),
      ];

  /// The step-1 keys of IbsApplicationsSaveCall (the rest stay `""`).
  Map<String, dynamic> saveFields({
    required String idTypeId,
    required String quotationId,
    required String leadDetailId,
    required String applicationType,
    required String actType,
    Map<String, dynamic> extra = const {},
  }) =>
      {
        'quotation_id': quotationId,
        'lead_dtl_id': leadDetailId,
        'id_type_id': idTypeId,
        'national_thai_id': removeCommaFromNumText(idCard),
        'gender': genderCode,
        'title_th_id': '',
        'title_th': title,
        'first_name_th': firstName,
        'last_name_th': lastName,
        'birth_day': birthDate,
        'occupation_id': '',
        'occupation_code': occupationCode,
        'occupation_name': occupationGroup,
        'occupation_subcode': occupationSubCode,
        'occupation_subname': occupationSubName,
        'mobile1': removeCommaFromNumText(phone),
        'mobile2': removeCommaFromNumText(otherPhone),
        'email1': email,
        'address': addressJson(),
        'employee_code_license': replaceAllTabAndSpace(licenseEmployeeId),
        'employee_firstname_license': replaceAllTabAndSpace(licenseFirstName),
        'employee_lastname_license': replaceAllTabAndSpace(licenseLastName),
        'employee_branch_license': replaceAllTabAndSpace(licenseBranch),
        'employee_licenseID_license': replaceAllTabAndSpace(licenseId),
        'employee_licenseImg_license': replaceAllTabAndSpace(licenseImg),
        'employee_licenseExp_license': replaceAllTabAndSpace(licenseExpiredDate),
        'employee_phone_number_license': replaceAllTabAndSpace(licenseMobilePhone),
        'quotation_type': applicationType,
        'sub_product': actType,
        ...extra,
      };
}
