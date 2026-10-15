import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/session/user_session.dart';
import '../features/fire_insurance/customer/fire_add_customer_page.dart';
import '../features/fire_insurance/detail/fire_package_detail_page.dart';
import '../features/fire_insurance/quotation/fire_quotation_page.dart';
import '../features/fire_insurance/results/fire_insurer_list_page.dart';
import '../features/fire_insurance/search/fire_search_page.dart';
import '../features/home/home_menu_page.dart';
import '../features/home/not_ported_page.dart';
import '../features/manual_request/create/basic_page.dart';
import '../features/manual_request/create/insurer_page.dart';
import '../features/manual_request/create/photo_pages.dart';
import '../features/manual_request/create/select_reason_page.dart';
import '../features/manual_request/edit/edit_pages.dart';
import '../features/manual_request/result_page.dart';
import '../features/quotation_list/detail/make_insurance_list_page.dart';
import '../features/quotation_list/detail/quotation_copy_page.dart';
import '../features/quotation_list/list/quotation_list_page.dart';
import '../features/search_package/compare/compare_page.dart';
import '../features/search_package/customer/add_customer_page.dart';
import '../features/search_package/detail/package_detail_page.dart';
import '../features/search_package/ev/ev_search_page.dart';
import '../features/search_package/mc/mc_search_page.dart';
import '../features/search_package/motor/motor_search_page.dart';
import '../features/search_package/product_type.dart';
import '../features/search_package/quotation/quotation_page.dart';
import '../features/search_package/results/insurer_list_page.dart';
import '../features/search_package/results/insurer_overall_page.dart';
import '../features/search_package/results/package_filter_page.dart';
import '../features/search_package/work_select/work_select_page.dart';

/// Route paths. Product-scoped pages live under `/<motor|ev|mc>/…`; flow data
/// is held in that product's `SearchPackageState`, never in the URL (no
/// customer data or tokens in links / history). A page reached with no state
/// (e.g. after a browser refresh) sends the user back to its search page.
abstract final class AppRoutes {
  static const home = '/';
  static String search(ProductType p) => '/${p.path}';
  static String insurers(ProductType p) => '/${p.path}/insurers';
  static String packages(ProductType p) => '/${p.path}/packages';
  static String filter(ProductType p, String fromPage) => '/${p.path}/filter?from=$fromPage';
  static String detail(ProductType p) => '/${p.path}/detail';
  static String compare(ProductType p) => '/${p.path}/compare';
  static String customer(ProductType p, {required String fromPage, required String fromBtn}) =>
      '/${p.path}/customer?from=$fromPage&btn=$fromBtn';
  static String quotation(ProductType p) => '/${p.path}/quotation';
  static String workSelect(ProductType p) => '/${p.path}/work-select';

  /// Quotation list (FF InsuranceListPage) → MakeInsuranceListPage →
  /// QuotationCopy. Not product-scoped; flow data in `QuotationListState`.
  static const quotationList = '/quotations';
  static const quotationDetail = '/quotations/detail';
  static const quotationCopy = '/quotations/pdf';

  /// Manual (none-package) request: create flow, result pages, edit flow.
  /// Flow data in `NonePackageState`.
  static const manualReason = '/manual/reason';
  static const manualBasic = '/manual/basic';
  static const manualPhotos = '/manual/photos';
  static const manualDocuments = '/manual/documents';
  static const manualInsurers = '/manual/insurers';
  static const manualSuccess = '/manual/success';
  static const manualUnsuccess = '/manual/unsuccess';
  static const manualEdit = '/manual/edit';
  static const manualEditDetail = '/manual/edit/detail';
  static const manualEditPhotos = '/manual/edit/photos';
  static const manualEditDocuments = '/manual/edit/documents';

  /// Fire insurance search package (FF SearchPackageFireInsurancePage →
  /// fireInsurerListPage → detailsFireInsurancePage → AddFireCustomerName →
  /// FireQuotationPage). Flow data in `FireSearchState`.
  static const fireSearch = '/fire';
  static const fireInsurers = '/fire/insurers';
  static const fireDetail = '/fire/detail';
  static String fireCustomer({required bool doInsurance}) =>
      '/fire/customer?btn=${doInsurance ? 'doInsurance' : 'quotation'}';
  static const fireQuotation = '/fire/quotation';

  /// Hand-off to a mobile-app page that isn't ported yet.
  static String notPorted(String pageName) => '/not-ported?page=${Uri.encodeQueryComponent(pageName)}';
}

final GoRouter appRouter = GoRouter(
  // Launch params (token, empId, …) are consumed by UserSession at boot; drop
  // them from the location so they never stay in the address bar or history.
  redirect: (context, state) {
    final q = state.uri.queryParameters;
    if (!q.keys.any(UserSession.launchParamNames.contains)) return null;
    final kept = Map.of(q)..removeWhere((k, _) => UserSession.launchParamNames.contains(k));
    return Uri(path: state.uri.path, queryParameters: kept.isEmpty ? null : kept).toString();
  },
  // Unknown paths land on the menu rather than an error page.
  errorBuilder: (context, state) => const HomeMenuPage(),
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeMenuPage()),
    GoRoute(path: '/motor', builder: (context, state) => const MotorSearchPage()),
    GoRoute(path: '/ev', builder: (context, state) => const EvSearchPage()),
    GoRoute(path: '/mc', builder: (context, state) => const McSearchPage()),
    // Before the `/:product/…` routes: `/quotations/detail` would match
    // `/:product/detail` otherwise (same for `/fire/…`). The fire routes are
    // flat (not nested) so `go(fireQuotation)` doesn't rebuild the search
    // page, whose open resets the flow state.
    GoRoute(path: AppRoutes.fireSearch, builder: (context, state) => const FireSearchPage()),
    GoRoute(path: AppRoutes.fireInsurers, builder: (context, state) => const FireInsurerListPage()),
    GoRoute(path: AppRoutes.fireDetail, builder: (context, state) => const FirePackageDetailPage()),
    GoRoute(
      path: '/fire/customer',
      builder: (context, state) =>
          FireAddCustomerPage(doInsurance: state.uri.queryParameters['btn'] == 'doInsurance'),
    ),
    GoRoute(path: AppRoutes.fireQuotation, builder: (context, state) => const FireQuotationPage()),
    GoRoute(
      path: AppRoutes.quotationList,
      builder: (context, state) => const QuotationListPage(),
      routes: [
        GoRoute(path: 'detail', builder: (context, state) => const MakeInsuranceListPage()),
        GoRoute(path: 'pdf', builder: (context, state) => const QuotationCopyPage()),
      ],
    ),
    GoRoute(path: AppRoutes.manualReason, builder: (context, state) => const SelectReasonPage()),
    GoRoute(path: AppRoutes.manualBasic, builder: (context, state) => const BasicPage()),
    GoRoute(path: AppRoutes.manualPhotos, builder: (context, state) => const BasicImage1Page()),
    GoRoute(path: AppRoutes.manualDocuments, builder: (context, state) => const BasicImage2Page()),
    GoRoute(path: AppRoutes.manualInsurers, builder: (context, state) => const InsurerPage()),
    GoRoute(path: AppRoutes.manualSuccess, builder: (context, state) => const RequestResultPage(success: true)),
    GoRoute(path: AppRoutes.manualUnsuccess, builder: (context, state) => const RequestResultPage(success: false)),
    GoRoute(
      path: AppRoutes.manualEdit,
      builder: (context, state) => const EditPage1(),
      routes: [
        GoRoute(path: 'detail', builder: (context, state) => const EditDetailPage()),
        GoRoute(path: 'photos', builder: (context, state) => const EditPage2()),
        GoRoute(path: 'documents', builder: (context, state) => const EditPage3()),
      ],
    ),
    GoRoute(
      path: '/not-ported',
      builder: (context, state) => NotPortedPage(pageName: state.uri.queryParameters['page'] ?? ''),
    ),
    GoRoute(
      path: '/:product/insurers',
      builder: (context, state) => _product(state, (p) => InsurerOverallPage(product: p)),
    ),
    GoRoute(
      path: '/:product/packages',
      builder: (context, state) => _product(state, (p) => InsurerListPage(product: p)),
    ),
    GoRoute(
      path: '/:product/filter',
      builder: (context, state) => _product(
        state,
        (p) => PackageFilterPage(product: p, fromPage: state.uri.queryParameters['from'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/:product/detail',
      builder: (context, state) => _product(state, (p) => PackageDetailPage(product: p)),
    ),
    GoRoute(
      path: '/:product/compare',
      builder: (context, state) => _product(state, (p) => ComparePage(product: p)),
    ),
    GoRoute(
      path: '/:product/customer',
      builder: (context, state) => _product(
        state,
        (p) => AddCustomerPage(
          product: p,
          fromPage: state.uri.queryParameters['from'] ?? 'detail',
          fromBtn: state.uri.queryParameters['btn'] ?? 'quotationBtn',
        ),
      ),
    ),
    GoRoute(
      path: '/:product/quotation',
      builder: (context, state) => _product(state, (p) => QuotationPage(product: p)),
    ),
    GoRoute(
      path: '/:product/work-select',
      builder: (context, state) => _product(state, (p) => WorkSelectPage(product: p)),
    ),
  ],
);

Widget _product(GoRouterState state, Widget Function(ProductType) build) {
  final product = ProductType.fromPath(state.pathParameters['product']);
  return product == null ? const HomeMenuPage() : build(product);
}
