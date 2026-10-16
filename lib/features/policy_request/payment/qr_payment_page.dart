import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/env_version_tag.dart';
import '../../../core/widgets/loading_scene.dart';
import '../../../router/app_router.dart';
import '../shared/request_widgets.dart';
import '../state/policy_request_state.dart';
import 'payment_rules.dart';
import 'png_download.dart';

const _red = Color(0xFFCC0000);

/// FF `PaywithQRcode` — 'ชำระด้วย คิวอาร์โค้ด'. Shows the payment QR built
/// from the refs step 4.2 fetched (`PaymentData.qr*`). No API call, no
/// polling, no expiry: after paying the user goes back and taps refresh on
/// step 4.2 (as FF).
///
/// Not ported: FF's Firestore `urlLinkStorage` read (result unused — it only
/// held a spinner), the dead `fromPage == 'VlonePayment'` texts, the
/// `if (false)` barcode / screenshot widgets.
class QrPaymentPage extends StatefulWidget {
  const QrPaymentPage({super.key});

  @override
  State<QrPaymentPage> createState() => _QrPaymentPageState();
}

class _QrPaymentPageState extends State<QrPaymentPage> {
  final _captureKey = GlobalKey();
  final _state = PolicyRequestState.instance;

  @override
  void initState() {
    super.initState();
    redirectIfNoFlow(context);
  }

  void _back() => context.canPop() ? context.pop() : context.go(AppRoutes.requestPayment);

  /// 'บันทึกรูปภาพ'. FF `capQrCode` saved a re-drawn image to the phone's
  /// gallery; on web the rendered QR block is downloaded as a PNG instead
  /// (the host-app bridge may take over later). Alert text kept from FF.
  Future<void> _save() async {
    final ok = await withLoading(context, () async {
      try {
        final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) return false;
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (data == null) return false;
        await downloadPng(data.buffer.asUint8List(), '${DateTime.now().millisecondsSinceEpoch}.png');
        return true;
      } catch (_) {
        return false;
      }
    });
    if (!mounted) return;
    // FF showed the exception text on failure; the port never shows raw errors.
    await showAlert(context, ok ? 'บันทึกภาพ QR Code ลง Gallery สำเร็จ' : 'พบข้อผิดพลาด');
  }

  @override
  Widget build(BuildContext context) {
    final p = _state.payment;
    final rules = PaymentRules.of(_state.variant);
    final width = MediaQuery.sizeOf(context).width;
    final payload = genQRCodePayment(p.qrSuffix, p.qrRef1, p.qrRef2, p.qrAmount, p.qrTaxId);
    final body16 = AppText.style(fontSize: 16, fontWeight: FontWeight.normal);

    final content = Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          SizedBox(
            width: 300,
            height: 60,
            child: rules.qrShowsFirstPaymentNotes
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final t in const [' *ใช้สำหรับชำระประกันครั้งแรกเท่านั้น', '**ห้ามนำ QR นี้ไปชำระค่างวดผ่อนชำระ'])
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(t,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: AppText.style(fontSize: 16, fontWeight: FontWeight.normal, color: _red)),
                        ),
                    ],
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: width * 0.5,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFF204A77), borderRadius: BorderRadius.circular(35)),
              child: Text('คิวอาร์โค้ด', style: AppText.style(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.white)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Container(
              width: width * 0.7,
              height: 200,
              color: Colors.white,
              alignment: Alignment.center,
              child: payload == null
                  ? null
                  : QrImageView(
                      data: payload,
                      size: 200,
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primaryText),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.primaryText,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('฿ ${showNumberWithComma(p.qrAmount)}',
                style: AppText.style(fontSize: 16, color: AppColors.error)),
          ),
          Text('R1: ${p.qrRef1}', style: body16),
          Text('R2: ${p.qrRef2}', style: body16),
          Text('คุณ ${p.firstName} ${p.lastName}', style: body16),
          if (rules.qrShowsFirstPaymentNotes) ...[
            Text('คุณสามารถสแกนชำระค่าเบี้ยประกันผ่านโมบายแบงค์กิ้งของทุกธนาคาร',
                textAlign: TextAlign.center, style: AppText.style(fontWeight: FontWeight.normal)),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('***กรณีวันหยุด เสาร์-อาทิตย์ และนักขัตฤกษ์\nจะออกกรมธรรม์ในวันทำการถัดไป',
                  textAlign: TextAlign.center, style: AppText.style(fontSize: 16, fontWeight: FontWeight.normal, color: _red)),
            ),
          ] else
            Text('ใช้สำหรับชำระค่า พ.ร.บ เท่านั้น',
                textAlign: TextAlign.center, style: AppText.style(fontWeight: FontWeight.normal)),
        ],
      ),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 70,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.brandOrange, size: 30),
            onPressed: _back,
          ),
          title: Text('ชำระด้วย คิวอาร์โค้ด', style: AppText.style(fontSize: 18, color: AppColors.navy)),
          actions: const [EnvVersionTag()],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Expanded(
                  flex: 9,
                  child: SingleChildScrollView(
                    child: RepaintBoundary(key: _captureKey, child: content),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: AppButton(text: 'บันทึกรูปภาพ', onPressed: _save, fontWeight: FontWeight.normal),
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
