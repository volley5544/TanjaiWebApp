import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ff_functions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialogs.dart';

/// Port of FF `custom_widgets.RangeSliderWidget` (+ its
/// `TextFieldComponentWidget` min/max entry sheet).
///
/// Like the original, the thumb values are initialised ONCE from
/// [currentMin]/[currentMax]; parent rebuilds don't reset them. Every drag
/// tick and every sheet entry reports the new range through [onChanged],
/// rounded to 2 decimals (FF wrote `toStringAsFixed(2)` strings to app state).
///
/// Fixes vs FF: values are clamped into [min, max] (Flutter asserts
/// otherwise), a degenerate range (max <= min, or max/step < 1) no longer
/// crashes, and dismissing the sheet / empty fields no longer throw.
class RangeSliderFilter extends StatefulWidget {
  const RangeSliderFilter({
    super.key,
    required this.min,
    required this.max,
    required this.currentMin,
    required this.currentMax,
    required this.step,
    required this.typeName,
    required this.onChanged,
    this.activeColor = AppColors.buttonOrange,
    this.inactiveColor = AppColors.secondaryText,
    this.overlayColor = AppColors.sliderOverlay,
  });

  final double min;
  final double max;
  final double currentMin;
  final double currentMax;
  final double step;

  /// 'ราคาเบี้ย' or 'ทุนประกัน' — prefixes every label.
  final String typeName;
  final void Function(double start, double end)? onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final Color overlayColor;

  @override
  State<RangeSliderFilter> createState() => _RangeSliderFilterState();
}

class _RangeSliderFilterState extends State<RangeSliderFilter> {
  late double _start = _clamp(widget.currentMin);
  late double _end = math.max(_start, _clamp(widget.currentMax));

  double get _sliderMax => widget.max > widget.min ? widget.max : widget.min + 1;

  double _clamp(double v) => v.clamp(widget.min, _sliderMax).toDouble();

  static double _round2(double v) => double.parse(v.toStringAsFixed(2));

  static String _fixed(double v) => v.toStringAsFixed(2);

  void _apply(double start, double end) {
    setState(() {
      _start = _round2(_clamp(start));
      _end = _round2(_clamp(end));
      if (_end < _start) _end = _start;
    });
    widget.onChanged?.call(_start, _end);
  }

  Future<void> _openEditSheet() async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Padding(
          padding: MediaQuery.viewInsetsOf(sheetContext),
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.4,
            child: _RangeEntrySheet(
              title: widget.typeName,
              minValue: _fixed(_start),
              maxValue: _fixed(_end),
              sliderMin: widget.min,
              sliderMax: widget.max,
            ),
          ),
        ),
      ),
    );
    if (result == null || !mounted) return; // dismissed: FF threw silently → no change
    final s = double.tryParse(result.$1);
    final e = double.tryParse(result.$2);
    if (s == null || e == null) return;
    _apply(s, e);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeColor.withValues(alpha: 1);
    // FF: divisions = (max / step).toInt() — max, not (max - min); kept so
    // the snapping positions match the app.
    final divisions = widget.step > 0 ? (widget.max / widget.step).toInt() : 0;
    final enabled = widget.max > widget.min;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RangeSlider(
          min: widget.min,
          max: _sliderMax,
          values: RangeValues(_start, _end),
          divisions: divisions >= 1 ? divisions : null,
          labels: RangeLabels(_fixed(_start), _fixed(_end)),
          activeColor: active,
          inactiveColor: widget.inactiveColor.withValues(alpha: 1),
          overlayColor: WidgetStatePropertyAll(widget.overlayColor.withValues(alpha: 1)),
          onChanged: enabled ? (v) => _apply(v.start, v.end) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(showNumberWithComma('${widget.min}'), style: AppText.bodyMedium),
              Text(showNumberWithComma('${widget.max}'), style: AppText.bodyMedium),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: _openEditSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.typeName}ต่ำสุด : ${showNumberWithComma(_fixed(_start))} บาท',
                          style: AppText.style(fontSize: 16),
                        ),
                        Text(
                          '${widget.typeName}สูงสุด : ${showNumberWithComma(_fixed(_end))} บาท',
                          style: AppText.style(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: active),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit, color: active, size: 30),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Port of FF `TextFieldComponentWidget`: manual min/max entry. Pops
/// `(start, end)` strings, or nothing when dismissed.
class _RangeEntrySheet extends StatefulWidget {
  const _RangeEntrySheet({
    required this.title,
    required this.minValue,
    required this.maxValue,
    required this.sliderMin,
    required this.sliderMax,
  });

  final String title;
  final String minValue;
  final String maxValue;
  final double sliderMin;
  final double sliderMax;

  @override
  State<_RangeEntrySheet> createState() => _RangeEntrySheetState();
}

class _RangeEntrySheetState extends State<_RangeEntrySheet> {
  late final _minCtrl = TextEditingController(text: widget.minValue);
  late final _maxCtrl = TextEditingController(text: widget.maxValue);

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    final t1 = _minCtrl.text.trim();
    final t2 = _maxCtrl.text.trim();
    // Empty field → the current value (FF's intended fallback; FF itself
    // crashed on `double.parse('')` here and the button did nothing).
    final lo = double.tryParse(t1.isEmpty ? widget.minValue : t1);
    final hi = double.tryParse(t2.isEmpty ? widget.maxValue : t2);
    if (lo == null || hi == null) return; // malformed number: FF threw → no-op
    final bothEmpty = t1.isEmpty && t2.isEmpty;
    // FF: strict `<` (equal min/max is rejected) unless both fields are empty.
    if (!bothEmpty && !(lo < hi)) {
      await showAlert(context, '${widget.title}สูงสุด จะต้องมีค่ามากกว่า${widget.title}ต่ำสุด');
      return;
    }
    if (!mounted) return;
    // FF only raised min to sliderMin and lowered max to sliderMax; both are
    // clamped into the range here so the slider never gets out-of-range values.
    final upper = math.max(widget.sliderMin, widget.sliderMax);
    final start = lo.clamp(widget.sliderMin, upper).toDouble();
    final end = hi.clamp(widget.sliderMin, upper).toDouble();
    Navigator.of(context).pop(('$start', '$end'));
  }

  Widget _field(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB3B3B3)),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          style: AppText.style(fontSize: 15, color: Colors.black),
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: hint,
            hintStyle: AppText.style(fontSize: 15, color: const Color(0xFFB3B3B3)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    return Material(
      color: AppColors.secondaryBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text('กรอกจำนวน$title', style: AppText.style(fontSize: 16)),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('กรอก$titleต่ำสุดที่ต้องการ', style: AppText.style()),
            ),
            _field(_minCtrl, 'กรุณากรอก$titleต่ำสุด'),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('กรอก$titleสูงสุดที่ต้องการ', style: AppText.style()),
            ),
            _field(_maxCtrl, 'กรุณากรอก$titleสูงสุด'),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: AppButton(
                text: 'ถัดไป',
                onPressed: _onNext,
                color: AppColors.sheetButtonOrange,
                textColor: AppColors.primaryBtnText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
