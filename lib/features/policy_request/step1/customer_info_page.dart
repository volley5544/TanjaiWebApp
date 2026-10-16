import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/firebase/firestore_rest.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../../router/app_router.dart';
import '../../search_package/shared/searchable_list_page.dart';
import '../data/policy_request_api.dart';
import '../models/application_detail.dart';
import '../shared/request_widgets.dart';
import '../state/policy_request_state.dart';
import 'step1_data.dart';
import 'step1_rules.dart';
import 'step1_widgets.dart';

enum _IdKind { idCard, passport, taxId }

/// Last CheckBlackList result of one ID field (FF checkBlackListOutput 1/2/3).
class _Check {
  const _Check(this.status, this.code, this.flag);

  final int status;
  final int? code;
  final String flag;

  bool get ok => status == 200 && code == 200 && flag == 'N';
}

/// 1. ข้อมูลส่วนตัวบุคคล (ลูกค้า) — FF InsuranceInfoPage1 (step 1 of 5).
class CustomerInfoPage extends StatefulWidget {
  const CustomerInfoPage({super.key});

  @override
  State<CustomerInfoPage> createState() => _CustomerInfoPageState();
}

class _CustomerInfoPageState extends State<CustomerInfoPage> {
  final _st = PolicyRequestState.instance;
  final _api = PolicyRequestApi.instance;
  Step1Data get _s1 => _st.step1;
  Step1Rules get _rules => Step1Rules.of(_st.variant);

  final _idCard = TextEditingController();
  final _passport = TextEditingController();
  final _taxId = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _age = TextEditingController();
  final _occupation = TextEditingController();
  final _phone = TextEditingController();
  final _otherPhone = TextEditingController();
  final _email = TextEditingController();
  final _licenseCode = TextEditingController();

  final _checks = <_IdKind, _Check>{};
  bool _loading = true;

  /// Firestore `urlLinkStorage/SHMpkLIsHEHrCQC183m9` (GetProfileImage base).
  Future<Map<String, dynamic>?>? _profileDoc;

  String get _empId => UserSession.instance.employeeId;

  /// The logged-in employee holds a licence → row 16 read-only, no 'ค้นหา'.
  bool get _ownLicence => _s1.licenceOf(_empId) != null;

  @override
  void initState() {
    super.initState();
    if (redirectIfNoFlow(context)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final c in [
      _idCard, _passport, _taxId, _firstName, _lastName, _age, _occupation, _phone, _otherPhone, _email, _licenseCode,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── on load (FF §3) ───────────────────────────────────────────────────────

  Future<void> _load() async {
    final dataListF = FirestoreRest.instance.firstWhere('dataList');
    _profileDoc = FirestoreRest.instance.getDocument('urlLinkStorage/SHMpkLIsHEHrCQC183m9');
    try {
      final lic = await _api.getLicenseList();
      if (!mounted) return;
      if (!await requestCheck(context, statusCode: lic.statusCode, code: lic.code, message: lic.message)) return;
      _s1.licenses = LicenseRow.listFrom(lic.json);

      final occ = await _api.getOccupation();
      if (!mounted) return;
      if (!occ.isHttpOk) {
        await showAlert(context, 'พบข้อผิดพลาด (Get Occupation ${occ.statusCode})');
        return;
      }
      if (occ.code != 200) {
        await showAlert(context, occ.message ?? '');
        return;
      }
      _s1.occupations = OccupationRow.listFrom(occ.json);

      final det = await _api.getApplicationDetail(_st.quotationId);
      if (!mounted) return;
      if (!await requestCheck(context, statusCode: det.statusCode, code: det.code, message: det.message)) return;
      _st.applyDetail(ApplicationDetail(det.json, leadDtlId: _st.leadDtlId));
      _fillControllers();

      // FF wrapped the body in a FutureBuilder on this doc; the port loads it
      // with the rest. Missing → the pickers get an empty list (FF: null).
      _s1.dataList = await dataListF;

      // FF step 11: the logged-in employee's own licence overrides the saved one.
      final own = _s1.licenceOf(_empId);
      if (own != null) {
        _s1.haveLicense = true;
        _s1.licenseImg = await _profileImage(_empId);
        _s1.applyLicence(own);
        _licenseCode.text = _empId;
      }
      // FF on-load "non-auto premium" check is dead code (spec B2) — not ported.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// FF §3.4.
  void _fillControllers() {
    if (_s1.idCard.isNotEmpty) _idCard.text = _s1.idCard;
    _firstName.text = _s1.firstName;
    _lastName.text = _s1.lastName;
    _occupation.text = _s1.occupationSubName;
    _email.text = _s1.email;
    _age.text = _s1.age;
    _licenseCode.text = _s1.licenseEmployeeId;
    _phone.text = _s1.phone;
    _otherPhone.text = _s1.otherPhone;
  }

  /// GetProfileImageCall → `data.img_profile`, else the blank avatar (no
  /// error dialog, like FF). The base URL comes from Firestore; only https
  /// is used.
  Future<String> _profileImage(String code) async {
    final doc = await (_profileDoc ?? Future.value(null));
    final base = '${doc?['url_link'] ?? ''}';
    if (!RequestNetworkImage.isHttps(base)) return kStep1BlankProfileUrl;
    final r = await _api.getProfileImage(baseUrl: base, employeeCode: code);
    final img = r.at('data.img_profile');
    if (r.isHttpOk && r.fileStatus == 200 && img != null) return '$img';
    return kStep1BlankProfileUrl;
  }

  // ── pickers (FF SearchableListPage P1–P5) ────────────────────────────────

  List<String> _dataListStrings(String key) {
    final v = _s1.dataList?[key];
    return v is List ? v.map((e) => '$e').toList() : const [];
  }

  Future<int?> _pick(String title, String label, List<String> items) async {
    final r = await SearchableListPage.open(context, titleText: title, searchLabel: label, items: items);
    return r == null || r.isEmpty ? null : r.first;
  }

  Future<void> _pickCardType() async {
    if (_s1.isCorporate) return;
    final items = _dataListStrings('CardType');
    final i = await _pick('ประเภทบัตร', 'ระบุประเภทบัตร', items);
    if (i == null || !mounted) return;
    setState(() => _s1.cardType = items[i]);
  }

  Future<void> _pickGender() async {
    final i = await _pick('เพศ', 'ระบุเพศ', kStep1Genders);
    if (i == null || !mounted) return;
    setState(() => _s1.selectGender(kStep1Genders[i]));
  }

  Future<void> _pickTitle() async {
    final items = _dataListStrings(_s1.isMale ? 'Title' : 'Title2');
    final i = await _pick('คำนำหน้า', 'ระบุคำนำหน้า', items);
    if (i == null || !mounted) return;
    setState(() => _s1.title = items[i]);
  }

  Future<void> _pickOccupationGroup() async {
    final items = _s1.occupationGroups;
    final i = await _pick('กลุ่มอาชีพ', 'ระบุกลุ่มอาชีพ', items);
    if (i == null || !mounted) return;
    setState(() => _s1.selectOccupationGroup(items[i]));
  }

  Future<void> _pickOccupation() async {
    final i = await _pick('อาชีพ', 'ระบุอาชีพ', _s1.occupationSubNames);
    if (i == null || !mounted) return;
    setState(() => _s1.selectOccupation(i));
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final last = DateTime(now.year - 18, now.month, now.day);
    final d = await showDatePicker(context: context, initialDate: last, firstDate: DateTime(1900), lastDate: last);
    FocusManager.instance.primaryFocus?.unfocus();
    // FF: cancel reset an earlier pick to today − 18 y, and crashed when
    // nothing was picked yet (spec B13) — the port keeps the value.
    if (d == null || !mounted) return;
    setState(() {
      _s1.birthDatePicked = d;
      _age.text = '${step1AgeFrom(d)}';
    });
  }

  Future<void> _openAddress() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await context.push(AppRoutes.requestAddress);
    if (mounted) setState(() {});
  }

  // ── actions ───────────────────────────────────────────────────────────────

  TextEditingController _ctrlOf(_IdKind k) => switch (k) {
        _IdKind.idCard => _idCard,
        _IdKind.passport => _passport,
        _IdKind.taxId => _taxId,
      };

  /// 'ตรวจสอบรายชื่อ' (rows 2 / 3 / 4).
  Future<void> _checkBlacklist(_IdKind kind) async {
    final id = removeCommaFromNumText(_ctrlOf(kind).text);
    if (kind != _IdKind.passport) {
      if (!checkIdCardInput(id)) return showAlert(context, 'กรุณากรอกเลขบัตร 13 หลัก');
      if (!checkIdCard(id)) return showAlert(context, 'กรุณากรอกเลขบัตรให้ถูกต้อง');
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final r = await withLoading(
      context,
      () => _api.checkBlacklist(
        idTypeId: _rules.blacklistIdTypeId(_s1.cardType),
        nationalThaiId: id,
        quotationId: _st.quotationId,
      ),
    );
    if (!mounted) return;
    setState(() => _checks[kind] = _Check(r.statusCode, r.code, '${r.at('results.data.blacklist_flag') ?? ''}'));
    // No message on success, none when blacklisted (only the ✓ is missing;
    // save then refuses) — FF.
    await requestCheck(context, statusCode: r.statusCode, code: r.code, message: r.message);
  }

  /// FF kept a passed check after the number was edited (spec B4); the port
  /// drops the result so the edited number has to be checked again.
  void _idChanged(_IdKind kind) {
    if (_checks.containsKey(kind)) setState(() => _checks.remove(kind));
  }

  /// 'ค้นหา' (row 16).
  Future<void> _searchLicence() async {
    FocusManager.instance.primaryFocus?.unfocus();
    _s1.haveLicense = false;
    final code = _licenseCode.text;
    if (code.isEmpty) {
      setState(() {});
      return showAlert(context, 'กรุณากรอกรหัสพนักงาน');
    }
    final row = _s1.licenceOf(code);
    if (row == null) {
      setState(_s1.clearLicence);
      return showAlert(context, 'เลขพนักงานนี้ไม่มีบัตรนายหน้าประกัน');
    }
    _s1.haveLicense = true;
    final img = await withLoading(context, () => _profileImage(code));
    if (!mounted) return;
    setState(() {
      _s1.licenseImg = img;
      _s1.applyLicence(row);
    });
  }

  Step1Form _form() => Step1Form(
        idCard: _idCard.text,
        passport: _passport.text,
        taxId: _taxId.text,
        firstName: _firstName.text,
        lastName: _lastName.text,
        occupation: _occupation.text,
        phone: _phone.text,
        otherPhone: _otherPhone.text,
        email: _email.text,
        age: _age.text,
        licenseCode: _licenseCode.text,
        idCardFlag: _checks[_IdKind.idCard]?.flag ?? '',
        passportFlag: _checks[_IdKind.passport]?.flag ?? '',
        taxIdFlag: _checks[_IdKind.taxId]?.flag ?? '',
      );

  /// 'บันทึกเตรียมข้อมูล' — save draft, step 1.
  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    _s1.copyFreeTextOccupation(_occupation.text);
    final form = _form();
    final msg = _rules.validate(_s1, form);
    if (msg != null) return showAlert(context, msg);

    _s1.applyForm(form);
    // The summary card shows the same FF fields (insuranceInfoFirstName …).
    _st.summary
      ..firstName = _s1.firstName
      ..lastName = _s1.lastName
      ..phone = _s1.phone;
    _st.notify();

    final sum = _st.summary;
    final fields = _s1.saveFields(
      idTypeId: _rules.saveIdTypeId(_s1),
      quotationId: _st.quotationId,
      leadDetailId: sum.leadDetailId.isNotEmpty ? sum.leadDetailId : '${_st.leadDtlId ?? ''}',
      applicationType: sum.applicationType,
      actType: sum.actType,
      extra: _rules.extraSaveFields(_s1),
    );
    final r = await withLoading(context, () => _api.saveApplication(step: '1', fields: fields));
    if (!mounted) return;
    if (!await requestCheck(context, statusCode: r.statusCode, code: r.code, message: r.message)) return;
    if (!mounted) return;
    await showAlert(context, 'บันทึกเตรียมข้อมูลขั้นตอนที่ 1 สำเร็จ');
    if (mounted) setState(() => _s1.saved = true);
  }

  /// 'ถัดไป' — no re-validation / re-save (FF; spec B16).
  void _next() {
    FocusManager.instance.primaryFocus?.unfocus();
    context.push(_rules.nextRoute);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  static const _title = '1. ข้อมูลส่วนตัวบุคคล (ลูกค้า)';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: requestAppBar(title: _title, onBack: () => leaveRequestFlow(context)),
          body: const PageLoadingView(),
        ),
      );
    }
    final s1 = _s1;
    final rules = _rules;
    final corp = s1.isCorporate;
    return RequestStepScaffold(
      title: _title,
      step: 1,
      // User decision 2026-10-16: back → the quotation list (FF
      // LeadFollowUpPage is not ported); FF's 500 ms wait dropped.
      onBack: () => leaveRequestFlow(context),
      children: [
        // 1. card type
        RequestField(
          label: 'ประเภทบัตร',
          tag: '(บังคับเลือก)',
          child: RequestPickerTile(
            text: _cardTypeText,
            isPlaceholder: s1.cardType.contains('เลือก'),
            onTap: _pickCardType,
          ),
        ),
        // 2. Thai ID
        if (step1IsIdCardType(s1.cardType) && !corp)
          _idRow(
            label: 'กรอกเลขบัตรลูกค้า',
            kind: _IdKind.idCard,
            masked: true,
            readOnly: _st.summary.discountFlg == '1' && s1.idCard.isNotEmpty,
          ),
        // 3. TAXID (CMI only)
        if (rules.showsTaxIdRow(s1)) _idRow(label: 'กรอกเลข TAXID', kind: _IdKind.taxId, masked: true),
        // 4. passport
        if (step1IsPassportType(s1.cardType) && !corp)
          _idRow(label: 'กรอกเลขพาสปอร์ตลูกค้า', kind: _IdKind.passport, masked: false),
        // 5. gender
        if (!corp)
          RequestField(
            label: 'เพศ',
            tag: '(บังคับเลือก)',
            child: RequestPickerTile(
              text: switch (s1.gender) {
                'MALE' || 'ชาย' => 'ชาย',
                'FEMALE' || 'หญิง' => 'หญิง',
                _ => 'กรุณาเลือกเพศ',
              },
              isPlaceholder: s1.gender.contains('เลือก'),
              onTap: _pickGender,
            ),
          ),
        // 6. title
        if (s1.gender.isNotEmpty && !corp)
          RequestField(
            label: 'คำนำหน้า',
            tag: '(บังคับเลือก)',
            child: RequestPickerTile(
              text: s1.title.isNotEmpty ? s1.title : 'กรุณาเลือกคำนำหน้า',
              isPlaceholder: s1.title.contains('เลือก'),
              onTap: _pickTitle,
            ),
          ),
        // 7. name
        RequestField(
          label: corp ? 'ชื่อบริษัท' : 'ชื่อลูกค้า (ไม่ต้องระบุคำนำหน้า)',
          tag: '(บังคับกรอก)',
          child: Step1TextBox(controller: _firstName, hint: 'กรุณากรอกชื่อ'),
        ),
        // 8. last name
        if (!corp)
          RequestField(
            label: 'นามสกุลลูกค้า',
            tag: '(บังคับกรอก)',
            child: Step1TextBox(controller: _lastName, hint: 'กรุณากรอกนามสกุล'),
          ),
        // 9. birth date + age
        if (rules.showsBirthDate) _birthDateRow(),
        // 10. occupation group
        if (!corp)
          RequestField(
            label: 'กลุ่มอาชีพ',
            tag: '(บังคับเลือก)',
            child: RequestPickerTile(
              text: s1.occupationName.isNotEmpty && s1.occupationCode.isNotEmpty
                  ? s1.occupationName
                  : 'กรุณาเลือกกลุ่มอาชีพ',
              isPlaceholder: s1.occupationGroup.contains('เลือก'),
              onTap: _pickOccupationGroup,
            ),
          ),
        // 11a / 11b. occupation
        if (s1.occupationName.isNotEmpty && !s1.isFreeTextOccupation)
          RequestField(
            label: 'อาชีพ',
            tag: '(บังคับเลือก)',
            child: RequestPickerTile(
              text: s1.occupationSubName.isNotEmpty ? s1.occupationSubName : 'กรุณาเลือกอาชีพ',
              // FF tests the group's value here, not the job's (kept).
              isPlaceholder: s1.occupationGroup.contains('เลือก'),
              onTap: _pickOccupation,
            ),
          ),
        if (s1.occupationName.isNotEmpty && s1.isFreeTextOccupation)
          RequestField(
            label: 'อาชีพ',
            tag: '(บังคับกรอก)',
            child: Step1TextBox(controller: _occupation, hint: 'กรุณากรอกอาชีพ'),
          ),
        // 12. mobile
        RequestField(
          label: 'เบอร์โทรศัพท์มือถือ',
          tag: '(บังคับกรอก)',
          child: Step1TextBox(
            controller: _phone,
            hint: 'กรุณากรอกเบอร์โทรศัพท์มือถือ',
            keyboardType: TextInputType.number,
            // FF maxLength 12 / 10 (prefilled raw digits) truncated edits of
            // a prefilled number (spec B15); the mask alone caps it here.
            inputFormatters: [PhoneMaskFormatter()],
          ),
        ),
        // 13. other phone
        RequestField(
          label: 'เบอร์โทรศัพท์อื่น ๆ',
          child: Step1TextBox(
            controller: _otherPhone,
            hint: 'กรุณากรอกเบอร์โทรศัพท์อื่นๆ',
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneMaskFormatter()],
          ),
        ),
        // 14. email (FF hint typo 'อีเมลล์' kept)
        RequestField(
          label: 'อีเมล',
          child: Step1TextBox(controller: _email, hint: 'กรุณากรอกอีเมลล์', keyboardType: TextInputType.emailAddress),
        ),
        // 15. address card
        _addressCard(),
        // 16 / 17. licence
        if (rules.showsLicence) _licenceRow(),
        if (rules.showsLicence && (s1.haveLicense || s1.licenseEmployeeId.isNotEmpty)) _licenceCard(),
        // 18. video-call link: always hidden in FF (value cleared on load) — not ported.
        // 19. buttons
        RequestSaveNextButtons(onSave: _save, onNext: s1.saved ? _next : null),
      ],
    );
  }

  String get _cardTypeText {
    final t = _s1.cardType;
    if (step1IsIdCardType(t)) return 'บัตรประชาชน';
    if (step1IsPassportType(t)) return 'Passport';
    if (t == '5' || _s1.isCorporate) return 'TAXID';
    return 'กรุณาเลือกประเภทบัตร';
  }

  Widget _idRow({required String label, required _IdKind kind, required bool masked, bool readOnly = false}) {
    final c = _checks[kind];
    // FF icon rules (⚠ conditions contradict each other — practically never
    // shown, spec B5; kept).
    Widget? suffix;
    if (c != null && c.ok) {
      suffix = const Icon(Icons.check, color: Color(0xFF00B505));
    } else if (c != null &&
        c.status != 200 &&
        c.code != 200 &&
        (kind == _IdKind.passport ? c.flag != 'N' : c.flag == 'N')) {
      suffix = const Icon(Icons.error_outline, color: AppColors.error);
    }
    return RequestField(
      label: label,
      tag: '(บังคับกรอก)',
      child: Row(
        children: [
          Expanded(
            child: Step1TextBox(
              controller: _ctrlOf(kind),
              hint: 'กรุณากรอกเลขบัตร',
              hintColor: AppColors.secondaryText,
              readOnly: readOnly,
              keyboardType: kind == _IdKind.idCard
                  ? TextInputType.phone
                  : kind == _IdKind.taxId
                      ? TextInputType.number
                      : null,
              // FF maxLength 17 / 13 cut edits of a prefilled raw ID (spec
              // B15); the mask alone caps the digits here.
              inputFormatters: masked ? [IdCardMaskFormatter()] : null,
              suffix: suffix,
              onChanged: (_) => _idChanged(kind),
            ),
          ),
          const SizedBox(width: 8),
          Step1SideButton(text: 'ตรวจสอบรายชื่อ', icon: Icons.list, onTap: () => _checkBlacklist(kind)),
        ],
      ),
    );
  }

  Widget _birthDateRow() {
    final s1 = _s1;
    String text;
    if (s1.birthDatePicked != null) {
      text = showDateBE(getDateFormat(s1.birthDatePicked!));
    } else if (s1.birthDate.isNotEmpty) {
      // FF threw on an unparsable date (e.g. its 'null'); the port shows it raw.
      try {
        text = showDateBE(s1.birthDate);
      } catch (_) {
        text = s1.birthDate;
      }
    } else {
      text = 'กรุณาเลือก วัน/เดือน/ปี เกิด';
    }
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: w * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RequestFieldLabel('วัน/เดือน/ปี เกิด', tag: '(บังคับเลือก)'),
                const SizedBox(height: 5),
                RequestBox(
                  child: InkWell(
                    onTap: _pickBirthDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              // FF: dark only for a date picked here, grey
                              // even for the saved date (kept).
                              style: AppText.style(
                                fontSize: 15,
                                color: s1.birthDatePicked != null ? AppColors.primaryText : kRequestPlaceholder,
                              ),
                            ),
                          ),
                          const Icon(Icons.edit_calendar_outlined, color: AppColors.secondaryText),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: w * 0.35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RequestFieldLabel('อายุ', tag: '(อายุมากกว่า 18 ปี)'),
                const SizedBox(height: 5),
                Step1TextBox(controller: _age, hint: 'กรุณากรอกอายุ', readOnly: true, color: const Color(0xFFF6F6F6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard() {
    final kw = _s1.docAddress.keyword;
    // FF showed 'เพิ่มที่อยู่' only for the exact placeholder; '' is treated the same.
    final empty = !step1HasAddressText(kw);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(8),
        color: AppColors.secondaryBackground,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _openAddress,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kRequestBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black)),
                  child: const Icon(Icons.home_outlined, color: AppColors.secondaryText, size: 30),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: empty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('เพิ่มที่อยู่', style: AppText.style(fontSize: 15, color: kRequestNavy)),
                            Text('กรุณาเพิ่มที่อยู่', style: AppText.style(fontSize: 12, color: kRequestTagRed)),
                          ],
                        )
                      : Text(
                          kw,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.style(fontSize: 15, color: kRequestNavy),
                        ),
                ),
                const Icon(Icons.navigate_next),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _licenceRow() {
    final own = _ownLicence;
    return RequestField(
      label: 'กรอกรหัสพนักงานผู้มีบัตรนายหน้า ฯ',
      tag: '(บังคับกรอก)',
      child: Row(
        children: [
          Expanded(
            child: Step1TextBox(
              controller: _licenseCode,
              hint: 'กรุณากรอกรหัสพนักงาน',
              keyboardType: TextInputType.number,
              readOnly: own,
            ),
          ),
          if (!own) ...[
            const SizedBox(width: 8),
            Step1SideButton(text: 'ค้นหา', icon: Icons.search, onTap: _searchLicence),
          ],
        ],
      ),
    );
  }

  Widget _licenceCard() {
    final s1 = _s1;
    final w = MediaQuery.sizeOf(context).width;
    final label = AppText.style(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF1D4774));
    final value = AppText.style(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1D4774));
    final img = s1.licenseImg.isNotEmpty ? s1.licenseImg : kStep1BlankProfileUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(8),
        color: AppColors.secondaryBackground,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: kRequestBorder)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: w * 0.60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ชื่อผู้ถือบัตร', style: label),
                    Text('${s1.licenseTitle}${s1.licenseFirstName} ${s1.licenseLastName}', style: value),
                    Text('หมายเลขบัตรประกันวินาศภัย', style: label),
                    Text(s1.licenseId, style: value),
                    Row(children: [
                      SizedBox(width: w * 0.25, child: Text('วันหมดอายุ', style: label)),
                      Expanded(child: Text(s1.licenseExpiredDate, style: value)),
                    ]),
                    Row(children: [
                      SizedBox(width: w * 0.25, child: Text('เบอร์โทร', style: label)),
                      Expanded(child: Text(s1.licenseMobilePhone, style: value)),
                    ]),
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  // FF: a 120×120 circle inside a 60-high box → a 60 px circle.
                  child: ClipOval(child: RequestNetworkImage(url: img, width: 60, height: 60)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
