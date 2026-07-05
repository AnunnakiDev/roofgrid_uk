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
import 'package:roofgrid_uk/app/labour_pricing/services/labour_section_method_resolver.dart';

void main() {
  group('LabourSectionMethodResolver', () {
    const input = LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.traditionalPantile,
      roofAreaSqm: 40,
      includeStrip: true,
    );
    const config = LabourQuoteConfig(gangSize: 2, targetMarginPercent: 20);
    final backend = LabourDefaults.backendData2026;

    test('average uses midpoint of method A and B labour', () {
      final dual = LabourPricingEngine.calculateDual(
        input: input,
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.average,
        includeProjectExtras: false,
      );
      const section = LabourRoofSection(
        id: 's1',
        label: 'Main',
        input: input,
        selectedMethod: LabourQuoteMethod.average,
      );

      final average = LabourSectionMethodResolver.activeLabourCostGbp(
        section: section,
        dual: dual,
      );

      expect(
        average,
        closeTo(
          (dual.methodA.baseLabourCostGbp + dual.methodB.baseLabourCostGbp) / 2,
          0.01,
        ),
      );
    });

    test('manual override uses entered labour cost', () {
      final dual = LabourPricingEngine.calculateDual(
        input: input,
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.manualOverride,
        includeProjectExtras: false,
      );
      const section = LabourRoofSection(
        id: 's1',
        label: 'Main',
        input: input,
        selectedMethod: LabourQuoteMethod.manualOverride,
        manualOverrideGbp: 2500,
      );

      final manual = LabourSectionMethodResolver.activeLabourCostGbp(
        section: section,
        dual: dual,
      );

      expect(manual, 2500);
    });
  });

  group('calculateProject with average and manual', () {
    const input = LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.traditionalPantile,
      roofAreaSqm: 35,
      includeStrip: true,
    );
    const config = LabourQuoteConfig(gangSize: 2, targetMarginPercent: 20);
    final backend = LabourDefaults.backendData2026;

    test('average section rolls into project labour total', () {
      final dual = LabourPricingEngine.calculateDual(
        input: input,
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.average,
        includeProjectExtras: false,
      );
      final expectedAverage =
          (dual.methodA.baseLabourCostGbp + dual.methodB.baseLabourCostGbp) / 2;

      final result = LabourPricingEngine.calculateProject(
        project: LabourQuoteProject(
          sections: [
            const LabourRoofSection(
              id: 's1',
              label: 'Average roof',
              input: input,
              selectedMethod: LabourQuoteMethod.average,
            ),
          ],
        ),
        backend: backend,
        config: config,
      );

      expect(result.rollup.baseLabourCostGbp, closeTo(expectedAverage, 0.01));
    });

    test('manual override section rolls into project labour total', () {
      const manualGbp = 1800.0;
      final result = LabourPricingEngine.calculateProject(
        project: LabourQuoteProject(
          sections: [
            const LabourRoofSection(
              id: 's1',
              label: 'Manual roof',
              input: input,
              selectedMethod: LabourQuoteMethod.manualOverride,
              manualOverrideGbp: manualGbp,
            ),
          ],
        ),
        backend: backend,
        config: config,
      );

      expect(result.rollup.baseLabourCostGbp, manualGbp);
    });
  });
}