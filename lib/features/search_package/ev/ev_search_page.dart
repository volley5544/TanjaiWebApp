import 'package:flutter/material.dart';

import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/loading_scene.dart';
import '../product_type.dart';
import '../shared/car_type_page.dart';
import '../shared/search_form/expiry_date_section.dart';
import '../shared/search_form/search_form_scaffold.dart';
import '../shared/search_form/search_pickers.dart';
import '../shared/search_form/search_selector_section.dart';
import 'ev_search_controller.dart';

/// EV ค้นหาประกันรถ — EV search entry page (FF SearchInsurancePage,
/// `fromIcon == 'EV'`).
class EvSearchPage extends StatefulWidget {
  const EvSearchPage({super.key});

  @override
  State<EvSearchPage> createState() => _EvSearchPageState();
}

class _EvSearchPageState extends State<EvSearchPage> {
  final _controller = EvSearchController();
  bool _pickUpUsagesLoading = true;

  @override
  void initState() {
    super.initState();
    _controller.loadPickUp2DoorUsages().whenComplete(() {
      if (mounted) setState(() => _pickUpUsagesLoading = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _onLoad());
  }

  /// FF reloads all master data every time the page opens.
  Future<void> _onLoad() async {
    _controller.resetOnLoad();
    final error = await withLoading(context, _controller.loadMasterData);
    if (error != null && mounted) await showAlert(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final provinceName = state.selectedProvince?.nameTh ?? '';
        return SearchFormScaffold(
          title: ProductType.ev.searchTitle,
          onBack: () => _controller.back(context),
          onSearch: () => _controller.search(context),
          sections: [
            SearchSelectorSection(
              label: 'ประเภทรถ',
              value: state.vehicleTypeLabel,
              isPlaceholder: isPlaceholderText(state.vehicleTypeLabel),
              onTap: () => CarTypePage.open(context, state),
            ),
            SearchSelectorSection(
              label: 'ยี่ห้อรถ',
              value: state.brandLabel,
              isPlaceholder: isPlaceholderText(state.brandLabel),
              onTap: () => SearchPickers.brand(context, state),
            ),
            if (state.isBrandSelected)
              FadeSlideIn(
                child: SearchSelectorSection(
                  label: 'รุ่นรถ',
                  value: state.modelLabel,
                  isPlaceholder: isPlaceholderText(state.modelLabel),
                  onTap: () => SearchPickers.model(context, state),
                ),
              ),
            SearchSelectorSection(
              label: 'ปีจดทะเบียน พ.ศ.',
              value: state.yearLabel,
              isPlaceholder: isPlaceholderText(state.yearLabel),
              onTap: () => SearchPickers.year(context, state),
            ),
            if (_pickUpUsagesLoading)
              const SectionSpinner()
            else
              SearchSelectorSection(
                label: 'ลักษณะการใช้รถ',
                value: usageDisplay(state),
                isPlaceholder: state.selectedUsage == null,
                onTap: () => SearchPickers.usage(context, state),
              ),
            SearchSelectorSection(
              label: 'ประเภทชั้นประกัน',
              note: '(บังคับเลือก สามารถเลือกได้มากกว่า 1)',
              value: state.selectedCoverTypes.isNotEmpty
                  ? combineStringFromList([for (final c in state.selectedCoverTypes) c.name])
                  : 'กรุณาเลือกประเภทชั้นประกัน',
              isPlaceholder: state.selectedCoverTypes.isEmpty,
              onTap: () => SearchPickers.coverTypes(context, state),
            ),
            SearchSelectorSection(
              label: 'ประเภทการซ่อม',
              note: '(บังคับเลือก สามารถเลือกได้มากกว่า 1)',
              labelColor: const Color(0xFF424242),
              value: state.selectedGarageTypes.isNotEmpty
                  ? combineStringFromList(state.selectedGarageTypes)
                  : 'กรุณาเลือกประเภทการซ่อม',
              isPlaceholder: state.selectedGarageTypes.isEmpty,
              onTap: () => SearchPickers.garageTypes(context, state),
            ),
            SearchSelectorSection(
              label: 'จังหวัดที่จดทะเบียน',
              note: '(บังคับกรอก)',
              provinceStyle: true,
              value: provinceName.isNotEmpty ? provinceName : 'กรุณาเลือกจังหวัดที่จดทะเบียน',
              isPlaceholder: provinceName.isEmpty,
              onTap: () => SearchPickers.province(context, state),
            ),
            ExpiryDateSection(
              date: state.oldPolicyExpiry,
              onChanged: (d) {
                state.oldPolicyExpiry = d;
                state.notify();
              },
            ),
          ],
        );
      },
    );
  }
}
