import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../models/house_type.dart';

/// Port of FF `SearchableHouseList` (ประเภทที่อยู่อาศัย): the 8 fixed house
/// types with their pictures. Pops with the tapped [HouseType] (null on back);
/// the search page stores it and re-runs the estimate — FF did both inside
/// this page before popping.
class HouseTypePage extends StatelessWidget {
  const HouseTypePage({super.key});

  static Future<HouseType?> open(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push<HouseType>(
      MaterialPageRoute(builder: (_) => const HouseTypePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const types = HouseType.all;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: tanjaiAppBar(
          title: 'ประเภทที่อยู่อาศัย',
          titleSize: 16,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
            itemCount: types.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => Padding(
              // FF: every row but the last had a 7px bottom padding.
              padding: EdgeInsets.only(bottom: i == types.length - 1 ? 0 : 7),
              child: _HouseTypeRow(
                type: types[i],
                onTap: () => Navigator.of(context).pop(types[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HouseTypeRow extends StatelessWidget {
  const _HouseTypeRow({required this.type, required this.onTap});

  final HouseType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 0.5),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(type.name, style: AppText.style(fontWeight: FontWeight.normal)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(type.image, width: 90, fit: BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 4, thickness: 1, color: AppColors.accent4),
          ],
        ),
      ),
    );
  }
}
