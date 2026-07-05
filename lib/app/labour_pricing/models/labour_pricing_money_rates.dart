/// Method A £/m² strip and install rates for one pricing mode.
class LabourPricingMoneyRates {
  final double stripPerSqm;
  final double installPerSqm;

  const LabourPricingMoneyRates({
    required this.stripPerSqm,
    required this.installPerSqm,
  });

  LabourPricingMoneyRates copyWith({
    double? stripPerSqm,
    double? installPerSqm,
  }) {
    return LabourPricingMoneyRates(
      stripPerSqm: stripPerSqm ?? this.stripPerSqm,
      installPerSqm: installPerSqm ?? this.installPerSqm,
    );
  }

  Map<String, dynamic> toJson() => {
        'stripPerSqm': stripPerSqm,
        'installPerSqm': installPerSqm,
      };

  factory LabourPricingMoneyRates.fromJson(Map<String, dynamic> json) {
    return LabourPricingMoneyRates(
      stripPerSqm: (json['stripPerSqm'] as num).toDouble(),
      installPerSqm: (json['installPerSqm'] as num).toDouble(),
    );
  }
}