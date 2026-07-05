import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_new_covering.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_stripping.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_pricing_engine.dart';

void main() {
  group('LabourPricingEngine section work', () {
    const config = LabourQuoteConfig(gangSize: 2, targetMarginPercent: 20);
    final backend = LabourDefaults.backendData2026;

    test('flat section uses flat roof rate set', () {
      const area = 35.0;
      final flat = LabourPricingEngine.calculateDual(
        input: const LabourQuoteInput(
          mode: LabourPricingMode.direct,
          roofType: LabourRoofType.flatFelt,
          roofAreaSqm: area,
          includeStrip: false,
        ),
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.timingBased,
        includeProjectExtras: false,
      );
      final pitched = LabourPricingEngine.calculateDual(
        input: const LabourQuoteInput(
          mode: LabourPricingMode.direct,
          roofType: LabourRoofType.traditionalPantile,
          roofAreaSqm: area,
          includeStrip: false,
        ),
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.timingBased,
        includeProjectExtras: false,
      );

      expect(
        flat.methodB.breakdown.firstWhere((l) => l.label.startsWith('Install')).hours,
        isNot(equals(
          pitched.methodB.breakdown.firstWhere((l) => l.label.startsWith('Install')).hours,
        )),
      );
    });

    test('lead bay linear metres are priced in Method A', () {
      const withLead = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 0,
        includeStrip: false,
        linearMetres: {LabourLinearItem.leadBay: 8},
      );
      final result = LabourPricingEngine.calculateDual(
        input: withLead,
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.rateBased,
        includeProjectExtras: false,
      );

      expect(result.methodA.baseLabourCostGbp, greaterThan(0));
      expect(
        result.methodA.breakdown.any((l) => l.label.contains('Lead bay')),
        isTrue,
      );
    });

    test('strip off reduces both method totals', () {
      const baseInput = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 40,
        includeStrip: true,
      );
      final withStrip = LabourPricingEngine.calculateDual(
        input: baseInput,
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.timingBased,
        includeProjectExtras: false,
      );
      final noStrip = LabourPricingEngine.calculateDual(
        input: baseInput.copyWith(includeStrip: false),
        backend: backend,
        config: config,
        selectedMethod: LabourQuoteMethod.timingBased,
        includeProjectExtras: false,
      );

      expect(
        withStrip.methodB.baseLabourCostGbp,
        greaterThan(noStrip.methodB.baseLabourCostGbp),
      );
      expect(
        withStrip.methodA.baseLabourCostGbp,
        greaterThan(noStrip.methodA.baseLabourCostGbp),
      );
    });

    test('old roof type uses separate strip rates', () {
      final section = LabourRoofSection(
        id: 'a',
        label: 'Re-roof',
        input: const LabourQuoteInput(
          mode: LabourPricingMode.direct,
          roofType: LabourRoofType.traditionalPantile,
          roofAreaSqm: 40,
        ),
        stripping: const SectionStripping(
          includeStrip: true,
          oldRoofType: LabourRoofType.naturalSlate,
        ),
      );
      final sameType = section.copyWith(
        stripping: const SectionStripping(includeStrip: true),
      );

      final slateStrip = LabourPricingEngine.calculateProject(
        project: LabourQuoteProject(sections: [section]),
        backend: backend,
        config: config,
      );
      final pantileStrip = LabourPricingEngine.calculateProject(
        project: LabourQuoteProject(sections: [sameType]),
        backend: backend,
        config: config,
      );

      final slateStripHours = slateStrip.sectionResults.first.dualResult.methodB
          .breakdown
          .firstWhere((line) => line.label.startsWith('Strip'))
          .hours;
      final pantileStripHours = pantileStrip.sectionResults.first.dualResult
          .methodB.breakdown
          .firstWhere((line) => line.label.startsWith('Strip'))
          .hours;
      expect(slateStripHours, greaterThan(pantileStripHours));
    });

    test('large format slate increases install cost', () {
      final standard = LabourRoofSection(
        id: 'a',
        label: 'Slate',
        input: const LabourQuoteInput(
          mode: LabourPricingMode.direct,
          roofType: LabourRoofType.naturalSlate,
          roofAreaSqm: 30,
          includeStrip: false,
        ),
        newCovering: const SectionNewCovering(
          slateSize: SlateSizeOption.standard,
        ),
      );
      final large = standard.copyWith(
        newCovering: const SectionNewCovering(
          slateSize: SlateSizeOption.largeFormat,
        ),
      );

      final standardResult = LabourPricingEngine.calculateProject(
        project: LabourQuoteProject(sections: [standard]),
        backend: backend,
        config: config,
      );
      final largeResult = LabourPricingEngine.calculateProject(
        project: LabourQuoteProject(sections: [large]),
        backend: backend,
        config: config,
      );

      final largeInstallHours = largeResult.sectionResults.first.dualResult
          .methodB.breakdown
          .firstWhere((line) => line.label.startsWith('Install'))
          .hours;
      final standardInstallHours = standardResult.sectionResults.first
          .dualResult.methodB.breakdown
          .firstWhere((line) => line.label.startsWith('Install'))
          .hours;
      expect(largeInstallHours, greaterThan(standardInstallHours));
    });
  });
}