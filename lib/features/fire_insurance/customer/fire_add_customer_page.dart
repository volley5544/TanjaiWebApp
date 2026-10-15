import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/user_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart' as ff;
import '../../../core/utils/input_formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../router/app_router.dart';
import '../data/fire_insurance_api.dart';
import '../models/fire_package.dart';
import '../state/fire_search_state.dart';

/// Port of FF `AddFireCustomerName` (เพิ่มชื่อลูกค้า): customer name + phone,
/// then `api/house/quotations/save` for the package on the detail page.
///
/// [doInsurance] false ('ออกใบเสนอราคา') → FireQuotationPage with the saved
/// PDFs; true ('ตกลงทำประกัน') → InsuranceInfoPage1 (not ported yet; the
/// quotation id / lead detail id stay in `FireSearchState.lastSave`).
class FireAddCustomerPage extends StatefulWidget {
  const FireAddCustomerPage({super.key, required this.doInsurance});

  final bool doInsurance;

  @override
  State<FireAddCustomerPage> createState() => _FireAddCustomerPageState();
}

class _FireAddCustomerPageState extends State<FireAddCustomerPage> {
  final _state = FireSearchState.instance;
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_state.selectedPackage == null || _state.criteria == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.fireSearch);
      });
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
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
    final phone = _phone.text;
    if (_firstName.text.isEmpty) {
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
    if (ff.checkNumberInString(_firstName.text)) {
      await showAlert(context, 'ชื่อห้ามมีตัวเลข กรุณากรอกใหม่');
      return false;
    }
    if (ff.checkNumberInString(_lastName.text)) {
      await showAlert(context, 'นามสกุลห้ามมีตัวเลข กรุณากรอกใหม่');
      return false;
    }
    return true;
  }

  /// FF `(double.parse(house) + double.parse(buildin)).toString()` as the
  /// mobile (Dart VM) app printed it — `'2700000.0'`; on the web a whole
  /// double would print without the `.0`.
  static String _sumTotal(String house, String buildin) {
    final total = (double.tryParse(house) ?? 0) + (double.tryParse(buildin) ?? 0);
    return total == total.truncateToDouble() ? '${total.toInt()}.0' : '$total';
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
    final package = _state.selectedPackage;
    if (package == null) return;

    final s = _state;
    final r = await withLoading(
      context,
      () => FireInsuranceApi.instance.saveQuotation(
        package: package,
        firstName: _firstName.text,
        lastName: _lastName.text,
        phoneNumber: ff.removeDatAndMakeUpperCase(_phone.text),
        sumInsureHouse: s.sumInsureHouse,
        sumInsureBuildin: s.sumInsureBuildin,
        sumInsureTotal: _sumTotal(s.sumInsureHouse, s.sumInsureBuildin),
        floor: s.houseFloor,
        width: s.houseWidth,
        length: s.houseLong,
        usableArea: s.usableArea,
        houseTypeCode: s.houseTypeCode,
        houseTypeName: s.houseTypeName,
      ),
    );
    if (!mounted) return;
    if (r.statusCode != 200) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.statusCode})');
      return;
    }
    if (r.code != 200) {
      await showAlert(context, '${r.message}');
      return;
    }
    _state
      ..lastSave = r.data ?? const FireQuotationSaveResult()
      ..notify();
    if (kDebugMode) debugPrint('[FireAddCustomer] quotation saved');

    // FF goNamed = the stack is replaced.
    if (widget.doInsurance) {
      context.go(AppRoutes.notPorted('InsuranceInfoPage1'));
    } else {
      context.go(AppRoutes.fireQuotation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: UnfocusOnTap(
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: tanjaiAppBar(
            title: 'เพิ่มชื่อลูกค้า',
            titleColor: const Color(0xFF204A77),
            backgroundColor: AppColors.primaryBackground,
            backColor: AppColors.brandOrange,
            onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.fireSearch),
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
                      required: true,
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
                      required: true,
                      child: _BoxTextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneMaskFormatter()],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 100,
                      color: AppColors.secondaryBackground,
                      child: Column(
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
      ),
    );
  }
}

/// Label row ('(บังคับกรอก)' red w600 12 when [required]) + 60px input box.
class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.child, this.required = false, this.topPadding = 0});

  final String label;
  final bool required;
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
                Text(label, style: AppText.style(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.labelGrey)),
                if (required)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text('(บังคับกรอก)', style: AppText.style(fontSize: 12, color: AppColors.requiredRed)),
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
