/// The three search-package products. Each has its own search page and its
/// own state (see `SearchPackageState.of`), so a change to one never affects
/// the others — the mobile app ran all three through one page keyed by
/// `fromIcon`.
enum ProductType {
  motor(fromIcon: 'motor', path: 'motor'),
  ev(fromIcon: 'EV', path: 'ev'),
  mc(fromIcon: 'MC', path: 'mc');

  const ProductType({required this.fromIcon, required this.path});

  /// The value the mobile app passed as `fromIcon` (also sent on to later
  /// pages and APIs, e.g. `carType` of get_vehicle).
  final String fromIcon;

  /// URL path segment: `/motor`, `/ev`, `/mc`.
  final String path;

  /// FF `searchPackageSubProduct`: 'MC' for motorcycles, 'Motor' otherwise.
  String get subProduct => this == ProductType.mc ? 'MC' : 'Motor';

  /// FF `searchPackageEvFlag`.
  String get evFlag => this == ProductType.ev ? 'Y' : 'N';

  /// Search page title (FF AppBar title per fromIcon).
  String get searchTitle => switch (this) {
        ProductType.motor => 'ค้นหาประกันรถ',
        ProductType.ev => 'EV ค้นหาประกันรถ',
        ProductType.mc => 'ค้นหาประกันมอเตอร์ไซค์',
      };

  static ProductType? fromPath(String? path) {
    for (final p in values) {
      if (p.path == path) return p;
    }
    return null;
  }
}
