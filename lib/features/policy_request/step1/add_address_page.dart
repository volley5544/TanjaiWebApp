import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/env_version_tag.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../data/policy_request_api.dart';
import '../shared/request_widgets.dart';
import '../state/policy_request_state.dart';
import 'step1_data.dart';
import 'step1_widgets.dart';

/// เพิ่มที่อยู่ — FF AddAddress (pushed from step 1's address card). Edits
/// `PolicyRequestState.step1` addresses; back pops without saving.
class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  Step1Data get _s1 => PolicyRequestState.instance.step1;

  // FF controllers start from the state; the FF default text
  // 'กรุณากรอกที่อยู่' (or FF's 'null') would have been put in the box as
  // text — the port starts those empty.
  late final _address2 = TextEditingController(text: _txt(_s1.idCardAddress.line1));
  late final _address3 = TextEditingController(text: _txt(_s1.idCardAddress.line2));
  late final _address4 = TextEditingController(text: _txt(_s1.docAddress.line1));
  late final _address5 = TextEditingController(text: _txt(_s1.docAddress.line2));

  static String _txt(String v) => step1HasAddressText(v) ? v : '';

  /// FF addressAtIdCardValue / addressForDocValue (set on first build).
  late bool _atIdCard;
  late bool _forDoc;

  bool _loading = AddressMasterRow.cache == null;

  @override
  void initState() {
    super.initState();
    if (redirectIfNoFlow(context)) return;
    final at = _s1.idCardAddress.keyword;
    final doc = _s1.docAddress.keyword;
    // FF used "non-empty"; the placeholder counts as empty here.
    final hasAt = step1HasAddressText(at);
    final hasDoc = step1HasAddressText(doc);
    _atIdCard = hasDoc ? (at == doc && hasAt) : hasAt;
    _forDoc = hasDoc && at != doc;
    if (_loading) WidgetsBinding.instance.addPostFrameCallback((_) => _loadMaster());
  }

  @override
  void dispose() {
    _address2.dispose();
    _address3.dispose();
    _address4.dispose();
    _address5.dispose();
    super.dispose();
  }

  /// GetAddressMasterCall — once per app session (FF addAddressCallAPI).
  Future<void> _loadMaster() async {
    try {
      final r = await PolicyRequestApi.instance.getAddressMaster();
      if (!mounted) return;
      if (!await requestCheck(context, statusCode: r.statusCode, code: r.code, message: r.message)) return;
      AddressMasterRow.cache = AddressMasterRow.listFrom(r.json);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick(Step1Address target) async {
    final rows = AddressMasterRow.cache ?? const <AddressMasterRow>[];
    final i = await AddressSearchPage.open(context, rows);
    if (i == null || !mounted) return;
    setState(() => target.pick(rows[i]));
  }

  void _setAtIdCard() => setState(() {
        _atIdCard = true;
        _forDoc = false;
      });

  void _setForDoc() => setState(() {
        _atIdCard = false;
        _forDoc = true;
      });

  /// FF 'บันทึก'.
  Future<void> _save() async {
    final s1 = _s1;
    bool filled(String v) => v != kStep1AddressPh && v.isNotEmpty;
    if (filled(s1.idCardAddress.keyword) && filled(_address2.text)) {
      s1.idCardAddress
        ..line1 = _address2.text
        ..line2 = _address3.text;
      s1.docSameAsIdCard = _atIdCard;
      s1.docSeparate = _forDoc;
      if (_atIdCard && !_forDoc) {
        // FF copies only the keyword; the save then sends the ID-card
        // address as CURRENT because docSameAsIdCard is set.
        s1.docAddress.keyword = s1.idCardAddress.keyword;
        context.pop();
        return;
      }
    } else {
      await showAlert(context, 'กรุณากรอกที่อยู่ให้ครบ');
      return;
    }
    // FF: also shown when neither option is ticked (the doc block is hidden then) — kept.
    if (!(filled(s1.docAddress.keyword) && filled(_address4.text))) {
      await showAlert(context, 'กรุณากรอกที่อยู่จัดส่งเอกสาร');
      return;
    }
    s1.docAddress
      ..line1 = _address4.text
      ..line2 = _address5.text;
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: AppColors.primaryBackground,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      centerTitle: true,
      elevation: 2,
      shadowColor: const Color(0x33000000),
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back, color: AppColors.brandOrange, size: 30),
      ),
      title: Text('เพิ่มที่อยู่', style: AppText.style(fontSize: 18, color: const Color(0xFF204A77))),
      actions: const [EnvVersionTag()],
    );
    return PopScope(
      canPop: false,
      child: UnfocusOnTap(
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: appBar,
          body: _loading || !PolicyRequestState.instance.isActive ? const PageLoadingView() : _body(),
        ),
      ),
    );
  }

  Widget _body() {
    final s1 = _s1;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FF tag text is missing its '(' — kept.
            _label('ที่อยู่ตามบัตรประชาชน', 'บังคับกรอกตำบล/อำเภอ/จังหวัด/ไปรษณีย์)', header: true),
            _picker(s1.idCardAddress, Colors.black),
            _label('ที่อยู่บรรทัด 1', '(บังคับกรอกเลขที่/หมู่บ้าน/อาคาร/ซอย/ถนน)'),
            _field(_address2),
            _label('ที่อยู่บรรทัด 2', ''),
            _field(_address3),
            _label('ที่อยู่จัดส่งเอกสาร', '(บังคับเลือก)', header: true),
            _option('ที่อยู่ตามบัตรประชาชน', _atIdCard, onTap: _setAtIdCard, onChanged: (v) {
              if (v) {
                _setAtIdCard();
              } else {
                setState(() => _atIdCard = false);
              }
            }),
            const SizedBox(height: 15),
            _option('ที่อยู่จัดส่งเอกสาร', _forDoc, onTap: _setForDoc, onChanged: (v) {
              if (v) {
                _setForDoc();
              } else {
                setState(() => _forDoc = false);
              }
            }),
            if (_forDoc) ...[
              _label('ที่อยู่จัดส่งเอกสาร', '(บังคับกรอกตำบล/อำเภอ/จังหวัด/ไปรษณีย์)', header: true),
              _picker(s1.docAddress, AppColors.primaryText),
              _label('ที่อยู่บรรทัด 1', '(บังคับกรอกเลขที่/หมู่บ้าน/อาคาร/ซอย/ถนน)'),
              _field(_address4),
              _label('ที่อยู่บรรทัด 2', ''),
              _field(_address5),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: AppButton(
                text: 'บันทึก',
                onPressed: _save,
                color: kRequestOrange,
                textColor: AppColors.primaryBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, String tag, {bool header = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            text,
            style: header
                ? AppText.style(fontSize: 15, color: const Color(0xFF1D4774))
                : AppText.style(fontSize: 15, fontWeight: FontWeight.normal),
          ),
          if (tag.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(tag, style: AppText.style(fontSize: 12, color: kRequestTagRed)),
            ),
        ],
      ),
    );
  }

  Widget _picker(Step1Address a, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: RequestBox(
        child: InkWell(
          onTap: () => _pick(a),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    step1HasAddressText(a.keyword) ? a.keyword : 'กรุณาเพิ่มที่อยู่',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.style(fontSize: 15, fontWeight: FontWeight.normal, color: color),
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

  Widget _field(TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: RequestBox(
        child: TextField(
          controller: c,
          style: AppText.style(fontSize: 15),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            hintText: kStep1AddressPh,
            hintStyle: AppText.style(fontSize: 15, color: kRequestGrey),
          ),
        ),
      ),
    );
  }

  Widget _option(String text, bool value, {required VoidCallback onTap, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: RequestBox(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              children: [
                Expanded(child: Text(text, style: AppText.style(fontSize: 15, color: kRequestGrey))),
                Step1RoundCheckbox(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
