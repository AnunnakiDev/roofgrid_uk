/// Section-level uplift percentages for heritage, pitch, and access.
class LabourSectionUplift {
  LabourSectionUplift._();

  static const double heritagePercent = 10;

  static double pitchUpliftPercent(double pitchDegrees) {
    if (pitchDegrees <= 30) return 0;
    if (pitchDegrees <= 40) return 5;
    if (pitchDegrees <= 50) return 10;
    return 15;
  }

  static double totalUpliftPercent({
    required double pitchDegrees,
    required bool heritage,
    required double accessUpliftPercent,
  }) {
    final heritageUplift = heritage ? heritagePercent : 0.0;
    final pitchUplift = pitchUpliftPercent(pitchDegrees);
    return heritageUplift + pitchUplift + accessUpliftPercent.clamp(0, 50);
  }
}