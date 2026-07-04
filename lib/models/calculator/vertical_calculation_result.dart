import 'rafter_calculation_detail.dart';

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
  final List<RafterCalculationDetail>? rafterDetails;

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
    this.rafterDetails,
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
    List<RafterCalculationDetail>? rafterDetails,
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
      rafterDetails: rafterDetails ?? this.rafterDetails,
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
      if (rafterDetails != null)
        'rafterDetails': rafterDetails!.map((d) => d.toJson()).toList(),
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
      firstBatten: json['firstBatten'] != null
          ? (json['firstBatten'] as num).toInt()
          : json['eaveBatten'] != null
              ? (json['eaveBatten'] as num).toInt()
              : 0,
      cutCourse:
          json['cutCourse'] != null ? (json['cutCourse'] as num).toInt() : null,
      gauge: json['gauge'] as String? ?? 'N/A',
      splitGauge: json['splitGauge'] as String?,
      warning: json['warning'] as String?,
      rafterDetails: (json['rafterDetails'] as List<dynamic>?)
          ?.map((item) =>
              RafterCalculationDetail.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
