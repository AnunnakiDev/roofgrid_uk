import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_catalog.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

void main() {
  group('LabourLinearCatalog', () {
    test('every linear item belongs to a group', () {
      for (final item in LabourLinearItem.values) {
        expect(LabourLinearCatalog.groupForItem(item), isNotNull);
      }
    });

    test('flat roof hides pitched-only groups', () {
      final groups = LabourLinearCatalog.groupsForRoofType(LabourRoofType.flatFelt);
      expect(groups, contains(LabourLinearGroup.flatRoofDetails));
      expect(groups, isNot(contains(LabourLinearGroup.ridgeHip)));
    });

    test('pitched roof hides flat-only group', () {
      final groups =
          LabourLinearCatalog.groupsForRoofType(LabourRoofType.traditionalPantile);
      expect(groups, contains(LabourLinearGroup.leadWork));
      expect(groups, isNot(contains(LabourLinearGroup.flatRoofDetails)));
    });

    test('visibleGroups always returns all eight groups', () {
      expect(LabourLinearCatalog.visibleGroups().length, 8);
    });

    test('lead work group is always enabled', () {
      expect(
        LabourLinearCatalog.isGroupEnabled(
          LabourLinearGroup.leadWork,
          LabourRoofType.flatFelt,
        ),
        isTrue,
      );
      expect(
        LabourLinearCatalog.isGroupEnabled(
          LabourLinearGroup.flatRoofDetails,
          LabourRoofType.traditionalPantile,
        ),
        isFalse,
      );
    });
  });
}