import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_material_line.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_materials_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_pricing_engine.dart';

void main() {
  const input = LabourQuoteInput(
    mode: LabourPricingMode.direct,
    roofType: LabourRoofType.traditionalPantile,
    roofAreaSqm: 40,
    includeStrip: true,
  );
  const config = LabourQuoteConfig(gangSize: 2, targetMarginPercent: 20);
  const materialLines = [
    LabourMaterialLine(
      description: 'Underlay roll',
      unit: 'roll',
      suggestedQty: 2,
      unitPrice: 55,
    ),
  ];

  test('Method A includes material costs', () {
    final without = LabourPricingEngine.calculateDual(
      input: input,
      backend: LabourDefaults.backendData2026,
      config: config,
      selectedMethod: LabourQuoteMethod.rateBased,
      includeProjectExtras: false,
    );
    final withMaterials = LabourPricingEngine.calculateDual(
      input: input,
      backend: LabourDefaults.backendData2026,
      config: config,
      selectedMethod: LabourQuoteMethod.rateBased,
      includeProjectExtras: false,
      materialLines: materialLines,
    );

    expect(
      withMaterials.methodA.baseLabourCostGbp,
      greaterThan(without.methodA.baseLabourCostGbp),
    );
    expect(
      withMaterials.methodA.baseLabourCostGbp - without.methodA.baseLabourCostGbp,
      110,
    );
  });

  test('Method B unchanged by materials', () {
    final without = LabourPricingEngine.calculateDual(
      input: input,
      backend: LabourDefaults.backendData2026,
      config: config,
      selectedMethod: LabourQuoteMethod.timingBased,
      includeProjectExtras: false,
    );
    final withMaterials = LabourPricingEngine.calculateDual(
      input: input,
      backend: LabourDefaults.backendData2026,
      config: config,
      selectedMethod: LabourQuoteMethod.timingBased,
      includeProjectExtras: false,
      materialLines: materialLines,
    );

    expect(
      withMaterials.methodB.baseLabourCostGbp,
      without.methodB.baseLabourCostGbp,
    );
  });

  test('project calculation applies section materials in Method A only', () {
    final project = LabourQuoteProject(
      sections: [
        LabourRoofSection(
          id: 's1',
          label: 'Main',
          input: input,
          selectedMethod: LabourQuoteMethod.rateBased,
          materialsMode: SectionMaterialsMode.sectionOverride,
          materialLines: materialLines,
        ),
      ],
    );

    final result = LabourPricingEngine.calculateProject(
      project: project,
      backend: LabourDefaults.backendData2026,
      config: config,
    );

    final dual = result.sectionResults.single.dualResult;
    final withoutMaterials = LabourPricingEngine.calculateDual(
      input: input,
      backend: LabourDefaults.backendData2026,
      config: config,
      selectedMethod: LabourQuoteMethod.rateBased,
      includeProjectExtras: false,
    );

    expect(
      dual.methodA.baseLabourCostGbp,
      withoutMaterials.methodA.baseLabourCostGbp + 110,
    );
    expect(
      dual.methodB.baseLabourCostGbp,
      withoutMaterials.methodB.baseLabourCostGbp,
    );
  });
}