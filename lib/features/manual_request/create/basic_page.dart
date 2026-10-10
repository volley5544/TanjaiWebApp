import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/user_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../../router/app_router.dart';
import '../../search_package/data/api_result.dart';
import '../../search_package/data/search_package_api.dart';
import '../../search_package/models/car_model.dart';
import '../../search_package/shared/search_form/search_pickers.dart';
import '../../search_package/shared/searchable_list_page.dart';
import '../shared/branch_and_sample_pages.dart';
import '../shared/np_widgets.dart';
import '../shared/photo_upload.dart';
import '../state/none_package_state.dart';
import 'np_car_type_page.dart';

/// Port of FF `NonePackageBasicPage` — step 1 of a manual request: vehicle,
/// customer and cover details (spec basic_page.md).
///
/// Web fixes (FF bugs, visible UI unchanged):
/// * a master-data error closes the loading view (FF left its loading sheet
///   up forever);
/// * a brand / model typed in lower case or not in the list no longer throws
///   (no suggestions / empty model code instead);
/// * the refrigerated-box price accepts the `12,000.00` the field formats
///   itself to (FF's int check could never pass);
/// * cancelling the date picker keeps the previous date (FF reset to today).
///
/// Not ported (dead in FF): the driver toggle / driver-behaviour picker and
/// the ID-card promotion check — `driverFlag` is always false.
class BasicPage extends StatefulWidget {
  const BasicPage({super.key});

  @override
  State<BasicPage> createState() => _BasicPageState();
}

class _BasicPageState extends State<BasicPage> {
  final _s = NonePackageState.instance;
  final _api = SearchPackageApi.instance;
  bool _loading = true;

  late final _carryPurpose = TextEditingController(text: _s.copyTexts['carryPurpose']);
  late final _currentPrice = TextEditingController(text: _s.copyTexts['currentPrice']);
  late final _carrierPrice = TextEditingController(text: _s.copyTexts['carrierPrice']);
  late final _brand = TextEditingController(text: _initial(_s.brandName));
  late final _model = TextEditingController(text: _initial(_s.modelName));
  final _oldVmi = TextEditingController();
  late final _cusName = TextEditingController(text: _s.copyTexts['cusName']);
  late final _cusPhone = TextEditingController(text: _maskPhone(_s.copyTexts['cusPhone'] ?? ''));
  late final _plate = TextEditingController(text: _s.copyTexts['plate']);
  late final _plateAdditional = TextEditingController(text: _s.copyTexts['plateAdditional']);
  late final _sumInsured = TextEditingController(text: _s.copyTexts['sumInsured']);
  late final _trailerSumInsured = TextEditingController(text: _s.copyTexts['trailerSumInsured']);
  late final _remark = TextEditingController(text: _s.copyTexts['remark']);

  final _brandFocus = FocusNode();
  final _modelFocus = FocusNode();
  final _numberFocus = <TextEditingController, FocusNode>{};

  DateTime? _datePicked;

  static String _initial(String v) => v.contains('กรุณา') || v.contains('เลือก') ? '' : v;

  static String _maskPhone(String digits) =>
      PhoneMaskFormatter().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: digits)).text;

  bool get _showBranch => UserSession.instance.branchCode.length > 2;

  @override
  void initState() {
    super.initState();
    if (!_s.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
      return;
    }
    for (final c in [_currentPrice, _carrierPrice, _sumInsured, _trailerSumInsured]) {
      final f = FocusNode();
      // FF F1 listener: plain digits while editing, `1,234.00` on blur.
      f.addListener(() {
        if (c.text.isEmpty) return;
        c.text = f.hasFocus ? removeCommaFromNumText(c.text) : showNumberWithCommaWithoutDot(c.text);
      });
      _numberFocus[c] = f;
    }
    _brandFocus.addListener(_computeModelList);
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _carryPurpose, _currentPrice, _carrierPrice, _brand, _model, _oldVmi, _cusName, _cusPhone,
      _plate, _plateAdditional, _sumInsured, _trailerSumInsured, _remark,
    ]) {
      c.dispose();
    }
    _brandFocus.dispose();
    _modelFocus.dispose();
    for (final f in _numberFocus.values) {
      f.dispose();
    }
    super.dispose();
  }

  /// Page-load master data, one call after another like FF.
  Future<void> _load() async {
    String? error;
    String? check<T>(ApiResult<T> r, {bool connection = true}) {
      if (!r.isHttpOk) return connection ? 'พบข้อผิดพลาดConnection (${r.statusCode})' : httpErrorText(r.statusCode);
      if (r.code != 200) return r.message ?? '';
      return null;
    }

    final provinces = await _api.getProvinces();
    error = check(provinces);
    if (error == null) {
      _s.provinces = provinces.data ?? [];
      final usages = await _api.getVehicles(vehicleCategory: 'manual', carType: _s.fromMenu);
      error = check(usages, connection: false);
      if (error == null) {
        _s.usages = usages.data ?? [];
        final brands = await _api.getBrands(vehicleGroup: _s.fromMenu);
        error = check(brands);
        if (error == null) {
          // FF resets the working brand list to the unfiltered one on open.
          _s.brandsOriginal = brands.data ?? [];
          _s.brands = List.of(_s.brandsOriginal);
          final models = await _api.getModels(vehicleGroup: _s.fromMenu);
          error = check(models);
          if (error == null) {
            _s.modelsOriginal = models.data ?? [];
            final covers = await _api.getCoverTypes();
            error = check(covers);
            if (error == null) _s.coverTypes = covers.data ?? [];
          }
        }
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) await showAlert(context, error);
  }

  /// FF brand focus listener / submit: models of the typed brand.
  void _computeModelList() {
    final upper = _brand.text.toUpperCase();
    final brand = _s.brands.where((b) => b.name == upper).firstOrNull;
    if (brand == null) {
      // FF threw here (RangeError) and kept the old list.
      _s.searchModels = [];
      return;
    }
    final group = _s.vehicleGroup;
    _s.searchModels = [
      for (final m in _s.modelsOriginal)
        if (m.brandId == brand.id &&
            m.carGroup.contains(group) &&
            (group != 'PICKUP' ||
                (_s.carTypeContain == m.carGroupDetail && (_s.carTypeDoors == m.carDoors || m.carDoors == '-'))))
          m,
    ];
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

  Future<int?> _pick(String title, String label, List<String> items) async {
    final r = await SearchableListPage.open(context, titleText: title, searchLabel: label, items: items);
    return (r == null || r.isEmpty) ? null : r.first;
  }

  Future<void> _pickTruckPart() async {
    const items = ['เฉพาะหัวลาก', truckWithTrailer];
    final i = await _pick('เลือกส่วนของรถบรรทุก', 'ระบุส่วนของรถบรรทุก', items);
    if (i != null) _s..truckPart = items[i]..notify();
  }

  Future<void> _pickMembership() async {
    const items = ['ลูกค้าสินเชื่อ', 'ลูกค้านอก'];
    final i = await _pick('เลือกประเภทลูกค้า', 'ระบุประเภทลูกค้า', items);
    if (i != null) _s..cusMembership = items[i]..notify();
  }

  Future<void> _pickCarrierType() async {
    const items = ['ตู้แห้ง', 'ตู้เย็น'];
    final i = await _pick('เลือกประเภทตู้เหล็ก', 'ระบุประเภทตู้เหล็ก', items);
    if (i != null) _s..carrierType = items[i]..notify();
  }

  Future<void> _pickYear() async {
    final years = registrationYearsBE();
    final i = await _pick('เลือกปีจดทะเบียน', 'ระบุปีจดทะเบียน', years);
    if (i == null) return;
    _s
      ..year = years[i]
      ..yearChrist = '${int.parse(years[i]) - 543}'
      ..notify();
  }

  List<String> get _usageLabels => [for (final u in _s.usages) '${u.code} ${u.type}-${u.name}'];

  Future<void> _pickUsage() async {
    final i = await _pick('เลือกลักษณะการใช้รถ', 'ระบุลักษณะการใช้รถ', _usageLabels);
    if (i == null) return;
    final u = _s.usages[i];
    _s
      ..usedTypeId = u.id
      ..usedTypeCode = u.code
      ..usedTypeName = u.name
      ..notify();
  }

  Future<void> _pickCover() async {
    final names = [for (final c in _s.coverTypes) c.name];
    final i = await _pick('เลือกประเภทชั้นประกัน', 'ระบุประเภทชั้นประกัน', names);
    if (i == null) return;
    final c = _s.coverTypes[i];
    _s
      ..coverTypeId = c.id
      ..coverTypeCode = c.code
      ..coverTypeName = c.name
      ..notify();
  }

  Future<void> _pickGarage() async {
    const names = ['ซ่อมอู่', 'ซ่อมห้าง'];
    final i = await _pick('เลือกประเภทการซ่อม', 'ระบุประเภทการซ่อม', names);
    if (i == null) return;
    _s
      ..garageTypeId = const ['2', '1'][i]
      ..garageTypeName = names[i]
      ..garageTypeCode = const ['COMPANY', 'DEALER'][i]
      ..notify();
  }

  Future<void> _pickProvince() async {
    final names = [for (final p in _s.provinces) p.nameTh];
    final i = await _pick('เลือกจังหวัดจดทะเบียน', 'ระบุจังหวัดจดทะเบียน', names);
    if (i == null) return;
    _s
      ..provinceId = _s.provinces[i].id
      ..province = names[i]
      ..notify();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _datePicked ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2050, 12, 31),
    );
    if (d != null) setState(() => _datePicked = DateTime(d.year, d.month, d.day));
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _uploadTransferDoc(void Function(String) store) async {
    await uploadSlot(context, store);
    if (mounted) setState(() {});
  }

  // ── ถัดไป ────────────────────────────────────────────────────────────────

  void _snack(String m) => showNpSnack(context, m);

  Future<void> _next() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero); // let the F1 formatters run, as FF's unfocus did
    if (!mounted) return;
    final s = _s;
    if (_showBranch && (s.branchCode.isEmpty || s.branchName.isEmpty)) {
      await showAlert(context, 'กรุณาเลือกสาขาที่จะลงผลงาน');
      return;
    }
    if (isPh(s.vehicleType)) return _snack('กรุณาเลือกประเภทรถ');
    if (_brand.text.isEmpty) return _snack('กรุณากรอกยี่ห้อรถ');
    if (_model.text.isEmpty) return _snack('กรุณากรอกรุ่นรถ');
    if (s.year.contains('เลือก')) return _snack('กรุณาเลือกปีจดทะเบียน');
    if (isPh(s.usedTypeName) || s.usedTypeName.contains('เลือก')) return _snack('กรุณาเลือกลักษณะการใช้รถ');
    if (isPh(s.coverTypeName)) return _snack('กรุณาเลือกชั้นประกัน');
    if (isPh(s.garageTypeName)) return _snack('กรุณาเลือกประเภทการซ่อม');
    if (_plate.text.isEmpty) return _snack('กรุณากรอกทะเบียนรถ');
    if (_plate.text.length > 10) return _snack('กรุณากรอกทะเบียนรถไม่เกิน 10 หลัก');
    if (isPh(s.province)) return _snack('กรุณาเลือกจังหวัดจดทะเบียน');
    if (_cusName.text.isEmpty) return _snack(s.buttonOrdinary ? 'กรุณากรอกชื่อลูกค้า' : 'กรุณากรอกชื่อบริษัท');
    if (s.flagRenew) {
      if (_cusPhone.text.isEmpty) return _snack('กรุณากรอกเบอร์โทรศัพท์');
      if (!checkPhoneNumberInput(removeCommaFromNumText(_cusPhone.text))) {
        return _snack('กรุณากรอกเบอร์โทรศัพท์เป็นตัวเลข 10 หลักให้ถูกต้อง');
      }
      if (_oldVmi.text.isEmpty) return _snack('กรุณากรอกเลขกรมธรรม์เดิม');
      if (_datePicked == null) return _snack('กรุณาเลือกวันที่หมดอายุประกันเดิม');
    }
    if (s.vehicleType == pickup && s.flagCarrier) {
      if (isPh(s.carrierType)) return _snack('กรุณาเลือกประเภทตู้เหล็ก');
      if (s.carrierType == 'ตู้เย็น') {
        if (_carrierPrice.text.isEmpty) return _snack('กรุณากรอกราคาตู้ + เครื่องทำความเย็น');
        if (double.tryParse(removeCommaFromNumText(_carrierPrice.text)) == null) {
          return _snack('กรุณากรอกราคาตู้ + เครื่องทำความเย็นเป็นตัวเลข');
        }
      }
    } else if (s.vehicleType == truck) {
      if (isPh(s.truckPart)) return _snack('กรุณาเลือกส่วนของรถบรรทุก');
      if (isPh(s.cusMembership)) return _snack('กรุณาเลือกประเภทลูกค้า');
      if (_carryPurpose.text.isEmpty) return _snack('กรุณากรอกรถใช้บรรทุกอะไร');
      if (s.truckPart == truckWithTrailer && _plateAdditional.text.isEmpty) {
        return _snack('กรุณากรอกเลขทะเบียนหางพ่วง');
      }
    }
    if (s.workType == 'transfer') {
      if (s.oldVmiImageUrl.isEmpty) return showAlert(context, 'กรุณาอัพโหลดรูปตารางกรมธรรม์เดิม');
      if (s.idCardUrl.isEmpty) return showAlert(context, 'กรุณาอัพโหลดรูปสำเนาบัตรประชาชนลูกค้า');
      if (!s.buttonOrdinary && s.companyBookUrl.isEmpty) {
        return showAlert(context, 'กรุณาอัพโหลดรูปหนังสือจดทะเบียนบริษัท');
      }
    }

    // Save to state (FF order / transformations).
    final modelUpper = _model.text.toUpperCase();
    s
      ..modelName = modelUpper
      ..modelCode = s.searchModels.where((m) => m.name == modelUpper).firstOrNull?.code ?? ''
      ..cusFullname = _cusName.text
      ..cusPhone = removeCommaFromNumText(_cusPhone.text)
      ..plate = removeSpacialLetterFromText(_plate.text)
      ..sumInsured = removeCommaFromNumText(_sumInsured.text)
      ..brandName = _brand.text.toUpperCase()
      ..brandId = s.brands.where((b) => b.name == _brand.text.toUpperCase()).firstOrNull?.id ?? ''
      ..carrierPrice = removeCommaFromNumText(_carrierPrice.text)
      ..truckCurrentPrice = removeCommaFromNumText(_currentPrice.text)
      ..plateAdditional = removeSpacialLetterFromText(_plateAdditional.text)
      ..truckCarryPurpose = _carryPurpose.text
      ..trailerSumInsured = removeCommaFromNumText(_trailerSumInsured.text)
      ..remark = _remark.text;
    if (s.flagRenew) {
      s
        ..oldVmiExpDate = _datePicked != null ? getDateFormat(_datePicked!) : s.oldVmiExpDate
        ..oldVmi = _oldVmi.text;
    } else {
      s.oldVmiExpDate = _datePicked != null ? getDateFormat(_datePicked!) : '';
    }
    s.notify();

    final docsOnly =
        s.workType == 'ev' || s.flagRenew || s.usedTypeCode == '110' || s.coverTypeName == 'ชั้น 3';
    if (mounted) context.push(docsOnly ? AppRoutes.manualDocuments : AppRoutes.manualPhotos);
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) => UnfocusOnTap(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: npAppBar(npTitle(_s.workType, flagRenew: _s.flagRenew), onBack: () => context.pop()),
          body: _loading
              ? const PageLoadingView()
              : SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        ..._fields(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  List<Widget> _fields() {
    final s = _s;
    final isTruckType = s.vehicleType == truck;
    final isPickup = s.vehicleType == pickup;
    bool grey2(String v) => v.contains('กรุณา') || v.contains('เลือก');
    return [
      if (_showBranch) NpSection(child: NpBranchSelector(state: s)),
      NpSection(
        bottom: 5,
        label: const NpLabel('ประเภทรถ', tag: '(บังคับเลือก)'),
        child: NpPickerBox(value: s.vehicleType, placeholder: grey2(s.vehicleType), onTap: () => NpCarTypePage.open(context)),
      ),
      if (isTruckType) ...[
        NpSection(
          bottom: 5,
          label: const NpLabel('ส่วนของรถบรรทุก', tag: '(บังคับเลือก)'),
          child: NpPickerBox(value: s.truckPart, placeholder: isPh(s.truckPart), onTap: _pickTruckPart),
        ),
        NpSection(
          bottom: 5,
          label: const NpLabel('ประเภทลูกค้า', tag: '(บังคับเลือก)'),
          child: NpPickerBox(value: s.cusMembership, placeholder: isPh(s.cusMembership), onTap: _pickMembership),
        ),
        NpSection(
          label: const NpLabel('รถใช้บรรทุกอะไร', tag: '(บังคับกรอก)'),
          child: NpTextBox(controller: _carryPurpose, hint: 'กรุณากรอกรถใช้บรรทุกอะไร'),
        ),
        NpSection(
          label: const NpLabel('ราคาซื้อขายปัจจุบัน'),
          child: NpTextBox(
            controller: _currentPrice,
            focusNode: _numberFocus[_currentPrice],
            hint: 'กรุณากรอกราคาซื้อขายปัจจุบัน',
            keyboardType: TextInputType.number,
            fill: false,
            textColor: AppColors.primaryText,
          ),
        ),
      ],
      if (isPickup)
        NpSection(
          child: NpToggleBox(
            text: 'ติดตู้เหล็กหรือไม่',
            on: s.flagCarrier,
            onTap: () => s..flagCarrier = !s.flagCarrier..notify(),
          ),
        ),
      if (isPickup && s.flagCarrier) ...[
        NpSection(
          child: NpToggleBox(
            text: 'ใช้วิ่งร่วมกับบริษัทขนส่งเอกชนหรือไม่',
            on: s.flagCoop,
            onTap: () => s..flagCoop = !s.flagCoop..notify(),
          ),
        ),
        NpSection(
          label: const NpLabel('ประเภทตู้เหล็ก', tag: '(บังคับเลือก)'),
          child: NpPickerBox(value: s.carrierType, placeholder: isPh(s.carrierType), onTap: _pickCarrierType),
        ),
        if (s.carrierType == 'ตู้เย็น')
          NpSection(
            label: const NpLabel('ราคาตู้ + เครื่องทำความเย็น', tag: '(บังคับกรอก เป็นตัวเลขเท่านั้น)'),
            child: NpTextBox(
              controller: _carrierPrice,
              focusNode: _numberFocus[_carrierPrice],
              hint: 'กรุณากรอกราคา',
              keyboardType: TextInputType.number,
              textColor: AppColors.primaryText,
            ),
          ),
      ],
      NpSection(
        label: const NpLabel('ยี่ห้อรถ', tag: '(บังคับเลือก)'),
        // FF hint says "model" on the brand field — verbatim.
        child: _autocomplete(_brand, _brandFocus, 'กรุณากรอกรุ่นรถ', () => [for (final b in s.brands) b.name],
            onSubmitted: _computeModelList),
      ),
      NpSection(
        label: const NpLabel('รุ่นรถ', tag: '(บังคับกรอก)'),
        child: _autocomplete(_model, _modelFocus, 'กรุณากรอกรุ่นรถ', () => [for (final CarModel m in s.searchModels) m.name]),
      ),
      NpSection(
        label: const NpLabel('ปีจดทะเบียนรถ พ.ศ.', tag: '(บังคับเลือก)'),
        child: NpPickerBox(value: s.year, placeholder: grey2(s.year), onTap: _pickYear),
      ),
      if (s.flagRenew)
        NpSection(
          label: NpLabel('เลขกรมธรรม์', extras: [npOldWord()], tag: '(บังคับกรอก)'),
          child: NpTextBox(controller: _oldVmi, hint: 'กรุณากรอกเลขกรมธรรม์เดิม'),
        ),
      NpSection(
        label: NpLabel('วันที่หมดอายุประกัน', extras: [npOldWord()], tag: s.flagRenew ? '(บังคับเลือก)' : null),
        child: _datePickerBox(),
      ),
      NpSection(
        label: const NpLabel('ลักษณะการใช้รถ', tag: '(บังคับเลือก)'),
        child: NpPickerBox(value: _usageDisplay(), placeholder: grey2(s.usedTypeName), onTap: _pickUsage),
      ),
      NpSection(
        label: NpLabel('ประเภทชั้นประกัน', extras: [if (s.flagRenew) npOldWord()], tag: '(บังคับเลือก)'),
        child: NpPickerBox(value: s.coverTypeName, placeholder: isPh(s.coverTypeName), onTap: _pickCover),
      ),
      NpSection(
        label: NpLabel('ประเภทการซ่อม', extras: [if (s.flagRenew) npOldWord()], tag: '(บังคับเลือก)'),
        child: NpPickerBox(value: s.garageTypeName, placeholder: isPh(s.garageTypeName), onTap: _pickGarage),
      ),
      NpSection(
        label: NpLabel(s.buttonOrdinary ? 'ชื่อลูกค้า' : 'ชื่อบริษัทลูกค้า', tag: '(บังคับกรอก)'),
        child: NpTextBox(controller: _cusName, hint: 'กรุณากรอกชื่อ', textInputAction: TextInputAction.next),
      ),
      NpSection(
        label: NpLabel('เบอร์โทรศัพท์ลูกค้า', tag: s.flagRenew ? '(บังคับกรอก)' : null),
        child: NpTextBox(
          controller: _cusPhone,
          hint: 'กรุณากรอกเบอร์โทรศัพท์',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [PhoneMaskFormatter()],
        ),
      ),
      NpSection(
        label: const NpLabel('ทะเบียนรถ', tag: '(บังคับกรอก ไม่ต้องมีขีด - )'),
        child: NpTextBox(controller: _plate, hint: 'กรุณากรอกทะเบียนรถ'),
      ),
      if (s.hasTrailer)
        NpSection(
          label: const NpLabel('เลขทะเบียนหางพ่วง', tag: '(กรุณาระบุเป็นตัวเลขเช่น 123456)'),
          child: NpTextBox(
            controller: _plateAdditional,
            hint: 'กรุณากรอกทะเบียนรถ', // FF hint, verbatim
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          ),
        ),
      NpSection(
        label: const NpLabel('จังหวัดจดทะเบียน', tag: '(บังคับเลือก)'),
        child: NpPickerBox(value: s.province, placeholder: isPh(s.province), onTap: _pickProvince),
      ),
      NpSection(
        bottom: 5,
        label: const NpLabel('ทุนประกันที่ลูกค้าต้องการ', tag: '(กรอกตัวเลขเท่านั้น)', tagColor: AppColors.primaryText),
        child: NpTextBox(
          controller: _sumInsured,
          focusNode: _numberFocus[_sumInsured],
          hint: 'กรุณากรอกทุนประกัน',
          keyboardType: TextInputType.number,
          fill: false,
          textColor: AppColors.primaryText,
        ),
      ),
      if (s.hasTrailer)
        NpSection(
          bottom: 5,
          label: const NpLabel('ทุนประกันหางพ่วงที่ลูกค้าต้องการ',
              tag: '(กรอกตัวเลขเท่านั้น)', tagColor: AppColors.primaryText),
          child: NpTextBox(
            controller: _trailerSumInsured,
            focusNode: _numberFocus[_trailerSumInsured],
            hint: 'กรุณากรอกทุนประกันหางพ่วง',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textColor: AppColors.primaryText,
          ),
        ),
      NpSection(
        bottom: 5,
        label: const NpLabel('หมายเหตุ'),
        child: NpTextBox(controller: _remark, hint: 'กรุณากรอกหมายเหตุ'),
      ),
      NpSection(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: NpToggleBox(
            text: 'ขอเบี้ย พ.ร.บ. หรือไม่',
            on: s.flagAct,
            onTap: () => s..flagAct = !s.flagAct..notify(),
          ),
        ),
      ),
      if (s.workType == 'transfer') _transferDocs(),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: AppButton(text: 'ถัดไป', onPressed: _next, color: AppColors.sheetButtonOrange, fontSize: 16),
      ),
    ];
  }

  String _usageDisplay() {
    final s = _s;
    if (s.usedTypeName.contains('เลือก')) return NpPlaceholders.usedTypeName;
    final u = s.usages.where((u) => u.code == s.usedTypeCode).firstOrNull;
    return u == null ? 'เลือกการใช้งาน' : '${u.code} ${u.type}-${u.name}';
  }

  Widget _datePickerBox() {
    final s = _s;
    String text;
    var placeholder = false;
    if (_datePicked != null) {
      text = showDateBE(getDateFormat(_datePicked!));
    } else if (s.oldVmiExpDate.isNotEmpty && !isPh(s.oldVmiExpDate) && DateTime.tryParse(s.oldVmiExpDate) != null) {
      text = showDateBE(s.oldVmiExpDate);
    } else {
      text = NpPlaceholders.oldVmiExpDate;
      placeholder = true;
    }
    return NpPickerBox(value: text, placeholder: placeholder, onTap: _pickDate, icon: Icons.edit_calendar_outlined);
  }

  Widget _autocomplete(
    TextEditingController controller,
    FocusNode focus,
    String hint,
    List<String> Function() options, {
    VoidCallback? onSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Container(
        height: 60,
        decoration: npBoxDecoration(),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        child: RawAutocomplete<String>(
          textEditingController: controller,
          focusNode: focus,
          optionsBuilder: (v) {
            if (v.text.isEmpty) return const [];
            final q = v.text.toLowerCase();
            return options().where((o) => o.toLowerCase().contains(q));
          },
          onSelected: (_) => focus.unfocus(),
          fieldViewBuilder: (context, c, f, onFieldSubmitted) => TextField(
            controller: c,
            focusNode: f,
            onSubmitted: (_) {
              f.unfocus();
              onSubmitted?.call();
            },
            style: AppText.style(fontSize: 15, color: Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.style(fontSize: 15, fontWeight: FontWeight.w500, color: npBorderGrey),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
            ),
          ),
          optionsViewBuilder: (context, onSelected, opts) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              color: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.sizeOf(context).width - 60),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final o in opts)
                      InkWell(
                        onTap: () => onSelected(o),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(o, style: AppText.bodyMedium),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _transferDocs() {
    final s = _s;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: SizedBox(
                height: 33,
                child: Row(
                  children: [
                    Text('เอกสารเพิ่มเติม', style: AppText.style(fontSize: 15, color: npTitleNavy)),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text('(งานโอนโค้ด)', style: AppText.style(fontSize: 12, color: npRequiredRed)),
                    ),
                  ],
                ),
              ),
            ),
            NpAttachRow(
              title: '1. ตารางกรมธรรม์เดิม',
              tag: '(บังคับอัพโหลดรูป)',
              done: s.oldVmiImageUrl.isNotEmpty,
              onTap: () => _uploadTransferDoc((u) => s.oldVmiImageUrl = u),
            ),
            NpAttachRow(
              title: '2. สำเนาบัตรประชาชน',
              tag: '(บังคับอัพโหลดรูป)',
              titleExtras: [
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Icon(Icons.content_paste_search_rounded, color: Color(0xFF354052), size: 24),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: InkWell(
                    onTap: () => SampleIdCardPage.open(context),
                    child: Text('ดูตัวอย่าง',
                        style: AppText.style(fontSize: 15, fontWeight: FontWeight.w500, decoration: TextDecoration.underline)),
                  ),
                ),
              ],
              done: s.idCardUrl.isNotEmpty,
              onTap: () => _uploadTransferDoc((u) => s.idCardUrl = u),
            ),
            if (s.buttonCorporation)
              NpAttachRow(
                title: '3. หนังสือจดทะเบียนบริษัท',
                tag: '(บังคับอัพโหลดรูป)',
                done: s.companyBookUrl.isNotEmpty,
                onTap: () => _uploadTransferDoc((u) => s.companyBookUrl = u),
              ),
          ],
        ),
      ),
    );
  }
}
