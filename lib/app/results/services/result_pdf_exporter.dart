import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';
import 'package:roofgrid_uk/utils/saved_result_inputs.dart';
import 'package:roofgrid_uk/utils/vertical_result_fields.dart';

/// Builds a printable PDF report for a saved calculation result.
class ResultPdfExporter {
  ResultPdfExporter._();

  static Future<List<int>> generateBytes(SavedResult result) async {
    final normalized = normalizeSavedResult(result);
    final workings = buildJobWorkingsDataFromSavedResult(normalized);
    final typeLabel = savedCalculationTypeLabel(normalized.type);
    final savedAt = DateFormat('d MMM yyyy, HH:mm').format(normalized.createdAt);
    final materialType = materialTypeFromTileJson(normalized.tile);

    VerticalCalculationResult? verticalResult;
    HorizontalCalculationResult? horizontalResult;

    switch (normalized.type) {
      case CalculationType.vertical:
        verticalResult = VerticalCalculationResult.fromJson(normalized.outputs);
      case CalculationType.horizontal:
        horizontalResult =
            HorizontalCalculationResult.fromJson(normalized.outputs);
      case CalculationType.combined:
        verticalResult =
            VerticalCalculationResult.fromJson(normalized.outputs['vertical']);
        horizontalResult =
            HorizontalCalculationResult.fromJson(normalized.outputs['horizontal']);
    }

    final verticalInputs =
        normalized.inputs['vertical_inputs'] as Map<String, dynamic>?;
    final horizontalInputs =
        normalized.inputs['horizontal_inputs'] as Map<String, dynamic>?;
    final slopes = verticalInputs?['rafterHeights'] != null
        ? slopeEntriesFromSavedInputs(verticalInputs!['rafterHeights'] as List)
        : const <SlopeInputEntry>[];
    final widths = horizontalInputs?['widths'] != null
        ? widthEntriesFromSavedInputs(horizontalInputs!['widths'] as List)
        : const <WidthInputEntry>[];

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final blocks = <pw.Widget>[
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
              normalized.projectName,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text('$typeLabel · Saved $savedAt',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),
          ];

          if (workings.tileRows.isNotEmpty) {
            blocks.add(_sectionTitle('Tile'));
            blocks.add(_rowTable(workings.tileRows));
            blocks.add(pw.SizedBox(height: 12));
          }

          if (verticalResult != null) {
            blocks.add(_sectionTitle('Vertical set-out'));
            blocks.add(
              _rowTable(
                verticalSummaryRows(
                  result: verticalResult,
                  materialType: materialType,
                  slopes: slopes,
                ),
              ),
            );
            blocks.add(pw.SizedBox(height: 12));
            if (workings.verticalInputRows.isNotEmpty) {
              blocks.add(_subsectionTitle(workings.verticalInputsTitle));
              blocks.add(_rowTable(workings.verticalInputRows));
              blocks.add(pw.SizedBox(height: 8));
            }
            for (final section in workings.verticalWorkings) {
              blocks.add(_subsectionTitle(section.title));
              blocks.add(_rowTable(section.rows));
              blocks.add(pw.SizedBox(height: 8));
            }
          }

          if (horizontalResult != null) {
            blocks.add(_sectionTitle('Horizontal set-out'));
            blocks.add(_rowTable(horizontalSummaryRows(horizontalResult)));
            blocks.add(pw.SizedBox(height: 12));
            if (workings.horizontalInputRows.isNotEmpty) {
              blocks.add(_subsectionTitle(workings.horizontalInputsTitle));
              blocks.add(_rowTable(workings.horizontalInputRows));
              blocks.add(pw.SizedBox(height: 8));
            }
            for (final section in workings.horizontalWorkings) {
              blocks.add(_subsectionTitle(section.title));
              blocks.add(_rowTable(section.rows));
              blocks.add(pw.SizedBox(height: 8));
            }
          }

          blocks.add(pw.SizedBox(height: 16));
          blocks.add(
            pw.Text(
              'Generated by RoofGrid UK',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          );

          return blocks;
        },
      ),
    );

    return doc.save();
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

  static pw.Widget _subsectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4, top: 2),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _rowTable(List<ResultDisplayRow> rows) {
    if (rows.isEmpty) {
      return pw.Text('No data', style: const pw.TextStyle(fontSize: 10));
    }

    return pw.Table(
      border: null,
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
                  child: pw.Text(
                    row.label,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    row.value,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
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