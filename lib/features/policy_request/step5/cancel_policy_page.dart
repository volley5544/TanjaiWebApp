import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/env_version_tag.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../router/app_router.dart';
import '../data/policy_request_api.dart';
import '../shared/request_widgets.dart';
import '../state/policy_request_state.dart';

const _navy = Color(0xFF204A77);

/// FF InsuranceInfoPage5Cancel — 'ยืนยันยกเลิกทำประกัน' with a free-text
/// reason (no reason choices in FF). Reached from page 5 'ยกเลิก' (FF
/// `goNamed`, stack replaced); every exit goes back to page 5 with
/// `context.go` (page 5 reloads).
class CancelPolicyPage extends StatefulWidget {
  const CancelPolicyPage({super.key});

  @override
  State<CancelPolicyPage> createState() => _CancelPolicyPageState();
}

class _CancelPolicyPageState extends State<CancelPolicyPage> {
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    redirectIfNoFlow(context);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _toStatus() => context.go(AppRoutes.requestStatus);

  /// 'ตกลง'. FF had no loading indicator (double-tap could send twice) and
  /// built the JSON by interpolation (a quote in the reason broke it); the
  /// port uses `withLoading` and `jsonEncode` (PolicyRequestApi).
  Future<void> _submit() async {
    // FF: no trim — a spaces-only reason passes (kept).
    if (_reason.text.isEmpty) {
      await showAlert(context, 'กรุณากรอกเหตุผล');
      return;
    }
    final r = await withLoading(
      context,
      () => PolicyRequestApi.instance.cancelPolicy(
        quotationId: PolicyRequestState.instance.quotationId,
        reason: _reason.text,
      ),
    );
    if (!mounted) return;
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.statusCode})');
      return;
    }
    if (r.code != 200) {
      await showAlert(context, 'พบข้อผิดพลาด (${r.code})');
      return;
    }
    await showAlert(context, 'ยกเลิกทำประกันสำเร็จ!');
    if (mounted) _toStatus();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width * 0.40;
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
            // FF `context.pop()` had nothing to pop (page opened with goNamed);
            // the port returns to page 5.
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.brandOrange, size: 30),
              onPressed: _toStatus,
            ),
            title: Text('ยืนยันยกเลิกทำประกัน', style: AppText.style(fontSize: 18, fontWeight: FontWeight.normal, color: _navy)),
            actions: const [EnvVersionTag()],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('กรอกเหตุผลการยกเลิกทำประกันและขอคืนเงิน',
                        style: AppText.style(fontSize: 15, fontWeight: FontWeight.normal)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 120,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextFormField(
                      controller: _reason,
                      autofocus: true,
                      style: AppText.style(fontSize: 15, fontWeight: FontWeight.normal),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: 'กรุณากรอกเหตุผล',
                        hintStyle: AppText.style(fontSize: 15, fontWeight: FontWeight.normal, color: AppColors.secondaryText),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AppButton(
                          text: 'ยกเลิก',
                          onPressed: _toStatus,
                          width: w,
                          color: Colors.white,
                          textColor: _navy,
                          borderColor: _navy,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: AppButton(
                            text: 'ตกลง',
                            onPressed: _submit,
                            width: w,
                            color: kRequestOrange,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      ],
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
}
