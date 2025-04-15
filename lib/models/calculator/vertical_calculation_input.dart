// Import MaterialType from tile_model.dart

class VerticalCalculationInput {
  final List<double> rafterHeights; // User-provided
  final double gutterOverhang; // User-provided
  final String useDryRidge; // User-provided

  VerticalCalculationInput({
    required this.rafterHeights,
    required this.gutterOverhang,
    required this.useDryRidge,
  });

  VerticalCalculationInput copyWith({
    List<double>? rafterHeights,
    double? gutterOverhang,
    String? useDryRidge,
  }) {
    return VerticalCalculationInput(
      rafterHeights: rafterHeights ?? this.rafterHeights,
      gutterOverhang: gutterOverhang ?? this.gutterOverhang,
      useDryRidge: useDryRidge ?? this.useDryRidge,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rafterHeights': rafterHeights,
      'gutterOverhang': gutterOverhang,
      'useDryRidge': useDryRidge,
    };
  }
}
