import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/firebase/firebase_auth_rest.dart';
import '../../../core/firebase/firestore_rest.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../core/widgets/page_loading_view.dart';
import '../../../router/app_router.dart';
import '../data/manual_request_api.dart';
import '../shared/np_widgets.dart';
import '../state/none_package_state.dart';

/// Port of FF `NonePackageInsurerPage` — pick up to 3 insurers (1 for a
/// renewal) and submit the request (`/api/manual-insurance/save`, which emails
/// the insurers).
///
/// Firestore `InsurerConfig2` (insurers hidden per cover type + "full payment
/// only" insurers) needs Firebase auth: read with the anonymous identity when
/// available, else treated as empty — the same result as today's prod values
/// (placeholders). The supercar filter is not ported: the supercar vehicle
/// type is hidden in the car-type picker (FF `false && …`), so it can't occur.
///
/// Web fixes: an insurer-list error no longer leaves the loading view up
/// forever; the submit shows the loading overlay (FF only had the button's
/// spinner); a missing server message no longer crashes the dialog.
class InsurerPage extends StatefulWidget {
  const InsurerPage({super.key});

  @override
  State<InsurerPage> createState() => _InsurerPageState();
}

class _InsurerPageState extends State<InsurerPage> {
  final _s = NonePackageState.instance;
  final _api = ManualRequestApi.instance;
  bool _loading = true;
  bool _listOk = false;

  /// InsurerConfig2: cover-type code key → hidden short names.
  Map<String, List<String>> _hiddenByCover = {};
  List<String> _installmentInsurers = [];

  @override
  void initState() {
    super.initState();
    if (!_s.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
      return;
    }
    _load();
  }

  Future<void> _load() async {
    final isEv = _s.fromMenu == 'EV' || _s.workType == 'ev';
    final configLoad = _loadInsurerConfig();
    final r = await _api.getInsurers(vehicleGroup: isEv ? 'EV' : 'ICE');
    await configLoad;
    if (!mounted) return;
    setState(() => _loading = false);
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.httpStatus})');
      return;
    }
    if (r.status1 != 200) {
      await showAlert(context, r.message1 ?? '');
      return;
    }
    final insurers = r.data ?? const <NpInsurer>[];
    final selected = List.filled(insurers.length, false);
    // FF setInsurerDupList: pre-select the insurers of a copied request.
    for (final d in _s.insurerShortNameDup) {
      final i = insurers.indexWhere((x) => x.shortName == d);
      if (i >= 0) selected[i] = true;
    }
    setState(() {
      _listOk = true;
      _s
        ..insurers = insurers
        ..insurerSelected = selected;
    });
  }

  Future<void> _loadInsurerConfig() async {
    final token = await FirebaseAuthRest.idToken();
    if (token != null) FirestoreRest.instance.idToken = token;
    final doc = await FirestoreRest.instance.getDocument('InsurerConfig2/hvT7Gz16JBaY3J2HE4SW');
    if (doc == null) return;
    final map = doc['insurer_short_name_map'];
    if (map is Map) {
      _hiddenByCover = {
        for (final e in map.entries) '${e.key}': [for (final x in (e.value as List? ?? const [])) '$x'],
      };
    }
    _installmentInsurers = [for (final x in (doc['InsurerInstallment'] as List? ?? const [])) '$x'];
  }

  bool _visible(NpInsurer i) {
    final key = switch (_s.coverTypeCode) {
      'VMI1' => 'VMI1',
      'VMI2' => 'VMI2',
      'VMI2+' => 'VMI25',
      'VMI3' => 'VMI3',
      _ => 'VMI35',
    };
    return !(_hiddenByCover[key] ?? const []).contains(i.shortName);
  }

  int get _count => _s.insurerSelected.where((x) => x).length;

  Future<void> _tap(int i) async {
    final ins = _s.insurers[i];
    final selected = _s.insurerSelected;
    if (_installmentInsurers.contains(ins.shortName) && !selected[i]) {
      final ok = await showConfirm(
        context,
        '${ins.listName} จะต้องชำระเงินแบบจ่ายเต็มเท่านั้น ไม่สามารถชำระแบบผ่อนชำระได้ คุณต้องการจะทำรายการต่อหรือไม่?',
        confirmText: 'ตกลง',
      );
      if (!ok) return;
    }
    setState(() {
      if (_s.flagRenew) {
        _s.insurerSelected = [for (var k = 0; k < selected.length; k++) k == i];
      } else if (_count >= 3) {
        selected[i] = false; // FF: at 3, tapping deselects only
      } else {
        selected[i] = !selected[i];
      }
    });
  }

  Map<String, String> _body() {
    final s = _s;
    final session = UserSession.instance;
    final chosen = [for (var i = 0; i < s.insurers.length; i++) if (s.insurerSelected[i]) s.insurers[i]];
    final n = chosen.length;
    String js(List<String> l) => jsonEncode(l);
    List<String> fill(String v) => List.filled(n, v);
    final renew = s.flagRenew;
    final reasonIndex = s.reason.indexOf(true);
    final ownBranch = session.branchCode.length <= 2;
    String photo(CarSlot c) => renew ? '' : s.carPhoto(c);
    return {
      'car_brand_id': s.brandId,
      'car_brand_name': s.brandName,
      'car_model_id': s.modelCode,
      'car_model_name': s.modelName,
      'first_name': noPh(s.cusFullname),
      'last_name': '',
      'phone_number': noPh(s.cusPhone),
      'driver_type': '0', // driverFlag is always false (FF dead UI)
      'car_province_code': s.provinceId,
      'car_province_name': s.province,
      'id_number': '',
      'car_registration': s.plate,
      'car_registration_year': s.yearChrist,
      'vehicle_id': s.usedTypeId,
      'vehicle_code': s.usedTypeCode,
      'vehicle_name': s.usedTypeName,
      'id_type': '',
      'branch_code': ownBranch ? session.branchCode : s.branchCode,
      'api_url': AppEnvironment.current.insuranceApiBase, // FF sent its API host as a field
      'insurer_code': js([for (final i in chosen) i.code]),
      'insurer_id': js([for (final i in chosen) i.id]),
      'insurer_name': js([for (final i in chosen) i.fullName]),
      'insurer_short_name': js([for (final i in chosen) i.shortName]),
      'cover_type_id': js(fill(s.coverTypeId)),
      'cover_type_code': js(fill(s.coverTypeCode)),
      'cover_type_name': js(fill(s.coverTypeName)),
      'garage_type_id': js(fill(s.garageTypeId)),
      'garage_type_name': js(fill(s.garageTypeName)),
      'garage_type_code': js(fill(s.garageTypeCode)),
      'company_name': '',
      'flg_renew': renew ? '1' : '0',
      'old_VMI_policyNumber': renew ? s.oldVmi : '',
      'flg_decoration': '',
      'decoration_detail': '',
      'flg_carrier': s.flagCarrier ? '1' : '0',
      'flg_co_org': s.flagCoop ? '1' : '0',
      'carrier_type': noPh(s.carrierType),
      'carrier_price': noPh(s.carrierPrice),
      'customer_type': s.buttonOrdinary ? 'บุคคลธรรมดา' : 'นิติบุคคล',
      'trailer_car_registration': noPh(s.plateAdditional),
      'carrier_propose': noPh(s.truckCarryPurpose),
      'remark': s.remark,
      'car_type': s.vehicleType,
      'customer_memberchip': isPh(s.cusMembership) ? '' : (s.cusMembership == 'ลูกค้านอก' ? '0' : '1'),
      'truck_part': isPh(s.truckPart) ? '' : (s.truckPart == truckWithTrailer ? '1' : '0'),
      'flg_act': s.flagAct ? '1' : '0',
      'sum_insured': noPh(s.sumInsured),
      'trailer_sum_insured': noPh(s.trailerSumInsured),
      'truck_current_price': noPh(s.truckCurrentPrice),
      'old_VMI_expriedDate': s.oldVmiExpDate,
      'reason': renew
          ? ''
          : switch (reasonIndex) { 0 => 'ไม่มีในเรท', 1 => 'ไม่พอใจในทุนประกัน', _ => 'รถแต่งหรือรถต่อคอก' },
      'image_idcard': s.idCardUrl,
      'old_VMI_image': renew ? s.oldVmiImageUrl : '',
      'image_company_book': renew ? s.companyBookUrl : '',
      for (final c in CarSlot.values) c.field: photo(c),
      'image_bluebook': s.blueBookUrl,
      for (var i = 0; i < 5; i++) 'image_other${i + 1}': s.otherPhotos[i],
      'branch_name': ownBranch ? session.branchName : s.branchName,
      'owner_id': session.employeeId,
      'owner_name': '${session.firstName} ${session.lastName}'.trim(),
      'car_type_detail': s.vehicleTypeDetail,
      'old_VMI_flg': s.workType == 'transfer' ? '1' : '0',
      'driver_behavior': js(List.filled(5, '0')),
      'national_thai_id': '',
      'ev_flag': !renew && s.workType == 'ev' ? 'Y' : 'N',
    };
  }

  Future<void> _submit() async {
    if (_count <= 0) {
      await showAlert(context, 'กรุณาเลือกบริษัทประกันอย่างน้อย 1 บริษัท');
      return;
    }
    final r = await withLoading(context, () => _api.saveRequest(_body()));
    if (!mounted) return;
    if (!r.isHttpOk) {
      await showAlert(context, 'พบข้อผิดพลาดConnection (${r.httpStatus})');
      return;
    }
    if (r.status2 != 201) {
      if (r.status2 == 500) {
        _s.reset();
        context.go(AppRoutes.manualUnsuccess);
      } else {
        await showAlert(context, r.message2 ?? httpErrorText(r.httpStatus));
      }
      return;
    }
    await showAlert(context, r.message2 ?? '');
    if (!mounted) return;
    _s.reset();
    context.go(AppRoutes.manualSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      backgroundColor: npPanelGrey,
      appBar: npAppBar(
        npTitle(s.workType, flagRenew: s.flagRenew),
        titleColor: AppColors.titleNavy,
        onBack: () => context.pop(),
      ),
      body: _loading
          ? const PageLoadingView()
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  s.flagRenew ? 'บริษัทประกันที่ต้องการต่ออายุ' : 'บริษัทประกันที่ต้องการใบเสนอราคา',
                                  style: AppText.style(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                              ),
                              if (!s.flagRenew)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text('($_count/3)',
                                      style: AppText.style(
                                          fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.error)),
                                ),
                            ],
                          ),
                          if (!s.flagRenew)
                            Container(
                              width: double.infinity,
                              color: Colors.white,
                              padding: const EdgeInsets.only(left: 4, top: 4),
                              child: Text(
                                'กรุณาถามลูกค้าให้เลือกบริษัทประกันสูงสุดเพียง 3 บริษัทเท่านั้น',
                                maxLines: 2,
                                style: AppText.style(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.error),
                              ),
                            ),
                          Expanded(
                            child: !_listOk
                                ? const SizedBox.shrink()
                                : ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: s.insurers.length,
                                    itemBuilder: (context, i) {
                                      final ins = s.insurers[i];
                                      if (!_visible(ins)) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: InkWell(
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () => _tap(i),
                                          child: Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: npBorderGrey),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 10),
                                                    child: Text(ins.listName,
                                                        style: AppText.style(fontSize: 15, color: npBorderGrey)),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 10),
                                                  child: NpSelectCircle(s.insurerSelected[i]),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  NpBottomButton(text: 'ตกลง', onPressed: _submit, padding: const EdgeInsets.fromLTRB(8, 16, 8, 24)),
                ],
              ),
            ),
    );
  }
}
