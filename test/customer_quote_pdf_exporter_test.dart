import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/customer_quote_branding.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_material_line.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_pricing_engine.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quote_pdf_exporter.dart';

void main() {
  test('generateBrandedBytes produces non-empty PDF', () async {
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
      quoteRef: 'CQ-001',
      customerName: 'Mrs Smith',
      siteAddress: '12 Oak Avenue',
    );
    final projectResult = LabourPricingEngine.calculateProject(
      project: project,
      backend: LabourDefaults.backendData2026,
      config: config,
    );
    const branding = CustomerQuoteBranding(
      companyName: 'Test Roofing Co',
      address: 'Unit 4, Industrial Estate',
      phone: '01234 567890',
      email: 'hello@testroofing.test',
      vatNumber: 'GB999999999',
      quoteFooterNotes: 'Payment due within 14 days.',
    );

    final bytes = await LabourQuotePdfExporter.generateBrandedBytes(
      project: project,
      config: config,
      projectResult: projectResult,
      branding: branding,
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('generateBrandedBytes includes materials BoQ table when lines exist',
      () async {
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
      quoteRef: 'CQ-002',
      customerName: 'Mr Jones',
      projectMaterialLines: const [
        LabourMaterialLine(
          description: 'Marley Double Roman',
          unit: 'each',
          suggestedQty: 1200,
          unitPrice: 0.85,
        ),
      ],
    );
    final projectResult = LabourPricingEngine.calculateProject(
      project: project,
      backend: LabourDefaults.backendData2026,
      config: config,
    );
    const branding = CustomerQuoteBranding(companyName: 'BoQ Roofing Ltd');

    final bytes = await LabourQuotePdfExporter.generateBrandedBytes(
      project: project,
      config: config,
      projectResult: projectResult,
      branding: branding,
    );

    expect(
      LabourQuotePdfExporter.brandedMaterialsBoqLineCount(project),
      1,
    );
    expect(bytes.length, greaterThan(2000));
  });
}