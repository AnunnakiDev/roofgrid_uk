import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_pricing_engine.dart';

void main() {
  group('LabourPricingEngine.calculateDual', () {
    const input = LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.traditionalPantile,
      roofAreaSqm: 50,
      includeStrip: true,
    );
    const config = LabourQuoteConfig(
      gangSize: 2,
      targetMarginPercent: 20,
    );

    test('returns both method totals', () {
      final dual = LabourPricingEngine.calculateDual(
        input: input,
        backend: LabourDefaults.backendData2026,
        config: config,
        selectedMethod: LabourQuoteMethod.timingBased,
      );

      expect(dual.methodA.quoteTotalGbp, greaterThan(0));
      expect(dual.methodB.quoteTotalGbp, greaterThan(0));
      expect(dual.activeQuoteTotalGbp, dual.methodB.quoteTotalGbp);
    });

    test('selected method switches active total', () {
      final dual = LabourPricingEngine.calculateDual(
        input: input,
        backend: LabourDefaults.backendData2026,
        config: config,
        selectedMethod: LabourQuoteMethod.rateBased,
      );

      expect(dual.activeQuoteTotalGbp, dual.methodA.quoteTotalGbp);
    });

    test('linear £/lm change affects method A only', () {
      final backend = LabourDefaults.backendData2026;
      final rateSet = backend.rateSetFor(LabourRoofType.traditionalPantile);
      const inputWithRidge = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 0,
        includeStrip: false,
        linearMetres: {LabourLinearItem.ridge: 10},
      );
      final higherRidgeBackend = backend.updateRateSet(
        LabourRoofType.traditionalPantile,
        rateSet.copyWith(
          directItemMoney: rateSet.directItemMoney.copyWith(
            linearRatePerMetre: {
              ...rateSet.directItemMoney.linearRatePerMetre,
              LabourLinearItem.ridge: 25,
            },
          ),
        ),
      );

      final base = LabourPricingEngine.calculateDual(
        input: inputWithRidge,
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.rateBased,
      );
      final raised = LabourPricingEngine.calculateDual(
        input: inputWithRidge,
        backend: higherRidgeBackend,
        config: config,
        selectedMethod: LabourQuoteMethod.rateBased,
      );

      expect(
        raised.methodA.quoteTotalGbp,
        greaterThan(base.methodA.quoteTotalGbp),
      );
      expect(
        raised.methodB.quoteTotalGbp,
        closeTo(base.methodB.quoteTotalGbp, 0.01),
      );
    });

    test('direct vs sub mode changes both method totals', () {
      const sharedInput = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 45,
        includeStrip: true,
      );
      final direct = LabourPricingEngine.calculateDual(
        input: sharedInput,
        backend: LabourDefaults.backendData2026,
        config: config,
        selectedMethod: LabourQuoteMethod.timingBased,
        includeProjectExtras: false,
      );
      final sub = LabourPricingEngine.calculateDual(
        input: sharedInput.copyWith(mode: LabourPricingMode.subContractor),
        backend: LabourDefaults.backendData2026,
        config: config,
        selectedMethod: LabourQuoteMethod.timingBased,
        includeProjectExtras: false,
      );

      expect(
        direct.methodA.baseLabourCostGbp,
        isNot(closeTo(sub.methodA.baseLabourCostGbp, 0.01)),
      );
      expect(
        direct.methodB.baseLabourCostGbp,
        isNot(closeTo(sub.methodB.baseLabourCostGbp, 0.01)),
      );
    });

    test('average active total is midpoint of A and B', () {
      final dual = LabourPricingEngine.calculateDual(
        input: input,
        backend: LabourDefaults.backendData2026,
        config: config,
        selectedMethod: LabourQuoteMethod.average,
      );

      expect(
        dual.activeResult.baseLabourCostGbp,
        closeTo(
          (dual.methodA.baseLabourCostGbp + dual.methodB.baseLabourCostGbp) / 2,
          0.01,
        ),
      );
    });

    test('strip rate change affects method A only', () {
      final backend = LabourDefaults.backendData2026;
      final rateSet = backend.rateSetFor(LabourRoofType.traditionalPantile);
      final higherStripBackend = backend.updateRateSet(
        LabourRoofType.traditionalPantile,
        rateSet.copyWith(
          directMoney: rateSet.directMoney.copyWith(stripPerSqm: 50),
        ),
      );

      final base = LabourPricingEngine.calculateDual(
        input: input,
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.rateBased,
      );
      final raised = LabourPricingEngine.calculateDual(
        input: input,
        backend: higherStripBackend,
        config: config,
        selectedMethod: LabourQuoteMethod.rateBased,
      );

      expect(
        raised.methodA.quoteTotalGbp,
        greaterThan(base.methodA.quoteTotalGbp),
      );
      expect(
        raised.methodB.quoteTotalGbp,
        closeTo(base.methodB.quoteTotalGbp, 0.01),
      );
    });
  });
}