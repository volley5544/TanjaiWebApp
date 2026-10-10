import 'package:flutter/services.dart';

/// FF `MaskTextInputFormatter(mask: '###-###-####')`: digits only, max 10,
/// dashes inserted after the 3rd and 6th digit.
class PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buf.write('-');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    // Keep the caret after the same number of digits it followed before.
    final caretDigits = newValue.text
        .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, digits.length);
    var offset = 0;
    for (var seen = 0; offset < text.length && seen < caretDigits; offset++) {
      if (text[offset] != '-') seen++;
    }
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: offset));
  }
}
