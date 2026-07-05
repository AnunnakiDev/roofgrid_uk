import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

enum SlateSizeOption {
  notApplicable,
  standard,
  largeFormat,
  randomCourtyard,
}

extension SlateSizeOptionLabels on SlateSizeOption {
  String get label {
    switch (this) {
      case SlateSizeOption.notApplicable:
        return 'Not applicable';
      case SlateSizeOption.standard:
        return 'Standard slate';
      case SlateSizeOption.largeFormat:
        return 'Large format';
      case SlateSizeOption.randomCourtyard:
        return 'Random / courtyard';
    }
  }
}

/// Category 5 — new covering notes and slate sizing.
class SectionNewCovering {
  final SlateSizeOption slateSize;
  final String underlayNotes;
  final String battenNotes;

  const SectionNewCovering({
    this.slateSize = SlateSizeOption.notApplicable,
    this.underlayNotes = '',
    this.battenNotes = '',
  });

  static SectionNewCovering forRoofType(LabourRoofType roofType) {
    if (roofType == LabourRoofType.naturalSlate) {
      return const SectionNewCovering(slateSize: SlateSizeOption.standard);
    }
    return const SectionNewCovering();
  }

  SectionNewCovering copyWith({
    SlateSizeOption? slateSize,
    String? underlayNotes,
    String? battenNotes,
  }) {
    return SectionNewCovering(
      slateSize: slateSize ?? this.slateSize,
      underlayNotes: underlayNotes ?? this.underlayNotes,
      battenNotes: battenNotes ?? this.battenNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'slateSize': slateSize.name,
        'underlayNotes': underlayNotes,
        'battenNotes': battenNotes,
      };

  factory SectionNewCovering.fromJson(Map<String, dynamic> json) {
    return SectionNewCovering(
      slateSize: SlateSizeOption.values.byName(
        json['slateSize'] as String? ?? 'notApplicable',
      ),
      underlayNotes: json['underlayNotes'] as String? ?? '',
      battenNotes: json['battenNotes'] as String? ?? '',
    );
  }
}