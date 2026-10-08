/// Build-time environment for the web app.
///
/// Chosen with `--dart-define=ENV=uat|prod` (CI sets it per branch: `uat` →
/// sawad-new-ibs-uat Hosting, `main` → sawad-new-ibs Hosting). Defaults to
/// [AppEnvironment.uat] so a stray local build never targets production.
library;

/// CI run number, logged on boot to spot a stale cached build.
const String kWebVersion = String.fromEnvironment('WEB_VERSION', defaultValue: '0');

enum AppEnvironment {
  uat(
    insuranceApiBase: 'https://is-dev.swpfin.com/ssw_tanjai_api_dev',
    localApiBase: 'https://prd-proxy.swpfin.com:8096',
  ),
  prod(
    insuranceApiBase: 'https://tanjai.swpfin.com/ssw_tanjai_api',
    localApiBase: 'https://prd-proxy.swpfin.com:8096',
  );

  const AppEnvironment({
    required this.insuranceApiBase,
    required this.localApiBase,
  });

  /// Insurance API base (`FFAppState().apiUrlInsuranceAppState` in the mobile
  /// app). UAT = Firestore `Key_Storage3.uat2_api_url`, PROD = `urlLinkStorage`
  /// `insurance_api_url`. Compiled in rather than accepted from the launch URL,
  /// so a crafted link can't point API calls (and the user's token) elsewhere.
  final String insuranceApiBase;

  /// "Local"/HR API base (`apiURLLocalState`, Firestore `Key_Storage.api_URL`).
  /// Only used by `getdate-time` on the package detail page.
  final String localApiBase;

  bool get isProduction => this == AppEnvironment.prod;

  static const AppEnvironment current =
      String.fromEnvironment('ENV') == 'prod' ? AppEnvironment.prod : AppEnvironment.uat;

  /// Firebase project whose Firestore holds the app's master data. The mobile
  /// app reads everything (both envs) from `sawad-new-ibs`; the uat project's
  /// Firestore is empty, so both builds read prod's publicly readable docs.
  static const String firestoreProjectId = 'sawad-new-ibs';

  /// Hard timeout for every API call (the FlutterFlow app had none).
  Duration get apiTimeout => const Duration(seconds: 60);
}
