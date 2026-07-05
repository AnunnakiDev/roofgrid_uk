import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:roofgrid_uk/app/labour_pricing/models/customer_quote_branding.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_complexity_feature.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_material_line.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_project_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

class LabourQuotePdfExporter {
  LabourQuotePdfExporter._();

  static Future<List<int>> generateBytes({
    required LabourQuoteProject project,
    required LabourQuoteConfig config,
    required LabourProjectResult projectResult,
    String? importedFrom,
  }) async {
    final gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');
    final quoteDate = project.quoteDate ?? DateTime.now();
    final formattedQuoteDate = DateFormat('d MMMM yyyy').format(quoteDate);
    final generatedAt = DateFormat('d MMM yyyy, HH:mm').format(DateTime.now());
    final title = project.customerName.trim().isNotEmpty
        ? project.customerName.trim()
        : (project.quoteRef.trim().isNotEmpty
            ? project.quoteRef.trim()
            : 'Labour quote');
    final rollup = projectResult.rollup;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text(
            'ROOFGRID UK',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Labour pricing quote · $formattedQuoteDate',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Generated $generatedAt',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          if (project.quoteRef.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Ref: ${project.quoteRef}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
          if (importedFrom != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Imported from set-out job: $importedFrom',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
          pw.SizedBox(height: 16),
          _sectionTitle('Customer & site'),
          _rowTable(_customerRows(project)),
          pw.SizedBox(height: 16),
          _sectionTitle('Project summary'),
          _rowTable([
            _PdfRow('Profitable day rate / man',
                gbp.format(rollup.profitableDayRatePerManGbp)),
            _PdfRow('Profitable day rate / gang',
                gbp.format(rollup.profitableDayRatePerGangGbp)),
            _PdfRow('Quote total', gbp.format(rollup.quoteTotalGbp)),
            _PdfRow('Method A total', gbp.format(projectResult.methodATotalGbp)),
            _PdfRow('Method B total', gbp.format(projectResult.methodBTotalGbp)),
            _PdfRow('Man-days (gang)', rollup.manDays.toStringAsFixed(2)),
            _PdfRow('Total hours', rollup.upliftedHours.toStringAsFixed(1)),
          ]),
          pw.SizedBox(height: 16),
          ...projectResult.sectionResults.expand(
            (sectionResult) => _sectionDetailWidgets(
              sectionResult: sectionResult,
              project: project,
              gbp: gbp,
            ),
          ),
          pw.SizedBox(height: 8),
          _sectionTitle('Gang & uplifts'),
          _rowTable([
            _PdfRow('Gang size', '${config.gangSize}'),
            _PdfRow('Difficulty uplift',
                '${config.difficultyUpliftPercent.toStringAsFixed(0)}%'),
            _PdfRow('Travel miles', config.travelMiles.toStringAsFixed(0)),
            _PdfRow('Overnight nights', '${config.overnightNights}'),
            _PdfRow('Contingency',
                '${project.contingencyPercent.toStringAsFixed(0)}%'),
            _PdfRow('Target margin',
                '${config.targetMarginPercent.toStringAsFixed(0)}%'),
          ]),
          pw.SizedBox(height: 16),
          _sectionTitle('Cost breakdown'),
          _rowTable([
            _PdfRow('Labour cost', gbp.format(rollup.baseLabourCostGbp)),
            if (rollup.travelCostGbp > 0)
              _PdfRow('Travel', gbp.format(rollup.travelCostGbp)),
            if (rollup.overnightCostGbp > 0)
              _PdfRow('Overnight', gbp.format(rollup.overnightCostGbp)),
            if (project.contingencyPercent > 0)
              _PdfRow('Contingency', gbp.format(projectResult.contingencyCostGbp)),
            _PdfRow('Subtotal', gbp.format(rollup.subtotalCostGbp)),
            _PdfRow('Quote total', gbp.format(rollup.quoteTotalGbp)),
          ]),
          pw.SizedBox(height: 20),
          pw.Text(
            'Generated by RoofGrid UK Labour Pricing Calculator',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<List<int>> generateBrandedBytes({
    required LabourQuoteProject project,
    required LabourQuoteConfig config,
    required LabourProjectResult projectResult,
    required CustomerQuoteBranding branding,
    Uint8List? logoBytes,
  }) async {
    final gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');
    final quoteDate = project.quoteDate ?? DateTime.now();
    final formattedDate = DateFormat('d MMMM yyyy').format(quoteDate);
    final rollup = projectResult.rollup;
    final companyName = branding.companyName.trim().isNotEmpty
        ? branding.companyName.trim()
        : 'Quotation';

    pw.ImageProvider? logoProvider;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      logoProvider = pw.MemoryImage(logoBytes);
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoProvider != null) ...[
                pw.Container(
                  width: 72,
                  height: 48,
                  child: pw.Image(logoProvider, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 12),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (branding.address.trim().isNotEmpty)
                      pw.Text(
                        branding.address.trim(),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    if (branding.phone.trim().isNotEmpty)
                      pw.Text(
                        branding.phone.trim(),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    if (branding.email.trim().isNotEmpty)
                      pw.Text(
                        branding.email.trim(),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    if (branding.vatNumber.trim().isNotEmpty)
                      pw.Text(
                        'VAT: ${branding.vatNumber.trim()}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'QUOTATION',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            formattedDate,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          if (project.quoteRef.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Reference: ${project.quoteRef}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
          pw.SizedBox(height: 16),
          _sectionTitle('Customer & site'),
          _rowTable(_customerRows(project)),
          pw.SizedBox(height: 16),
          _sectionTitle('Quoted works'),
          _rowTable([
            ...projectResult.sectionResults.map((sectionResult) {
              final section = sectionResult.section;
              final areaLabel = section.input.roofAreaSqm > 0
                  ? '${section.input.roofAreaSqm.toStringAsFixed(1)} m²'
                  : '—';
              return _PdfRow(
                '${section.label} (${section.input.roofType.label}, $areaLabel)',
                gbp.format(sectionResult.activeLabourCostGbp),
              );
            }),
            _PdfRow(
              'Total quotation',
              gbp.format(rollup.quoteTotalGbp),
              highlight: true,
            ),
          ]),
          ..._brandedMaterialsBoqWidgets(
            project: project,
            gbp: gbp,
          ),
          if (branding.quoteFooterNotes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Terms & notes'),
            pw.Text(
              branding.quoteFooterNotes.trim(),
              style: const pw.TextStyle(fontSize: 10, height: 1.4),
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Text(
            'This quotation is subject to site survey and final specification.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }

  @visibleForTesting
  static int brandedMaterialsBoqLineCount(LabourQuoteProject project) {
    var count = 0;
    for (final section in project.sections) {
      count += project
          .materialLinesFor(section)
          .where((line) => line.hasQuantity)
          .length;
    }
    return count;
  }

  static List<pw.Widget> _brandedMaterialsBoqWidgets({
    required LabourQuoteProject project,
    required NumberFormat gbp,
  }) {
    final sectionGroups = <String, List<LabourMaterialLine>>{};
    for (final section in project.sections) {
      final lines = project
          .materialLinesFor(section)
          .where((line) => line.hasQuantity)
          .toList();
      if (lines.isEmpty) continue;
      sectionGroups[section.label] = lines;
    }
    if (sectionGroups.isEmpty) return const [];

    var grandTotal = 0.0;
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 16),
      _sectionTitle('Materials specification'),
    ];

    for (final entry in sectionGroups.entries) {
      var sectionTotal = 0.0;
      for (final line in entry.value) {
        sectionTotal += line.lineTotalGbp;
      }
      grandTotal += sectionTotal;

      if (sectionGroups.length > 1) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
            child: pw.Text(
              entry.key,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        );
      }
      widgets.add(_materialsBoqTable(lines: entry.value, gbp: gbp));
      if (sectionGroups.length > 1) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, bottom: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Section materials: ${gbp.format(sectionTotal)}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'Materials total: ${gbp.format(grandTotal)}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.Text(
          'Material costs are included in the quoted labour total where applicable.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ),
    );

    return widgets;
  }

  static pw.Widget _materialsBoqTable({
    required List<LabourMaterialLine> lines,
    required NumberFormat gbp,
  }) {
    pw.Widget cell(
      String text, {
      bool header = false,
      pw.TextAlign align = pw.TextAlign.left,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: header ? 9 : 9,
            fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: header ? PdfColors.blueGrey800 : PdfColors.black,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            cell('Description', header: true),
            cell('Qty', header: true, align: pw.TextAlign.right),
            cell('Unit', header: true),
            cell('Unit price', header: true, align: pw.TextAlign.right),
            cell('Line total', header: true, align: pw.TextAlign.right),
          ],
        ),
        ...lines.map(
          (line) => pw.TableRow(
            children: [
              cell(line.description),
              cell(
                line.effectiveQty.toStringAsFixed(1),
                align: pw.TextAlign.right,
              ),
              cell(line.unit),
              cell(gbp.format(line.unitPrice), align: pw.TextAlign.right),
              cell(gbp.format(line.lineTotalGbp), align: pw.TextAlign.right),
            ],
          ),
        ),
      ],
    );
  }

  static List<_PdfRow> _customerRows(LabourQuoteProject project) {
    final rows = <_PdfRow>[];
    if (project.customerName.isNotEmpty) {
      rows.add(_PdfRow('Customer', project.customerName));
    }
    if (project.siteAddress.isNotEmpty) {
      rows.add(_PdfRow('Site address', project.siteAddress));
    }
    if (project.accessNotes.isNotEmpty) {
      rows.add(_PdfRow('Access notes', project.accessNotes));
    }
    if (project.scaffoldNotes.isNotEmpty) {
      rows.add(_PdfRow('Scaffold notes', project.scaffoldNotes));
    }
    if (rows.isEmpty) {
      rows.add(const _PdfRow('Customer', '—'));
    }
    return rows;
  }

  static List<pw.Widget> _sectionDetailWidgets({
    required LabourSectionResult sectionResult,
    required LabourQuoteProject project,
    required NumberFormat gbp,
  }) {
    final section = sectionResult.section;
    final dual = sectionResult.dualResult;
    final methodA = dual.methodA.baseLabourCostGbp;
    final methodB = dual.methodB.baseLabourCostGbp;
    final average = (methodA + methodB) / 2;
    final chosen = section.selectedMethod;

    final rows = <_PdfRow>[
      _PdfRow('Roof type', section.input.roofType.label),
      _PdfRow(
        'Roof area',
        section.input.roofAreaSqm > 0
            ? '${section.input.roofAreaSqm.toStringAsFixed(1)} m²'
            : '—',
      ),
      _PdfRow(
        'Strip existing',
        section.stripping.includeStrip ? 'Yes' : 'No',
      ),
      _PdfRow(
        'Method A (rate-based)',
        gbp.format(methodA),
        highlight: chosen == LabourQuoteMethod.rateBased,
      ),
      _PdfRow(
        'Method B (timing-based)',
        gbp.format(methodB),
        highlight: chosen == LabourQuoteMethod.timingBased,
      ),
      if (chosen == LabourQuoteMethod.average)
        _PdfRow(
          'Average of A & B',
          gbp.format(average),
          highlight: true,
        ),
      if (chosen == LabourQuoteMethod.manualOverride &&
          section.manualOverrideGbp != null)
        _PdfRow(
          'Manual override',
          gbp.format(section.manualOverrideGbp!),
          highlight: true,
        ),
      _PdfRow(
        'Chosen method',
        chosen.shortLabel,
      ),
      _PdfRow(
        'Section labour',
        gbp.format(sectionResult.activeLabourCostGbp),
        highlight: chosen == LabourQuoteMethod.manualOverride ||
            chosen == LabourQuoteMethod.average,
      ),
    ];

    final complexityRows = _complexityRows(section.complexityFeatures);
    if (complexityRows.isNotEmpty) {
      rows.addAll(complexityRows);
    }

    final materialLines = project.materialLinesFor(section);
    if (materialLines.isNotEmpty) {
      var materialTotal = 0.0;
      for (final line in materialLines) {
        if (!line.hasQuantity) continue;
        materialTotal += line.lineTotalGbp;
        rows.add(
          _PdfRow(
            'Material: ${line.description}',
            '${line.effectiveQty.toStringAsFixed(1)} ${line.unit} · ${gbp.format(line.lineTotalGbp)}',
          ),
        );
      }
      if (materialTotal > 0) {
        rows.add(
          _PdfRow(
            'Materials subtotal',
            gbp.format(materialTotal),
          ),
        );
      }
    }

    return [
      _sectionTitle(section.label),
      _rowTable(rows),
      pw.SizedBox(height: 12),
    ];
  }

  static List<_PdfRow> _complexityRows(
    List<LabourComplexityFeature> features,
  ) {
    final rows = <_PdfRow>[];
    for (final feature in features) {
      if (feature.quantity <= 0) continue;
      rows.add(
        _PdfRow(
          feature.type.label,
          '${feature.quantity}',
        ),
      );
    }
    return rows;
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey900,
        ),
      ),
    );
  }

  static pw.Widget _rowTable(List<_PdfRow> rows) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: rows
          .map(
            (row) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(row.label,
                      style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    row.value,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: row.highlight
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                      color: row.highlight
                          ? PdfColors.blueGrey900
                          : PdfColors.black,
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _PdfRow {
  final String label;
  final String value;
  final bool highlight;

  const _PdfRow(this.label, this.value, {this.highlight = false});
}