/// Which product / work type a request-policy flow is for.
///
/// Design (user, 2026-10-16): the five step pages are shared, but every
/// product- or work-type-specific rule lives in a per-step *rules* class
/// (`stepN/stepN_rules.dart`: `MotorStepNRules`, `EvStepNRules`,
/// `McStepNRules`, …) chosen from this variant. A change that concerns one
/// product or work type edits only that class — never an `if` in a page.
enum RequestProduct {
  /// sub_product 'Motor', ev_flag ≠ 'Y'.
  motor,

  /// sub_product 'Motor', ev_flag 'Y'.
  ev,

  /// sub_product 'MC'.
  mc,

  /// sub_product 'CMI' (stand-alone พ.ร.บ.) — not ported yet.
  cmi,

  /// sub_product 'House' (fire) — steps 2–5 are separate FF pages; not ported yet.
  house,
}

enum RequestWorkType {
  /// quotation_type_bak 'auto' (in-package / ในเรท).
  auto,

  /// anything else (manual / นอกเรท, renew …) — not ported yet.
  manual,
}

class RequestVariant {
  const RequestVariant(this.product, this.workType);

  final RequestProduct product;
  final RequestWorkType workType;

  /// From the application detail: `leads[0].sub_product`, `ev_flag`,
  /// `quotations.quotation_type_bak`.
  factory RequestVariant.from({
    required String subProduct,
    required String evFlag,
    required String applicationType,
  }) {
    final product = switch (subProduct) {
      'MC' => RequestProduct.mc,
      'CMI' => RequestProduct.cmi,
      'House' => RequestProduct.house,
      _ => evFlag == 'Y' ? RequestProduct.ev : RequestProduct.motor,
    };
    return RequestVariant(product, applicationType == 'auto' ? RequestWorkType.auto : RequestWorkType.manual);
  }

  bool get isAuto => workType == RequestWorkType.auto;

  /// The combinations this web port implements (motor / EV / MC, auto).
  bool get isSupported =>
      isAuto && (product == RequestProduct.motor || product == RequestProduct.ev || product == RequestProduct.mc);

  @override
  String toString() => '${product.name}/${workType.name}';
}
