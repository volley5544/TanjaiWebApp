/// The fixed rows of FF `SearchableHouseList` (ประเภทที่อยู่อาศัย).
class HouseType {
  const HouseType(this.code, this.name, this.image);

  final String code;
  final String name;
  final String image;

  // 'อาคารพานิชย์' is spelled as in the mobile app (it's also sent to the API).
  static const all = [
    HouseType('01', 'บ้านเดี่ยว', 'assets/images/fire/house_01_detached.png'),
    HouseType('02', 'บ้านแฝด', 'assets/images/fire/house_02_twin.png'),
    HouseType('03', 'ทาวน์เฮาส์', 'assets/images/fire/house_03_townhouse.png'),
    HouseType('04', 'ทาวน์โฮม', 'assets/images/fire/house_04_townhome.png'),
    HouseType('05', 'อาคารพานิชย์', 'assets/images/fire/house_05_commercial.png'),
    HouseType('06', 'ตึกแถว', 'assets/images/fire/house_06_shophouse.png'),
    HouseType('07', 'คอนโด', 'assets/images/fire/house_07_condo.png'),
    HouseType('08', 'แฟลต', 'assets/images/fire/house_08_flat.png'),
  ];
}
