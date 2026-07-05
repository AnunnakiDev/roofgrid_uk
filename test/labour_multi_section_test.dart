import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_pricing_engine.dart';

void main() {
  group('LabourPricingEngine.calculateProject', () {
    const config = LabourQuoteConfig(
      gangSize: 2,
      travelMiles: 20,
      overnightNights: 1,
      targetMarginPercent: 20,
    );
    final backend = LabourDefaults.backendData2026;

    const sectionAInput = LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.traditionalPantile,
      roofAreaSqm: 40,
      includeStrip: true,
    );
    const sectionBInput = LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.plainTile,
      roofAreaSqm: 30,
      includeStrip: false,
    );

    test('sums section labour and applies travel/overnight once', () {
      final project = LabourQuoteProject(
        sections: [
          const LabourRoofSection(
            id: 'a',
            label: 'Main roof',
            input: sectionAInput,
          ),
          const LabourRoofSection(
            id: 'b',
            label: 'Extension',
            input: sectionBInput,
          ),
        ],
      );

      final singleA = LabourPricingEngine.calculateDual(
        input: sectionAInput,
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.timingBased,
        includeProjectExtras: false,
      );
      final singleB = LabourPricingEngine.calculateDual(
        input: sectionBInput,
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.timingBased,
        includeProjectExtras: false,
      );

      final projectResult = LabourPricingEngine.calculateProject(
        project: project,
        backend: backend,
        config: config,
      );

      final expectedLabour =
          singleA.methodB.baseLabourCostGbp + singleB.methodB.baseLabourCostGbp;
      expect(projectResult.rollup.baseLabourCostGbp, closeTo(expectedLabour, 0.01));
      expect(projectResult.rollup.travelCostGbp, closeTo(20 * 0.65 * 2, 0.01));
      expect(projectResult.rollup.overnightCostGbp, 85);
      expect(projectResult.sectionResults.length, 2);

      final naiveDoubleTravel = LabourPricingEngine.calculateDual(
        input: sectionAInput,
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.timingBased,
      ).methodB.quoteTotalGbp +
          LabourPricingEngine.calculateDual(
            input: sectionBInput,
            backend: backend,
            config: config,
            selectedMethod: LabourQuoteMethod.timingBased,
          ).methodB.quoteTotalGbp;

      expect(
        projectResult.rollup.quoteTotalGbp,
        lessThan(naiveDoubleTravel),
      );
    });

    test('contingency applies to labour plus travel and overnight', () {
      final baseProject = LabourQuoteProject.singleSection(input: sectionAInput);
      final base = LabourPricingEngine.calculateProject(
        project: baseProject,
        backend: backend,
        config: config,
      );

      final withContingency = LabourPricingEngine.calculateProject(
        project: baseProject.copyWith(contingencyPercent: 10),
        backend: backend,
        config: config,
      );

      final preMarginBase = base.rollup.subtotalCostGbp;
      final preMarginWith = withContingency.rollup.subtotalCostGbp;
      expect(preMarginWith, closeTo(preMarginBase * 1.1, 0.5));
      expect(withContingency.contingencyCostGbp, greaterThan(0));
    });

    test('per-section method selection affects active rollup', () {
      final project = LabourQuoteProject(
        sections: [
          const LabourRoofSection(
            id: 'a',
            label: 'Rate section',
            input: sectionAInput,
            selectedMethod: LabourQuoteMethod.rateBased,
          ),
          const LabourRoofSection(
            id: 'b',
            label: 'Timing section',
            input: sectionBInput,
            selectedMethod: LabourQuoteMethod.timingBased,
          ),
        ],
      );

      final result = LabourPricingEngine.calculateProject(
        project: project,
        backend: backend,
        config: const LabourQuoteConfig(gangSize: 2, targetMarginPercent: 20),
      );

      final labourA = LabourPricingEngine.calculateDual(
        input: sectionAInput,
        backend: backend,
        config: const LabourQuoteConfig(gangSize: 2, targetMarginPercent: 20),
        selectedMethod: LabourQuoteMethod.rateBased,
        includeProjectExtras: false,
      ).methodA.baseLabourCostGbp;
      final labourB = LabourPricingEngine.calculateDual(
        input: sectionBInput,
        backend: backend,
        config: const LabourQuoteConfig(gangSize: 2, targetMarginPercent: 20),
        selectedMethod: LabourQuoteMethod.timingBased,
        includeProjectExtras: false,
      ).methodB.baseLabourCostGbp;

      expect(
        result.rollup.baseLabourCostGbp,
        closeTo(labourA + labourB, 0.01),
      );
    });

    test('skips sections without quantities', () {
      const emptyInput = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 0,
      );
      final project = LabourQuoteProject(
        sections: [
          const LabourRoofSection(id: 'a', label: 'Empty', input: emptyInput),
          const LabourRoofSection(
            id: 'b',
            label: 'Filled',
            input: sectionAInput,
          ),
        ],
      );

      final result = LabourPricingEngine.calculateProject(
        project: project,
        backend: backend,
        config: const LabourQuoteConfig(),
      );

      expect(result.sectionResults.length, 1);
      expect(result.sectionResults.first.section.label, 'Filled');
    });
  });
}