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
  });

  factory HorizontalCalculationResult.fromJson(Map<String, dynamic> json) {
    return HorizontalCalculationResult(
      width: json['Width'] as int,
      solution: json['Solution'] as String,
      newWidth: json['New Width'] as int,
      lhOverhang: json['LH Overhang'] as int?,
      rhOverhang: json['RH Overhang'] as int?,
      cutTile: json['Cut Tile'] as int?,
      firstMark: json['1st Mark'] as int,
      secondMark: json['2nd Mark'] as int?,
      marks: json['Marks'] as String,
      splitMarks: json['Split Marks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Width': width,
      'Solution': solution,
      'New Width': newWidth,
      if (lhOverhang != null) 'LH Overhang': lhOverhang,
      if (rhOverhang != null) 'RH Overhang': rhOverhang,
      if (cutTile != null) 'Cut Tile': cutTile,
      '1st Mark': firstMark,
      if (secondMark != null) '2nd Mark': secondMark,
      'Marks': marks,
      if (splitMarks != null) 'Split Marks': splitMarks,
    };
  }
}
