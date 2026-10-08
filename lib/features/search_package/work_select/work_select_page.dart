import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../router/app_router.dart';
import '../product_type.dart';

/// Port of FF `InsuranceWorkSelectPage` (เลือกงานประกัน, spec 10): shown when
/// the package search found nothing; offers the off-rate job (งานนอกเรท).
///
/// Not ported (dead / debug / no effect):
/// * the hidden `if (false)` renew row (ต่ออายุ → NonePackageRenewPage);
/// * the 9 debug AlertDialogs on AppBar-title tap;
/// * the Firestore `disable_work_weekend` FutureBuilder — its value was only
///   used in an empty `if` (and crashed when missing).
class WorkSelectPage extends StatelessWidget {
  const WorkSelectPage({super.key, required this.product});

  final ProductType product;

  /// FF goNamed('SearchInsurancePage', fromIcon: fromMenuAppState) — stack
  /// replaced. System/browser back does the same (FF blocked it).
  void _back(BuildContext context) => context.go(AppRoutes.search(product));

  void _onOffRate(BuildContext context) {
    // TODO(SelectReasonPage port): before pushing, FF reset ~100
    // `nonePackage*` app-state fields to their placeholders (spec 10 §2
    // step A), set nonePackageFlagRenew=false (B), prefilled from the search
    // form per `checkFilled` flags (C: vehicle type, brand name/id, model
    // name/code, year BE, usage id/code/name, model lists, isBrandSelect,
    // and always oldVmiExpDate) and re-cleared image fields (D). The future
    // port must build that none-package state from this product's
    // SearchPackageState and pass `workType`:
    //   'ev' if fromIcon == 'EV', else 'manual'.
    // FF quirk: SearchInsurancePage never passed fromIcon (default 'motor'),
    // so workType was ALWAYS 'manual', even for EV. On web we know the
    // product, but we keep FF's behaviour: workType = 'manual'.
    context.push(AppRoutes.notPorted('SelectReasonPage'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(context);
      },
      child: UnfocusOnTap(
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: tanjaiAppBar(
            title: 'เลือกงานประกัน',
            titleColor: const Color(0xFF003063),
            backColor: AppColors.brandOrange,
            onBack: () => _back(context),
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      boxShadow: const [
                        BoxShadow(blurRadius: 4, color: Color(0x33000000), offset: Offset(0, 2)),
                      ],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondaryText),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primaryText),
                                ),
                                // FF FontAwesome carSide (no FA package here).
                                child: const Icon(Icons.directions_car, color: Color(0xFF7A848E), size: 24),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 45),
                            child: Text('งานนอกเรท', style: AppText.style(fontSize: 16)),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: AppButton(
                              text: 'นอกเรท',
                              onPressed: () => _onOffRate(context),
                              height: 40,
                              color: const Color(0xFFD9D9D9),
                              textColor: const Color(0xFF090F13), // theme black600
                              fontSize: 16,
                              radius: 8,
                              // FF padding h24 would squeeze the label in this
                              // narrow cell on web; centred text instead.
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
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
}
