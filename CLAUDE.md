# CLAUDE.md — Tanjai Web (ประกันทันใจ / New IBS)

Flutter **web** port of the FlutterFlow insurance mobile app "ประกันทันใจ"
(a.k.a. Tanjai, New IBS). The web build runs inside the Tanjai mobile app's
WebView. Features are ported **one at a time, as the user names them**, from the
FlutterFlow source repo `/Users/volley5544/Projects/Flutter/tanjai`.
App text/data is Thai; code, comments and commit messages are English.

`README.md` is the human-facing overview (features, run, launch params,
structure, deploy, security). This file is the working guide for Claude:
current state, rules, conventions, and what's open.

## Current state (read first) — updated 2026-10-08

- **Feature 1 — search insurance package (motor / EV / MC): ported, on `uat`,
  user-tested and confirmed working.** The user called it done for now. The
  next feature will be named by the user — wait for it.
- Live UAT: https://sawad-new-ibs-uat.web.app (`/motor`, `/ev`, `/mc`).
- **Prod (`main`) has never been deployed.** Nothing goes to prod until the user
  explicitly says so for that job.
- Commits on `uat`:
  - `eb77ccc` port of the search package feature
  - `f71435f` white-page loading view for on-open data loads
  - `1f045d2` "(UAT ver<build>)" tag in every AppBar
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
  `lib/search_package`; entry `search_insurance_page_widget.dart`).
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

E2E checks were done with headless Chrome + puppeteer-core from the session
scratchpad (not in the repo): serve `build/web` with the `firebase.json`
headers, click by coordinates, screenshot each step. Recreate if needed.

## Environments & data

| | UAT | PROD |
|---|---|---|
| Branch → Hosting | `uat` → `sawad-new-ibs-uat` | `main` → `sawad-new-ibs` |
| Insurance API | `https://is-dev.swpfin.com/ssw_tanjai_api_dev` | `https://tanjai.swpfin.com/ssw_tanjai_api` |
| Local/auth API | `https://prd-proxy.swpfin.com:8096` | same |

- `ENV` dart-define selects the env (default `uat`), `lib/core/config/app_environment.dart`.
  API hosts are compiled in, never read from the URL.
- **All Firestore data lives in prod project `sawad-new-ibs`** (UAT Firestore is
  empty). Read via REST without the SDK (`FirestoreRest`). Docs needing auth
  (`InsurerConfig2`, `hideInAppContent`) return 403 → defaults are used.
- `WEB_VERSION` = GitHub Actions `run_number`; shown as "(UAT ver N)" on UAT and
  logged at boot (`[TanjaiWeb] env=… webVersion=…`).
- CI: `.github/workflows/deploy-uat.yml` / `deploy-prod.yml`, secrets
  `FIREBASE_SERVICE_ACCOUNT_UAT` / `_PROD` (already set by the user).

## Architecture & conventions

- `lib/core/` — shared: `config/`, `session/` (UserSession + URL cleaner),
  `network/ApiClient` (JSON POST, timeout, no logging, `-1` on failure),
  `firebase/FirestoreRest`, `theme/` (`AppColors` = FF tokens + Tanjai oranges/navy,
  `AppText.style`), `utils/ff_functions.dart` (null-safe ports of FF custom
  functions, **same names** as FF), `widgets/`.
- `lib/features/<feature>/` — `models/`, `data/` (`*Api` singleton returning
  `ApiResult<T>`), `state/` (ChangeNotifier replacing FFAppState), pages.
- Router: go_router, path URL strategy, `lib/router/app_router.dart` (`AppRoutes`).
  Flow data lives in state, **never in the URL**; a page opened by refresh
  without its state redirects back to the product search page.
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
  git-ignored). Firestore: only via `tools/firestore-inspect/read.mjs`.
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
   data), the filter and compare pages (not click-tested), the quotation PDF
   iframe inside the Android WebView (may need the bridge to open the URL).
2. **'ชำระเต็มจำนวนเท่านั้น' label** is hidden on web: `InsurerConfig2` needs
   Firebase auth → needs a product decision or an ID token from the bridge.
3. **Security findings outside the web app:** the shared Basic credential for
   `getdate-time` ships in the bundle (`_kGetDateTimeBasicAuth`); insurance
   master/search APIs are unauthenticated; the API reflects any `Origin` in CORS.
4. **GitHub repo is public** — recommended to make it private before the pentest.
5. Pages reached from the flow but not ported yet open `/not-ported`
   (InsuranceInfoPage1, InsuranceListPage, SelectReasonPage).
6. JS bridge not started; it should replace the launch-param hand-off.
