import 'package:roofgrid_uk/app/labour_pricing/models/complexity_derivation_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/complexity_measurement.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_complexity_feature.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';

/// Derives extra m², linear metres, ancillaries, and hours from measurements.
class ComplexityDerivation {
  ComplexityDerivation._();

  static ComplexityDerivationResult derive(
    Iterable<LabourComplexityFeature> features,
  ) {
    var result = const ComplexityDerivationResult();
    for (final feature in features) {
      if (feature.quantity <= 0) continue;
      for (final measurement in feature.instances) {
        result = result.merge(_deriveInstance(feature.type, measurement));
      }
    }
    return result;
  }

  static ComplexityDerivationResult _deriveInstance(
    LabourComplexityFeatureType type,
    ComplexityMeasurement measurement,
  ) {
    switch (type) {
      case LabourComplexityFeatureType.dormer:
        return _deriveDormer(measurement);
      case LabourComplexityFeatureType.leadBay:
        return _deriveLeadBay(measurement);
      case LabourComplexityFeatureType.chimneyDetail:
        return _deriveChimneyDetail(measurement);
      case LabourComplexityFeatureType.skylight:
        return _deriveSkylight(measurement);
      case LabourComplexityFeatureType.flatUpstand:
        return _deriveFlatUpstand(measurement);
      case LabourComplexityFeatureType.abutmentDetail:
        return _deriveAbutmentDetail(measurement);
    }
  }

  static ComplexityDerivationResult _deriveDormer(ComplexityMeasurement m) {
    if (m.widthM <= 0 && m.heightM <= 0 && m.projectionM <= 0) {
      return const ComplexityDerivationResult();
    }

    final cheekMetres = m.heightM > 0 ? m.heightM * 2 : 0.0;
    final topMetres = m.widthM;
    final dormerArea = m.widthM > 0 && m.projectionM > 0
        ? m.widthM * m.projectionM
        : 0.0;
    final pitchHours = m.pitchDegrees > 45 ? 1.5 : 0.0;

    return ComplexityDerivationResult(
      extraRoofAreaSqm: dormerArea,
      extraLinearMetres: {
        if (cheekMetres > 0) LabourLinearItem.dormerCheek: cheekMetres,
        if (topMetres > 0) LabourLinearItem.dormerTop: topMetres,
      },
      extraHours: pitchHours,
    );
  }

  static ComplexityDerivationResult _deriveLeadBay(ComplexityMeasurement m) {
    if (m.widthM <= 0 && m.heightM <= 0) {
      return const ComplexityDerivationResult();
    }

    return ComplexityDerivationResult(
      extraLinearMetres: {
        if (m.widthM > 0) LabourLinearItem.leadBay: m.widthM,
      },
      extraHours: m.heightM > 1.5 ? m.heightM * 0.75 : 0,
    );
  }

  static ComplexityDerivationResult _deriveChimneyDetail(
    ComplexityMeasurement m,
  ) {
    if (m.widthM <= 0 && m.heightM <= 0) {
      return const ComplexityDerivationResult();
    }

    final flashingMetres = _perimeter(m.widthM, m.heightM);
    return ComplexityDerivationResult(
      extraLinearMetres: {
        if (flashingMetres > 0) LabourLinearItem.steppedFlashing: flashingMetres,
      },
      extraAncillaryCounts: const {LabourAncillary.chimney: 1},
      extraHours: 2,
    );
  }

  static ComplexityDerivationResult _deriveSkylight(ComplexityMeasurement m) {
    final cuttingMetres = _perimeter(m.widthM, m.heightM);
    if (cuttingMetres <= 0) return const ComplexityDerivationResult();

    return ComplexityDerivationResult(
      extraLinearMetres: {LabourLinearItem.cutting: cuttingMetres},
      extraHours: 1.5,
    );
  }

  static ComplexityDerivationResult _deriveFlatUpstand(ComplexityMeasurement m) {
    final perimeter = _perimeter(m.widthM, m.heightM);
    if (perimeter <= 0 && m.upstandHeightM <= 0) {
      return const ComplexityDerivationResult();
    }

    return ComplexityDerivationResult(
      extraLinearMetres: {
        if (perimeter > 0) LabourLinearItem.flatUpstand: perimeter,
      },
      extraHours: m.upstandHeightM > 0 ? perimeter * m.upstandHeightM * 0.15 : 0,
    );
  }

  static ComplexityDerivationResult _deriveAbutmentDetail(
    ComplexityMeasurement m,
  ) {
    if (m.widthM <= 0 && m.heightM <= 0 && m.upstandHeightM <= 0) {
      return const ComplexityDerivationResult();
    }

    return ComplexityDerivationResult(
      extraLinearMetres: {
        if (m.widthM > 0) LabourLinearItem.abutment: m.widthM,
      },
      extraHours: m.upstandHeightM > 0.15 ? m.upstandHeightM * 2 : 0,
    );
  }

  static double _perimeter(double widthM, double heightM) {
    if (widthM <= 0 || heightM <= 0) return 0;
    return 2 * (widthM + heightM);
  }
}