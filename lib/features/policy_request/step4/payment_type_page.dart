import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/firebase/firebase_auth_rest.dart';
import '../../../core/firebase/firestore_rest.dart';
import '../../../core/session/user_profile.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/env_version_tag.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../../router/app_router.dart';
import '../data/policy_request_api.dart';
import '../shared/request_widgets.dart';
import '../state/policy_request_state.dart';
import 'step4_data.dart';
import 'step4_rules.dart';

/// ประเภทการชำระเงิน — FF HomepageRequest41: choose 'ชำระเต็มจำนวน' or
/// 'ผ่อนชำระ (เป้า ง)', save draft step 4 with the page-4 documents, then
/// the payment page (P4_2, which reloads the detail; ids stay in state).
///
/// Options come from Firestore `InsurerConfig2` (auth → anonymous token) and
/// the employee profile ([UserProfile]: position, level) + employee id.
/// FF's inner `InsurerConfig` read is dropped: nothing of it was used (it
/// only gated rendering and is not in UAT). Not ported: `fromPage:
/// 'RenewBasic'` (renew flow — sets renewPaymentType and pops).
///
/// FF fixes: the choice starts empty on every visit (FF kept the global
/// `maxCurrentSelected` / `installmentSelected` of a previous flow, even for
/// a hidden card); `InsurerConfig2` unreadable → treated as empty (full
/// payment shown, installment needs permission) instead of a blank page; a
/// missing `$.message` / installment list no longer crashes; the loading
/// overlay closes before the dialogs.
class PaymentTypePage extends StatefulWidget {
  const PaymentTypePage({super.key});

  @override
  State<PaymentTypePage> createState() => _PaymentTypePageState();
}

class _PaymentTypePageState extends State<PaymentTypePage> {
  final _state = PolicyRequestState.instance;
  bool _noFlow = false;
  bool _loading = true;
  InsurerPaymentConfig _config = const InsurerPaymentConfig();

  /// FF maxCurrentSelected / installmentSelected.
  bool _full = false;
  bool _installment = false;

  @override
  void initState() {
    super.initState();
    _noFlow = redirectIfNoFlow(context);
    if (!_noFlow) _load();
  }

  Future<void> _load() async {
    Future<Map<String, dynamic>?> config() async {
      final token = await FirebaseAuthRest.idToken();
      if (token != null) FirestoreRest.instance.idToken = token;
      return FirestoreRest.instance.firstWhere('InsurerConfig2');
    }

    final results = await Future.wait<Object?>([config(), UserProfile.instance.ensureLoaded()]);
    if (!mounted) return;
    final doc = results.first as Map<String, dynamic>?;
    setState(() {
      if (doc != null) _config = InsurerPaymentConfig.fromFirestore(doc);
      _loading = false;
    });
  }

  String get _insurer => _state.summary.insurerShortName;

  bool get _showsFull => _config.showsFullPayment(_insurer);

  bool get _showsInstallment => _config.showsInstallment(
        insurer: _insurer,
        flagRenew: _state.step4.flagRenew,
        coverTypeCode: _state.summary.coverTypeCode,
        positionName: UserProfile.instance.positionName,
        employeeId: UserSession.instance.employeeId,
        level: UserProfile.instance.level,
      );

  String get _leadDtlId {
    final s = _state.summary.leadDetailId;
    return s.isNotEmpty ? s : '${_state.leadDtlId ?? ''}';
  }

  Future<void> _confirm() async {
    if (!_full && !_installment) {
      await showAlert(context, kStep4ChoosePayment);
      return;
    }
    final fields = Step4Rules.of(_state.variant).saveFields(
      _state.step4,
      fullPayment: _full,
      quotationId: _state.quotationId,
      leadDtlId: _leadDtlId,
      subProduct: _state.summary.actType,
    );
    final r = await withLoading(context, () => PolicyRequestApi.instance.saveApplication(step: '4', fields: fields));
    if (!mounted) return;
    if (!await requestCheck(context, statusCode: r.statusCode, code: r.code, message: r.message)) return;
    _state.step4.lastSave = Step4SaveResult.fromJson(r.json);
    if (!mounted) return;
    await showAlert(context, 'เลือกประเภทการชำระเงินสำเร็จ');
    if (mounted) context.push(AppRoutes.requestPayment);
  }

  @override
  Widget build(BuildContext context) {
    if (_noFlow) return const Scaffold(backgroundColor: Colors.white);
    return PopScope(
      canPop: false,
      child: UnfocusOnTap(
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryBackground,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            centerTitle: true,
            elevation: 2,
            shadowColor: const Color(0x33000000),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.brandOrange, size: 30),
              onPressed: () => context.canPop() ? context.pop() : leaveRequestFlow(context),
            ),
            title: Text('ประเภทการชำระเงิน',
                style: AppText.style(fontSize: 18, fontWeight: FontWeight.normal, color: const Color(0xFF204A77))),
            actions: const [EnvVersionTag()],
          ),
          body: _loading
              ? const PageLoadingView()
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Expanded(child: SingleChildScrollView(child: _options())),
                        Expanded(
                          child: Align(
                            alignment: const Alignment(0, 0.75),
                            child: Container(
                              height: 100,
                              color: Colors.white,
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 50),
                              child: AppButton(text: 'ตกลง', onPressed: _confirm, fontWeight: FontWeight.normal),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _options() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text('ประเภทการชำระเงิน', style: AppText.style(fontSize: 15, color: const Color(0xFF1D4774))),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text('(บังคับเลือก)', style: AppText.style(fontSize: 12, color: kRequestTagRed)),
              ),
            ],
          ),
        ),
        if (_showsFull) ...[
          const SizedBox(height: 12),
          _card('ชำระเต็มจำนวน', _full, () => setState(() {
                _full = true;
                _installment = false;
              })),
        ],
        if (_showsInstallment) ...[
          const SizedBox(height: 12),
          _card('ผ่อนชำระ (เป้า ง)', _installment, () => setState(() {
                _full = false;
                _installment = true;
              })),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  /// FF option card; the text stays grey #B3B3B3 when selected (kept).
  Widget _card(String text, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kRequestGrey),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(text, style: AppText.style(fontSize: 15, color: kRequestGrey)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.success : Colors.white,
                  border: selected ? null : Border.all(color: kRequestPlaceholder),
                ),
                child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
