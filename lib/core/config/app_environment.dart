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
    firebaseProjectId: 'sawad-new-ibs-uat',
    firebaseApiKey: 'AIzaSyBr2ubqZaPAo5iL8mYztzGDZP8GYO3IoWU',
    storageBucket: 'sawad-new-ibs-uat.appspot.com',
  ),
  prod(
    insuranceApiBase: 'https://tanjai.swpfin.com/ssw_tanjai_api',
    localApiBase: 'https://prd-proxy.swpfin.com:8096',
    firebaseProjectId: 'sawad-new-ibs',
    firebaseApiKey: 'AIzaSyDCTqsBpj5Hf4NGjKFHtmg_xArMIRiQEL4',
    storageBucket: 'sawad-new-ibs.appspot.com',
  );

  const AppEnvironment({
    required this.insuranceApiBase,
    required this.localApiBase,
    required this.firebaseProjectId,
    required this.firebaseApiKey,
    required this.storageBucket,
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

  /// Firebase project of this environment: Firestore reads, anonymous
  /// sign-in and photo Storage. UAT uses its own project (Firestore copied
  /// from prod with tools/firestore-copy — config / master data only);
  /// prod uses `sawad-new-ibs`, the mobile app's project.
  final String firebaseProjectId;

  /// Public web API key of [firebaseProjectId]. It only identifies the
  /// project to Google's endpoints and grants nothing on its own; used for
  /// anonymous sign-in (photo uploads, auth-only Firestore docs).
  final String firebaseApiKey;

  /// Cloud Storage bucket request photos are uploaded to.
  final String storageBucket;

  /// Hard timeout for every API call (the FlutterFlow app had none).
  Duration get apiTimeout => const Duration(seconds: 60);
}
