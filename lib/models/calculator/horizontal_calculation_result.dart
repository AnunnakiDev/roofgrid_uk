class HorizontalCalculationResult {
  final int width;
  final String solution;
  final int newWidth;
  final int? lhOverhang;
  final int? rhOverhang;
  final int? cutTile;
  final int firstMark;
  final int? secondMark;
  final String marks;
  final String? splitMarks;
  final int? actualSpacing;
  final String? warning;

  const HorizontalCalculationResult({
    required this.width,
    required this.solution,
    required this.newWidth,
    this.lhOverhang,
    this.rhOverhang,
    this.cutTile,
    required this.firstMark,
    this.secondMark,
    required this.marks,
    this.splitMarks,
    this.actualSpacing,
    this.warning,
  });

  factory HorizontalCalculationResult.fromJson(Map<String, dynamic> json) {
    return HorizontalCalculationResult(
      width: (json['width'] as num?)?.toInt() ?? 0,
      solution: json['solution'] as String? ?? 'Invalid',
      newWidth: (json['newWidth'] as num?)?.toInt() ?? 0,
      lhOverhang: (json['lhOverhang'] as num?)?.toInt(),
      rhOverhang: (json['rhOverhang'] as num?)?.toInt(),
      cutTile: (json['cutTile'] as num?)?.toInt(),
      firstMark: (json['firstMark'] as num?)?.toInt() ?? 0,
      secondMark: (json['secondMark'] as num?)?.toInt(),
      marks: json['marks'] as String? ?? 'N/A',
      splitMarks: json['splitMarks'] as String?,
      actualSpacing: (json['actualSpacing'] as num?)?.toInt(),
      warning: json['warning'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'solution': solution,
      'newWidth': newWidth,
      if (lhOverhang != null) 'lhOverhang': lhOverhang,
      if (rhOverhang != null) 'rhOverhang': rhOverhang,
      if (cutTile != null) 'cutTile': cutTile,
      'firstMark': firstMark,
      if (secondMark != null) 'secondMark': secondMark,
      'marks': marks,
      if (splitMarks != null) 'splitMarks': splitMarks,
      if (actualSpacing != null) 'actualSpacing': actualSpacing,
      if (warning != null) 'warning': warning,
    };
  }
}
