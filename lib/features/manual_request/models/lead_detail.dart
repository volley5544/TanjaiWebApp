import '../../search_package/models/json_read.dart';

/// FF `checkNullValueAndReturn('${x}')`: JSON null → '-', else the text.
String _chk(dynamic v) => v == null || '$v' == 'null' ? '-' : '$v';

List<String> _strList(dynamic v) => [
      for (final e in jsonChildren(v))
        if (e != null) '$e',
    ];

/// One insurer row of `get-lead-detail` `$.results.info[0].leads_detail[:]`.
///
/// FF read each column as a separate `leads_detail[:].x` list with
/// `.withoutNulls` (a null shifted the column); here each row keeps its own
/// values and a null becomes ''.
class LeadDetailInsurer {
  LeadDetailInsurer(Map<String, dynamic> j)
      : insurerName = jsonStr(j['insurer_name']),
        insurerShortName = jsonStr(j['insurer_short_name']),
        coverTypeId = _chk(j['cover_type_id']),
        coverTypeCode = _chk(j['cover_type_code']),
        coverTypeName = _chk(j['cover_type_name']),
        garageTypeId = _chk(j['garage_type_id']),
        garageTypeCode = _chk(j['garage_type_code']),
        garageTypeName = _chk(j['garage_type_name']),
        imageOtherName = jsonStr(j['image_other_name']),
        imageOther = _strList(j['image_other']),
        images = {
          for (final k in const [
            'image_front', 'image_rightfront', 'image_right', 'image_rightrear', 'image_rear',
            'image_leftrear', 'image_left', 'image_leftfront', 'image_roof',
            'image_front_trailer', 'image_rightfront_trailer', 'image_right_trailer',
            'image_rightrear_trailer', 'image_rear_trailer', 'image_leftrear_trailer',
            'image_left_trailer', 'image_leftfront_trailer',
            'old_VMI_image', 'image_company_book', 'image_idcard', 'image_bluebook',
          ])
            k: jsonStr(j[k]),
        };

  final String insurerName;
  final String insurerShortName;
  final String coverTypeId;
  final String coverTypeCode;
  final String coverTypeName;
  final String garageTypeId;
  final String garageTypeCode;
  final String garageTypeName;
  final String imageOtherName;

  /// This insurer's `image_other` URLs.
  final List<String> imageOther;

  /// Existing image URL per API field name ('' when none).
  final Map<String, String> images;
}

/// `POST /api/lead/get-lead-detail` `$.results.info[0]` (FF
/// InsuranceRequestDetailAPICall). Scalar fields go through FF's
/// `checkNullValueAndReturn` (null → '-').
class LeadDetail {
  LeadDetail(Map<String, dynamic> i)
      : flgCarrier = jsonStr(i['flg_carrier']),
        carType = _chk(i['car_type']),
        carBrandName = _chk(i['car_brand_name']),
        carBrandId = _chk(i['car_brand_id']),
        carModelName = _chk(i['car_model_name']),
        carModelId = _chk(i['car_model_id']),
        carRegistrationYear = _chk(i['car_registration_year']),
        vehicleId = _chk(i['vehicle_id']),
        vehicleCode = _chk(i['vehicle_code']),
        vehicleName = _chk(i['vehicle_name']),
        firstName = _chk(i['first_name']),
        rawFirstName = '${i['first_name']}',
        rawLastName = '${i['last_name']}',
        phoneNumber = _chk(i['phone_number']),
        carRegistration = _chk(i['car_registration']),
        carProvinceName = _chk(i['car_province_name']),
        carProvinceCode = _chk(i['car_province_code']),
        sumInsured = _chk(i['sum_insured']),
        flgAct = jsonStr(i['flg_act']),
        carrierType = _chk(i['carrier_type']),
        flgCoOrg = jsonStr(i['flg_co_org']),
        truckPart = _chk(i['truck_part']),
        customerMemberchip = _chk(i['customer_memberchip']),
        truckCurrentPrice = _chk(i['truck_current_price']),
        trailerCarRegistration = _chk(i['trailer_car_registration']),
        carrierPropose = _chk(i['carrier_propose']),
        trailerSumInsured = _chk(i['trailer_sum_insured']),
        carrierPrice = _chk(i['carrier_price']),
        flgRenew = jsonStr(i['flg_renew']),
        oldVmiExpiredDate = _chk(i['old_VMI_expriedDate']),
        oldVmiPolicyNumber = _chk(i['old_VMI_policyNumber']),
        customerType = _chk(i['customer_type']),
        leadId = _chk(i['lead_id']),
        leadNo = _chk(i['lead_no']),
        remark = _chk(i['remark']),
        branchCode = _chk(i['branch_code']),
        branchName = _chk(i['branch_name']),
        rawBranchCode = '${i['branch_code']}',
        rawBranchName = '${i['branch_name']}',
        oldVmiFlg = '${i['old_VMI_flg']}',
        reason = jsonStr(i['reason']),
        evFlag = '${i['ev_flag']}',
        details = [
          for (final e in jsonChildren(i['leads_detail']))
            if (e is Map) LeadDetailInsurer(Map<String, dynamic>.from(e)),
        ];

  final String flgCarrier;
  final String carType;
  final String carBrandName;
  final String carBrandId;
  final String carModelName;
  final String carModelId;
  final String carRegistrationYear;
  final String vehicleId;
  final String vehicleCode;
  final String vehicleName;
  final String firstName;
  final String rawFirstName;
  final String rawLastName;
  final String phoneNumber;
  final String carRegistration;
  final String carProvinceName;
  final String carProvinceCode;
  final String sumInsured;
  final String flgAct;
  final String carrierType;
  final String flgCoOrg;
  final String truckPart;
  final String customerMemberchip;
  final String truckCurrentPrice;
  final String trailerCarRegistration;
  final String carrierPropose;
  final String trailerSumInsured;
  final String carrierPrice;
  final String flgRenew;
  final String oldVmiExpiredDate;
  final String oldVmiPolicyNumber;
  final String customerType;
  final String leadId;
  final String leadNo;
  final String remark;
  final String branchCode;
  final String branchName;
  final String rawBranchCode;
  final String rawBranchName;
  final String oldVmiFlg;
  final String reason;
  final String evFlag;
  final List<LeadDetailInsurer> details;

  static LeadDetail? fromJson(dynamic json) {
    final info = jsonAt(jsonAt(json, 'results'), 'info');
    final first = jsonChildren(info).firstOrNull;
    return first is Map ? LeadDetail(Map<String, dynamic>.from(first)) : null;
  }
}
