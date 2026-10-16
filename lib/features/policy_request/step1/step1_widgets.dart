import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/env_version_tag.dart';
import '../shared/request_widgets.dart';
import 'step1_data.dart';

/// FF `MaskTextInputFormatter(mask: '#-####-#####-##-#')`: digits only,
/// max 13, dashes after digit 1, 5, 10 and 12.
class IdCardMaskFormatter extends TextInputFormatter {
  static String format(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 13) digits = digits.substring(0, 13);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 1 || i == 5 || i == 10 || i == 12) buf.write('-');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = format(newValue.text);
    final caretDigits = newValue.text
        .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'\D'), '')
        .length;
    var offset = 0;
    for (var seen = 0; offset < text.length && seen < caretDigits; offset++) {
      if (text[offset] != '-') seen++;
    }
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: offset));
  }
}

/// FF text box of page 1: 60 high, radius 8, border #B3B3B3, text 15 w600.
class Step1TextBox extends StatelessWidget {
  const Step1TextBox({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
    this.suffix,
    this.color = AppColors.secondaryBackground,
    this.hintColor = kRequestGrey,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final Widget? suffix;
  final Color color;
  final Color hintColor;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return RequestBox(
      color: color,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: AppText.style(fontSize: 15, color: Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          hintText: hint,
          hintStyle: AppText.style(fontSize: 15, color: hintColor),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}

/// FF 'ตรวจสอบรายชื่อ' / 'ค้นหา' button: 37 % wide, 60 high, #FCEFE4, radius 16.
class Step1SideButton extends StatelessWidget {
  const Step1SideButton({super.key, required this.text, required this.icon, required this.onTap});

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.37,
      height: 60,
      child: Material(
        color: kRequestLightOrange,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kRequestOrange, size: 20),
              const SizedBox(width: 4),
              Flexible(
                child: Text(text, overflow: TextOverflow.ellipsis, style: AppText.style(color: kRequestOrange)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// FF circular compact checkbox (active #00B505, white check, unselected
/// border secondaryText 2 px).
class Step1RoundCheckbox extends StatelessWidget {
  const Step1RoundCheckbox({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      shape: const CircleBorder(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      activeColor: const Color(0xFF00B505),
      checkColor: Colors.white,
      side: const BorderSide(width: 2, color: AppColors.secondaryText),
    );
  }
}

/// FF `SearchableListPage` in its 'ค้นหาที่อยู่' mode: the list stays hidden
/// until something is typed (thousands of rows). Pops with the master index.
class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({super.key, required this.rows});

  final List<AddressMasterRow> rows;

  static Future<int?> open(BuildContext context, List<AddressMasterRow> rows) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push<int>(MaterialPageRoute(builder: (_) => AddressSearchPage(rows: rows)));
  }

  @override
  State<AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  List<int> _hits = const [];

  /// FF filter: `item.contains(query.toUpperCase())` or the item without
  /// dashes contains it (case-sensitive for Latin text — FF quirk, kept).
  void _search(String query) {
    final q = query.toUpperCase();
    setState(() {
      _hits = query.isEmpty
          ? const []
          : [
              for (var i = 0; i < widget.rows.length; i++)
                if (widget.rows[i].keyword.contains(q) || widget.rows[i].keyword.replaceAll('-', '').contains(q)) i,
            ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return UnfocusOnTap(
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          centerTitle: true,
          elevation: 2,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.backIconOrange, size: 30),
          ),
          title: Text('ค้นหาที่อยู่', style: AppText.style(fontSize: 16, color: AppColors.titleNavy)),
          actions: const [EnvVersionTag()],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(width: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  child: TextField(
                    autofocus: true,
                    onChanged: _search,
                    style: AppText.bodyMedium,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      hintText: 'ระบุรหัสไปรษณีย์หรือตำบล,อำเภอ,จังหวัด',
                      hintStyle: AppText.labelMedium,
                      prefixIcon: const Icon(Icons.search_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _hits.length,
                    itemBuilder: (context, n) {
                      final i = _hits[n];
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(i),
                        child: Container(
                          color: AppColors.secondaryBackground,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 60,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(widget.rows[i].keyword, style: AppText.bodyMedium),
                                  ),
                                ),
                              ),
                              const Divider(height: 1, thickness: 1, color: AppColors.accent4),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
