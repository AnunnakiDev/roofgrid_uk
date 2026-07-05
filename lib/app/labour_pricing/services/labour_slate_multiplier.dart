import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_new_covering.dart';

/// Install-area multiplier for natural slate sizing (Method A + B).
class LabourSlateMultiplier {
  LabourSlateMultiplier._();

  static double installMultiplier({
    required LabourRoofType roofType,
    required SlateSizeOption slateSize,
  }) {
    if (roofType != LabourRoofType.naturalSlate) return 1.0;
    switch (slateSize) {
      case SlateSizeOption.largeFormat:
        return 1.05;
      case SlateSizeOption.randomCourtyard:
        return 1.10;
      case SlateSizeOption.standard:
      case SlateSizeOption.notApplicable:
        return 1.0;
    }
  }
}