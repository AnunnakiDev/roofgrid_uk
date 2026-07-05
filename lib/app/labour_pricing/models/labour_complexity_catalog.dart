import 'package:roofgrid_uk/app/labour_pricing/models/labour_complexity_feature.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

/// Which measurement fields apply per complexity feature type.
enum ComplexityMeasurementField {
  width,
  height,
  pitch,
  upstandHeight,
  projection,
  notes,
}

class LabourComplexityCatalog {
  LabourComplexityCatalog._();

  static const Map<LabourComplexityGroup, List<LabourComplexityFeatureType>>
      typesByGroup = {
    LabourComplexityGroup.dormerSpecial: [
      LabourComplexityFeatureType.dormer,
    ],
    LabourComplexityGroup.leadWork: [
      LabourComplexityFeatureType.leadBay,
      LabourComplexityFeatureType.chimneyDetail,
      LabourComplexityFeatureType.abutmentDetail,
    ],
    LabourComplexityGroup.penetrations: [
      LabourComplexityFeatureType.skylight,
    ],
    LabourComplexityGroup.flatDetails: [
      LabourComplexityFeatureType.flatUpstand,
    ],
  };

  static const Map<LabourComplexityGroup, String> groupLabels = {
    LabourComplexityGroup.dormerSpecial: 'Dormer & special details',
    LabourComplexityGroup.leadWork: 'Lead work complexity',
    LabourComplexityGroup.penetrations: 'Penetrations',
    LabourComplexityGroup.flatDetails: 'Flat roof details',
  };

  static const Map<LabourComplexityFeatureType, List<ComplexityMeasurementField>>
      fieldsForType = {
    LabourComplexityFeatureType.dormer: [
      ComplexityMeasurementField.width,
      ComplexityMeasurementField.height,
      ComplexityMeasurementField.pitch,
      ComplexityMeasurementField.projection,
      ComplexityMeasurementField.notes,
    ],
    LabourComplexityFeatureType.leadBay: [
      ComplexityMeasurementField.width,
      ComplexityMeasurementField.height,
      ComplexityMeasurementField.notes,
    ],
    LabourComplexityFeatureType.chimneyDetail: [
      ComplexityMeasurementField.width,
      ComplexityMeasurementField.height,
      ComplexityMeasurementField.notes,
    ],
    LabourComplexityFeatureType.skylight: [
      ComplexityMeasurementField.width,
      ComplexityMeasurementField.height,
      ComplexityMeasurementField.notes,
    ],
    LabourComplexityFeatureType.flatUpstand: [
      ComplexityMeasurementField.width,
      ComplexityMeasurementField.height,
      ComplexityMeasurementField.upstandHeight,
      ComplexityMeasurementField.notes,
    ],
    LabourComplexityFeatureType.abutmentDetail: [
      ComplexityMeasurementField.width,
      ComplexityMeasurementField.height,
      ComplexityMeasurementField.upstandHeight,
      ComplexityMeasurementField.notes,
    ],
  };

  /// Flat roofs hide dormer groups; pitched roofs hide flat-only details.
  static bool isGroupVisibleForRoof(
    LabourComplexityGroup group,
    LabourRoofType roofType,
  ) {
    if (roofType.isFlat) {
      return group != LabourComplexityGroup.dormerSpecial;
    }
    return group != LabourComplexityGroup.flatDetails;
  }

  static String fieldLabel(ComplexityMeasurementField field) {
    switch (field) {
      case ComplexityMeasurementField.width:
        return 'Width (m)';
      case ComplexityMeasurementField.height:
        return 'Height (m)';
      case ComplexityMeasurementField.pitch:
        return 'Pitch (°)';
      case ComplexityMeasurementField.upstandHeight:
        return 'Upstand height (m)';
      case ComplexityMeasurementField.projection:
        return 'Projection (m)';
      case ComplexityMeasurementField.notes:
        return 'Notes';
    }
  }
}