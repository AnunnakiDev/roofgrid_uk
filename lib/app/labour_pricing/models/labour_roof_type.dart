enum LabourRoofType {
  modernInterlocking,
  traditionalPantile,
  plainTile,
  naturalSlate,
  shingles,
  flatFelt,
  flatGrp,
  flatLiquid,
  flatTraditionalLead,
  flatSinglePly,
}

extension LabourRoofTypeLabels on LabourRoofType {
  String get label {
    switch (this) {
      case LabourRoofType.modernInterlocking:
        return 'Modern interlocking tiles';
      case LabourRoofType.traditionalPantile:
        return 'Traditional pantiles';
      case LabourRoofType.plainTile:
        return 'Plain tiles';
      case LabourRoofType.naturalSlate:
        return 'Natural slate';
      case LabourRoofType.shingles:
        return 'Shingles';
      case LabourRoofType.flatFelt:
        return 'Flat — felt';
      case LabourRoofType.flatGrp:
        return 'Flat — GRP';
      case LabourRoofType.flatLiquid:
        return 'Flat — liquid';
      case LabourRoofType.flatTraditionalLead:
        return 'Flat — traditional lead';
      case LabourRoofType.flatSinglePly:
        return 'Flat — single ply';
    }
  }

  bool get isFlat {
    switch (this) {
      case LabourRoofType.flatFelt:
      case LabourRoofType.flatGrp:
      case LabourRoofType.flatLiquid:
      case LabourRoofType.flatTraditionalLead:
      case LabourRoofType.flatSinglePly:
        return true;
      default:
        return false;
    }
  }

  bool get isPitched => !isFlat;
}

/// Parses roof type names from JSON, including legacy v1 enum values.
LabourRoofType labourRoofTypeFromName(String name) {
  switch (name) {
    case 'pantile':
      return LabourRoofType.traditionalPantile;
    case 'fibreCement':
      return LabourRoofType.modernInterlocking;
    case 'slate':
      return LabourRoofType.naturalSlate;
    default:
      return LabourRoofType.values.byName(name);
  }
}