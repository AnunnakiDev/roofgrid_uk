class VerticalCalculationResult {
  final int inputRafter;
  final int totalCourses;
  final String solution;
  final int ridgeOffset;
  final int? underEaveBatten;
  final int? eaveBatten;
  final int firstBatten;
  final int? cutCourse;
  final String gauge;
  final String? splitGauge;
  final String? warning;

  const VerticalCalculationResult({
    required this.inputRafter,
    required this.totalCourses,
    required this.solution,
    required this.ridgeOffset,
    this.underEaveBatten,
    this.eaveBatten,
    required this.firstBatten,
    this.cutCourse,
    required this.gauge,
    this.splitGauge,
    this.warning,
  });

  VerticalCalculationResult copyWith({
    int? inputRafter,
    int? totalCourses,
    String? solution,
    int? ridgeOffset,
    int? underEaveBatten,
    int? eaveBatten,
    int? firstBatten,
    int? cutCourse,
    String? gauge,
    String? splitGauge,
    String? warning,
  }) {
    return VerticalCalculationResult(
      inputRafter: inputRafter ?? this.inputRafter,
      totalCourses: totalCourses ?? this.totalCourses,
      solution: solution ?? this.solution,
      ridgeOffset: ridgeOffset ?? this.ridgeOffset,
      underEaveBatten: underEaveBatten ?? this.underEaveBatten,
      eaveBatten: eaveBatten ?? this.eaveBatten,
      firstBatten: firstBatten ?? this.firstBatten,
      cutCourse: cutCourse ?? this.cutCourse,
      gauge: gauge ?? this.gauge,
      splitGauge: splitGauge ?? this.splitGauge,
      warning: warning ?? this.warning,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inputRafter': inputRafter,
      'totalCourses': totalCourses,
      'solution': solution,
      'ridgeOffset': ridgeOffset,
      'underEaveBatten': underEaveBatten,
      'eaveBatten': eaveBatten,
      'firstBatten': firstBatten,
      'cutCourse': cutCourse,
      'gauge': gauge,
      'splitGauge': splitGauge,
      'warning': warning,
    };
  }

  factory VerticalCalculationResult.fromJson(Map<String, dynamic> json) {
    return VerticalCalculationResult(
      inputRafter: (json['inputRafter'] as num).toInt(),
      totalCourses: json['totalCourses'] as int,
      solution: json['solution'] as String,
      ridgeOffset: (json['ridgeOffset'] as num).toInt(),
      underEaveBatten: json['underEaveBatten'] != null
          ? (json['underEaveBatten'] as num).toInt()
          : null,
      eaveBatten: json['eaveBatten'] != null
          ? (json['eaveBatten'] as num).toInt()
          : null,
      firstBatten: (json['firstBatten'] as num).toInt(),
      cutCourse:
          json['cutCourse'] != null ? (json['cutCourse'] as num).toInt() : null,
      gauge: json['gauge'] as String,
      splitGauge: json['splitGauge'] as String?,
      warning: json['warning'] as String?,
    );
  }
}
