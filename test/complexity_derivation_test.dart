import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/complexity_measurement.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_complexity_feature.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/complexity_derivation.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_section_uplift.dart';

void main() {
  group('ComplexityDerivation', () {
    test('dormer derives cheek, top, and roof area', () {
      final feature = LabourComplexityFeature(
        type: LabourComplexityFeatureType.dormer,
        quantity: 1,
        instances: const [
          ComplexityMeasurement(
            widthM: 2,
            heightM: 1.5,
            projectionM: 1.2,
            pitchDegrees: 50,
          ),
        ],
      );

      final derived = ComplexityDerivation.derive([feature]);

      expect(derived.extraRoofAreaSqm, closeTo(2.4, 0.01));
      expect(
        derived.extraLinearMetres[LabourLinearItem.dormerCheek],
        closeTo(3, 0.01),
      );
      expect(
        derived.extraLinearMetres[LabourLinearItem.dormerTop],
        closeTo(2, 0.01),
      );
      expect(derived.extraHours, greaterThan(0));
    });

    test('two dormers accumulate derived quantities', () {
      final feature = LabourComplexityFeature(
        type: LabourComplexityFeatureType.dormer,
        quantity: 2,
        instances: const [
          ComplexityMeasurement(widthM: 2, heightM: 1.5, projectionM: 1),
          ComplexityMeasurement(widthM: 1.5, heightM: 1.2, projectionM: 0.8),
        ],
      );

      final derived = ComplexityDerivation.derive([feature]);

      expect(derived.extraRoofAreaSqm, closeTo(3.2, 0.01));
      expect(
        derived.extraLinearMetres[LabourLinearItem.dormerCheek],
        closeTo(5.4, 0.01),
      );
    });

    test('lead bay derives bay width linear metres', () {
      final feature = LabourComplexityFeature(
        type: LabourComplexityFeatureType.leadBay,
        quantity: 1,
        instances: const [ComplexityMeasurement(widthM: 1.8, heightM: 2)],
      );

      final derived = ComplexityDerivation.derive([feature]);

      expect(
        derived.extraLinearMetres[LabourLinearItem.leadBay],
        closeTo(1.8, 0.01),
      );
      expect(derived.extraHours, greaterThan(0));
    });

    test('chimney detail adds stepped flashing and chimney ancillary', () {
      final feature = LabourComplexityFeature(
        type: LabourComplexityFeatureType.chimneyDetail,
        quantity: 1,
        instances: const [ComplexityMeasurement(widthM: 0.6, heightM: 1.2)],
      );

      final derived = ComplexityDerivation.derive([feature]);

      expect(
        derived.extraLinearMetres[LabourLinearItem.steppedFlashing],
        closeTo(3.6, 0.01),
      );
      expect(derived.extraAncillaryCounts[LabourAncillary.chimney], 1);
    });

    test('flat upstand derives perimeter linear metres and hours', () {
      final feature = LabourComplexityFeature(
        type: LabourComplexityFeatureType.flatUpstand,
        quantity: 1,
        instances: const [
          ComplexityMeasurement(widthM: 2, heightM: 3, upstandHeightM: 0.15),
        ],
      );

      final derived = ComplexityDerivation.derive([feature]);

      expect(
        derived.extraLinearMetres[LabourLinearItem.flatUpstand],
        closeTo(10, 0.01),
      );
      expect(derived.extraHours, greaterThan(0));
    });
  });

  group('LabourSectionUplift', () {
    test('heritage and pitch bands stack', () {
      expect(
        LabourSectionUplift.totalUpliftPercent(
          pitchDegrees: 45,
          heritage: true,
          accessUpliftPercent: 5,
        ),
        25,
      );
    });

    test('low pitch has no pitch uplift', () {
      expect(
        LabourSectionUplift.pitchUpliftPercent(30),
        0,
      );
    });
  });
}