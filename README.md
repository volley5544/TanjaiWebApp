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
| Search insurance package — motor | `/motor` | ported, user-tested on UAT |
| Search insurance package — EV | `/ev` | ported, user-tested on UAT |
| Search insurance package — motorcycle | `/mc` | ported, user-tested on UAT |
| Quotation list (InsuranceListPage) → detail (MakeInsuranceListPage) → quotation PDF (QuotationCopy) | `/quotations` | ported, tested with stubbed API responses; awaiting user test on UAT |

Live UAT: https://sawad-new-ibs-uat.web.app. Prod has not been deployed yet.

Pages the flows reach that are not ported yet (InsuranceInfoPage1 / 42 / 5,
NonePackageEditPage1, NonePackageBasicPage, NonePackageSelectedInsurerPage,
SelectReasonPage, LicenseSelectComponent) open a placeholder (`/not-ported`).

### Quotation list (`/quotations`)

- List: `POST /api/lead/get-lead-list` (`owner_id`, `mode: arunsawad`,
  `list: quotation`). Search by first name, refresh, ⚠ legend = in-rate /
  out-of-rate filter, call button (`tel:`), card buttons 'แก้ไข' / 'คัดลอก'
  (none-package flow, not ported) and 'ทำประกัน'.
- 'ทำประกัน' → confirm → `POST /api/lead/get-lead-by-id` → detail page
  (`results.info.watingInfo`, count `results.counting.status_waiting_info`).
- Detail buttons: 'ดูใบเสนอราคา' (`/quotations/pdf`), 'ดูกรมธรรม์'
  (`/api/quotations/get-file-vmi`, new tab), 'ดู พ.ร.บ'
  (`/api/quotations/get-file-cmi`), 'ติดตามงาน' (`/api/lead/get-history`
  sheet), 'เงื่อนไข บ.ประกัน' (insurer remark), main button → not-ported pages.
- All calls are reads; nothing is created or changed.
- Also reached from the add-customer save flow when the video-call gate
  blocks InsuranceInfoPage1.

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
    widgets/               PageLoadingView (on-open loads), LoadingScene/withLoading (user actions),
                           EnvVersionTag, dialogs, AppButton, app bars, selector tiles
  features/
    home/                  test menu + not-ported placeholder
    quotation_list/        quotation list → MakeInsuranceListPage → QuotationCopy
      models/  data/       lead models + LeadApi (statusCode / results.statusCode envelope)
      state/               QuotationListState (filter, detail items, PDF URLs)
      list/  detail/       pages, legend sheet, history sheet
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

`WEB_VERSION` is the GitHub Actions run number. UAT builds show it as a small
**"(UAT ver N)"** tag in every AppBar (hidden on prod) and log it at boot, so
testers can tell which build the WebView is running.

## UI conventions

- **Loading:** a page loading its data on open shows a white body with an
  orange spinner and caption (`PageLoadingView`, like sawadLoanUniversal); a
  user action (search, save) shows the Tanjai overlay loader (`withLoading`).
- Screens, texts and colors follow the FlutterFlow app; deliberate FF quirks
  are kept and commented.

## Not yet verified end to end

- Quotation save (needs a real token; creates real data).
- Filter and compare pages (built, not click-tested).
- Quotation PDF iframe inside the Android WebView.
- Quotation list / detail against the real API: tested only with stubbed
  responses built from the fields the FF pages read. The sample in
  `etc/api_sample/quotation_api_sample.txt` has application-style fields for
  `get-lead-list` (`first_name_th`, `mobile1`, `application_no`, …), not the
  ones the FF page reads (`first_name`, `phone_number`, `quotation_no`, …),
  and its `get-lead-by-id` has `payments` instead of `watingInfo`.
- The call button (`tel:`) inside the host WebView.

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
4. The GitHub repo is public — make it private before the pentest.
