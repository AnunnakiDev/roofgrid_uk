import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/services/horizontal_calculation_service.dart';
import 'package:roofgrid_uk/app/calculator/services/vertical_calculation_service.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_input.dart';
import 'package:roofgrid_uk/utils/calculator_input_visibility.dart';
import 'package:roofgrid_uk/utils/tile_calculation_profile.dart'
    show isRidgeOffsetInBounds, resolveHorizontalSetSize;
import 'support/golden_job_fixtures.dart';
import 'support/golden_job_validation.dart';

void main() {
  group('golden job fixtures', () {
    for (final fixture in kGoldenJobFixtures) {
      test('${fixture.id} vertical and horizontal site job', () async {
        final tile = tileModelFromGoldenFixture(fixture);
        final vertical = await VerticalCalculationService.calculateVertical(
          input: VerticalCalculationInput(
            rafterHeights: [kGoldenRafterHeightMm],
            gutterOverhang: kGoldenGutterOverhangMm,
            useDryRidge: 'NO',
          ),
          materialType: fixture.materialType,
          slateTileHeight: fixture.slateTileHeight,
          maxGauge: fixture.maxGauge,
          minGauge: fixture.minGauge,
        );
        final horizontal = HorizontalCalculationService.calculateHorizontal(
          HorizontalCalculationInput(
            widths: [kGoldenRoofWidthMm],
            tileCoverWidth: fixture.tileCoverWidth,
            minSpacing: fixture.minSpacing,
            maxSpacing: fixture.maxSpacing,
            lhTileWidth: fixture.tileCoverWidth,
            useDryVerge: 'NO',
            abutmentSide: 'NONE',
            useLHTile: 'NO',
            crossBonded: crossBondedFromTile(tile),
            materialType: fixture.materialType,
          ),
        );

        expect(vertical.solution, fixture.vertical.solution);
        expect(vertical.totalCourses, fixture.vertical.totalCourses);
        expect(vertical.gauge, fixture.vertical.gauge);
        expectValidVerticalGoldenResult(
          result: vertical,
          materialType: fixture.materialType,
          expectedEaveBatten: fixture.vertical.eaveBatten,
          expectedUnderEaveBatten: fixture.vertical.underEaveBatten,
          expectedRidgeOffset: fixture.vertical.ridgeOffset,
          assertRidgePlanningBounds: true,
        );

        expect(horizontal.solution, fixture.horizontal.solution);
        expect(horizontal.marks, fixture.horizontal.marks);
        expect(horizontal.firstMark, fixture.horizontal.firstMark);
        expect(horizontal.actualSpacing, fixture.horizontal.actualSpacing);
        expectHorizontalGoldenWidths(
          result: horizontal,
          expected: fixture.horizontal,
        );
        expectValidHorizontalGoldenResult(
          result: horizontal,
          defaultCrossBonded: fixture.defaultCrossBonded,
          expectedSecondMark: fixture.horizontal.secondMark,
        );
        expectHorizontalReconciles(
          input: HorizontalCalculationInput(
            widths: [kGoldenRoofWidthMm],
            tileCoverWidth: fixture.tileCoverWidth,
            minSpacing: fixture.minSpacing,
            maxSpacing: fixture.maxSpacing,
            lhTileWidth: fixture.tileCoverWidth,
            useDryVerge: 'NO',
            abutmentSide: 'NONE',
            useLHTile: 'NO',
            crossBonded: crossBondedFromTile(tile),
            materialType: fixture.materialType,
          ),
          result: horizontal,
        );

        final setSize = resolveHorizontalSetSize(
          materialType: fixture.materialType,
          tileCoverWidth: fixture.tileCoverWidth,
        );
        expect(horizontal.marks, contains('sets of $setSize'));
      });
    }

    test('plain tile mixed rafter heights stay within wet ridge bounds',
        () async {
      final fixture = kGoldenMultiRafterPlainTile;
      final result = await VerticalCalculationService.calculateVertical(
        input: VerticalCalculationInput(
          rafterHeights: fixture.rafterHeights.map((h) => h.toDouble()).toList(),
          gutterOverhang: kGoldenGutterOverhangMm,
          useDryRidge: 'NO',
        ),
        materialType: fixture.materialType,
        slateTileHeight: fixture.slateTileHeight,
        maxGauge: fixture.maxGauge,
        minGauge: fixture.minGauge,
      );

      expect(result.solution, fixture.solution);
      expect(result.rafterDetails, hasLength(fixture.ridgeOffsets.length));
      expect(
        result.rafterDetails!.map((detail) => detail.ridgeOffset).toList(),
        fixture.ridgeOffsets,
      );
      expect(
        result.rafterDetails!.every(
          (detail) => isRidgeOffsetInBounds(detail.ridgeOffset, 'NO'),
        ),
        isTrue,
      );
      expect(
        result.rafterDetails!.map((detail) => detail.ridgeOffset).toSet(),
        hasLength(greaterThan(1)),
      );
    });

    test('cross bonded interlocking tile uses set size 2 with second mark',
        () async {
      final fixture = kGoldenJobFixtures.firstWhere(
        (entry) => entry.id == 'interlocking-cross-bonded',
      );
      final tile = tileModelFromGoldenFixture(fixture);

      expect(tile.defaultCrossBonded, isTrue);
      expect(
        resolveHorizontalSetSize(
          materialType: fixture.materialType,
          tileCoverWidth: fixture.tileCoverWidth,
        ),
        2,
      );

      final horizontal = HorizontalCalculationService.calculateHorizontal(
        HorizontalCalculationInput(
          widths: [kGoldenRoofWidthMm],
          tileCoverWidth: fixture.tileCoverWidth,
          minSpacing: fixture.minSpacing,
          maxSpacing: fixture.maxSpacing,
          lhTileWidth: fixture.tileCoverWidth,
          useDryVerge: 'NO',
          abutmentSide: 'NONE',
          useLHTile: 'NO',
          crossBonded: crossBondedFromTile(tile),
          materialType: fixture.materialType,
        ),
      );

      expect(horizontal.marks, contains('sets of 2'));
      expectValidHorizontalGoldenResult(
        result: horizontal,
        defaultCrossBonded: true,
        expectedSecondMark: fixture.horizontal.secondMark,
      );
    });
  });
}