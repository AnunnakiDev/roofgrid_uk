import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

/// Human-readable summary after importing a set-out job into labour pricing.
class SavedResultLabourImportSummary {
  final String projectName;
  final String? tileName;
  final LabourRoofType roofType;
  final int sectionCount;
  final double roofAreaSqm;
  final double ridgeMetres;
  final double vergeMetres;
  final bool dryRidge;
  final bool dryVerge;
  final List<String> sectionLabels;
  final List<String> notes;

  const SavedResultLabourImportSummary({
    required this.projectName,
    this.tileName,
    required this.roofType,
    required this.sectionCount,
    required this.roofAreaSqm,
    required this.ridgeMetres,
    required this.vergeMetres,
    this.dryRidge = false,
    this.dryVerge = false,
    this.sectionLabels = const [],
    this.notes = const [],
  });
}