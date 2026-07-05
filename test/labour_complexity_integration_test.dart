import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/complexity_measurement.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_complexity_feature.dart';
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
  group('complexity integration', () {
    const baseInput = LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.traditionalPantile,
      roofAreaSqm: 40,
      includeStrip: true,
    );
    const config = LabourQuoteConfig(gangSize: 2, targetMarginPercent: 20);
    final backend = LabourDefaults.backendData2026;

    test('dormer measurements increase project totals', () {
      final plain = LabourQuoteProject.singleSection(input: baseInput);
      final withDormers = LabourQuoteProject(
        sections: [
          LabourRoofSection(
            id: 'a',
            label: 'Main roof',
            input: baseInput,
            complexityFeatures: [
              LabourComplexityFeature(
                type: LabourComplexityFeatureType.dormer,
                quantity: 2,
                instances: const [
                  ComplexityMeasurement(
                    widthM: 2,
                    heightM: 1.5,
                    projectionM: 1,
                  ),
                  ComplexityMeasurement(
                    widthM: 1.5,
                    heightM: 1.2,
                    projectionM: 0.8,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final plainResult = LabourPricingEngine.calculateProject(
        project: plain,
        backend: backend,
        config: config,
      );
      final complexResult = LabourPricingEngine.calculateProject(
        project: withDormers,
        backend: backend,
        config: config,
      );

      expect(
        complexResult.rollup.baseLabourCostGbp,
        greaterThan(plainResult.rollup.baseLabourCostGbp),
      );
      expect(
        complexResult.rollup.quoteTotalGbp,
        greaterThan(plainResult.rollup.quoteTotalGbp),
      );
    });

    test('heritage uplift increases totals above plain section', () {
      final plain = LabourQuoteProject.singleSection(input: baseInput);
      final heritage = LabourQuoteProject(
        sections: [
          LabourRoofSection(
            id: 'a',
            label: 'Heritage',
            input: baseInput,
            heritage: true,
            pitchDegrees: 45,
          ),
        ],
      );

      final plainResult = LabourPricingEngine.calculateProject(
        project: plain,
        backend: backend,
        config: config,
      );
      final heritageResult = LabourPricingEngine.calculateProject(
        project: heritage,
        backend: backend,
        config: config,
      );

      expect(
        heritageResult.rollup.upliftedHours,
        greaterThan(plainResult.rollup.upliftedHours),
      );
      expect(
        heritageResult.rollup.quoteTotalGbp,
        greaterThanOrEqualTo(plainResult.rollup.quoteTotalGbp),
      );
    });

    test('complexity-only section can still quote via derived quantities', () {
      final project = LabourQuoteProject(
        sections: [
          LabourRoofSection(
            id: 'a',
            label: 'Dormers only',
            input: const LabourQuoteInput(
              mode: LabourPricingMode.direct,
              roofType: LabourRoofType.traditionalPantile,
              roofAreaSqm: 0,
              includeStrip: false,
            ),
            complexityFeatures: [
              LabourComplexityFeature(
                type: LabourComplexityFeatureType.dormer,
                quantity: 1,
                instances: const [
                  ComplexityMeasurement(
                    widthM: 2,
                    heightM: 1.5,
                    projectionM: 1,
                  ),
                ],
              ),
            ],
            selectedMethod: LabourQuoteMethod.timingBased,
          ),
        ],
      );

      final result = LabourPricingEngine.calculateProject(
        project: project,
        backend: backend,
        config: config,
      );

      expect(result.sectionResults.length, 1);
      expect(result.rollup.quoteTotalGbp, greaterThan(0));
    });
  });
}