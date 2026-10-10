import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../data/manual_request_api.dart';
import '../state/none_package_state.dart';
import 'np_widgets.dart';

/// Port of FF `SearchBranchPage` (`fromPage: 'NonePackage'`): branches from
/// the local API, filtered by code / name; tapping one sets the request's
/// branch and pops.
///
/// Web fix: FF's error dialogs read the response of a dead button (always
/// showing `(null)` / `(200)`); here they show the real status.
class SearchBranchPage extends StatefulWidget {
  const SearchBranchPage({super.key});

  static Future<void> open(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchBranchPage()));
  }

  @override
  State<SearchBranchPage> createState() => _SearchBranchPageState();
}

class _SearchBranchPageState extends State<SearchBranchPage> {
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
        backgroundColor: npPanelGrey,
        appBar: tanjaiAppBar(
          title: 'ค้นหาสาขาที่จะลงผลงาน',
          titleSize: 16,
          onBack: () => Navigator.of(context).pop(),
        ),
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
                      if (_branches != null)
                        Expanded(
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final b = items[i];
                              return InkWell(
                                onTap: () {
                                  NonePackageState.instance
                                    ..branchCode = b.code.toUpperCase()
                                    ..branchName = b.name
                                    ..notify();
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  height: 60,
                                  color: Colors.white,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 50,
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(left: 12),
                                              child: Text('(${b.code}) ${b.name}', style: AppText.bodyMedium),
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

/// Branch selector box of the basic / edit pages (shown when the user's
/// own branch code is longer than 2 characters, FF rule).
class NpBranchSelector extends StatelessWidget {
  const NpBranchSelector({super.key, required this.state, this.labelColor, this.boxColor = Colors.white});

  final NonePackageState state;
  final Color? labelColor;
  final Color boxColor;

  @override
  Widget build(BuildContext context) {
    final set = state.branchCode.isNotEmpty && state.branchName.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelColor == null
            ? const NpLabel('เลือกสาขาที่จะลงผลงาน', tag: '(บังคับเลือก)')
            : Row(
                children: [
                  Text('เลือกสาขาที่จะลงผลงาน', style: AppText.style(fontSize: 16, color: labelColor!)),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text('(บังคับเลือก)', style: AppText.style(fontSize: 12, color: npRequiredRed)),
                  ),
                ],
              ),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: InkWell(
            onTap: () => SearchBranchPage.open(context),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: boxColor == Colors.white ? npBorderGrey : const Color(0xFF737373)),
              ),
              alignment: Alignment.center,
              child: ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                title: Text(
                  set ? '(${state.branchCode}) ${state.branchName}' : 'กรุณาเลือกสาขาที่จะลงผลงาน',
                  style: AppText.style(fontSize: 15, color: set ? Colors.black : const Color(0xFF9F9F9F)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.chevronGrey, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Port of FF `SampleIDcard` (image branch): the sample ID-card copy.
class SampleIdCardPage extends StatelessWidget {
  const SampleIdCardPage({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SampleIdCardPage()));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: tanjaiAppBar(
          title: 'ตัวอย่างสำเนาบัตรประชาชน',
          titleColor: npSectionNavy,
          backColor: npOrange,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Material(
                elevation: 1,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE6E6E6)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/sample_id_card.jpg', fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
