class RafterCalculationDetail {
  final int rafterHeight;
  final int gauge;
  final int ridgeOffset;
  final int? gauge1;
  final int? gauge2;
  final int? cutCourse;

  const RafterCalculationDetail({
    required this.rafterHeight,
    required this.gauge,
    required this.ridgeOffset,
    this.gauge1,
    this.gauge2,
    this.cutCourse,
  });

  factory RafterCalculationDetail.fromJson(Map<String, dynamic> json) {
    return RafterCalculationDetail(
      rafterHeight: (json['rafterHeight'] as num).toInt(),
      gauge: json['gauge'] != null ? (json['gauge'] as num).toInt() : 0,
      ridgeOffset: (json['ridgeOffset'] as num).toInt(),
      gauge1: json['gauge1'] != null ? (json['gauge1'] as num).toInt() : null,
      gauge2: json['gauge2'] != null ? (json['gauge2'] as num).toInt() : null,
      cutCourse: json['cutCourse'] != null
          ? (json['cutCourse'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rafterHeight': rafterHeight,
      'gauge': gauge,
      'ridgeOffset': ridgeOffset,
      if (gauge1 != null) 'gauge1': gauge1,
      if (gauge2 != null) 'gauge2': gauge2,
      if (cutCourse != null) 'cutCourse': cutCourse,
    };
  }
}