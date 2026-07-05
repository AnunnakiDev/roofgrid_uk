/// How a roof section sources its material lines.
enum SectionMaterialsMode {
  /// Use project-level default material lines.
  inheritProject,

  /// Section has its own material lines.
  sectionOverride,

  /// No materials on this section.
  none,
}

extension SectionMaterialsModeLabels on SectionMaterialsMode {
  String get label {
    switch (this) {
      case SectionMaterialsMode.inheritProject:
        return 'Use project materials';
      case SectionMaterialsMode.sectionOverride:
        return 'Section override';
      case SectionMaterialsMode.none:
        return 'No materials';
    }
  }
}