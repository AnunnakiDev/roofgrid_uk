import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_complexity_feature.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_pricing_engine.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quote_pdf_exporter.dart';

void main() {
  test('LabourQuotePdfExporter generates non-empty PDF bytes', () async {
    const input = LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.traditionalPantile,
      roofAreaSqm: 40,
      includeStrip: true,
    );
    const config = LabourQuoteConfig(gangSize: 2, targetMarginPercent: 20);
    final project = LabourQuoteProject.singleSection(
      input: input,
    ).copyWith(
      quoteRef: 'Q-001',
      customerName: 'Test labour quote',
    );
    final projectResult = LabourPricingEngine.calculateProject(
      project: project,
      backend: LabourDefaults.backendData2026,
      config: config,
    );

    final bytes = await LabourQuotePdfExporter.generateBytes(
      project: project,
      config: config,
      projectResult: projectResult,
      importedFrom: 'Site job',
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('generates PDF for multi-section project with complexity', () async {
    const inputA = LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.traditionalPantile,
      roofAreaSqm: 30,
      includeStrip: true,
    );
    const inputB = LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.plainTile,
      roofAreaSqm: 20,
      includeStrip: true,
    );
    const config = LabourQuoteConfig(gangSize: 2, targetMarginPercent: 20);
    final project = LabourQuoteProject(
      quoteRef: 'Q-MULTI',
      customerName: 'Multi Customer',
      siteAddress: '2 Roof Lane',
      accessNotes: 'Narrow lane',
      scaffoldNotes: 'Full scaffold',
      sections: [
        LabourRoofSection(
          id: 'section-1',
          label: 'Main roof',
          input: inputA,
          complexityFeatures: [
            LabourComplexityFeature(
              type: LabourComplexityFeatureType.dormer,
              quantity: 2,
            ),
          ],
        ),
        LabourRoofSection(
          id: 'section-2',
          label: 'Rear extension',
          input: inputB,
        ),
      ],
    );
    final projectResult = LabourPricingEngine.calculateProject(
      project: project,
      backend: LabourDefaults.backendData2026,
      config: config,
    );

    final bytes = await LabourQuotePdfExporter.generateBytes(
      project: project,
      config: config,
      projectResult: projectResult,
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1200));
  });
}