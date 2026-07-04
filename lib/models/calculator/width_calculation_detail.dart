class WidthCalculationDetail {
  final int inputWidth;
  final int totalWidth;
  final int? lhOverhang;
  final int? rhOverhang;
  final int firstMark;
  final int? secondMark;
  final int? cutTile;
  final int? actualSpacing;

  const WidthCalculationDetail({
    required this.inputWidth,
    required this.totalWidth,
    this.lhOverhang,
    this.rhOverhang,
    required this.firstMark,
    this.secondMark,
    this.cutTile,
    this.actualSpacing,
  });

  factory WidthCalculationDetail.fromJson(Map<String, dynamic> json) {
    return WidthCalculationDetail(
      inputWidth: (json['inputWidth'] as num?)?.toInt() ?? 0,
      totalWidth: (json['totalWidth'] as num).toInt(),
      lhOverhang: (json['lhOverhang'] as num?)?.toInt(),
      rhOverhang: (json['rhOverhang'] as num?)?.toInt(),
      firstMark: (json['firstMark'] as num).toInt(),
      secondMark: (json['secondMark'] as num?)?.toInt(),
      cutTile: (json['cutTile'] as num?)?.toInt(),
      actualSpacing: (json['actualSpacing'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inputWidth': inputWidth,
      'totalWidth': totalWidth,
      if (lhOverhang != null) 'lhOverhang': lhOverhang,
      if (rhOverhang != null) 'rhOverhang': rhOverhang,
      'firstMark': firstMark,
      if (secondMark != null) 'secondMark': secondMark,
      if (cutTile != null) 'cutTile': cutTile,
      if (actualSpacing != null) 'actualSpacing': actualSpacing,
    };
  }
}