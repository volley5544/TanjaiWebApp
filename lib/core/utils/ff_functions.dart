// Ports of the FlutterFlow custom functions (`lib/custom_code/functions/` in
// the tanjai mobile app) used by the ported features.
//
// Behaviour is kept identical to the originals — including their quirks — so
// screens produce the same results; only the null-bang (`!`) crashes are
// replaced with safe defaults. Names are kept so a port can be traced back to
// the original `functions.xxx(...)` call.
import 'package:intl/intl.dart';

String addCoverType(String input) => input.split(',').map((p) => 'ชั้น$p').join(',');

String changeADToBD(String dateInAD) {
  final d = DateTime.parse(dateInAD);
  return DateFormat('dd/MM/yyyy', 'th_TH').format(DateTime(d.year + 543, d.month, d.day));
}

List<String> changeListintToString(List<int> input) => input.map((e) => '$e').toList();

/// Thai national ID checksum (13 digits).
bool checkIdCard(String idCard) {
  if (!RegExp(r'^\d{13}$').hasMatch(idCard)) return false;
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += int.parse(idCard[i]) * (13 - i);
  }
  return (11 - (sum % 11)) % 10 == int.parse(idCard[12]);
}

bool checkIdCardInput(String input) => input.length == 13 && int.tryParse(input) != null;

bool checkIsStringLengthInLength(String input, int length) => input.length <= length;

bool checkIsStringPhoneLength(String input, int length) => input.length == length;

/// `'null'` (the literal string the APIs send) → `'-'`.
String checkNullValueAndReturn(String? value) => value == null || value == 'null' ? '-' : value;

bool checkNumberInString(String input) => RegExp(r'\d').hasMatch(input);

double _num(String s) => double.tryParse(removeCommaFromNumText(s)) ?? 0;

/// True if insurer [selectedInsurerShortName] has at least one package whose
/// price is within [minValue]..[maxValue] and whose cover type matches the
/// "contains 1" class of [selectedCoverType].
bool checkPackageInRangePage2Copy(
  List<String> insurerShortNameList,
  List<String> priceList,
  String selectedInsurerShortName,
  String minValue,
  String maxValue,
  String selectedCoverType,
  List<String> coverTypeList,
) {
  for (var i = 0; i < insurerShortNameList.length; i++) {
    if (selectedInsurerShortName != insurerShortNameList[i]) continue;
    final wantClass1 = selectedCoverType.contains('1');
    final isClass1 = i < coverTypeList.length && coverTypeList[i].contains('1');
    if (wantClass1 != isClass1) continue;
    final price = i < priceList.length ? _num(priceList[i]) : 0;
    if (_num(minValue) <= price && _num(maxValue) >= price) return true;
  }
  return false;
}

bool checkPackageInRangePage3(String price, String minValue, String maxValue) =>
    _num(minValue) <= _num(price) && _num(maxValue) >= _num(price);

bool checkWeekendDate(String date) {
  final d = DateTime.parse(date);
  return d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
}

String combineStringFromList(List<String> list) => list.join(',');

bool containWordinStringUrl(String word, String url) => url.contains(word);

int countTrueInBoolList(List<bool> list) => list.where((e) => e).length;

List<String> coverTypeCodeToId(List<String> codes) => codes
    .map((c) => switch (c) { 'VMI1' => '1', 'VMI2' => '2', 'VMI2+' => '3', 'VMI3' => '4', _ => '5' })
    .toList();

List<String> coverTypeCodeToName(List<String> codes) => codes
    .map((c) => switch (c) {
          'VMI1' => 'ชั้น 1',
          'VMI2' => 'ชั้น 2',
          'VMI2+' => 'ชั้น 2+',
          'VMI3' => 'ชั้น 3',
          _ => 'ชั้น 3+',
        })
    .toList();

List<bool> createFalseListByItemNumber(bool value, int length) => List.filled(length, value, growable: true);

List<String> createGarageTypeCodeList(List<String> names) =>
    names.map((n) => n == 'ซ่อมอู่' ? 'COMPANY' : 'DEALER').toList();

List<String> filledDataInListByLength(String input, int length) => List.filled(length, input, growable: true);

List<String> ganerateYearList(int start, int end) => [for (var y = start; y <= end; y++) '$y'];

List<String> garageTypeCodeToName(List<String> codes) =>
    codes.map((c) => c == 'DEALER' ? 'ซ่อมห้าง' : 'ซ่อมอู่').toList();

List<String> garageTypeCodetoId(List<String> codes) => codes.map((c) => c == 'DEALER' ? '1' : '2').toList();

/// `'<code> <type>-<name>'` per row — note the single space and the dash.
List<String> generateInsuranceVehicleTypeDropdown(List<String> codes, List<String> types, List<String> names) => [
      for (var i = 0; i < codes.length; i++)
        '${codes[i]} ${i < types.length ? types[i] : ''}-${i < names.length ? names[i] : ''}',
    ];

String getDateFormat(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

int getIndexOfBoolList(List<bool> list, bool value) => list.indexOf(value);

int getIndexOfSomethingList(List<String> list, String value) => list.indexOf(value);

/// Smallest / largest numeric value of [list] as a string (`'1234.0'`), or the
/// single element unchanged (comma-stripped) when the list has one item.
String getMinMaxValueFromList(List<String> list, String type) {
  if (list.isEmpty) return '0';
  if (list.length == 1) return removeCommaFromNumText(list.first);
  final values = list.map(_num).toList();
  final v = type == 'min' ? values.reduce((a, b) => b < a ? b : a) : values.reduce((a, b) => b > a ? b : a);
  return '$v';
}

List<String> makeStringToList1(String? input) => [input ?? ''];

String removeCommaFromNumText(String text) => text.replaceAll(RegExp('[^A-Za-z0-9.]'), '');

String removeDash(String input) => input.replaceAll('-', '');

List<String> removeDupeInList(List<String> list) => list.toSet().toList();

/// Keeps only `[A-Za-z0-9ก-ฮ]` (used to clean licence plates).
String removeSpacialLetterFromText(String text) => text.replaceAll(RegExp('[^A-Za-z0-9ก-ฮ]'), '');

String replaceAllTabAndSpace(String input) => input.replaceAll('\t', '').replaceAll(' ', '');

List<String> returnMappedListFrom2List(List<String> list1, List<String> list2, String search) => [
      for (var i = 0; i < list1.length; i++)
        if (i < list2.length && list2[i] == search) list1[i],
    ];

List<String> returnMappedListFrom2ListContain(List<String> list1, List<String> list2, String search) => [
      for (var i = 0; i < list1.length; i++)
        if (i < list2.length && list2[i].contains(search)) list1[i],
    ];

List<String> returnMappedListFrom3List(
  List<String> list1,
  List<String> list2,
  String search,
  List<String> vehicleGroupList,
  String vehicleGroupSearch,
  List<String> carGroupDetailList,
  String carTypeContain,
  List<String> carDoorList,
  String carTypeDoors,
) =>
    [
      for (var i = 0; i < list1.length; i++)
        if (search == list2[i] &&
            vehicleGroupList[i].contains(vehicleGroupSearch) &&
            carTypeContain == carGroupDetailList[i] &&
            (carTypeDoors == carDoorList[i] || carDoorList[i] == '-'))
          list1[i],
    ];

List<String> returnMappedListFrom3ListOther(
  List<String> list1,
  List<String> list2,
  String search,
  List<String> vehicleGroupList,
  String vehicleGroupSearch,
) =>
    [
      for (var i = 0; i < list1.length; i++)
        if (search == list2[i] && vehicleGroupList[i].contains(vehicleGroupSearch)) list1[i],
    ];

List<String> returnMappedListFromBoolList(List<String> list1, List<bool> flags, bool search) => [
      for (var i = 0; i < list1.length; i++)
        if (i < flags.length && flags[i] == search) list1[i],
    ];

List<String> reverseList(List<String> list) => list.reversed.toList();

List<bool> setBoolValueListAtIndex(List<bool> list, int index) => list..[index] = true;

String showCoverTypeThai(String? code) => switch (code) {
      'VMI1' => 'ชั้น 1',
      'VMI2' => 'ชั้น 2',
      'VMI2+' => 'ชั้น 2+',
      'VMI3' => 'ชั้น 3',
      'VMI3+' => 'ชั้น 3+',
      _ => '',
    };

/// `yyyy-MM-dd…` → `dd/MM/<BE year>`.
String showDateBE(String input) {
  final d = DateTime.parse(input);
  return '${DateFormat('dd/MM').format(d)}/${d.year + 543}';
}

String showGarageType(String garageType) => garageType == 'COMPANY' ? 'ซ่อมอู่' : 'ซ่อมห้าง';

/// `'1234.5'` → `'1,234.50'`; truncates (does not round) to 2 decimals like
/// the original; non-numeric input is returned unchanged.
String showNumberWithComma(String? number) {
  if (number == null || number.isEmpty) return '';
  if (double.tryParse(number) == null) return number;
  final parts = number.split('.');
  double? parsed;
  if (number.contains('.')) {
    final frac = parts[1];
    parsed = double.tryParse(frac.length > 1 ? '${parts[0]}.${frac[0]}${frac[1]}' : '${parts[0]}.${frac}0');
  } else {
    parsed = double.tryParse('$number.00');
  }
  if (parsed == null) return '';
  return parsed
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

String showThaiIdNumberForm(String id) {
  if (id.length < 13) return id;
  return '${id[0]}-${id.substring(1, 5)}-${id.substring(5, 10)}-${id.substring(10, 12)}-${id[12]}';
}
