/// User-entered measurement and option values for calculator flows.
class VerticalInputs {
  final List<Map<String, dynamic>> rafterHeights;
  final double gutterOverhang;
  final String useDryRidge;

  const VerticalInputs({
    this.rafterHeights = const [],
    this.gutterOverhang = 50.0,
    this.useDryRidge = 'NO',
  });

  VerticalInputs copyWith({
    List<Map<String, dynamic>>? rafterHeights,
    double? gutterOverhang,
    String? useDryRidge,
  }) {
    return VerticalInputs(
      rafterHeights: rafterHeights ?? this.rafterHeights,
      gutterOverhang: gutterOverhang ?? this.gutterOverhang,
      useDryRidge: useDryRidge ?? this.useDryRidge,
    );
  }
}

class HorizontalInputs {
  final List<Map<String, dynamic>> widths;
  final String useDryVerge;
  final String abutmentSide;
  final String useLHTile;
  final String crossBonded;

  const HorizontalInputs({
    this.widths = const [],
    this.useDryVerge = 'NO',
    this.abutmentSide = 'NONE',
    this.useLHTile = 'NO',
    this.crossBonded = 'NO',
  });

  HorizontalInputs copyWith({
    List<Map<String, dynamic>>? widths,
    String? useDryVerge,
    String? abutmentSide,
    String? useLHTile,
    String? crossBonded,
  }) {
    return HorizontalInputs(
      widths: widths ?? this.widths,
      useDryVerge: useDryVerge ?? this.useDryVerge,
      abutmentSide: abutmentSide ?? this.abutmentSide,
      useLHTile: useLHTile ?? this.useLHTile,
      crossBonded: crossBonded ?? this.crossBonded,
    );
  }
}

List<double> rafterValuesFromEntries(List<Map<String, dynamic>> entries) {
  return entries.map((entry) => entry['value'] as double).toList();
}

List<double> widthValuesFromEntries(List<Map<String, dynamic>> entries) {
  return entries.map((entry) => entry['value'] as double).toList();
}