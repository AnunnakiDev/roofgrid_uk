/// Detailed measurements for one complexity feature instance.
class ComplexityMeasurement {
  final double widthM;
  final double heightM;
  final double pitchDegrees;
  final double upstandHeightM;
  final double projectionM;
  final String notes;

  const ComplexityMeasurement({
    this.widthM = 0,
    this.heightM = 0,
    this.pitchDegrees = 0,
    this.upstandHeightM = 0,
    this.projectionM = 0,
    this.notes = '',
  });

  ComplexityMeasurement copyWith({
    double? widthM,
    double? heightM,
    double? pitchDegrees,
    double? upstandHeightM,
    double? projectionM,
    String? notes,
  }) {
    return ComplexityMeasurement(
      widthM: widthM ?? this.widthM,
      heightM: heightM ?? this.heightM,
      pitchDegrees: pitchDegrees ?? this.pitchDegrees,
      upstandHeightM: upstandHeightM ?? this.upstandHeightM,
      projectionM: projectionM ?? this.projectionM,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'widthM': widthM,
        'heightM': heightM,
        'pitchDegrees': pitchDegrees,
        'upstandHeightM': upstandHeightM,
        'projectionM': projectionM,
        'notes': notes,
      };

  factory ComplexityMeasurement.fromJson(Map<String, dynamic> json) {
    return ComplexityMeasurement(
      widthM: (json['widthM'] as num?)?.toDouble() ?? 0,
      heightM: (json['heightM'] as num?)?.toDouble() ?? 0,
      pitchDegrees: (json['pitchDegrees'] as num?)?.toDouble() ?? 0,
      upstandHeightM: (json['upstandHeightM'] as num?)?.toDouble() ?? 0,
      projectionM: (json['projectionM'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
}