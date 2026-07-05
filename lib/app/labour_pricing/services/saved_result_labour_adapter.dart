import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/saved_result_labour_import_summary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';
import 'package:roofgrid_uk/utils/saved_result_inputs.dart';
import 'package:roofgrid_uk/utils/vertical_result_fields.dart';

class SavedResultLabourMeasurements {
  final double roofAreaSqm;
  final double ridgeMetres;
  final double vergeMetres;

  const SavedResultLabourMeasurements({
    this.roofAreaSqm = 0,
    this.ridgeMetres = 0,
    this.vergeMetres = 0,
  });
}

/// Maps set-out [SavedResult] quantities into labour quote input (read-only).
class SavedResultLabourAdapter {
  SavedResultLabourAdapter._();

  static LabourRoofType? roofTypeFromTile(Map<String, dynamic>? tile) {
    final raw = materialTypeFromTileJson(tile)?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;

    if (raw.contains('slate') && !raw.contains('fibre')) {
      return LabourRoofType.naturalSlate;
    }
    if (raw.contains('shingle')) {
      return LabourRoofType.shingles;
    }
    if (raw.contains('felt')) {
      return LabourRoofType.flatFelt;
    }
    if (raw.contains('grp')) {
      return LabourRoofType.flatGrp;
    }
    if (raw.contains('liquid')) {
      return LabourRoofType.flatLiquid;
    }
    if (raw.contains('single') && raw.contains('ply')) {
      return LabourRoofType.flatSinglePly;
    }
    if (raw.contains('lead') && raw.contains('flat')) {
      return LabourRoofType.flatTraditionalLead;
    }
    if (raw.contains('fibre')) {
      return LabourRoofType.fibreCementSlate;
    }
    if (raw.contains('plain')) {
      return LabourRoofType.plainTile;
    }
    if (raw.contains('interlocking') || raw.contains('concrete')) {
      return LabourRoofType.modernInterlocking;
    }
    if (raw.contains('pantile')) {
      return LabourRoofType.traditionalPantile;
    }
    return LabourRoofType.traditionalPantile;
  }

  static Map<LabourLinearItem, double> linearMetresFromJobFlags({
    required double ridgeMetres,
    required double vergeMetres,
    String? useDryRidge,
    String? useDryVerge,
  }) {
    final linearMetres = <LabourLinearItem, double>{};
    if (ridgeMetres > 0) {
      if (useDryRidge == 'YES') {
        linearMetres[LabourLinearItem.dryRidge] = ridgeMetres;
      } else {
        linearMetres[LabourLinearItem.ridge] = ridgeMetres;
      }
    }
    if (vergeMetres > 0) {
      if (useDryVerge == 'YES') {
        linearMetres[LabourLinearItem.dryVerge] = vergeMetres;
      } else {
        linearMetres[LabourLinearItem.verge] = vergeMetres;
      }
    }
    return linearMetres;
  }

  static _SavedJobFlags _flagsFromInputs(Map<String, dynamic> inputs) {
    final verticalInputs = inputs['vertical_inputs'] as Map<String, dynamic>?;
    final horizontalInputs =
        inputs['horizontal_inputs'] as Map<String, dynamic>?;
    return _SavedJobFlags(
      useDryRidge: verticalInputs?['useDryRidge'] as String?,
      useDryVerge: horizontalInputs?['useDryVerge'] as String?,
    );
  }

  static SavedResultLabourMeasurements measurementsFromSavedResult(
    SavedResult result,
  ) {
    final normalized = normalizeSavedResult(result);
    final inputs = normalized.inputs;

    final verticalInputs = inputs['vertical_inputs'] as Map<String, dynamic>?;
    final horizontalInputs =
        inputs['horizontal_inputs'] as Map<String, dynamic>?;

    final slopes = verticalInputs?['rafterHeights'] != null
        ? slopeEntriesFromSavedInputs(verticalInputs!['rafterHeights'] as List)
        : const <SlopeInputEntry>[];
    final widths = horizontalInputs?['widths'] != null
        ? widthEntriesFromSavedInputs(horizontalInputs!['widths'] as List)
        : const <WidthInputEntry>[];

    var areaSqm = 0.0;
    var ridgeMetres = 0.0;
    var vergeMetres = 0.0;

    if (slopes.isNotEmpty && widths.isNotEmpty) {
      final pairs = slopes.length < widths.length ? slopes.length : widths.length;
      for (var i = 0; i < pairs; i++) {
        final slopeM = slopes[i].value / 1000;
        final widthM = widths[i].value / 1000;
        areaSqm += slopeM * widthM;
        ridgeMetres += widthM;
        vergeMetres += slopeM * 2;
      }
    } else if (slopes.isNotEmpty) {
      for (final slope in slopes) {
        vergeMetres += (slope.value / 1000) * 2;
      }
    } else if (widths.isNotEmpty) {
      for (final width in widths) {
        ridgeMetres += width.value / 1000;
      }
    }

    return SavedResultLabourMeasurements(
      roofAreaSqm: areaSqm,
      ridgeMetres: ridgeMetres,
      vergeMetres: vergeMetres,
    );
  }

  static LabourQuoteInput? inputFromSavedResult(SavedResult result) {
    final project = projectFromSavedResult(result);
    if (project == null || project.sections.isEmpty) return null;

    if (project.sections.length == 1) {
      return project.sections.first.input;
    }

    final normalized = normalizeSavedResult(result);
    final measurements = measurementsFromSavedResult(normalized);
    final flags = _flagsFromInputs(normalized.inputs);
    final linearMetres = linearMetresFromJobFlags(
      ridgeMetres: measurements.ridgeMetres,
      vergeMetres: measurements.vergeMetres,
      useDryRidge: flags.useDryRidge,
      useDryVerge: flags.useDryVerge,
    );

    return LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: project.sections.first.input.roofType,
      roofAreaSqm: measurements.roofAreaSqm,
      includeStrip: true,
      linearMetres: linearMetres,
    );
  }

  /// Builds a multi-section project — one [LabourRoofSection] per slope/bay pair.
  static LabourQuoteProject? projectFromSavedResult(SavedResult result) {
    final normalized = normalizeSavedResult(result);
    final roofType = roofTypeFromTile(normalized.tile);
    if (roofType == null) return null;

    final inputs = normalized.inputs;
    final flags = _flagsFromInputs(inputs);
    final verticalInputs = inputs['vertical_inputs'] as Map<String, dynamic>?;
    final horizontalInputs =
        inputs['horizontal_inputs'] as Map<String, dynamic>?;

    final slopes = verticalInputs?['rafterHeights'] != null
        ? slopeEntriesFromSavedInputs(verticalInputs!['rafterHeights'] as List)
        : const <SlopeInputEntry>[];
    final widths = horizontalInputs?['widths'] != null
        ? widthEntriesFromSavedInputs(horizontalInputs!['widths'] as List)
        : const <WidthInputEntry>[];

    final sections = <LabourRoofSection>[];

    if (slopes.isNotEmpty && widths.isNotEmpty) {
      final pairs = slopes.length < widths.length ? slopes.length : widths.length;
      for (var i = 0; i < pairs; i++) {
        sections.add(
          _sectionFromBay(
            index: i,
            roofType: roofType,
            slope: slopes[i],
            width: widths[i],
            useDryRidge: flags.useDryRidge,
            useDryVerge: flags.useDryVerge,
          ),
        );
      }
      for (var i = pairs; i < slopes.length; i++) {
        sections.add(
          _sectionFromSlopeOnly(
            index: i,
            roofType: roofType,
            slope: slopes[i],
          ),
        );
      }
      for (var i = pairs; i < widths.length; i++) {
        sections.add(
          _sectionFromWidthOnly(
            index: i,
            roofType: roofType,
            width: widths[i],
          ),
        );
      }
    } else if (slopes.isNotEmpty) {
      for (var i = 0; i < slopes.length; i++) {
        sections.add(
          _sectionFromSlopeOnly(
            index: i,
            roofType: roofType,
            slope: slopes[i],
          ),
        );
      }
    } else if (widths.isNotEmpty) {
      for (var i = 0; i < widths.length; i++) {
        sections.add(
          _sectionFromWidthOnly(
            index: i,
            roofType: roofType,
            width: widths[i],
          ),
        );
      }
    } else {
      sections.add(
        LabourRoofSection.initial(
          id: 'section-1',
          label: 'Section 1',
        ).copyWith(
          input: LabourQuoteInput(
            mode: LabourPricingMode.direct,
            roofType: roofType,
            roofAreaSqm: 0,
            includeStrip: true,
          ),
        ),
      );
    }

    return LabourQuoteProject(
      customerName: result.projectName,
      sections: sections,
    );
  }

  static SavedResultLabourImportSummary? importSummaryFromSavedResult(
    SavedResult result,
  ) {
    final project = projectFromSavedResult(result);
    if (project == null || project.sections.isEmpty) return null;

    final normalized = normalizeSavedResult(result);
    final measurements = measurementsFromSavedResult(normalized);
    final flags = _flagsFromInputs(normalized.inputs);
    final roofType = roofTypeFromTile(normalized.tile);
    if (roofType == null) return null;

    final notes = <String>[
      'Area uses slope length × width per bay — add pitch or hips/valleys manually if needed.',
    ];
    if (measurements.ridgeMetres <= 0 || measurements.vergeMetres <= 0) {
      notes.add('Some linear quantities are missing — check sections before calculating.');
    }

    return SavedResultLabourImportSummary(
      projectName: result.projectName,
      tileName: normalized.tile['name']?.toString(),
      roofType: roofType,
      sectionCount: project.sections.length,
      roofAreaSqm: measurements.roofAreaSqm,
      ridgeMetres: measurements.ridgeMetres,
      vergeMetres: measurements.vergeMetres,
      dryRidge: flags.useDryRidge == 'YES',
      dryVerge: flags.useDryVerge == 'YES',
      sectionLabels: project.sections.map((section) => section.label).toList(),
      notes: notes,
    );
  }

  static LabourRoofSection _sectionFromBay({
    required int index,
    required LabourRoofType roofType,
    required SlopeInputEntry slope,
    required WidthInputEntry width,
    String? useDryRidge,
    String? useDryVerge,
  }) {
    final slopeM = slope.value / 1000;
    final widthM = width.value / 1000;
    final linearMetres = linearMetresFromJobFlags(
      ridgeMetres: widthM,
      vergeMetres: slopeM > 0 ? slopeM * 2 : 0,
      useDryRidge: useDryRidge,
      useDryVerge: useDryVerge,
    );

    return LabourRoofSection(
      id: 'section-${index + 1}',
      label: _sectionLabel(slope.label, width.label, index),
      input: LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: roofType,
        roofAreaSqm: slopeM * widthM,
        includeStrip: true,
        linearMetres: linearMetres,
      ),
    );
  }

  static LabourRoofSection _sectionFromSlopeOnly({
    required int index,
    required LabourRoofType roofType,
    required SlopeInputEntry slope,
  }) {
    final slopeM = slope.value / 1000;
    final linearMetres = <LabourLinearItem, double>{};
    if (slopeM > 0) {
      linearMetres[LabourLinearItem.verge] = slopeM * 2;
    }

    return LabourRoofSection(
      id: 'section-${index + 1}',
      label: slope.label.trim().isNotEmpty
          ? slope.label.trim()
          : 'Section ${index + 1}',
      input: LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: roofType,
        roofAreaSqm: 0,
        includeStrip: true,
        linearMetres: linearMetres,
      ),
    );
  }

  static LabourRoofSection _sectionFromWidthOnly({
    required int index,
    required LabourRoofType roofType,
    required WidthInputEntry width,
  }) {
    final widthM = width.value / 1000;
    final linearMetres = <LabourLinearItem, double>{};
    if (widthM > 0) {
      linearMetres[LabourLinearItem.ridge] = widthM;
    }

    return LabourRoofSection(
      id: 'section-${index + 1}',
      label: width.label.trim().isNotEmpty
          ? width.label.trim()
          : 'Section ${index + 1}',
      input: LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: roofType,
        roofAreaSqm: 0,
        includeStrip: true,
        linearMetres: linearMetres,
      ),
    );
  }

  static String _sectionLabel(String slopeLabel, String widthLabel, int index) {
    final slope = slopeLabel.trim();
    final width = widthLabel.trim();
    if (slope.isNotEmpty && width.isNotEmpty) {
      return '$slope / $width';
    }
    if (slope.isNotEmpty) return slope;
    if (width.isNotEmpty) return width;
    return 'Section ${index + 1}';
  }
}

class _SavedJobFlags {
  final String? useDryRidge;
  final String? useDryVerge;

  const _SavedJobFlags({
    this.useDryRidge,
    this.useDryVerge,
  });
}