import 'package:roofgrid_uk/app/labour_pricing/models/labour_material_line.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_materials_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_section_calculator.dart';

/// Multi-section labour quote with project-level header fields.
class LabourQuoteProject {
  final String quoteRef;
  final DateTime? quoteDate;
  final String customerName;
  final String siteAddress;
  final String accessNotes;
  final String scaffoldNotes;
  final double contingencyPercent;
  final List<LabourRoofSection> sections;
  final List<LabourMaterialLine> projectMaterialLines;
  final bool useProjectMaterialsByDefault;

  const LabourQuoteProject({
    this.quoteRef = '',
    this.quoteDate,
    this.customerName = '',
    this.siteAddress = '',
    this.accessNotes = '',
    this.scaffoldNotes = '',
    this.contingencyPercent = 0,
    required this.sections,
    this.projectMaterialLines = const [],
    this.useProjectMaterialsByDefault = true,
  });

  factory LabourQuoteProject.initial({String sectionId = 'section-1'}) {
    return LabourQuoteProject(
      sections: [LabourRoofSection.initial(id: sectionId)],
    );
  }

  /// Wraps a single-section input for tests and legacy flows.
  factory LabourQuoteProject.singleSection({
    required LabourQuoteInput input,
    String sectionId = 'section-1',
    String sectionLabel = 'Section 1',
  }) {
    return LabourQuoteProject(
      sections: [
        LabourRoofSection(
          id: sectionId,
          label: sectionLabel,
          input: input,
        ),
      ],
    );
  }

  bool get hasQuantities => sections.any(_sectionHasQuantities);

  /// Material lines effective for a section (respects materials mode).
  List<LabourMaterialLine> materialLinesFor(LabourRoofSection section) {
    switch (section.materialsMode) {
      case SectionMaterialsMode.inheritProject:
        return projectMaterialLines;
      case SectionMaterialsMode.sectionOverride:
        return section.materialLines;
      case SectionMaterialsMode.none:
        return const [];
    }
  }

  double get projectMaterialCostGbp => projectMaterialLines.fold<double>(
        0,
        (sum, line) => sum + line.lineTotalGbp,
      );

  static bool _sectionHasQuantities(LabourRoofSection section) {
    final effective = LabourSectionCalculator.effectiveInput(section);
    if (effective.hasQuantities) return true;
    return LabourSectionCalculator.calcParams(section).additionalHours > 0;
  }

  LabourRoofSection? sectionById(String id) {
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }

  LabourQuoteProject copyWith({
    String? quoteRef,
    DateTime? quoteDate,
    String? customerName,
    String? siteAddress,
    String? accessNotes,
    String? scaffoldNotes,
    double? contingencyPercent,
    List<LabourRoofSection>? sections,
    List<LabourMaterialLine>? projectMaterialLines,
    bool? useProjectMaterialsByDefault,
  }) {
    return LabourQuoteProject(
      quoteRef: quoteRef ?? this.quoteRef,
      quoteDate: quoteDate ?? this.quoteDate,
      customerName: customerName ?? this.customerName,
      siteAddress: siteAddress ?? this.siteAddress,
      accessNotes: accessNotes ?? this.accessNotes,
      scaffoldNotes: scaffoldNotes ?? this.scaffoldNotes,
      contingencyPercent: contingencyPercent ?? this.contingencyPercent,
      sections: sections ?? this.sections,
      projectMaterialLines: projectMaterialLines ?? this.projectMaterialLines,
      useProjectMaterialsByDefault:
          useProjectMaterialsByDefault ?? this.useProjectMaterialsByDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'quoteRef': quoteRef,
        'quoteDate': quoteDate?.toIso8601String(),
        'customerName': customerName,
        'siteAddress': siteAddress,
        'accessNotes': accessNotes,
        'scaffoldNotes': scaffoldNotes,
        'contingencyPercent': contingencyPercent,
        'sections': sections.map((s) => s.toJson()).toList(),
        'projectMaterialLines':
            projectMaterialLines.map((line) => line.toJson()).toList(),
        'useProjectMaterialsByDefault': useProjectMaterialsByDefault,
      };

  factory LabourQuoteProject.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>? ?? const [];
    return LabourQuoteProject(
      quoteRef: json['quoteRef'] as String? ?? '',
      quoteDate: json['quoteDate'] != null
          ? DateTime.tryParse(json['quoteDate'] as String)
          : null,
      customerName: json['customerName'] as String? ?? '',
      siteAddress: json['siteAddress'] as String? ?? '',
      accessNotes: json['accessNotes'] as String? ?? '',
      scaffoldNotes: json['scaffoldNotes'] as String? ?? '',
      contingencyPercent:
          (json['contingencyPercent'] as num?)?.toDouble() ?? 0,
      sections: rawSections
          .map(
            (raw) => LabourRoofSection.fromJson(raw as Map<String, dynamic>),
          )
          .toList(),
      projectMaterialLines: _parseMaterialLines(json['projectMaterialLines']),
      useProjectMaterialsByDefault:
          json['useProjectMaterialsByDefault'] as bool? ?? true,
    );
  }

  static List<LabourMaterialLine> _parseMaterialLines(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map(
          (entry) =>
              LabourMaterialLine.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
  }
}