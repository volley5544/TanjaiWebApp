# ประกันทันใจ — Tanjai Web (New IBS)

Flutter **web** app embedded in the Tanjai mobile app's WebView. Features are
ported one at a time from the FlutterFlow mobile app
(`/Users/volley5544/Projects/Flutter/tanjai`), keeping the same screen flow,
results and look.

| | |
|---|---|
| Flutter | **3.47.6** (`~/DevelopTools/flutter3.47.6/bin/flutter`) |
| Envs | `uat` branch → `sawad-new-ibs-uat` Hosting · `main` branch → `sawad-new-ibs` Hosting |
| Data | Insurance API (per env, compiled in) + Firebase per env (UAT `sawad-new-ibs-uat`, prod `sawad-new-ibs`): Firestore config, anonymous sign-in, photo Storage — REST, no SDK |

## Ported features

| Feature | Entry | Status |
|---|---|---|
| Search insurance package — motor | `/motor` | ported, user-tested on UAT |
| Search insurance package — EV | `/ev` | ported, user-tested on UAT |
| Search insurance package — motorcycle | `/mc` | ported, user-tested on UAT |
| Quotation list (InsuranceListPage) → detail (MakeInsuranceListPage) → quotation PDF (QuotationCopy) | `/quotations` | ported, user-tested on UAT |
| Search insurance package — fire (ประกันอัคคีภัย): search → insurer list → detail → customer → quotation PDF | `/fire` | ported, user-tested on UAT |
| Fire quotation list (fireInsuranceListPage) → detail (MakeFireInsuranceListPage) → quotation PDF (FireQuotationCopy) | `/fire/quotations` | ported, user-tested on UAT |
| Request status / follow-up (LeadFollowUpPage, ติดตามประกันรถ): status counts → MakeInsuranceListPage → 'ทำประกัน' → request step 1 | `/follow-up` | ported, E2E-tested with stubbed data; awaiting user test |
| Request policy (ทำคำขอ / in-package, 5 steps): customer → vehicle → photos → documents + payment type → payment (full / installment, QR) → issue → status / cancel — **auto work, motor / EV / MC** | `/request/*` (from add-customer 'ทำประกัน' and the quotation list) | ported, E2E-tested in headless Chrome with all APIs stubbed; awaiting user test |
| Manual request งานนอกเรท — create (SelectReason → form → photos → documents → insurers → submit) and edit photos ('แก้ไข') | `/manual/*` (from 'นอกเรท' / 'คัดลอก' / 'แก้ไข') | ported, user-tested on UAT (uploads, compression, see-image) |

Live UAT: https://sawad-new-ibs-uat.web.app. Prod has not been deployed yet.

Pages the flows reach that are not ported yet (InsuranceInfoPage1 / 42 / 5,
NonePackageSelectedInsurerPage, LicenseSelectComponent) open a placeholder
(`/not-ported`).

### Quotation list (`/quotations`)

- List: `POST /api/lead/get-lead-list` (`owner_id`, `mode: arunsawad`,
  `list: quotation`). Search by first name, refresh, ⚠ legend = in-rate /
  out-of-rate filter, call button (`tel:`), card buttons 'แก้ไข' / 'คัดลอก'
  (manual request edit / copy, below) and 'ทำประกัน'.
- 'ทำประกัน' → confirm → `POST /api/lead/get-lead-by-id` → detail page
  (`results.info.watingInfo`, count `results.counting.status_waiting_info`).
- Detail buttons: 'ดูใบเสนอราคา' (`/quotations/pdf`), 'ดูกรมธรรม์'
  (`/api/quotations/get-file-vmi`, new tab), 'ดู พ.ร.บ'
  (`/api/quotations/get-file-cmi`), 'ติดตามงาน' (`/api/lead/get-history`
  sheet), 'เงื่อนไข บ.ประกัน' (insurer remark), main button → not-ported pages.
- All calls are reads; nothing is created or changed.
- Also reached from the add-customer save flow when the video-call gate
  blocks InsuranceInfoPage1.

### Fire insurance search package (`/fire`)

- `/fire` (FF SearchPackageFireInsurancePage): house type (8 fixed types),
  usable area as width × length or m², floors (1–5), building value
  (สิ่งปลูกสร้าง) from `POST /api/house/cal-estimated` once type + area +
  floors are set, and the contents value (ทรัพย์สินภายในสิ่งปลูกสร้าง).
- 'ค้นหา' → `/fire/insurers`: `POST /api/insurance/house/get_package?flag_get=1`
  (`sum_insured` = building + contents, 1 year) → package cards, order
  toggle (reverses the list, as FF) → 'รายละเอียด' → `/fire/detail`.
- 'ออกใบเสนอราคา' / 'ตกลงทำประกัน' → `/fire/customer` → `POST
  /api/house/quotations/save` (multipart, Bearer token; **creates a real
  quotation**) → `/fire/quotation` (PDF pager, no back arrow as in FF) or,
  for 'ตกลงทำประกัน', InsuranceInfoPage1 (not ported).
- Flow data in `FireSearchState`; reset when `/fire` opens.

### Fire quotation list (`/fire/quotations`)

- List: `POST /api/house/leads/get` (`owner_id`, Bearer token). Search by
  first name, call button, 'ทำประกัน' → confirm → `/fire/quotations/detail`
  with that lead.
- Detail: 'ดูใบเสนอราคา' (`leads_detail_house.pdf_quotation` →
  `/fire/quotations/pdf`, the same page as QuotationCopy), 'ดูกรมธรรม์' for
  approved leads (`/api/quotations/get-file-vmi`, new tab), main button →
  InsuranceInfoPage1 / 42 / 5 (not ported).
- All calls are reads. Not ported: the home-page fire dashboard preview and
  FireLeadFollowUpPage.

### Request policy — 5 steps (`/request/*`, FF `in_package_insurance`)

- Entry: add-customer 'ทำประกัน' (motor / EV / MC), the quotation-list main
  button and the follow-up page `/follow-up` (status tiles → list →
  'ทำประกัน'; auto: status → step 1, payment or status page). Step 1's back
  and the payment / status exits return to `/follow-up` (FF LeadFollowUpPage). Ids live in
  `PolicyRequestState`, never in the URL.
- Step 1 `/request/customer` (+ `/request/address`), step 2 `/request/vehicle`
  (+ accessories / พ.ร.บ. / beneficiary / branch sub-pages), step 3
  `/request/documents` (photos, consents), step 4 `/request/payment-documents`
  → `/request/payment-type` (full / installment), payment `/request/payment`
  (+ `/request/payment/qr`), step 5 `/request/status` (+ `/request/status/cancel`).
- APIs: `applications/list` (detail), `applications/save` (steps 1–4, **writes
  a draft**), `payment/calculate|save|regenerate`, `applications/edit`,
  `insurance/post/issue_policy` (**sends the application to the insurer**),
  `insurance/get|cancel/policy`, masters, blacklist, local `getdate-time`,
  `user-profile` and `license-insurance-broker` (employee level / position /
  licence, loaded once per session).
- Firestore (UAT copied from prod, config only): `dataList`, `urlLinkStorage`,
  `effectiveDayConfig`, `role_menu`, `InsurerConfig2`.
- Step 2: 'ปีที่ผลิต ค.ศ.' is required for every product (MC too); chassis /
  engine numbers are cleaned while typing (uppercase, only A–Z 0–9 .).
- Payment page in 'เตรียมข้อมูล': shows the payment type, channel, totals and
  tenor list returned by the 4.1 save (as the mobile app does).
- Step 3 (MC): the blue book photo is saved with the step (the mobile app
  required it but sent it empty).
- Structure: one set of step pages; every product / work-type difference is in
  a per-step rules class (`stepN_rules.dart`: Motor / EV / MC …), so a change
  for one product or work type touches only its class.
- Not ported: manual / renew / CMI / fire (House) branches of these pages,
  page 3_1, the CMI 'บันทึก พ.ร.บ.' admin button, 'การ์ดค่างวด' (http link).

### Manual request — งานนอกเรท (`/manual/*`)

- Create: 'นอกเรท' on work-select / result pages (pre-filled from the search
  form) or 'คัดลอก' on the quotation list (`/api/lead/get-lead-detail`) →
  `/manual/reason` → `/manual/basic` (master data: province, vehicle usage
  `vehicle_category: manual`, brands, models, cover types) → `/manual/photos`
  (car / truck / trailer diagram; skipped for EV, renew, usage 110, ชั้น 3) →
  `/manual/documents` (vehicle book, ID card, others, consents) →
  `/manual/insurers` (`get_insurers_all`, max 3) → `POST
  /api/manual-insurance/save` (multipart; **creates the request and emails
  the insurers**) → `/manual/success` or `/manual/unsuccess`.
- Edit ('แก้ไข'): `/manual/edit` (branch, one insurer) → detail → photos →
  documents → `POST /api/manual-insurance/edit` → back to the reloaded list.
- Photos: picked with `image_picker` (Gallery / Camera sheet, every image re-encoded to JPEG quality 50 within 1920×1920 px),
  uploaded to Firebase Storage `users/<anonUid>/uploads/…` via REST with an
  **anonymous Firebase identity** (`FirebaseAuthRest`); the API receives the
  download URLs, as with the mobile app. Firebase is per environment: UAT →
  `sawad-new-ibs-uat` (Anonymous enabled, bucket
  `sawad-new-ibs-uat.appspot.com`), prod → `sawad-new-ibs` (enable Anonymous
  there before the prod deploy).
- Every uploaded photo gets a "see image" icon next to its ✓ (on edit pages
  it shows the photo already on the request until a new one is uploaded).
- After a submit the insurance support team uploads the insurer quotation in
  the back office; the request then reaches the choose-insurer step
  (NonePackageSelectedInsurerPage — not ported yet).

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
| `token` | `accessToken` | `Authorization: Bearer` on lead / quotation / manual-request APIs |
| `empId` | `employeeID` | `owner_id` |
| `firstName`, `lastName` | `profileFirstName/LastName` | owner name (quotation, manual request) |
| `phone` | `ProfilePhoneNumber` | `owner_phone` |
| `branchCode`, `branchName` | `branchCode`, `profileUnitCodeName` (assumed) | request branch; a code longer than 2 chars shows the branch picker (FF rule) |

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
    firebase/              FirestoreRest (read-only REST), FirebaseAuthRest (anonymous),
                           FirebaseStorageRest (photo upload)
    theme/                 AppColors / AppText (FlutterFlow theme values)
    utils/ff_functions.dart  ports of FF custom functions
    widgets/               PageLoadingView (on-open loads), LoadingScene/withLoading (user actions),
                           EnvVersionTag, dialogs, AppButton, app bars, selector tiles
  features/
    home/                  test menu + not-ported placeholder
    policy_request/        5-step request-policy flow (PolicyRequestApi, ApplicationDetail,
                           RequestVariant, PolicyRequestState; step1/ … step5/, payment/,
                           each with its data, rules and pages; shared/ step widgets)
    fire_insurance/        fire search package (FireSearchState, FireInsuranceApi,
                           search/ results/ detail/ customer/ quotation/) and
                           fire quotation list (quotation_list/, FireQuotationListState)
    manual_request/        งานนอกเรท create + edit flows (NonePackageState, ManualRequestApi,
                           create/ edit/ shared/ — photo upload, diagram, form widgets)
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
tools/firestore-copy/      copy named collections prod → UAT (config only; refuses to write prod)
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

Hosting serves every page path (`/`, `/manual/basic`, …) with `no-cache`, so a
new deploy's headers (CSP) apply on the next load.

Firestore config for UAT is copied from prod with
`node tools/firestore-copy/copy.mjs prod uat <collections…>` — only the
collections the web reads (`Vehicle_Type_Dropdown`, `hideInAppContent`,
`InsurerConfig2`, `dataList`, `urlLinkStorage`, `effectiveDayConfig`,
`role_menu`); prod also holds user data and credentials.

**Before the first prod deploy:** enable Authentication → Sign-in method →
Anonymous in `sawad-new-ibs` (photo uploads need it).

## UI conventions

- **Loading:** a page loading its data on open shows a white body with an
  orange spinner and caption (`PageLoadingView`, like sawadLoanUniversal); a
  user action (search, save) shows the Tanjai overlay loader (`withLoading`).
- Screens, texts and colors follow the FlutterFlow app; deliberate FF quirks
  are kept and commented.

## Not yet verified end to end

- Quotation save for motor / EV / MC (needs a real token; creates real
  data). The fire save is user-tested.
- Request-policy flow against the real API: only click-tested with every API
  stubbed (no real application response was available); real saves, payment,
  QR, issue and cancel need the user's test on UAT.
- Filter and compare pages (built, not click-tested).
- Quotation PDF iframe inside the Android WebView.
- Quotation detail: 'ดูกรมธรรม์' / 'ดู พ.ร.บ' (need an approved quotation).
- On the office network the API hosts resolve to private 10.x IPs, so
  Chrome's Local Network Access check can block calls from the `web.app`
  origin until the user allows it — check the host WebView on office Wi-Fi.
- The call button (`tel:`) inside the host WebView.
- Manual request: the result of a real `manual-insurance/save` / `edit` in the
  back office, the 'นอกเรท' entry from the search pages (built, not
  click-tested), and Camera / file chooser inside the host WebView (needs
  file-chooser support in the host app).

## Security posture (pentest prep)

- No secrets in the repo or bundle except the known finding below; `etc/` and
  service-account keys are git-ignored.
- Launch params validated + stripped from the URL; API hosts compiled in.
- Hosting headers: CSP (self-hosted CanvasKit/fonts, `connect-src` limited to
  the API, Firestore, Firebase Auth / Storage hosts and `blob:`), HSTS, nosniff, `Referrer-Policy: no-referrer`,
  `X-Frame-Options: DENY`, Permissions-Policy, COOP.
- Release builds show a generic Thai error instead of stack traces and log no
  user data.

**Known findings to fix outside the web app**

1. The local API (`getdate-time`, `check-in/location`) requires a shared
   `Authorization: Basic` credential that ships in the client bundle
   (`kLocalApiBasicAuth`) — needs a per-user auth scheme server-side.
2. Master-data and package-search insurance APIs are unauthenticated (also
   the fire `house/get_package` and `house/cal-estimated`, which answers
   without a token), and the API echoes any `Origin` in
   `Access-Control-Allow-Origin`.
3. Auth-only Firestore docs (`hideInAppContent`, `InsurerConfig2`) are read
   with an anonymous Firebase identity where needed; anyone can mint one with
   the public web API key, so those docs must never hold secrets.
4. The GitHub repo is public — make it private before the pentest.
5. The **mobile app** signs every employee into Firebase as
   `<empId>@srisawadinsurance.com` with one hard-coded shared password
   (`check_status_firebase.dart`), so anyone who knows an employee ID can act
   as that employee in Firebase. The web build does not copy this (it uses an
   anonymous identity); the mobile app should move to per-user tokens.
