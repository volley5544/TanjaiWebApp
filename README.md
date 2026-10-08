# ประกันทันใจ — Tanjai Web (New IBS)

Flutter **web** app embedded in the Tanjai mobile app's WebView. Features are
ported one at a time from the FlutterFlow mobile app
(`/Users/volley5544/Projects/Flutter/tanjai`), keeping the same screen flow,
results and look.

| | |
|---|---|
| Flutter | **3.47.6** (`~/DevelopTools/flutter3.47.6/bin/flutter`) |
| Envs | `uat` branch → `sawad-new-ibs-uat` Hosting · `main` branch → `sawad-new-ibs` Hosting |
| Data | Insurance API (per env, compiled in) + public Firestore docs of `sawad-new-ibs` (REST, no SDK) |

## Ported features

| Feature | Entry | Status |
|---|---|---|
| Search insurance package — motor | `/motor` | ported |
| Search insurance package — EV | `/ev` | ported |
| Search insurance package — motorcycle | `/mc` | ported |

Pages the flow reaches that are not ported yet (InsuranceInfoPage1,
InsuranceListPage, SelectReasonPage) open a placeholder (`/not-ported`).

## Run locally

```sh
F=~/DevelopTools/flutter3.47.6/bin/flutter
$F pub get
$F run -d chrome --dart-define=ENV=uat
# open http://localhost:<port>/?token=<access_token>&empId=<employee_id>&firstName=…&lastName=…&phone=…&branchCode=…&branchName=…
```

## Launch parameters (host app → web)

Until the JS bridge exists the host passes the logged-in user as query
params. They are validated, read once at boot, then **removed from the address
bar** (`lib/core/session/user_session.dart`).

| Param | Mobile `FFAppState` field | Used for |
|---|---|---|
| `token` | `accessToken` | `Authorization: Bearer` on quotation save |
| `empId` | `employeeID` | `owner_id` |
| `firstName`, `lastName` | `profileFirstName/LastName` | quotation owner name |
| `phone` | `ProfilePhoneNumber` | `owner_phone` |
| `branchCode`, `branchName` | `profileBranch`, `profileUnitCodeName` | quotation branch |

API base URLs are **not** accepted from the URL — they're compiled in per env
(`lib/core/config/app_environment.dart`).

## Structure

```
lib/
  app/                     MaterialApp (Thai locale, light theme)
  router/                  go_router table (AppRoutes) + path URL strategy
  core/
    config/                AppEnvironment (uat/prod API bases)
    session/               UserSession (launch params) + URL cleaner
    network/               ApiClient (JSON POST, timeout, no logging)
    firebase/              FirestoreRest (read-only REST)
    theme/                 AppColors / AppText (FlutterFlow theme values)
    utils/ff_functions.dart  ports of FF custom functions
    widgets/               LoadingScene/withLoading, dialogs, AppButton, selector tiles
  features/
    home/                  test menu + not-ported placeholder
    search_package/
      models/  data/       typed models + SearchPackageApi
      state/               SearchPackageState — one per product (motor/ev/mc)
      motor/ ev/ mc/       separate search page per product
      shared/              pickers + shared form widgets
      results/ detail/ compare/ customer/ quotation/ work_select/
tools/firestore-inspect/   read-only Firestore viewer (uses `firebase login`)
```

## Deploy

Push to `uat` → GitHub Actions builds and deploys UAT Hosting; push to `main`
→ prod. One-time setup in GitHub → Settings → Secrets and variables → Actions:

| Secret | Value |
|---|---|
| `FIREBASE_SERVICE_ACCOUNT_UAT` | full JSON of a service account with *Firebase Hosting Admin* on `sawad-new-ibs-uat` |
| `FIREBASE_SERVICE_ACCOUNT_PROD` | same for `sawad-new-ibs` |

Release builds use `--csp --no-web-resources-cdn --no-source-maps`.

## Security posture (pentest prep)

- No secrets in the repo or bundle except the known finding below; `etc/` and
  service-account keys are git-ignored.
- Launch params validated + stripped from the URL; API hosts compiled in.
- Hosting headers: CSP (self-hosted CanvasKit/fonts, `connect-src` limited to
  the API + Firestore hosts), HSTS, nosniff, `Referrer-Policy: no-referrer`,
  `X-Frame-Options: DENY`, Permissions-Policy, COOP.
- Release builds show a generic Thai error instead of stack traces and log no
  user data.

**Known findings to fix outside the web app**

1. `getdate-time` (local API) requires a shared `Authorization: Basic`
   credential that ships in the client bundle — needs a per-user auth scheme
   server-side.
2. Master-data and package-search insurance APIs are unauthenticated, and the
   API echoes any `Origin` in `Access-Control-Allow-Origin`.
3. `hideInAppContent` requires Firebase Auth, which the web build doesn't have
   yet — it falls back to the current prod values until the bridge supplies an
   ID token.
