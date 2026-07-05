/// Per-quote job settings: gang, uplifts, margin.
class LabourQuoteConfig {
  final int gangSize;
  final double difficultyUpliftPercent;
  final double travelMiles;
  final int overnightNights;
  final double targetMarginPercent;
  final double hoursPerManDay;

  const LabourQuoteConfig({
    this.gangSize = 2,
    this.difficultyUpliftPercent = 0,
    this.travelMiles = 0,
    this.overnightNights = 0,
    this.targetMarginPercent = 20,
    this.hoursPerManDay = 8,
  });

  LabourQuoteConfig copyWith({
    int? gangSize,
    double? difficultyUpliftPercent,
    double? travelMiles,
    int? overnightNights,
    double? targetMarginPercent,
    double? hoursPerManDay,
  }) {
    return LabourQuoteConfig(
      gangSize: gangSize ?? this.gangSize,
      difficultyUpliftPercent:
          difficultyUpliftPercent ?? this.difficultyUpliftPercent,
      travelMiles: travelMiles ?? this.travelMiles,
      overnightNights: overnightNights ?? this.overnightNights,
      targetMarginPercent: targetMarginPercent ?? this.targetMarginPercent,
      hoursPerManDay: hoursPerManDay ?? this.hoursPerManDay,
    );
  }

  Map<String, dynamic> toJson() => {
        'gangSize': gangSize,
        'difficultyUpliftPercent': difficultyUpliftPercent,
        'travelMiles': travelMiles,
        'overnightNights': overnightNights,
        'targetMarginPercent': targetMarginPercent,
        'hoursPerManDay': hoursPerManDay,
      };

  factory LabourQuoteConfig.fromJson(Map<String, dynamic> json) {
    return LabourQuoteConfig(
      gangSize: (json['gangSize'] as num?)?.toInt() ?? 2,
      difficultyUpliftPercent:
          (json['difficultyUpliftPercent'] as num?)?.toDouble() ?? 0,
      travelMiles: (json['travelMiles'] as num?)?.toDouble() ?? 0,
      overnightNights: (json['overnightNights'] as num?)?.toInt() ?? 0,
      targetMarginPercent:
          (json['targetMarginPercent'] as num?)?.toDouble() ?? 20,
      hoursPerManDay: (json['hoursPerManDay'] as num?)?.toDouble() ?? 8,
    );
  }
}