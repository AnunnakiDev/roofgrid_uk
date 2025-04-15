class HorizontalCalculationInput {
  final List<double> widths;
  final double tileCoverWidth;
  final double minSpacing;
  final double maxSpacing;
  final String useDryVerge; // 'YES' or 'NO'
  final String abutmentSide; // 'NONE', 'LEFT', 'RIGHT', or 'BOTH'
  final String useLHTile; // 'YES' or 'NO'
  final double lhTileWidth;
  final String crossBonded; // 'YES' or 'NO'

  const HorizontalCalculationInput({
    required this.widths,
    required this.tileCoverWidth,
    required this.minSpacing,
    required this.maxSpacing,
    required this.useDryVerge,
    required this.abutmentSide,
    required this.useLHTile,
    required this.lhTileWidth,
    required this.crossBonded,
  });

  Map<String, dynamic> toJson() {
    return {
      'widths': widths,
      'tileCoverWidth': tileCoverWidth,
      'minSpacing': minSpacing,
      'maxSpacing': maxSpacing,
      'useDryVerge': useDryVerge,
      'abutmentSide': abutmentSide,
      'useLHTile': useLHTile,
      'lhTileWidth': lhTileWidth,
      'crossBonded': crossBonded,
    };
  }
}
