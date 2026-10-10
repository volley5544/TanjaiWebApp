import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/env_version_tag.dart';
import '../../router/app_router.dart';

/// Port of FF `InsuranceSuccessPage` / `InsuranceUnSuccessPage` (request
/// saved; "unsuccess" = saved, but the insurer email waits for the next
/// round). No AppBar in FF; the env tag sits top-right instead.
///
/// The Lottie animations are bundled (`assets/lottie/`) instead of loaded
/// from lottiefiles / Storage. 'ปิด' went to SuperAppPage; on web it goes to
/// the menu (TODO(bridge): hand back to the host app).
class RequestResultPage extends StatelessWidget {
  const RequestResultPage({super.key, required this.success});

  final bool success;

  @override
  Widget build(BuildContext context) {
    final bg = success ? AppColors.secondary : AppColors.tertiary;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
                    // FF shows this title on both pages (kept).
                    child: Text('บันทึกข้อมูลสำเร็จ',
                        textAlign: TextAlign.center, style: AppText.style(fontSize: 24, color: Colors.white)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 0),
                    child: Lottie.asset(
                      success ? 'assets/lottie/insurance_success.json' : 'assets/lottie/insurance_unsuccess.json',
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      repeat: false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
                    child: Text(
                      success ? 'ข้อมูลของคุณได้ส่งให้เจ้าหน้าที่ประกันเรียบร้อย' : 'กรุณารอรอบการส่งอีเมลล์ภายใน 1 วัน',
                      textAlign: TextAlign.center,
                      style: AppText.style(fontSize: 15, color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 55),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: AppButton(
                            text: 'ปิด',
                            onPressed: () => context.go(AppRoutes.home),
                            color: Colors.white,
                            textColor: AppColors.tertiary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Positioned(top: 8, right: 8, child: EnvVersionTag()),
            ],
          ),
        ),
      ),
    );
  }
}
