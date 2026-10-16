import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/firebase/firebase_auth_rest.dart';
import '../../../core/firebase/firestore_rest.dart';
import '../../../core/session/user_profile.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../search_package/shared/searchable_list_page.dart';
import '../data/policy_request_api.dart';
import '../models/application_detail.dart';
import '../shared/request_widgets.dart';
import '../state/policy_request_state.dart';
import 'accessory_page.dart';
import 'act_page.dart';
import 'beneficiary_page.dart';
import 'step2_data.dart';
import 'step2_rules.dart';
import 'widgets.dart';

/// 2. ข้อมูลรถยนต์ / ข้อมูลมอเตอร์ไซค์ — FF `InsuranceInfoPage2` (auto work
/// type, motor / EV / MC). Mostly a review of the car data loaded by step 1,
/// with these inputs: branch (employee branch code longer than 2), old
/// policy number / expiry (renew lead), insurance start date (capped by
/// Firestore `effectiveDayConfig`), plate, chassis, engine, seats, cc /
/// horsepower, weight, registration / production year, province, and the
/// sub-pages อุปกรณ์เสริม / พ.ร.บ. / ผู้รับผลประโยชน์. 'บันทึกเตรียมข้อมูล'
/// validates, saves step 2 and reloads the detail; then 'ถัดไป' appears.
///
/// Product differences: [Step2Rules]. Not ported: the renew-only branch
/// (`flagRenew == '1'`: vehicle-type / brand / model / usage editing and
/// the get_vehicle / get_brands / get_models loads — the fields stay
/// read-only here), CMI (act-date row, Act summary card), the non-auto
/// truck / pickup rows and trailer plate, and FF's dead EV inputs
/// (motors / battery / Wall Charge, `&& false`) with their pages.
class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({super.key});

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  final _state = PolicyRequestState.instance;
  Step2Data get _d => _state.step2;
  late final Step2Rules _rules = Step2Rules.of(_state.variant);

  bool _loading = true;
  List<({String id, String name})> _provinces = const [];
  int? _daysInsure;
  int? _daysAct;

  late final _oldVmi = TextEditingController(text: _d.oldVmi);
  late final _plate = TextEditingController(text: _d.carRegis);
  late final _chassis = TextEditingController(text: _d.bodyNumber);
  late final _engine = TextEditingController(text: _d.engineNumber);
  late final _seats = TextEditingController(text: _d.carSeat);
  late final _size = TextEditingController(text: _initialSize());
  late final _weight = TextEditingController(text: _d.weightCar.isEmpty ? '' : removeDotInString(_d.weightCar));

  String _initialSize() {
    if (_rules.isEv && _d.horsePower.isNotEmpty) return removeDotInString(_d.horsePower);
    if (_d.sizeCar.isNotEmpty) return removeDotInString(_d.sizeCar);
    return '';
  }

  @override
  void initState() {
    super.initState();
    if (redirectIfNoFlow(context)) return;
    _load();
  }

  @override
  void dispose() {
    for (final c in [_oldVmi, _plate, _chassis, _engine, _seats, _size, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- load ------------------------------------------------------------------

  Future<void> _load() async {
    final provincesF = PolicyRequestApi.instance.getProvinces();
    final configF = _loadEffectiveDayConfig();
    final profileF = UserProfile.instance.ensureLoaded();
    final r = await provincesF;
    final days = effectiveDaysFrom(await configF);
    await profileF;
    if (!mounted) return;
    setState(() {
      _loading = false;
      _daysInsure = days.insure;
      _daysAct = days.act;
    });
    if (!await requestCheck(context, statusCode: r.statusCode, code: r.code, message: r.message)) return;
    setState(() {
      _provinces = [
        for (final e in (r.at('results.data') as List?) ?? const [])
          if (e is Map) (id: '${e['prov_id'] ?? ''}', name: '${e['prov_th'] ?? ''}'),
      ];
    });
  }

  /// FF wrapped the whole form in a query of `effectiveDayConfig` and showed
  /// an empty page when the collection was empty. The port reads it
  /// unauthenticated, retries with the anonymous Firebase token (in case the
  /// rules need auth) and, if it is still missing, renders the page anyway
  /// with no day limit on the start-date pickers.
  Future<Map<String, dynamic>?> _loadEffectiveDayConfig() async {
    final fs = FirestoreRest.instance;
    final doc = await fs.firstWhere('effectiveDayConfig');
    if (doc != null) return doc;
    final token = await FirebaseAuthRest.idToken();
    if (token == null) return null;
    fs.idToken = token;
    return fs.firstWhere('effectiveDayConfig');
  }

  // ---- employee branch (FF branchCode / profileBranch / profileUnitCodeName) --

  String get _userBranchCode {
    final p = UserProfile.instance.branchCode;
    return p.isNotEmpty ? p : UserSession.instance.branchCode;
  }

  bool get _branchRequired => _userBranchCode.length > 2;

  String get _ownBranchCode {
    final p = UserProfile.instance.branch;
    return p.isNotEmpty ? p : UserSession.instance.branchCode;
  }

  String get _ownBranchName {
    final p = UserProfile.instance.branchName;
    return p.isNotEmpty ? p : UserSession.instance.branchName;
  }

  // ---- actions ---------------------------------------------------------------

  Step2Form _form() => Step2Form(
        plate: _plate.text,
        chassis: _chassis.text,
        engine: _engine.text,
        seats: _seats.text,
        size: _size.text,
        weight: _weight.text,
        oldVmi: _oldVmi.text,
      );

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    context.canPop() ? context.pop() : leaveRequestFlow(context);
  }

  Future<void> _pickBranch() async {
    final b = await Step2BranchPage.open(context);
    if (b == null || !mounted) return;
    setState(() {
      _d.branchCode = b.code.toUpperCase();
      _d.branchName = b.name;
    });
  }

  Future<void> _pickOldExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2050),
    );
    if (picked == null || !mounted) return;
    setState(() => _d.oldVmiExpDate = getDateFormat(picked));
  }

  Future<void> _pickInsureDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // FF: renew / transfer work types used "now" too (no difference).
    final picked = await showDatePicker(context: context, initialDate: today, firstDate: today, lastDate: DateTime(2050));
    if (picked == null || !mounted) return;
    if (isWithinEffectiveDays(picked, _daysInsure)) {
      setState(() => _d.effectiveDateInsure = getDateFormat(picked));
    } else {
      await showAlert(context, 'ไม่สามารถเลือกวันเกิน $_daysInsure วันได้กรุณาเลือกใหม่');
    }
  }

  Future<void> _pickRegisYear() async {
    // FF: ignored once a year is set (step 1 loads it on the auto path).
    if (_d.regisYear.isNotEmpty) return;
    final items = regisYearItems();
    final sel = await SearchableListPage.open(
      context,
      titleText: 'เลือกปีจดทะเบียน',
      searchLabel: 'ระบุปีจดทะเบียน',
      items: items,
    );
    if (sel == null || sel.isEmpty || !mounted) return;
    // FF (fromPage 'RenewStep2') also wrote the BE year into the plate state
    // (insuranceInfoCarRegis) — bug, not ported: only the year is set.
    setState(() => _d.regisYear = '${int.parse(items[sel.first]) - 543}');
  }

  Future<void> _pickProductYear() async {
    final items = productYearItems();
    final sel = await SearchableListPage.open(context, titleText: 'เลือกปีที่ผลิต', searchLabel: 'เลือกปี', items: items);
    if (sel == null || sel.isEmpty || !mounted) return;
    setState(() => _d.productYear = items[sel.first]);
  }

  Future<void> _pickProvince() async {
    final provinces = _provinces;
    final sel = await SearchableListPage.open(
      context,
      titleText: 'เลือกจังหวัดที่จดทะเบียน',
      searchLabel: 'เลือกจังหวัดที่จดทะเบียน',
      items: [for (final p in provinces) p.name],
    );
    if (sel == null || sel.isEmpty || !mounted) return;
    final p = provinces[sel.first];
    setState(() {
      _d.provinceCode = p.id;
      _d.provinceName = p.name;
    });
  }

  Future<void> _openAccessory() async {
    await AccessoryPage.open(context, _d);
    if (mounted) setState(() {});
  }

  Future<void> _openAct() async {
    await ActPage.open(context, _d, actFlag: _state.summary.actFlag, days: _daysAct);
    if (mounted) setState(() {});
  }

  Future<void> _openBeneficiary() async {
    final s = _state.summary;
    await BeneficiaryPage.open(context, _d, insuredName: '${s.firstName} ${s.lastName}');
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final f = _form();
    final invalid = _rules.validateSave(_d, f, branchRequired: _branchRequired);
    if (invalid != null) {
      await showAlert(context, invalid);
      return;
    }
    _rules.applyForm(_d, f);
    final fields = _rules.saveFields(
      _d,
      quotationId: _state.quotationId,
      leadDtlId: _state.summary.leadDetailId.isNotEmpty ? _state.summary.leadDetailId : '${_state.leadDtlId ?? ''}',
      subProduct: _state.summary.actType,
      ownBranchCode: _ownBranchCode,
      ownBranchName: _ownBranchName,
      branchRequired: _branchRequired,
    );
    final api = PolicyRequestApi.instance;
    final error = await withLoading<String?>(context, () async {
      final r = await api.saveApplication(step: '2', fields: fields);
      // FF showed only the HTTP status here (no 'พบข้อผิดพลาด' prefix) — kept.
      if (!r.isHttpOk) return '${r.statusCode}';
      if (r.code != 200) return r.message ?? '';
      final dr = await api.getApplicationDetail(_state.quotationId);
      if (!dr.isHttpOk) return 'พบข้อผิดพลาด (${dr.statusCode})';
      if (dr.code != 200) return dr.message ?? '';
      final before = Step2Data()..copyFrom(_d);
      _state.applyDetail(ApplicationDetail(dr.json, leadDtlId: _state.leadDtlId));
      _d
        ..keepAfterReload(before)
        ..saved = true;
      return null;
    });
    if (!mounted) return;
    setState(() {});
    await showAlert(context, error ?? 'บันทึกเตรียมข้อมูลขั้นตอนที่ 2 สำเร็จ');
  }

  Future<void> _next() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final f = _form();
    final invalid = _rules.validateNext(_d, f);
    if (invalid != null) {
      await showAlert(context, invalid);
      return;
    }
    _d.applyNextTexts(f);
    if (mounted) context.push(_rules.nextRoute);
  }

  // ---- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_state.isActive || _loading) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: requestAppBar(title: _rules.title, onBack: _back),
        body: const PageLoadingView(),
      );
    }
    final d = _d;
    final s = _state.summary;
    final isTruck = d.vehicleType == MotorStep2Rules.truck;
    return RequestStepScaffold(
      title: _rules.title,
      step: 2,
      onBack: _back,
      children: [
        const SizedBox(height: 10),
        if (_branchRequired)
          RequestField(
            label: 'เลือกสาขาที่จะลงผลงาน',
            tag: '(บังคับเลือก)',
            child: RequestPickerTile(
              text: d.branchCode.isNotEmpty && d.branchName.isNotEmpty
                  ? '(${d.branchCode}) ${d.branchName}'
                  : 'กรุณาเลือกสาขาที่จะลงผลงาน',
              isPlaceholder: d.branchCode.isEmpty || d.branchName.isEmpty,
              onTap: _pickBranch,
            ),
          ),
        RequestField(label: 'ประเภทรถ', tag: '(บังคับเลือก)', child: _vehicleTypeBox(d)),
        // Renew (flagRenew '1') brand / model autocomplete editing: not ported
        // — the auto path shows them read-only like FF.
        RequestField(
          label: 'ยี่ห้อรถ',
          tag: '(บังคับเลือก)',
          // FF hint on the brand field says 'กรุณากรอกรุ่นรถ' (kept).
          child: _readOnlyText(_brandModelText(d.brandName), 'กรุณากรอกรุ่นรถ'),
        ),
        RequestField(
          label: 'รุ่นรถ',
          tag: '(บังคับกรอก)',
          child: _readOnlyText(_brandModelText(d.modelName), 'กรุณากรอกรุ่นรถ'),
        ),
        if (d.leadFlagRenew)
          _fieldWithLabel(
            _underlinedLabel('เลขกรมธรรม์ ', tag: '(บังคับกรอก)'),
            // FF: read-only once the state holds a number (kept).
            _textField(_oldVmi, 'กรุณากรอกเลขกรมธรรม์เดิม', readOnly: d.oldVmi.isNotEmpty),
          ),
        if (_rules.showsBeneficiary) ...[
          _fieldWithLabel(
            _underlinedLabel('วันที่หมดอายุประกัน', tag: d.leadFlagRenew ? '(บังคับเลือก)' : ''),
            _tapBox(
              text: d.oldVmiExpDate.isNotEmpty && !d.oldVmiExpDate.contains('กรุณา')
                  ? showDateBESafe(d.oldVmiExpDate)
                  : 'กรุณาเลือกวันหมดอายุประกันเดิม',
              color: Colors.black,
              onTap: _pickOldExpiry,
            ),
          ),
          RequestField(
            label: 'วันที่ต้องการเริ่มคุ้มครองประกัน',
            tag: '(บังคับเลือก)',
            child: _tapBox(
              text: d.effectiveDateInsure.isEmpty
                  ? 'กรุณาเลือกวันที่ต้องการเริ่มคุ้มครองประกัน'
                  : showDateBESafe(d.effectiveDateInsure),
              // FF coloured this text by the พ.ร.บ. date (wrong field); fixed.
              color: d.effectiveDateInsure.isEmpty ? kRequestPlaceholder : Colors.black,
              trailing: const Icon(Icons.edit_calendar_outlined, color: AppColors.secondaryText, size: 24),
              trailingPadding: 10,
              onTap: _pickInsureDate,
            ),
          ),
        ],
        RequestField(
          label: 'เลขทะเบียนรถ',
          tag: '(บังคับกรอก ตัวอย่าง 1ฒต3333)',
          child: _textField(_plate, 'กรุณากรอกเลขทะเบียนรถ'),
        ),
        RequestField(
          label: 'ปีจดทะเบียน พ.ศ.',
          tag: '(บังคับเลือก)',
          child: _tapBox(
            text: d.regisYear.isNotEmpty ? regisYearText(d.regisYear) : 'กรุณาเลือกปีจดทะเบียน',
            color: Colors.black,
            trailing: const Icon(Icons.arrow_forward_ios_sharp, color: AppColors.primaryText, size: 20),
            trailingPadding: 16,
            onTap: _pickRegisYear,
          ),
        ),
        if (_rules.showsBeneficiary)
          RequestField(
            label: 'ปีที่ผลิต ค.ศ.',
            tag: '(บังคับกรอก)',
            child: RequestPickerTile(
              text: d.productYear.isNotEmpty ? d.productYear : 'กรุณาเลือกปีที่ผลิต',
              isPlaceholder: d.productYear.isEmpty || d.productYear.contains('เลือก'),
              onTap: _pickProductYear,
            ),
          ),
        RequestField(
          label: 'จังหวัดที่จดทะเบียน',
          tag: '(บังคับกรอก)',
          child: RequestPickerTile(
            text: d.provinceName.isNotEmpty ? d.provinceName : 'กรุณาเลือกจังหวัดที่จดทะเบียน',
            // FF coloured this by the production year (wrong field); fixed.
            isPlaceholder: d.provinceName.isEmpty,
            onTap: _pickProvince,
          ),
        ),
        RequestField(label: 'ลักษณะการใช้รถ', tag: '(บังคับเลือก)', child: _usageBox(d)),
        RequestField(
          label: 'เลขตัวถัง',
          tag: '(บังคับกรอก ไม่ต้องใส่ - )',
          child: _upperPreviewField(_chassis, 'กรุณากรอกเลขตัวถัง'),
        ),
        RequestField(
          label: 'เลขตัวเครื่อง',
          tag: '(บังคับกรอก ไม่ต้องใส่ - )',
          child: _upperPreviewField(_engine, 'กรุณากรอกเลขเครื่อง'),
        ),
        RequestField(
          label: 'จำนวนที่นั่ง',
          tag: '(บังคับกรอก)',
          child: _textField(
            _seats,
            'กรุณากรอกจำนวนที่นั่ง',
            keyboard: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
          ),
        ),
        RequestField(
          label: _rules.sizeLabel,
          tag: isTruck ? '' : '(บังคับกรอก)',
          child: _textField(_size, _rules.sizeHint, keyboard: TextInputType.number),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RequestField(
            label: 'น้ำหนักรถ',
            tag: '(บังคับกรอก กิโลกรัม)',
            child: _textField(
              _weight,
              'กรุณากรอกน้ำหนัก',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
            ),
          ),
        ),
        if (_rules.showsDriver) _driverRow(d),
        if (_rules.showsAccessory)
          Step2NavRow(
            icon: Icons.dashboard_customize_outlined,
            onTap: _openAccessory,
            texts: d.accessoryProtect.isEmpty
                ? [step2NavText('อุปกรณ์เสริม'), _navTag()]
                : [
                    step2NavText(
                      d.accessoryProtect == Step2Data.kAccessoryProtect
                          ? 'คุ้มครองอุปกรณ์เสริม ${showNumberWithComma(d.accessory)}'
                          : d.accessoryProtect,
                    ),
                  ],
          ),
        if (_rules.showsAct)
          Step2NavRow(
            icon: Icons.playlist_add,
            onTap: _openAct,
            texts: [
              if (d.actOfLegislation.isEmpty) ...[step2NavText('พ.ร.บ.'), _navTag()] else step2NavText(d.actOfLegislation),
              if (s.actFlag.isNotEmpty && d.effectiveDateAct.isNotEmpty)
                step2NavText(
                  '${showNumberWithComma(s.actFlag == '1' ? s.grossTotalNet : s.netPremiumTotal)} บาท',
                ),
            ],
          ),
        if (_rules.showsBeneficiary)
          Step2NavRow(
            icon: Icons.person_add_alt_outlined,
            onTap: _openBeneficiary,
            texts: d.beneficiaryName.isEmpty
                ? [step2NavText('ผู้รับผลประโยชน์'), _navTag()]
                : [step2NavText(d.beneficiaryName, color: AppColors.info)],
          ),
        RequestSaveNextButtons(onSave: _save, onNext: d.saved ? _next : null),
      ],
    );
  }

  /// FF: '' when the stored value is a placeholder ('กรุณา…' / '…เลือก…').
  String _brandModelText(String v) => v.contains('กรุณา') || v.contains('เลือก') ? '' : v;

  Widget _navTag() => Padding(
        padding: const EdgeInsets.only(left: 5),
        child: Text('(บังคับเลือก)', style: AppText.style(fontSize: 12, fontWeight: FontWeight.w500, color: kRequestTagRed)),
      );

  /// Label with an underlined, heavier 'เดิม' (FF RichText).
  Widget _underlinedLabel(String prefix, {String tag = ''}) {
    final base = AppText.style(fontSize: 15, fontWeight: FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: prefix, style: base),
            TextSpan(
              text: 'เดิม',
              style: AppText.style(fontSize: 15, fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
            ),
          ])),
          if (tag.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(tag, style: AppText.style(fontSize: 12, color: kRequestTagRed)),
            ),
        ],
      ),
    );
  }

  Widget _fieldWithLabel(Widget label, Widget child) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [label, Padding(padding: const EdgeInsets.only(top: 5), child: child)],
        ),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppText.style(fontSize: 15, color: AppColors.secondaryText),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      );

  Widget _textField(
    TextEditingController c,
    String hint, {
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    bool readOnly = false,
  }) {
    return RequestBox(
      child: TextField(
        controller: c,
        readOnly: readOnly,
        keyboardType: keyboard,
        inputFormatters: formatters,
        style: AppText.style(fontSize: 15, color: Colors.black),
        decoration: _decoration(hint),
      ),
    );
  }

  Widget _readOnlyText(String text, String hint) => RequestBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text.isEmpty ? hint : text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.style(
              fontSize: 15,
              fontWeight: text.isEmpty ? FontWeight.w600 : FontWeight.normal,
              color: text.isEmpty ? AppColors.secondaryText : Colors.black,
            ),
          ),
        ),
      );

  /// FF chassis / engine field: the typed text is transparent and a live
  /// preview of `removeDatAndMakeUpperCase(text)` is drawn over it.
  Widget _upperPreviewField(TextEditingController c, String hint) {
    return RequestBox(
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          TextField(
            controller: c,
            onChanged: (_) => setState(() {}),
            cursorColor: Colors.black,
            style: AppText.style(fontSize: 15, color: const Color(0x00101213)),
            decoration: _decoration(hint),
          ),
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(removeDatAndMakeUpperCase(c.text), style: AppText.style(fontSize: 15, color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tapBox({
    required String text,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
    double trailingPadding = 0,
  }) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onTap,
      child: RequestBox(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(text, style: AppText.style(fontSize: 15, color: color)),
              ),
            ),
            if (trailing != null) Padding(padding: EdgeInsets.only(right: trailingPadding), child: trailing),
          ],
        ),
      ),
    );
  }

  Widget _vehicleTypeBox(Step2Data d) {
    final img = carTypeImage(d.carTypeDetail);
    // Tap: FF opened SearchableCarListPage only for renew (not ported).
    return RequestBox(
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(d.vehicleType, style: AppText.style(fontSize: 15, color: Colors.black)),
            ),
          ),
          if (img.width > 0)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RequestNetworkImage(url: img.url, width: img.width, height: 56),
              ),
            ),
        ],
      ),
    );
  }

  Widget _usageBox(Step2Data d) {
    // Tap: FF opened the usage picker only for renew (not ported; on renew
    // its choice was never shown or saved either).
    return Container(
      width: double.infinity,
      height: 60,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 0.5),
      ),
      child: Text(
        d.vehicleUsage.isNotEmpty ? d.vehicleUsage : 'เลือกการใช้งาน',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        // FF coloured this by the search-package usage field, so a usage
        // loaded in step 1 showed grey; fixed to the row's own value.
        style: AppText.style(fontSize: 15, color: d.vehicleUsage.isEmpty ? kRequestPlaceholder : Colors.black),
      ),
    );
  }

  Widget _driverRow(Step2Data d) {
    final complete = d.firstDriverComplete;
    // FF onTap was empty (read-only; ShowDriverPage isn't reachable here).
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kRequestGrey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                d.driverType == '1' && complete ? 'ระบุผู้ขับขี่' : 'ไม่ระบุผู้ขับขี่',
                style: AppText.style(fontSize: 15, color: Colors.black),
              ),
            ),
            if (complete)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.gpp_good_outlined, color: Color(0xFF00B505), size: 24),
              ),
          ],
        ),
      ),
    );
  }
}
