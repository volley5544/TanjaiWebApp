# CLAUDE.md — Tanjai Web (ประกันทันใจ / New IBS)

Flutter **web** port of the FlutterFlow insurance mobile app "ประกันทันใจ"
(a.k.a. Tanjai, New IBS). The web build runs inside the Tanjai mobile app's
WebView. Features are ported **one at a time, as the user names them**, from the
FlutterFlow source repo `/Users/volley5544/Projects/Flutter/tanjai`.
App text/data is Thai; code, comments and commit messages are English.

`README.md` is the human-facing overview (features, run, launch params,
structure, deploy, security). This file is the working guide for Claude:
current state, rules, conventions, and what's open.

## Current state (read first) — updated 2026-10-15 (fire port + fire list)

- **Feature 1 — search insurance package (motor / EV / MC): ported, on `uat`,
  user-tested and confirmed working.**
- **Feature 2 — quotation list (`/quotations`): ported, on `uat`,
  user-tested and confirmed working (2026-10-09).** FF InsuranceListPage → 'ทำประกัน' →
  MakeInsuranceListPage (`/quotations/detail`) → QuotationCopy
  (`/quotations/pdf`). Code in `lib/features/quotation_list/`. Verified on
  UAT (ver7) with a real token in headless Chrome: list, search, confirm →
  get-lead-by-id → detail, real quotation PDF in the iframe, 'ดาวน์โหลด PDF'
  new tab, 'ติดตามงาน' history sheet, main button → InsuranceInfoPage1.
- **Feature 3 — manual request งานนอกเรท (create + edit): ported, on `uat`
  (ver16+); user tested uploads on UAT — "run smooth", photo compression and
  the see-image icon confirmed (2026-10-12…14).** Code in
  `lib/features/manual_request/` (ported from FF: create = SelectReason →
  NonePackageBasic → BasicImage1 → BasicImage2 → NonePackageInsurer →
  Success/UnSuccess; edit = EditPage1 → EditDetail / EditPage2 → EditPage3).
  Entries: 'นอกเรท' on work-select + result pages, quotation list 'คัดลอก' /
  'แก้ไข'. User scope choice: create + edit; NonePackageSelectedInsurerPage
  (choose insurer, after the insurance team uploads the insurer quotation)
  is the natural next step — not ported yet.
  - Follow-up changes on request: per-environment Firebase (UAT build →
    `sawad-new-ibs-uat`, only needed Firestore config copied from prod);
    every photo → JPEG q50 within 1920×1920; "see image" icon next to every
    uploaded photo's ✓.
- **Feature 4 — fire insurance search package (`/fire`): ported, on `uat`,
  E2E-tested in headless Chrome (real UAT cal-estimated / get_package; the
  quotation save stubbed — it creates real data); waiting for the user's
  test (2026-10-15).** User scope: "only the search package until got
  quotation". FF SearchPackageFireInsurancePage → SearchableHouseList / floor
  picker → fireInsurerListPage → detailsFireInsurancePage →
  AddFireCustomerName → FireQuotationPage. Code in
  `lib/features/fire_insurance/`. Not ported: 'ตกลงทำประกัน' continues to
  InsuranceInfoPage1 (`/not-ported`); the fire quotation list / lead
  follow-up / policy pages (`fire_inpackage_folder`, FireInsuranceListPage,
  MakeFireInsuranceListPage, FireQuotationCopy, …).
- **Feature 5 — fire quotation list (`/fire/quotations`): ported, on `uat`,
  user-tested on UAT with real data and confirmed working (2026-10-15).** FF fireInsuranceListPage → 'ทำประกัน' →
  MakeFireInsuranceListPage (`/fire/quotations/detail`) → FireQuotationCopy
  (`/fire/quotations/pdf` = `QuotationCopyPage(fire: true)`). Code in
  `lib/features/fire_insurance/quotation_list/`. User chose a separate page
  (as the mobile app), not inside `/quotations`. Not ported: the home-page
  fire dashboard preview / FireLeadFollowUpPage entry points.
- The next feature will be named by the user — wait for it.
- Live UAT: https://sawad-new-ibs-uat.web.app (`/motor`, `/ev`, `/mc`,
  `/fire`, `/quotations`; manual flows are reached from those pages).
- **Prod (`main`) has never been deployed.** Nothing goes to prod until the user
  explicitly says so for that job.
- Commits on `uat`:
  - `eb77ccc` port of the search package feature
  - `f71435f` white-page loading view for on-open data loads
  - `1f045d2` "(UAT ver<build>)" tag in every AppBar
  - `6a4c1e0` port of the quotation list feature (+ doc commits)
  - `556c571` port of the manual request (งานนอกเรท) create + edit flows
  - `f6f6bf0` no-cache for SPA page paths (new CSP applies right after deploy)
  - `66a59eb` per-environment Firebase + `tools/firestore-copy`
  - `44320e0` photo compression (JPEG q50, max 1920×1920, PNG included)
  - `f9f96c9` see-image icon next to uploaded photos
  - `277fb55` port of the fire insurance search package (search → quotation)
  - `a12051e` port of the fire quotation list (list → detail → PDF)
- JS bridge to the host app: **not started** ("do nothing yet"). Launch params
  are the interim hand-off.

## Rules from the user (always follow)

1. **End of every code task:** commit + push to the `uat` branch (auto-deploys
   UAT). Prod (`main`) only when the user explicitly asks, job by job.
2. **End of every task:** wrap up what was done into `README.md` + this
   `CLAUDE.md` (current state, new conventions, open items), then commit/push.
3. **Port fidelity:** same screen flow, results, UI and theme colors as the
   mobile app; same APIs. Use a clean structure (models / api / functions /
   state / pages) rather than FF's. Web side only — ask the user if a param or
   info from the mobile app is needed.
4. **Separate pages per product** (motor / EV / MC) so editing one product
   doesn't affect the others (user's request).
5. **Pentest-ready:** see Security below — applies to every new feature.
6. **Language:** reply in English by default; Thai only when the user asks.
7. Use Flutter **3.47.6** at `/Users/volley5544/DevelopTools/flutter3.47.6/bin/flutter`
   (the `flutter` on PATH is 3.38.6 — wrong).

## Reference projects

- FF source: `/Users/volley5544/Projects/Flutter/tanjai` (search package lives in
  `lib/search_package`; entry `search_insurance_page_widget.dart`; quotation
  list = `lib/pages/super_app/insurance_list_page`, detail =
  `lib/pages/super_app/make_insurance_list_page`; manual request =
  `lib/none_package_insurance`; success pages = `lib/search_package/insurance_(un_)success_page`;
  fire = `lib/fire_insurance`, entry `search_package_fire_insurance_page`,
  APIs in `HouseInsuranceGroup` of `backend/api_requests/api_calls.dart`).
- API response samples from the user: `etc/api_sample/` (git-ignored, may hold
  real customer data — never commit or paste it).
- Web structure + JS bridge patterns: `/Users/volley5544/Projects/Flutter/sawadLoanUniversal`
  (borrowed so far: `PLoanLoadingView` → `PageLoadingView`, `EnvVersionTag`,
  `WEB_VERSION`, Firestore inspection approach).
- Host app that runs the web: `/Users/volley5544/Projects/Flutter/srisawad_mobile_app_flutter3.38.5`.

## Commands

```sh
F=/Users/volley5544/DevelopTools/flutter3.47.6/bin/flutter
$F pub get
$F analyze                 # must be clean
$F test                    # unit tests in test/widget_test.dart
$F run -d chrome --dart-define=ENV=uat
# release build exactly as CI does:
$F build web --release --pwa-strategy=none --csp --no-web-resources-cdn \
  --no-source-maps --no-wasm-dry-run --dart-define=ENV=uat --dart-define=WEB_VERSION=0
```

Read-only Firestore inspection (uses the `firebase login` CLI token, values
masked unless listed in `--show`, GET only):

```sh
node tools/firestore-inspect/read.mjs <uat|prod> <collection> [--show f1,f2] [--limit N]
```

Copy Firestore collections prod → UAT (CLI login; refuses to write prod):

```sh
node tools/firestore-copy/copy.mjs --list <uat|prod>          # collections + counts (slow on prod)
node tools/firestore-copy/copy.mjs prod uat <coll...> [--dry-run]
```

E2E checks were done with headless Chrome + puppeteer-core from a temp dir
(not in the repo): serve `build/web` with the `firebase.json` CSP, intercept
API calls when needed (stub lead APIs / Firebase / save), click by
coordinates, screenshot each step; `page.waitForFileChooser()` feeds test
images. Launch Chrome with `--disable-features=LocalNetworkAccessChecks`
(API hosts are private IPs on the office network). Recreate if needed.

Git push uses the macOS keychain (HTTPS). If it fails with "could not read
Username", the user re-authenticates by pushing once from Terminal with a
GitHub PAT — never paste tokens into the chat.

## Environments & data

| | UAT | PROD |
|---|---|---|
| Branch → Hosting | `uat` → `sawad-new-ibs-uat` | `main` → `sawad-new-ibs` |
| Insurance API | `https://is-dev.swpfin.com/ssw_tanjai_api_dev` | `https://tanjai.swpfin.com/ssw_tanjai_api` |
| Local/auth API | `https://prd-proxy.swpfin.com:8096` | same |

- `ENV` dart-define selects the env (default `uat`), `lib/core/config/app_environment.dart`.
  API hosts are compiled in, never read from the URL.
- **Firebase is per environment** (`AppEnvironment.firebaseProjectId` /
  `firebaseApiKey` / `storageBucket`): UAT build → `sawad-new-ibs-uat`, prod
  build → `sawad-new-ibs` (the mobile app's project). Used for Firestore reads
  (REST, `FirestoreRest`), anonymous sign-in and photo Storage. Anonymous
  sign-in is enabled in UAT (user, 2026-10-12); **enable it in `sawad-new-ibs`
  before the prod deploy.**
- UAT Firestore holds **only the config the web reads**, copied from prod
  with `tools/firestore-copy/copy.mjs` (2026-10-12): `Vehicle_Type_Dropdown`,
  `hideInAppContent`, `InsurerConfig2` (user's instruction: copy only needed
  data — prod also holds user data and credentials). Re-run the copy when a
  feature starts reading another collection or prod config changes. Docs
  needing auth (`InsurerConfig2`, `hideInAppContent`) are read with the
  anonymous token only on the insurer page; elsewhere they 403 → defaults.
- `WEB_VERSION` = GitHub Actions `run_number`; shown as "(UAT ver N)" on UAT and
  logged at boot (`[TanjaiWeb] env=… webVersion=…`).
- CI: `.github/workflows/deploy-uat.yml` / `deploy-prod.yml`, secrets
  `FIREBASE_SERVICE_ACCOUNT_UAT` / `_PROD` (already set by the user).

## Architecture & conventions

- `lib/core/` — shared: `config/`, `session/` (UserSession + URL cleaner),
  `network/ApiClient` (JSON + multipart POST, timeout, no logging, `-1` on
  failure), `firebase/` (`FirestoreRest`, `FirebaseAuthRest` anonymous,
  `FirebaseStorageRest`), `theme/` (`AppColors` = FF tokens + Tanjai oranges/navy,
  `AppText.style`), `utils/ff_functions.dart` (null-safe ports of FF custom
  functions, **same names** as FF), `widgets/`.
- `lib/features/<feature>/` — `models/`, `data/` (`*Api` singleton returning
  `ApiResult<T>`), `state/` (ChangeNotifier replacing FFAppState), pages.
- Router: go_router, path URL strategy, `lib/router/app_router.dart` (`AppRoutes`).
  Flow data lives in state, **never in the URL**; a page opened by refresh
  without its state redirects back to the product search page.
- Lead / quotation-file APIs (`LeadApi`) use a different envelope from the
  search APIs: `$.statusCode` / `$.statusMessage` (layer 1) and
  `$.results.statusCode` / `$.results.statusMessage` (layer 2) →
  `LeadApiResult.status1/message1/status2/message2`.
- FF read list APIs as parallel `info[:].field` lists with `.withoutNulls`
  (a null shifts that column); the port reads each item's own object instead.
- Manual request: `NonePackageState.instance` replaces FF's ~150
  `nonePackage*` fields (placeholder texts live inside the values like FF —
  `isPh()` / `noPh()`); `reset()` = FF RESET_NP. Create pages redirect home and
  edit pages to `/quotations` when opened without an active flow. Photo
  upload: `pickAndUploadPhoto` / `uploadSlot` (image_picker, no resize options → `compressToJpeg` canvas: every image, PNG included, → JPEG q50 within 1920×1920, inside the loading overlay →
  `FirebaseStorageRest` with `FirebaseAuthRest` anonymous token). Save/edit
  are multipart (`ApiClient.postMultipart`). FF functional bugs fixed with a
  comment (stuck loading sheets, crashes on lower-case brand/model, fridge-box
  price check, date-cancel reset, page-local upload status); visible UI and
  visibility rules kept.
- Upload rows (`NpPhotoRow`, `NpAttachRow`, `PhotoStatusCard`) take the
  uploaded URL (+ `existingUrl` on edit pages) and show one "see image" icon
  next to ✓: the new upload, else the photo already on the request (user
  request 2026-10-14; FF had no such icon on create pages).
- `QuotationListState.requestReload()` makes an existing list page reload
  (go_router reuses the page; FF `goNamed` rebuilt it).
- Hosting: every extension-less path (`/`, `/manual/basic`, … = SPA
  rewrites to index.html) is `no-cache` (regex `^/[^.]*$` in `firebase.json`);
  otherwise browsers kept the HTML — and its old CSP header — for an hour.
- CSP `connect-src` includes `blob:` (image_picker reads the picked file via a
  blob URL) and the Firebase Auth / Storage hosts.
- Quotation list: `QuotationListState.instance` holds the legend filter
  (`searchList1`), the detail items and the PDF URLs. Routes under
  `/quotations` are declared before `/:product/…` (else `/quotations/detail`
  matches `/:product/detail`).
- Fire insurance: `FireSearchState.instance` (FF
  `fireInsuranceSearchPackageData` + `calEstimatedData` + route params),
  reset in `FireSearchPage.initState` (FF on-load reset). Routes `/fire/…` are
  **flat** and declared before `/:product/…`; nested routes would rebuild the
  search page on `go(fireQuotation)` and reset the state. Pickers return the
  choice and the search page runs `cal-estimated` itself (FF ran it inside
  each picker). FF fixes, commented: estimate host per env (FF floor picker
  hard-coded UAT), digits-only area / amount fields (FF int.parse crashes),
  search waits for the blur-triggered estimate, m² usable area sent without
  commas, overlay on every estimate, quotation long-press opens the fire PDF
  (FF opened the motor one). Kept: no back arrow on the fire quotation page,
  'sum_insure_buildin' shown for empty detail amounts, 'อากร' /
  'ภาษีมูลค่าเพิ่ม' show vat / stamp swapped, `sum_insure_total` printed like
  the Dart VM (`'1400000.0'`).
- Fire quotation list: `FireQuotationListState.instance` (selected lead +
  copy URLs). `FireLead` reads each lead's own first `leads_detail_house` /
  `app_detail_house` entry (list or object; FF used parallel flattened
  lists); missing values print `'null'` like FF `toString()`, list defaults
  'sabaide' / '40000' kept. The detail page only implements FF's
  `checkVMI == '0'`, `checkPayment == '0'` variant (the only one the list
  opens). Routes `/fire/quotations…` are flat, before `/:product/…`.
- `VerticalExpandingDots` (`core/widgets/`) is shared by the motor and fire
  quotation pagers.
- Search package: one `SearchPackageState.of(ProductType)` per product;
  `SearchableListPage.open(...)` returns selected indices and the caller applies
  them.
- **Loading UI:**
  - Data a page loads when it opens → `PageLoadingView` (white body, orange
    spinner, Thai caption; AppBar stays so back works). Pattern: `bool _loading = true`,
    clear it after the call.
  - Actions the user triggers (search, save) → `withLoading(context, task)`
    overlay (FF LoadingScene with the Tanjai GIF, always removed in `finally`).
- **AppBars:** use `tanjaiAppBar` / `resultAppBar` / `detailAppBar` — they
  append `EnvVersionTag` automatically. A new raw `AppBar` must add
  `actions: const [EnvVersionTag()]`.
- Dialogs: `showAlert`, `showConfirm`, `httpErrorText(code)`.
- `MobileFrame` caps the app at 600px wide on desktop browsers.
- FF quirks are kept deliberately when they affect visible behavior, with a
  comment saying so (e.g. the picker's missing ')' and case-sensitive search).

## Security (pentest-ready — every feature)

- Never commit or use the service-account keys in `etc/secret/` (`etc/` is
  git-ignored). Firestore: read via `tools/firestore-inspect/read.mjs`; copy
  prod → UAT only with `tools/firestore-copy/copy.mjs` (refuses to write to
  prod; copy only collections the web reads).
- Don't create real records in UAT (e.g. quotation save) without asking.
- Launch params (`token, empId, firstName, lastName, phone, branchCode,
  branchName`) are regex-validated, then stripped from the URL by `UrlCleaner`
  and the router `redirect`. Never log tokens or PII.
- Hosting headers in `firebase.json`: CSP (update `connect-src` when adding an
  API host), HSTS, nosniff, `Referrer-Policy: no-referrer`, `X-Frame-Options: DENY`,
  Permissions-Policy, COOP. No inline scripts in `web/index.html`.
- Release builds: no source maps, self-hosted CanvasKit/fonts, generic Thai
  error widget instead of stack traces.
- PDF/external URLs: https only, opened with `noopener`.

## Open items

1. **Not tested end to end:** quotation save (needs a real token, creates real
   data — motor/EV/MC, and fire which was only tested with a stubbed save), the filter and compare pages (not click-tested), the quotation PDF
   iframe inside the Android WebView (may need the bridge to open the URL).
2. **'ชำระเต็มจำนวนเท่านั้น' label** (search package detail page) is still
   hidden: `InsurerConfig2` needs Firebase auth. The anonymous token
   (`FirebaseAuthRest`) now makes it readable — wire it in if the user wants
   the label (the manual insurer page already does).
3. **Security findings outside the web app:** the shared Basic credential for
   the local API (`getdate-time`, `check-in/location`) ships in the bundle
   (`kLocalApiBasicAuth`); the mobile app signs employees into Firebase with a
   hard-coded shared password (`<empId>@srisawadinsurance.com` / `check_status_firebase.dart`); insurance
   master/search APIs are unauthenticated (fire `house/get_package` and
   `house/cal-estimated` too — cal-estimated answers without a token); the
   API reflects any `Origin` in CORS.
4. **GitHub repo is public** — recommended to make it private before the pentest.
5. Pages reached from the flows but not ported yet open `/not-ported`
   (InsuranceInfoPage1 / 42 / 5, NonePackageSelectedInsurerPage,
   LicenseSelectComponent). Renew / transfer (NonePackageRenewPage) entries
   are not ported; their branches exist in the manual pages.
6. JS bridge not started; it should replace the launch-param hand-off.
7. Quotation list: 'ดูกรมธรรม์' / 'ดู พ.ร.บ' not tried on real data (the
   test user has no 'อนุมัติ' quotation).
8. Not reachable from the list, so not ported on MakeInsuranceListPage: the
   `checkPayment == '1'` filter/legend, `fromPage: 'FollowUpPage'` back
   target; the dashboard / lead-follow-up entry points.
9. `tel:` call button and new-tab PDF opening inside the host WebView are
   untested (may need the bridge).
10. **API hosts resolve to private IPs on the office network** (`is-dev` →
    10.1.112.122, `tanjai` → 10.1.114.126). Chrome's Local Network Access
    check then blocks calls from `*.web.app` (`ERR_BLOCKED_BY_LOCAL_NETWORK_ACCESS_CHECKS`)
    unless the user allows it; headless tests need
    `--disable-features=LocalNetworkAccessChecks`. Check how the host
    Android/iOS WebView behaves on office Wi-Fi vs. mobile data.
11. **Manual request:** uploads work on UAT (user, browser). Still to
    confirm: a real `manual-insurance/save` / `edit` result in the back office
    (user allowed UAT submits), 'นอกเรท' from the search pages, and the camera
    / file chooser inside the host Android / iOS WebView (needs file-chooser
    support in the host app). Before prod: enable Anonymous sign-in in
    `sawad-new-ibs`. Anonymous users are created per session (token in memory
    only; auto clean-up after 30 days is on in UAT).
    Branch mapping assumption: launch param `branchCode` = FF
    `FFAppState().branchCode` (picker shown when longer than 2 chars),
    `branchName` = `profileUnitCodeName`, owner name = first + last name.
12. **Fire insurance:** the fire list is user-confirmed (2026-10-15); the
    fire search package (`/fire`) still waits for the user's test. Owner name sent as
    `firstName lastName` (FF `profileFullName`), branch = launch `branchCode`
    (FF `profileBranch`). The FF search page nested `Expanded` in unbounded
    columns; the port lays each field out as label-above-box — compare with
    the phone. Fire quotation list / follow-up / policy pages are not ported.
