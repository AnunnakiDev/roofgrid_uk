import 'package:roofgrid_uk/app/results/models/saved_result.dart';

/// Options when launching the set-out calculator (e.g. installer locked spec).
class CalculatorLaunchOptions {
  final SavedResult? savedResult;
  final bool lockTileSpec;
  final String? orgJobId;

  const CalculatorLaunchOptions({
    this.savedResult,
    this.lockTileSpec = false,
    this.orgJobId,
  });
}