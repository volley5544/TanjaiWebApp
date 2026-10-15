import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart' as ff;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../router/app_router.dart';
import '../../search_package/shared/searchable_list_page.dart';
import '../data/fire_insurance_api.dart';
import '../models/fire_package.dart';
import '../state/fire_search_state.dart';
import 'house_type_page.dart';

const _labelGrey = Color(0xFF5E5D5D);
const _boxBorder = Color(0xFF8A8989);
const _hintGrey = Color(0xFFB3B1B1);
const _noteRed = Color(0xFFFF0202);

/// Port of FF `SearchPackageFireInsurancePage` (ค้นหาประกันอัคคีภัย): house
/// type, usable area (width × length or m²), floors, the estimated building
/// value from `cal-estimated`, and the contents value → insurer list.
///
/// Not ported: the AppBar title's hidden tap action (a debug Firebase-upload
/// test in the mobile app) and the area boxes' taps that toggled the unrelated
/// `buttonOrdinary` / `buttonCorporation` app flags.
class FireSearchPage extends StatefulWidget {
  const FireSearchPage({super.key});

  @override
  State<FireSearchPage> createState() => _FireSearchPageState();
}

class _FireSearchPageState extends State<FireSearchPage> {
  final _state = FireSearchState.instance;

  final _width = TextEditingController();
  final _long = TextEditingController();
  final _squareMeter = TextEditingController();
  final _buildinAsset = TextEditingController();
  final _widthFocus = FocusNode();
  final _longFocus = FocusNode();
  final _squareMeterFocus = FocusNode();
  final _buildinAssetFocus = FocusNode();

  /// FF page-local `isSelectedCentimeterSquar` (false = width × length).
  bool _isSquareMeter = false;

  /// The estimate started by a field losing focus; the search button waits
  /// for it (see [_onSearch]).
  Future<void>? _pendingEstimate;

  @override
  void initState() {
    super.initState();
    // FF on-load: clear the search data and the estimate.
    _state.reset();
    _widthFocus.addListener(() => _onAreaFocus(_widthFocus, _width));
    _longFocus.addListener(() => _onAreaFocus(_longFocus, _long));
    _squareMeterFocus.addListener(() => _onAreaFocus(_squareMeterFocus, _squareMeter));
    _buildinAssetFocus.addListener(() => _formatOnFocus(_buildinAssetFocus, _buildinAsset));
  }

  @override
  void dispose() {
    for (final c in [_width, _long, _squareMeter, _buildinAsset]) {
      c.dispose();
    }
    for (final f in [_widthFocus, _longFocus, _squareMeterFocus, _buildinAssetFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  String get _areaType => _isSquareMeter ? '02' : '01';

  /// Focus → plain digits; blur → digits with commas (FF behaviour).
  void _formatOnFocus(FocusNode node, TextEditingController c) {
    setState(() {
      c.text = node.hasFocus
          ? ff.removeCommaFromNumText(c.text)
          : ff.showNumberWithCommaWithoutDot2(c.text);
    });
  }

  void _onAreaFocus(FocusNode node, TextEditingController c) {
    if (!node.hasFocus) _pendingEstimate = _estimateIfReady();
    _formatOnFocus(node, c);
  }

  int? _int(String text) => int.tryParse(ff.removeCommaFromNumText(text));

  /// Re-runs `cal-estimated` once house type, area and floor are all set —
  /// the check FF repeated after the house-type picker, the floor picker and
  /// every area field's blur.
  Future<void> _estimateIfReady() async {
    if (_state.houseTypeName.isEmpty || _state.houseFloor.isEmpty) return;
    String usableArea;
    String width;
    String length;
    if (_isSquareMeter) {
      if (_squareMeter.text.isEmpty) return;
      usableArea = ff.removeCommaFromNumText(_squareMeter.text);
      width = '0';
      length = '0';
    } else {
      final w = _int(_width.text);
      final l = _int(_long.text);
      // FF int.parse threw on a bad value (nothing happened); skip instead.
      if (w == null || l == null) return;
      usableArea = '${w * l}';
      width = '$w';
      length = '$l';
    }
    // FF showed the loading overlay for the m² path and the pickers only; the
    // port shows it on every estimate so the search can't start mid-request.
    final r = await withLoading(
      context,
      () => FireInsuranceApi.instance.calEstimated(
        houseAreaType: _areaType,
        houseTypeCode: _state.houseTypeCode,
        usableArea: usableArea,
        floor: _state.houseFloor,
        width: width,
        length: length,
      ),
    );
    if (!mounted) return;
    if (r.statusCode != 200) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.statusCode})');
    } else if (r.code != 200) {
      await showAlert(context, '${r.message}');
    } else {
      _state.estimate = r.data ?? _state.estimate;
      setState(() {});
    }
  }

  /// FF stored the typed area into the app state before opening a picker.
  void _saveAreaToState() {
    _state.houseAreaType = _areaType;
    final w = _int(_width.text);
    final l = _int(_long.text);
    _state.usableArea = _isSquareMeter
        ? ff.removeCommaFromNumText(_squareMeter.text)
        : (w != null && l != null ? '${w * l}' : '');
    _state.houseWidth = ff.removeCommaFromNumText(_width.text);
    _state.houseLong = ff.removeCommaFromNumText(_long.text);
  }

  Future<void> _pickHouseType() async {
    _saveAreaToState();
    final type = await HouseTypePage.open(context);
    if (type == null || !mounted) return;
    setState(() {
      _state
        ..houseTypeCode = type.code
        ..houseTypeName = type.name;
    });
    await _estimateIfReady();
  }

  Future<void> _pickFloor() async {
    _saveAreaToState();
    const floors = ['1', '2', '3', '4', '5'];
    final picked = await SearchableListPage.open(
      context,
      titleText: 'เลือกจำนวนชั้น',
      searchLabel: 'ระบุจำนวนชั้น',
      items: floors,
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() => _state.houseFloor = floors[picked.first]);
    await _estimateIfReady();
  }

  /// Area-type card tap (even on the selected one): clear the other inputs,
  /// the estimate and everything but the house type.
  void _selectAreaType(bool squareMeter) {
    setState(() {
      _isSquareMeter = squareMeter;
      if (squareMeter) {
        _width.clear();
        _long.clear();
      } else {
        _squareMeter.clear();
      }
      _buildinAsset.clear();
      _state
        ..estimate = const HouseEstimate()
        ..clearArea();
    });
  }

  Future<void> _onSearch() async {
    // FF read the fields without leaving them, so a value typed last had not
    // been estimated yet; blur first and wait for that estimate.
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    await _pendingEstimate;
    if (!mounted) return;

    Future<void> alert(String m) => showAlert(context, m);
    if (_state.houseTypeName.isEmpty) return alert('กรุณาเลือกประเภทที่อยู่อาศัย');
    if (_isSquareMeter) {
      if (_squareMeter.text.isEmpty) return alert('กรุณากรอกขนาดตารางเมตร');
    } else {
      if (_width.text.isEmpty) return alert('กรุณากรอกความกว้าง');
      if (_long.text.isEmpty) return alert('กรุณากรอกความยาว');
    }
    if (_state.houseFloor.isEmpty) return alert('กรุณาเลือกจำนวนชั้น');
    if (_buildinAsset.text.isEmpty) return alert('กรุณากรอกทรัพย์สินภายในสิ่งปลูกสร้าง');

    final w = _int(_width.text) ?? 0;
    final l = _int(_long.text) ?? 0;
    final floor = int.tryParse(_state.houseFloor) ?? 0;
    final house = '${_state.estimate.estimatedPrice}';
    final buildin = ff.removeCommaFromNumber(_buildinAsset.text);
    _state
      ..houseAreaType = _areaType
      // FF sent the m² text as shown (with commas); the port sends digits.
      // Width × length mode multiplies by the floors here (not in the estimate).
      ..usableArea = _isSquareMeter ? ff.removeCommaFromNumText(_squareMeter.text) : '${w * l * floor}'
      ..sumInsureHouse = house
      ..sumInsureBuildin = buildin
      ..houseWidth = _isSquareMeter ? '0' : ff.removeCommaFromNumber(_width.text)
      ..houseLong = _isSquareMeter ? '0' : ff.removeCommaFromNumber(_long.text)
      ..criteria = FireSearchCriteria(
        yearMin: '1',
        yearMax: '1',
        sumInsured: '${(int.tryParse(house) ?? 0) + (int.tryParse(buildin) ?? 0)}',
        sumInsureHouse: house,
        sumInsureBuilding: buildin,
      )
      ..notify();
    context.push(AppRoutes.fireInsurers);
  }

  void _back() {
    // FF safePop. Opened by the host as the first page → web menu.
    // TODO(bridge): hand control back to the host app instead.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final floorSet = _state.houseFloor.isNotEmpty;
    return UnfocusOnTap(
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: tanjaiAppBar(
          title: 'ค้นหาประกันอัคคีภัย',
          titleSize: 22,
          titleColor: const Color(0xFF003063),
          backColor: AppColors.buttonOrange,
          onBack: _back,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _Section(
                  label: 'ประเภทที่อยู่อาศัย',
                  note: '(กรุณาเลือก)',
                  child: _SelectBox(
                    value: _state.houseTypeName,
                    placeholder: 'เลือกประเภทที่อยู่อาศัย',
                    onTap: _pickHouseType,
                  ),
                ),
                _Section(
                  label: 'ขนาดพื้นที่ใช้สอย',
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                          child: _AreaTypeCard(
                            selected: !_isSquareMeter,
                            image: 'assets/images/fire/area_width_length.png',
                            label: 'ขนาดกว้าง x ยาว',
                            onTap: () => _selectAreaType(false),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                          child: _AreaTypeCard(
                            selected: _isSquareMeter,
                            image: 'assets/images/fire/area_square_meter.png',
                            label: 'ขนาดตารางเมตร',
                            onTap: () => _selectAreaType(true),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _isSquareMeter ? _squareMeterInput() : _widthLengthInput(),
                ),
                _Section(
                  label: 'จำนวนชั้น',
                  note: '(กรุณาเลือก)',
                  child: _SelectBox(
                    value: _state.houseFloor,
                    placeholder: 'เลือกจำนวนชั้น',
                    onTap: _pickFloor,
                  ),
                ),
                _Section(
                  label: 'สิ่งปลูกสร้าง',
                  note: '(ไม่รวมรากฐาน)',
                  noteStyle: AppText.style(fontSize: 18, color: _labelGrey),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _boxBorder),
                    ),
                    padding: const EdgeInsets.only(left: 15),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ff.showNumberWithCommaWithoutDot2('${_state.estimate.estimatedPrice}'),
                      style: AppText.style(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: floorSet ? Colors.black : _hintGrey,
                      ),
                    ),
                  ),
                ),
                _Section(
                  label: 'ทรัพย์สินภายในสิ่งปลูกสร้าง',
                  note: '(กรุณากรอก)',
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _boxBorder),
                    ),
                    alignment: Alignment.center,
                    child: _NumberField(
                      controller: _buildinAsset,
                      focusNode: _buildinAssetFocus,
                      hint: 'กรุณากรอกจำนวนเงิน',
                      fontSize: 14,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 100,
                  color: AppColors.secondaryBackground,
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: AppButton(text: 'ค้นหา', onPressed: _onSearch),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _widthLengthInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LabelRow(label: 'ขนาดกว้าง x ยาว', note: '(กรุณากรอก)'),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                    child: _InputBox(
                      child: _NumberField(controller: _width, focusNode: _widthFocus, hint: 'กว้าง'),
                    ),
                  ),
                ),
                Text('X', style: AppText.style(fontSize: 20, color: _labelGrey)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                    child: _InputBox(
                      child: _NumberField(controller: _long, focusNode: _longFocus, hint: 'ยาว'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Text('เมตร', style: AppText.style(color: _labelGrey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _squareMeterInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LabelRow(label: 'ขนาดตารางเมตร', note: '(กรุณากรอก)'),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _InputBox(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _NumberField(
                          controller: _squareMeter,
                          focusNode: _squareMeterFocus,
                          hint: 'ขนาดตารางเมตร',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Text('ตารางเมตร', style: AppText.style(color: _labelGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grey 18 label + optional red 15 note (FF section header).
class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, this.note = '', this.noteStyle});

  final String label;
  final String note;
  final TextStyle? noteStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        children: [
          Text(label, style: AppText.style(fontSize: 18, color: _labelGrey)),
          if (note.isNotEmpty)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(note, style: noteStyle ?? AppText.style(fontSize: 15, color: _noteRed)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Section with the FF padding (15, 20, 23, 0): header, then the field.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child, this.note = '', this.noteStyle});

  final String label;
  final String note;
  final TextStyle? noteStyle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 20, 23, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelRow(label: label, note: note, noteStyle: noteStyle),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// 60px picker box: value (or grey placeholder) + chevron.
class _SelectBox extends StatelessWidget {
  const _SelectBox({required this.value, required this.placeholder, required this.onTap});

  final String value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSet = value.isNotEmpty;
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _boxBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Text(
                  isSet ? value : placeholder,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.style(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSet ? Colors.black : _hintGrey,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 5),
              child: Icon(Icons.arrow_forward_ios_sharp, color: _labelGrey, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

/// 'ขนาดกว้าง x ยาว' / 'ขนาดตารางเมตร' card; the selected one is raised,
/// taller and has a thick orange border.
class _AreaTypeCard extends StatelessWidget {
  const _AreaTypeCard({required this.selected, required this.image, required this.label, required this.onTap});

  final bool selected;
  final String image;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        elevation: selected ? 10 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: selected ? 140 : 128,
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.buttonOrange : _boxBorder,
              width: selected ? 3 : 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(image, fit: BoxFit.cover),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppText.style(fontSize: 18, color: _boxBorder),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 60px rounded input box (radius 16, grey border).
class _InputBox extends StatelessWidget {
  const _InputBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _boxBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Borderless numeric field. Digits only: FF's int.parse crashed (and the
/// page silently did nothing) on anything else.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.fontSize = 14,
    this.keyboardType = TextInputType.number,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final double fontSize;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      cursorColor: AppColors.primaryText,
      style: AppText.style(fontSize: fontSize),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.secondaryBackground,
        hoverColor: Colors.transparent,
        hintText: hint,
        hintStyle: AppText.style(fontSize: 16, fontWeight: FontWeight.w500, color: _hintGrey),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
