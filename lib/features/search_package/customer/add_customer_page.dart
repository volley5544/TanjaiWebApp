import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/firebase/firestore_rest.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart' as ff;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../router/app_router.dart';
import '../data/search_package_api.dart';
import '../models/insurance_package.dart';
import '../models/quotation_save_request.dart';
import '../product_type.dart';
import '../state/search_package_state.dart';

/// Port of FF `AddCustomerName` (เพิ่มชื่อลูกค้า, spec 08): customer name /
/// phone / plate form that saves a quotation for the chosen package(s).
///
/// * [fromPage] `'detail'` → the package opened on the detail page;
///   `'compare'` → every compared package (FF passed the whole parallel lists
///   and `sendJsonData` zipped them all, so the save covers all of them).
/// * [fromBtn] `'saveBtn'` → continue to the application flow; anything else
///   (`'quotationBtn'`, compare's `''`) → Quotation PDF page.
///
/// End of the `saveBtn` flow: InsuranceInfoPage1 (not ported) or, when the
/// video-call gate blocks it, the quotation list (`AppRoutes.quotationList`,
/// FF `goNamed('insuranceListPage')` = stack replaced).
class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({
    super.key,
    required this.product,
    required this.fromPage,
    required this.fromBtn,
  });

  final ProductType product;
  final String fromPage;
  final String fromBtn;

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  late final SearchPackageState _state = SearchPackageState.of(widget.product);

  // Prefilled from the previous successful save (FF AddCustomerPage* fields).
  late final _firstName = TextEditingController(text: _state.customerFirstName);
  late final _lastName = TextEditingController(text: _state.customerLastName);
  late final _phone = TextEditingController(text: _state.customerPhone);
  late final _plate = TextEditingController(text: _state.customerCarRegistration);

  bool get _fromDetail => widget.fromPage != 'compare';

  /// The package(s) the quotation is saved for.
  List<InsurancePackage> get _packages {
    if (_fromDetail) {
      final p = _state.selectedPackage;
      return p == null ? const [] : [p];
    }
    return _state.comparePackages;
  }

  @override
  void initState() {
    super.initState();
    // Opened without flow state (e.g. browser refresh) → back to search.
    if (_state.result == null || _packages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.search(widget.product));
      });
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _plate.dispose();
    super.dispose();
  }

  void _snack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text(message, style: AppText.style(color: Colors.white)),
      duration: const Duration(milliseconds: 3000),
      backgroundColor: const Color(0xB2000000),
    ));
  }

  /// FF validation chain, same order and texts (typos kept verbatim).
  Future<bool> _validate() async {
    final first = _firstName.text;
    final phone = _phone.text;
    final plate = _plate.text;
    if (first.isEmpty) {
      await showAlert(context, 'บังคับกรอกชื่อ');
      return false;
    }
    if (phone.isEmpty) {
      await showAlert(context, 'บังคับกรอกเบอร์โทรศัพท์');
      return false;
    }
    if (!ff.checkIsStringPhoneLength(ff.removeCommaFromNumText(phone), 10)) {
      _snack('กรุณากรอกเบอร์โทรศัพ 10 หลัก');
      return false;
    }
    if (!phone.startsWith('0')) {
      _snack('เบอร์โทรศัพตัวแรกต้องเป็นเลข 0');
      return false;
    }
    // Raw length (FF quirk: checked before filtering, sent filtered).
    if (plate.isNotEmpty && !ff.checkIsStringLengthInLength(plate, 10)) {
      _snack('กรุณากรอกทะเบียนรถไม่เกิน 10 หลัก');
      return false;
    }
    if (ff.checkNumberInString(first)) {
      await showAlert(context, 'ชื่อห้ามมีตัวเลข กรุณากรอกใหม่');
      return false;
    }
    if (ff.checkNumberInString(_lastName.text)) {
      await showAlert(context, 'นามสกุลห้ามมีตัวเลข กรุณากรอกใหม่');
      return false;
    }
    return true;
  }

  QuotationSaveRequest? _buildRequest() {
    final s = _state;
    final session = UserSession.instance;
    // FF: int.parse(insuranceBasicYear) - 543 (crashed on a bad value).
    final yearBE = int.tryParse(s.yearBE ?? '');
    if (yearBE == null) return null;
    final expiry = s.oldPolicyExpiry;
    return QuotationSaveRequest(
      nationalThaiId: s.criteria?.idCard ?? '',
      evFlag: widget.product.evFlag,
      subProduct: widget.product.subProduct,
      carProvinceName: s.selectedProvince?.nameTh ?? '',
      carProvinceCode: s.selectedProvince?.id ?? '',
      carTypeDetail: s.carTypeDetailSelected,
      oldVmiExpiredDate: expiry == null ? '' : ff.getDateFormat(expiry),
      ownerId: session.employeeId,
      firstName: _firstName.text,
      phoneNumber: ff.removeCommaFromNumText(_phone.text),
      carType: s.vehicleTypeLabel,
      carRegistration: ff.removeSpacialLetterFromText(_plate.text),
      // Detail/compare forwarded the list page's `driver` (driverFlag).
      driverType: s.criteria?.driverFlag ?? '0',
      carRegistrationYear: '${yearBE - 543}',
      carBrandId: s.selectedBrand?.id ?? '',
      carBrandName: s.brandLabel,
      carModelName: s.modelLabel,
      carModelId: s.selectedModel?.code ?? '',
      vehicleId: s.selectedUsage?.id ?? '',
      vehicleCode: s.selectedUsage?.code ?? '',
      vehicleName: s.selectedUsage?.name ?? SearchPlaceholders.usage,
      ownerName: '${ff.replaceAllTabAndSpace(session.firstName)} ${ff.replaceAllTabAndSpace(session.lastName)}',
      ownerPhone: ff.replaceAllTabAndSpace(session.phone),
      branchCode: ff.replaceAllTabAndSpace(session.branchCode),
      branchName: ff.replaceAllTabAndSpace(session.branchName),
      packages: [
        for (final p in _packages) QuotationPackageItem.fromPackage(p, viaDetailPage: _fromDetail),
      ],
      lastName: _lastName.text,
    );
  }

  /// Firestore `hideInAppContent` / `video_call`. Unreadable on web without
  /// auth → treated as `isShowContent = false` (FF crashed on a missing doc).
  Future<bool> _isVideoCallShown() async {
    final doc = await FirestoreRest.instance
        .firstWhere('hideInAppContent', field: 'content_name', equals: 'video_call');
    return doc?['is_show_content'] == true;
  }

  Future<void> _onSave() async {
    if (!await _validate() || !mounted) return;

    final confirmed = await showConfirm(
      context,
      'คุณต้องการบันทึกใช่หรือไม่',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (!confirmed || !mounted) return;

    // Never call the API without a token / employee id.
    if (!UserSession.instance.isSignedIn) {
      await showAlert(context, 'ไม่พบข้อมูลผู้ใช้งาน กรุณาเข้าสู่ระบบผ่านแอปประกันทันใจ');
      return;
    }
    final request = _buildRequest();
    if (request == null || _packages.isEmpty) {
      await showAlert(context, 'กรุณาเลือกปีจดทะเบียน');
      return;
    }

    String? error;
    QuotationSaveResult? saved;
    var videoCallShown = false;
    await withLoading(context, () async {
      final r = await SearchPackageApi.instance.saveQuotation(request);
      if (r.statusCode != 200) {
        error = httpErrorText(r.statusCode);
      } else if (r.code != 200) {
        error = '${r.message}';
      } else {
        saved = r.data ?? const QuotationSaveResult();
        if (widget.fromBtn == 'saveBtn') videoCallShown = await _isVideoCallShown();
      }
    });
    if (!mounted) return;
    if (error != null) {
      await showAlert(context, error!);
      return;
    }
    final result = saved!;

    _state
      ..customerFirstName = _firstName.text
      ..customerLastName = _lastName.text
      ..customerPhone = _phone.text // stored masked, as FF did
      ..customerCarRegistration = _plate.text
      ..quotationSaved = true
      // Per-package PDFs + compare PDF (literal 'null' when absent — FF quirk).
      ..quotationPdfs = result.quotationPdfList
      ..lastSaveResult = result
      ..notify();
    if (kDebugMode) debugPrint('[AddCustomer] quotation saved');

    if (widget.fromBtn == 'saveBtn') {
      // FF: allowed = video_call shown ? profileIsHaveInsuranceCard : true.
      // profileIsHaveInsuranceCard isn't handed to the web app yet → FF
      // default false.
      const haveInsuranceCard = false;
      final allowed = videoCallShown ? haveInsuranceCard : true;
      if (allowed) {
        // FF pushNamed('insuranceInfoPage1', quotationId: '${result.quotationId}',
        // leadDtailId: result.leadDtlIds.first) — both kept in
        // state.lastSaveResult for the future port (not put in the URL).
        context.go(AppRoutes.notPorted('InsuranceInfoPage1'));
      } else {
        context.go(AppRoutes.quotationList);
      }
    } else {
      final router = GoRouter.of(context);
      if (router.canPop()) router.pop();
      router.push(AppRoutes.quotation(widget.product));
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnfocusOnTap(
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: tanjaiAppBar(
          title: 'เพิ่มชื่อลูกค้า',
          titleColor: const Color(0xFF204A77),
          backgroundColor: AppColors.primaryBackground,
          backColor: AppColors.brandOrange,
          onBack: () => context.pop(),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldBlock(
                    topPadding: 5,
                    label: 'ชื่อลูกค้า',
                    note: '(บังคับกรอก)',
                    child: _BoxTextField(controller: _firstName),
                  ),
                  // Last name is optional (FF hid its '(บังคับกรอก)' tag).
                  _FieldBlock(
                    topPadding: 5,
                    label: 'นามสกุลลูกค้า',
                    child: _BoxTextField(controller: _lastName),
                  ),
                  _FieldBlock(
                    label: 'เบอร์โทรศัพท์',
                    note: '(บังคับกรอก)',
                    child: _BoxTextField(
                      controller: _phone,
                      keyboardType: TextInputType.number,
                      inputFormatters: [PhoneMaskFormatter()],
                    ),
                  ),
                  _FieldBlock(
                    label: 'ทะเบียนรถ',
                    note: '(ไม่ต้องมีขีด - ) ',
                    noteColor: Colors.black,
                    child: _BoxTextField(controller: _plate),
                  ),
                  Container(
                    width: double.infinity,
                    height: 100,
                    color: AppColors.secondaryBackground,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        AppButton(text: 'บันทึก', onPressed: _onSave),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Label row + 60px bordered input box.
class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.child,
    this.note = '',
    this.noteColor = AppColors.requiredRed,
    this.topPadding = 0,
  });

  final String label;
  final String note;
  final Color noteColor;
  final double topPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(label,
                    style: AppText.style(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.labelGrey)),
                if (note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(note, style: AppText.style(fontSize: 12, color: noteColor)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 0.5),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoxTextField extends StatelessWidget {
  const _BoxTextField({required this.controller, this.keyboardType, this.inputFormatters});

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppText.style(fontSize: 15),
      decoration: InputDecoration(
        hintText: 'กรุณากรอก',
        hintStyle: AppText.style(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFFAAAAAA)),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
      ),
    );
  }
}

/// FF `MaskTextInputFormatter(mask: '###-###-####')`: digits only, max 10,
/// dashes inserted after the 3rd and 6th digit.
class PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buf.write('-');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    // Keep the caret after the same number of digits it followed before.
    final caretDigits = newValue.text
        .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, digits.length);
    var offset = 0;
    for (var seen = 0; offset < text.length && seen < caretDigits; offset++) {
      if (text[offset] != '-') seen++;
    }
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: offset));
  }
}
