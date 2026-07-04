import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/utils/tile_calculation_profile.dart';
import 'package:roofgrid_uk/utils/vertical_result_fields.dart';

void main() {
  group('visualization batten start logic', () {
    const plainResult = VerticalCalculationResult(
      inputRafter: 5000,
      totalCourses: 44,
      solution: 'Even Courses',
      ridgeOffset: 27,
      eaveBatten: 150,
      firstBatten: 200,
      gauge: '43 @ 111',
    );

    const concreteResult = VerticalCalculationResult(
      inputRafter: 4000,
      totalCourses: 12,
      solution: 'Even Courses',
      ridgeOffset: 77,
      eaveBatten: 345,
      firstBatten: 345,
      gauge: '11 @ 333',
    );

    test('plain tiles gauge starts at first gauge batten', () {
      expect(
        showsUnderEaveBattenForMaterial('Plain Tile'),
        isFalse,
      );
      expect(
        gaugeBattenStartMm(plainResult, materialType: 'Plain Tile'),
        plainResult.firstBatten,
      );
    });

    test('concrete tiles omit under-eave and start gauge at eave batten', () {
      expect(
        showsUnderEaveBattenForMaterial('Concrete Tile'),
        isFalse,
      );
      expect(
        shouldShowUnderEaveBatten(
          materialType: 'Concrete Tile',
          result: concreteResult,
        ),
        isFalse,
      );
      expect(shouldShowEaveBatten(concreteResult), isTrue);
      expect(
        gaugeBattenStartMm(concreteResult, materialType: 'Concrete Tile'),
        concreteResult.eaveBatten,
      );
      expect(concreteResult.firstBatten, concreteResult.eaveBatten);
    });
  });
}