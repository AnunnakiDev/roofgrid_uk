import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

enum StripDisposalOption {
  onSite,
  skipHire,
  recycle,
}

extension StripDisposalOptionLabels on StripDisposalOption {
  String get label {
    switch (this) {
      case StripDisposalOption.onSite:
        return 'On-site / customer disposal';
      case StripDisposalOption.skipHire:
        return 'Skip hire';
      case StripDisposalOption.recycle:
        return 'Recycle / segregated waste';
    }
  }
}

/// Category 4 — stripping details for a roof section.
class SectionStripping {
  final bool includeStrip;
  final LabourRoofType? oldRoofType;
  final String conditionNotes;
  final StripDisposalOption disposalOption;

  const SectionStripping({
    this.includeStrip = true,
    this.oldRoofType,
    this.conditionNotes = '',
    this.disposalOption = StripDisposalOption.onSite,
  });

  SectionStripping copyWith({
    bool? includeStrip,
    LabourRoofType? oldRoofType,
    bool clearOldRoofType = false,
    String? conditionNotes,
    StripDisposalOption? disposalOption,
  }) {
    return SectionStripping(
      includeStrip: includeStrip ?? this.includeStrip,
      oldRoofType: clearOldRoofType ? null : (oldRoofType ?? this.oldRoofType),
      conditionNotes: conditionNotes ?? this.conditionNotes,
      disposalOption: disposalOption ?? this.disposalOption,
    );
  }

  Map<String, dynamic> toJson() => {
        'includeStrip': includeStrip,
        'oldRoofType': oldRoofType?.name,
        'conditionNotes': conditionNotes,
        'disposalOption': disposalOption.name,
      };

  factory SectionStripping.fromJson(Map<String, dynamic> json) {
    return SectionStripping(
      includeStrip: json['includeStrip'] as bool? ?? true,
      oldRoofType: json['oldRoofType'] != null
          ? labourRoofTypeFromName(json['oldRoofType'] as String)
          : null,
      conditionNotes: json['conditionNotes'] as String? ?? '',
      disposalOption: StripDisposalOption.values.byName(
        json['disposalOption'] as String? ?? 'onSite',
      ),
    );
  }
}