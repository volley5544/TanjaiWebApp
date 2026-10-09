import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/env_version_tag.dart';
import '../../router/app_router.dart';
import '../search_package/product_type.dart';

/// Entry menu for opening the web app directly (browser testing). Inside the
/// Tanjai mobile app the host opens `/motor`, `/ev`, `/mc` or `/quotations`
/// straight away — these tiles copy that app's home-menu tiles
/// (super_app_page).
class HomeMenuPage extends StatelessWidget {
  const HomeMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    Widget tile(String path, IconData icon, String label) => InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () => context.go(path),
          child: Container(
            width: width * 0.28,
            height: 100,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(icon, color: AppColors.brandOrange, size: 30),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppText.style(fontSize: 14, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text('ประกันทันใจ', style: AppText.style(fontSize: 18, color: AppColors.titleNavy)),
        actions: const [EnvVersionTag()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            tile(AppRoutes.search(ProductType.motor), Icons.search, 'ค้นหาประกันรถ'),
            tile(AppRoutes.search(ProductType.ev), Icons.electric_car, 'ค้นหาประกัน\nรถ EV'),
            tile(AppRoutes.search(ProductType.mc), Icons.motorcycle, 'ค้นหาประกันมอเตอร์ไซค์'),
            tile(AppRoutes.quotationList, Icons.list_alt, 'รายการ\nใบเสนอราคา'),
          ],
        ),
      ),
    );
  }
}
