import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';

/// Generic searchable picker — the UI of FF `SearchableListPage`.
///
/// Unlike the FF page (which wrote ~30 mode-specific FFAppState fields keyed
/// on the Thai title), this one only *returns* the chosen row indices and the
/// caller applies the result. Pops with:
/// * single mode: `[index]` as soon as a row is tapped;
/// * multi mode: the selected indices (ascending) when ตกลง is pressed;
/// * `null` on back.
///
/// Open with [SearchableListPage.open].
class SearchableListPage extends StatefulWidget {
  const SearchableListPage({
    super.key,
    required this.titleText,
    required this.searchLabel,
    required this.items,
    this.labels,
    this.multiSelect = false,
    this.maxSelected = 0,
  });

  final String titleText;
  final String searchLabel;

  /// Row values (what the search matches against).
  final List<String> items;

  /// Optional display labels parallel to [items] (FF mapped some modes, e.g.
  /// cover-type codes → 'ชั้น 1'). Defaults to [items].
  final List<String>? labels;
  final bool multiSelect;

  /// Multi mode cap; 0 = unlimited.
  final int maxSelected;

  static Future<List<int>?> open(
    BuildContext context, {
    required String titleText,
    required String searchLabel,
    required List<String> items,
    List<String>? labels,
    bool multiSelect = false,
    int maxSelected = 0,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push<List<int>>(
      MaterialPageRoute(
        builder: (_) => SearchableListPage(
          titleText: titleText,
          searchLabel: searchLabel,
          items: items,
          labels: labels,
          multiSelect: multiSelect,
          maxSelected: maxSelected,
        ),
      ),
    );
  }

  @override
  State<SearchableListPage> createState() => _SearchableListPageState();
}

class _SearchableListPageState extends State<SearchableListPage> {
  final _searchController = TextEditingController();
  late final List<bool> _selected = List.filled(widget.items.length, false);
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// FF filter: case-sensitive `contains`, only the query is upper-cased;
  /// also matches the item with dashes removed.
  bool _visible(int i) {
    if (_query.isEmpty) return true;
    final q = _query.toUpperCase();
    final item = widget.items[i];
    return item.contains(q) || removeDash(item).contains(q);
  }

  void _onRowTap(int i) {
    if (!widget.multiSelect) {
      Navigator.of(context).pop(<int>[i]);
      return;
    }
    setState(() {
      if (widget.maxSelected == 0) {
        _selected[i] = !_selected[i];
      } else if (countTrueInBoolList(_selected) >= widget.maxSelected) {
        _selected[i] = false; // at the cap rows can only be un-selected
      } else {
        _selected[i] = !_selected[i];
      }
    });
  }

  Future<void> _onConfirm() async {
    if (countTrueInBoolList(_selected) <= 0) {
      await showAlert(context, 'กรุณาเลือกอย่างน้อย 1 รายการ');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop([
      for (var i = 0; i < _selected.length; i++)
        if (_selected[i]) i,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final count = countTrueInBoolList(_selected);
    return UnfocusOnTap(
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: tanjaiAppBar(
          title: widget.titleText,
          titleSize: 16,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      if (widget.multiSelect) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.maxSelected > 0
                                  // The FF text has no closing ')' — kept as-is.
                                  ? 'สามารถเลือกได้สูงสุด ${widget.maxSelected} รายการ ($count/${widget.maxSelected}'
                                  : 'สามารถเลือกได้มากกว่า 1 รายการ',
                              style: AppText.style(color: AppColors.error),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (widget.items.length > 5) ...[
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
                            controller: _searchController,
                            onChanged: (v) => setState(() => _query = v),
                            style: AppText.bodyMedium,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              hintText: widget.searchLabel,
                              hintStyle: AppText.labelMedium,
                              prefixIcon: const Icon(Icons.search_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: widget.items.length,
                          itemBuilder: (context, i) {
                            if (!_visible(i)) return const SizedBox.shrink();
                            final label = widget.labels != null && i < widget.labels!.length
                                ? widget.labels![i]
                                : widget.items[i];
                            return InkWell(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              onTap: () => _onRowTap(i),
                              child: Container(
                                color: AppColors.secondaryBackground,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 60,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 12),
                                              child: Text(label.isEmpty ? '-' : label, style: AppText.bodyMedium),
                                            ),
                                          ),
                                          if (_selected[i])
                                            const Padding(
                                              padding: EdgeInsets.only(right: 12),
                                              child: Icon(Icons.check_rounded, color: AppColors.success, size: 24),
                                            ),
                                        ],
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
                if (widget.multiSelect)
                  Container(
                    height: 100,
                    color: AppColors.secondaryBackground,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: AppButton(text: 'ตกลง', onPressed: _onConfirm),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
