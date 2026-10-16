import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ff_functions.dart';
import '../shared/request_widgets.dart';
import 'step2_data.dart';
import 'widgets.dart';

/// FF `Homepage_Request_2_1` — อุปกรณ์เสริม (motor / EV). 'ไม่คุ้มครอง' /
/// 'คุ้มครอง' (mutually exclusive) and the read-only accessory amount from
/// the package. 'ตกลง' writes [Step2Data.accessoryProtect] (nothing ticked =
/// not protected, FF) and pops `true`; back pops without a change. No API.
class AccessoryPage extends StatefulWidget {
  const AccessoryPage({super.key, required this.data});

  final Step2Data data;

  static Future<bool?> open(BuildContext context, Step2Data data) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => AccessoryPage(data: data)));
  }

  @override
  State<AccessoryPage> createState() => _AccessoryPageState();
}

class _AccessoryPageState extends State<AccessoryPage> {
  late bool _noProtect = widget.data.accessoryProtect == Step2Data.kAccessoryNoProtect;
  late bool _protect =
      widget.data.accessoryProtect != Step2Data.kAccessoryNoProtect && widget.data.accessoryProtect != '';

  void _ok() {
    widget.data.accessoryProtect = _protect ? Step2Data.kAccessoryProtect : Step2Data.kAccessoryNoProtect;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: step2SubAppBar(context, 'อุปกรณ์เสริม'),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Step2SubLabel('อุปกรณ์เสริม', tag: '(บังคับเลือก)'),
                      const SizedBox(height: 5),
                      Step2OptionBox(
                        label: 'ไม่คุ้มครอง',
                        value: _noProtect,
                        onTap: () => setState(() {
                          _noProtect = true;
                          _protect = false;
                        }),
                        onChanged: (v) => setState(() {
                          _noProtect = v;
                          if (v) _protect = false;
                        }),
                      ),
                      const SizedBox(height: 25),
                      Step2OptionBox(
                        label: 'คุ้มครอง',
                        value: _protect,
                        onTap: () => setState(() {
                          _noProtect = false;
                          _protect = true;
                        }),
                        onChanged: (v) => setState(() {
                          _protect = v;
                          if (v) _noProtect = false;
                        }),
                      ),
                      const SizedBox(height: 20),
                      const Step2SubLabel('มูลค่ารวมคุ้มครองอุปกรณ์เสริม'),
                      const SizedBox(height: 5),
                      RequestBox(
                        color: kRequestBorder,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            _protect ? '${showNumberWithComma(widget.data.accessory)} บาท' : '',
                            style: AppText.style(fontSize: 15, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Step2OkButton(onPressed: _ok),
            ],
          ),
        ),
      ),
    );
  }
}
