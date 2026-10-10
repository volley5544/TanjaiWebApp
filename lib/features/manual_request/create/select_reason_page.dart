import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../router/app_router.dart';
import '../shared/np_widgets.dart';
import '../state/none_package_state.dart';

const _navy = Color(0xFF1D4774);

/// Port of FF `SelectReasonPage` ('งานนอกเรท'): one of three reasons + the
/// customer type, then the basic form.
///
/// Web fix: FF built the first frame with an empty reasons list (null crash
/// until its post-frame reset); here the reasons start as [false×3].
class SelectReasonPage extends StatefulWidget {
  const SelectReasonPage({super.key});

  @override
  State<SelectReasonPage> createState() => _SelectReasonPageState();
}

class _SelectReasonPageState extends State<SelectReasonPage> {
  final _s = NonePackageState.instance;

  static const _reasons = ['ไม่มีในเรท', 'ไม่พอใจในทุนประกัน', 'รถแต่งหรือรถต่อคอก'];

  @override
  void initState() {
    super.initState();
    if (!_s.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
    } else {
      _s.reason = [false, false, false];
    }
  }

  void _next() {
    if (!_s.reason.contains(true)) {
      showAlert(context, 'กรุณาเลือกเหตุผลการทำประกัน');
      return;
    }
    if (!_s.buttonOrdinary && !_s.buttonCorporation) {
      showAlert(context, 'กรุณาเลือกผู้ทำประกัน');
      return;
    }
    context.push(AppRoutes.manualBasic);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.white,
        appBar: npAppBar('งานนอกเรท', titleColor: _navy, onBack: () => context.pop()),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 15, 12, 0),
                  child: Text('กรุณากรอกเหตุผลที่ต้องการประกันนอกเรท', style: AppText.style(fontSize: 15, color: _navy)),
                ),
                for (var i = 0; i < 3; i++) _reasonCard(i),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFF1F4F8),
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _customerCard(
                                label: 'บุคคลธรรมดา',
                                icon: Icons.person_outline_sharp,
                                iconSize: 35,
                                selected: _s.buttonOrdinary,
                                onTap: () {
                                  final on = !_s.buttonOrdinary;
                                  _s
                                    ..buttonOrdinary = on
                                    ..buttonCorporation = false
                                    ..notify();
                                },
                              ),
                              _customerCard(
                                label: 'นิติบุคคล',
                                icon: Icons.home_work_outlined,
                                iconSize: 30,
                                selected: _s.buttonCorporation,
                                onTap: () {
                                  final on = !_s.buttonCorporation;
                                  _s
                                    ..buttonCorporation = on
                                    ..buttonOrdinary = false
                                    ..notify();
                                },
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                            child: AppButton(
                              text: 'ถัดไป',
                              onPressed: _next,
                              height: 50,
                              color: const Color(0xB6FF6500),
                              fontSize: 16,
                              radius: 12,
                              elevation: 2,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reasonCard(int i) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            _s.reason = [for (var k = 0; k < 3; k++) k == i];
            _s.notify();
          },
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(blurRadius: 5, color: Color(0x34111417), offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(_reasons[i], style: AppText.style(fontSize: 15, color: const Color(0xFF878787))),
                ),
                Padding(padding: const EdgeInsets.only(right: 10), child: NpSelectCircle(_s.reason[i])),
              ],
            ),
          ),
        ),
      );

  Widget _customerCard({
    required String label,
    required IconData icon,
    required double iconSize,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: onTap,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFDBE2E7) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _navy, width: 1.5),
                        ),
                        child: Icon(icon, color: _navy, size: iconSize),
                      ),
                    ),
                  ),
                  Expanded(child: Text(label, style: AppText.style(fontSize: 15, color: _navy))),
                ],
              ),
            ),
          ),
        ),
      );
}
