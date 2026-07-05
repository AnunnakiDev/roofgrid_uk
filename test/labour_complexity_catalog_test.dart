import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_complexity_catalog.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_complexity_feature.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

void main() {
  group('LabourComplexityCatalog.isGroupVisibleForRoof', () {
    test('hides dormer group on flat roofs', () {
      expect(
        LabourComplexityCatalog.isGroupVisibleForRoof(
          LabourComplexityGroup.dormerSpecial,
          LabourRoofType.flatFelt,
        ),
        isFalse,
      );
    });

    test('shows dormer group on pitched roofs', () {
      expect(
        LabourComplexityCatalog.isGroupVisibleForRoof(
          LabourComplexityGroup.dormerSpecial,
          LabourRoofType.traditionalPantile,
        ),
        isTrue,
      );
    });

    test('hides flat details on pitched roofs', () {
      expect(
        LabourComplexityCatalog.isGroupVisibleForRoof(
          LabourComplexityGroup.flatDetails,
          LabourRoofType.plainTile,
        ),
        isFalse,
      );
    });

    test('shows flat details on flat roofs', () {
      expect(
        LabourComplexityCatalog.isGroupVisibleForRoof(
          LabourComplexityGroup.flatDetails,
          LabourRoofType.flatGrp,
        ),
        isTrue,
      );
    });
  });
}