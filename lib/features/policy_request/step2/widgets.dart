import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/env_version_tag.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../manual_request/data/manual_request_api.dart';
import '../shared/request_widgets.dart';

/// Widgets shared by step 2 and its sub-pages (HR21 / HR22 / HR23,
/// SearchBranchPage 'Step2').

/// HR21/22/23 AppBar: white, elevation 2, back `arrow_back` #DB771A 30,
/// centred title #204A77 18.
PreferredSizeWidget step2SubAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: AppColors.primaryBackground,
    surfaceTintColor: Colors.transparent,
    automaticallyImplyLeading: false,
    centerTitle: true,
    elevation: 2,
    shadowColor: const Color(0x33000000),
    leading: IconButton(
      onPressed: () => Navigator.of(context).pop(),
      splashRadius: 30,
      icon: const Icon(Icons.arrow_back, color: AppColors.brandOrange, size: 30),
    ),
    title: Text(title, style: AppText.style(fontSize: 18, color: const Color(0xFF204A77))),
    actions: const [EnvVersionTag()],
  );
}

/// HR label: '<label>' #1D4774 15 w600 + red tag 12 w600.
class Step2SubLabel extends StatelessWidget {
  const Step2SubLabel(this.label, {super.key, this.tag = '', this.color = const Color(0xFF1D4774)});

  final String label;
  final String tag;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label, style: AppText.style(fontSize: 15, color: color)),
          if (tag.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(tag, style: AppText.style(fontSize: 12, color: kRequestTagRed)),
            ),
        ],
      ),
    );
  }
}

/// HR option box: 60 high, white, radius 8, border #B3B3B3, label #B3B3B3
/// 15 w600 on the left, round checkbox on the right.
class Step2OptionBox extends StatelessWidget {
  const Step2OptionBox({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    required this.onChanged,
    this.activeColor = const Color(0xFF00FD76),
  });

  final String label;
  final bool value;
  final VoidCallback onTap;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onTap,
      child: RequestBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(label, style: AppText.style(fontSize: 15, color: kRequestGrey)),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Checkbox(
                value: value,
                shape: const CircleBorder(),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(width: 2, color: AppColors.secondaryText),
                activeColor: activeColor,
                checkColor: AppColors.primaryBtnText,
                onChanged: (v) => onChanged(v ?? false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page-2 sub-page row (อุปกรณ์เสริม / พ.ร.บ. / ผู้รับผลประโยชน์): 60 px box,
/// left part 60 % wide with a 50 px black-bordered circle icon, then
/// [texts]; trailing `navigate_next`.
class Step2NavRow extends StatelessWidget {
  const Step2NavRow({super.key, required this.icon, required this.texts, required this.onTap});

  final IconData icon;
  final List<Widget> texts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: RequestBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: w * 0.6,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Icon(icon, color: AppColors.secondaryText, size: 30),
                      ),
                    ),
                    for (final t in texts) Flexible(child: t),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.navigate_next, color: AppColors.secondaryText, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text inside a [Step2NavRow] (#003063 15, left padding [left]).
Widget step2NavText(String text, {double left = 10, Color color = kRequestNavy, double size = 15}) => Padding(
      padding: EdgeInsets.only(left: left),
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.style(fontSize: size, color: color)),
    );

/// HR 'ตกลง' button: full width, 60 high, #DB771B, white 15, radius 16.
class Step2OkButton extends StatelessWidget {
  const Step2OkButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: AppButton(text: 'ตกลง', onPressed: onPressed, color: AppColors.buttonOrange),
    );
  }
}

/// FF `FlutterFlowDropDown(isSearchable: true)` in a 60 px box: shows
/// [value] or [hint]; tapping opens a searchable list dialog.
class Step2SearchDropdown extends StatelessWidget {
  const Step2SearchDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final List<String> options;
  final String? value;
  final String hint;
  final ValueChanged<String> onChanged;

  Future<void> _open(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _SearchDialog(options: options, hint: hint),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return RequestBox(
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: value == null
                      ? AppText.style(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.secondaryText)
                      : AppText.style(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  const _SearchDialog({required this.options, required this.hint});

  final List<String> options;
  final String hint;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.toLowerCase();
    final items = widget.options.where((o) => q.isEmpty || o.toLowerCase().contains(q)).toList();
    return Dialog(
      backgroundColor: AppColors.secondaryBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              style: AppText.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppText.labelMedium,
                prefixIcon: const Icon(Icons.search_outlined),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, i) => InkWell(
                onTap: () => Navigator.of(context).pop(items[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(items[i], style: AppText.style(fontSize: 15, fontWeight: FontWeight.normal)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// FF `SearchBranchPage(fromPage: 'Step2')`: branches from the local API,
/// filtered by code / name; tapping one pops with it (the caller stores
/// `code.toUpperCase()` / name). Same UI and errors as the manual-request
/// copy (`manual_request/shared/branch_and_sample_pages.dart`, which writes
/// the manual-request state and so can't be reused as is).
class Step2BranchPage extends StatefulWidget {
  const Step2BranchPage({super.key});

  static Future<NpBranch?> open(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push<NpBranch>(MaterialPageRoute(builder: (_) => const Step2BranchPage()));
  }

  @override
  State<Step2BranchPage> createState() => _Step2BranchPageState();
}

class _Step2BranchPageState extends State<Step2BranchPage> {
  final _search = TextEditingController();
  bool _loading = true;
  List<NpBranch>? _branches;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await ManualRequestApi.instance.getBranches();
    if (!mounted) return;
    setState(() => _loading = false);
    // FF read a dead button's response here ('(null)' / '(200)'); the real
    // status is shown instead.
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.httpStatus})');
    } else if (r.status1 == 404) {
      await showAlert(context, 'ไม่พบข้อมูลสาขา');
    } else if (r.status1 != 200) {
      await showAlert(context, 'พบข้อผิดพลาดLayer2 (${r.status1})');
    } else {
      setState(() => _branches = r.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    // FF matched the upper-cased query against the raw values (case-sensitive).
    final q = _search.text;
    final items = (_branches ?? const <NpBranch>[])
        .where((b) => q.isEmpty || b.code.contains(q.toUpperCase()) || b.name.contains(q.toUpperCase()))
        .toList();
    return UnfocusOnTap(
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: tanjaiAppBar(title: 'ค้นหาสาขาที่จะลงผลงาน', titleSize: 16, onBack: () => Navigator.of(context).pop()),
        body: _loading
            ? const PageLoadingView()
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(width: 0.5),
                        ),
                        alignment: Alignment.center,
                        child: TextField(
                          controller: _search,
                          style: AppText.bodyMedium,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_outlined),
                            hintText: 'กรอกชื่อสาขาที่จะค้นหา',
                            hintStyle: AppText.labelMedium,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final b = items[i];
                            return InkWell(
                              onTap: () => Navigator.of(context).pop(b),
                              child: Container(
                                height: 60,
                                color: Colors.white,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 50,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 12),
                                              child: Text('(${b.code}) ${b.name}', style: AppText.bodyMedium),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 10, thickness: 1, color: Color(0xFFEEEEEE)),
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
