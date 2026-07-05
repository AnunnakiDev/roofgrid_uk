import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_pricing_engine.dart';

void main() {
  group('LabourPricingEngine', () {
    final rates = LabourDefaults.starterRates;
    const config = LabourQuoteConfig(
      gangSize: 2,
      targetMarginPercent: 20,
    );

    test('direct pantile re-roof produces expected hours and profitable rate',
        () {
      const input = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 50,
        includeStrip: true,
        linearMetres: {
          LabourLinearItem.ridge: 12,
          LabourLinearItem.verge: 24,
        },
        ancillaryCounts: {
          LabourAncillary.chimney: 1,
        },
      );

      final result = LabourPricingEngine.calculate(
        input: input,
        rates: rates,
        config: config,
      );

      // Strip 50×0.15=7.5, install 50×0.35=17.5, ridge 12×0.25=3, verge 24×0.2=4.8, chimney 4
      expect(result.baseHours, closeTo(36.8, 0.01));
      expect(result.upliftedHours, closeTo(36.8, 0.01));
      // 36.8 / (2×8) = 2.3 gang-days → billed 2.5
      expect(result.manDays, closeTo(2.3, 0.01));
      expect(result.baseLabourCostGbp, closeTo(2.5 * 2 * 220, 0.01));
      expect(result.travelCostGbp, 0);
      expect(result.subtotalCostGbp, closeTo(1100, 0.01));
      expect(result.quoteTotalGbp, closeTo(1375, 0.01));
      expect(
        result.profitableDayRatePerManGbp,
        closeTo(1375 / (2.3 * 2), 0.5),
      );
      expect(result.breakdown.length, 5);
    });

    test('sub-contractor mode uses lower day rate profile', () {
      const input = LabourQuoteInput(
        mode: LabourPricingMode.subContractor,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 40,
        includeStrip: false,
      );

      final direct = LabourPricingEngine.calculate(
        input: input.copyWith(mode: LabourPricingMode.direct),
        rates: rates,
        config: config,
      );
      final sub = LabourPricingEngine.calculate(
        input: input,
        rates: rates,
        config: config,
      );

      expect(sub.baseHours, lessThan(direct.baseHours));
      expect(sub.baseLabourCostGbp, lessThan(direct.baseLabourCostGbp));
      expect(sub.profitableDayRatePerManGbp, lessThan(direct.profitableDayRatePerManGbp));
    });

    test('slate roof type multiplier increases hours', () {
      const baseInput = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 30,
        includeStrip: true,
      );

      final pantile = LabourPricingEngine.calculate(
        input: baseInput,
        rates: rates,
        config: config,
      );
      final slate = LabourPricingEngine.calculate(
        input: baseInput.copyWith(roofType: LabourRoofType.naturalSlate),
        rates: rates,
        config: config,
      );

      expect(slate.baseHours / pantile.baseHours, closeTo(1.25, 0.01));
    });

    test('difficulty uplift and travel costs increase quote total', () {
      const input = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.plainTile,
        roofAreaSqm: 35,
        includeStrip: true,
      );

      final base = LabourPricingEngine.calculate(
        input: input,
        rates: rates,
        config: config,
      );
      final withUplifts = LabourPricingEngine.calculate(
        input: input,
        rates: rates,
        config: const LabourQuoteConfig(
          gangSize: 2,
          difficultyUpliftPercent: 15,
          travelMiles: 40,
          overnightNights: 1,
          targetMarginPercent: 20,
        ),
      );

      expect(withUplifts.upliftedHours, greaterThan(base.upliftedHours));
      expect(withUplifts.travelCostGbp, closeTo(40 * 0.65 * 2, 0.01));
      expect(withUplifts.overnightCostGbp, 85);
      expect(withUplifts.quoteTotalGbp, greaterThan(base.quoteTotalGbp));
    });

    test('margin raises profitable day rate above cost day rate', () {
      const input = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.modernInterlocking,
        roofAreaSqm: 45,
        includeStrip: true,
        linearMetres: {LabourLinearItem.valley: 8},
      );

      final result = LabourPricingEngine.calculate(
        input: input,
        rates: rates,
        config: const LabourQuoteConfig(
          gangSize: 2,
          targetMarginPercent: 25,
        ),
      );

      expect(
        result.profitableDayRatePerManGbp,
        greaterThan(rates.direct.fullDayRatePerMan),
      );
      expect(result.quoteTotalGbp, greaterThan(result.subtotalCostGbp));
    });

    test('zero area with linear items only still quotes', () {
      const input = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 0,
        includeStrip: false,
        linearMetres: {LabourLinearItem.ridge: 10},
      );

      final result = LabourPricingEngine.calculate(
        input: input,
        rates: rates,
        config: config,
      );

      expect(result.baseHours, closeTo(2.5, 0.01));
      expect(result.quoteTotalGbp, greaterThan(0));
    });
  });
}