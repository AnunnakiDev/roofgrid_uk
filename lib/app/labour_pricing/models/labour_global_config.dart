/// Project-wide day rates, travel, and timing defaults.
class LabourGlobalConfig {
  final double directFullDayRatePerMan;
  final double directHalfDayRatePerMan;
  final double subFullDayRatePerMan;
  final double subHalfDayRatePerMan;
  final double costPerMile;
  final double overnightCostPerNight;
  final double hoursPerManDay;
  final int defaultGangSize;

  const LabourGlobalConfig({
    this.directFullDayRatePerMan = 220,
    this.directHalfDayRatePerMan = 132,
    this.subFullDayRatePerMan = 180,
    this.subHalfDayRatePerMan = 108,
    this.costPerMile = 0.65,
    this.overnightCostPerNight = 85,
    this.hoursPerManDay = 8,
    this.defaultGangSize = 2,
  });

  double fullDayRateFor(bool isDirect) =>
      isDirect ? directFullDayRatePerMan : subFullDayRatePerMan;

  LabourGlobalConfig copyWith({
    double? directFullDayRatePerMan,
    double? directHalfDayRatePerMan,
    double? subFullDayRatePerMan,
    double? subHalfDayRatePerMan,
    double? costPerMile,
    double? overnightCostPerNight,
    double? hoursPerManDay,
    int? defaultGangSize,
  }) {
    return LabourGlobalConfig(
      directFullDayRatePerMan:
          directFullDayRatePerMan ?? this.directFullDayRatePerMan,
      directHalfDayRatePerMan:
          directHalfDayRatePerMan ?? this.directHalfDayRatePerMan,
      subFullDayRatePerMan: subFullDayRatePerMan ?? this.subFullDayRatePerMan,
      subHalfDayRatePerMan: subHalfDayRatePerMan ?? this.subHalfDayRatePerMan,
      costPerMile: costPerMile ?? this.costPerMile,
      overnightCostPerNight:
          overnightCostPerNight ?? this.overnightCostPerNight,
      hoursPerManDay: hoursPerManDay ?? this.hoursPerManDay,
      defaultGangSize: defaultGangSize ?? this.defaultGangSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'directFullDayRatePerMan': directFullDayRatePerMan,
        'directHalfDayRatePerMan': directHalfDayRatePerMan,
        'subFullDayRatePerMan': subFullDayRatePerMan,
        'subHalfDayRatePerMan': subHalfDayRatePerMan,
        'costPerMile': costPerMile,
        'overnightCostPerNight': overnightCostPerNight,
        'hoursPerManDay': hoursPerManDay,
        'defaultGangSize': defaultGangSize,
      };

  factory LabourGlobalConfig.fromJson(Map<String, dynamic> json) {
    return LabourGlobalConfig(
      directFullDayRatePerMan:
          (json['directFullDayRatePerMan'] as num?)?.toDouble() ?? 220,
      directHalfDayRatePerMan:
          (json['directHalfDayRatePerMan'] as num?)?.toDouble() ?? 132,
      subFullDayRatePerMan:
          (json['subFullDayRatePerMan'] as num?)?.toDouble() ?? 180,
      subHalfDayRatePerMan:
          (json['subHalfDayRatePerMan'] as num?)?.toDouble() ?? 108,
      costPerMile: (json['costPerMile'] as num?)?.toDouble() ?? 0.65,
      overnightCostPerNight:
          (json['overnightCostPerNight'] as num?)?.toDouble() ?? 85,
      hoursPerManDay: (json['hoursPerManDay'] as num?)?.toDouble() ?? 8,
      defaultGangSize: (json['defaultGangSize'] as num?)?.toInt() ?? 2,
    );
  }
}