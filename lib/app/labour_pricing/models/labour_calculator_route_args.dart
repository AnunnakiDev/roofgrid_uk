import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';

/// Optional host handoff payload for [LabourPricingCalculatorScreen] via GoRouter `extra`.
class LabourCalculatorRouteArgs {
  final LabourQuoteProject? initialProject;
  final LabourQuoteConfig? initialQuoteConfig;
  final String? importJobId;
  final void Function(LabourSavedQuote quote)? onQuoteSaved;

  const LabourCalculatorRouteArgs({
    this.initialProject,
    this.initialQuoteConfig,
    this.importJobId,
    this.onQuoteSaved,
  });
}