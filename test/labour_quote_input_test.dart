import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

void main() {
  group('LabourQuoteInput.hasQuantities', () {
    const empty = LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.traditionalPantile,
      roofAreaSqm: 0,
    );

    test('false when all quantities are zero', () {
      expect(empty.hasQuantities, isFalse);
    });

    test('true when roof area is set', () {
      expect(empty.copyWith(roofAreaSqm: 25).hasQuantities, isTrue);
    });

    test('true when linear metres are set', () {
      expect(
        empty
            .copyWith(
              linearMetres: {LabourLinearItem.ridge: 8},
            )
            .hasQuantities,
        isTrue,
      );
    });

    test('preserves imported project name semantics via copyWith', () {
      final imported = empty.copyWith(roofAreaSqm: 30);
      expect(imported.roofAreaSqm, 30);
      expect(imported.hasQuantities, isTrue);
    });
  });
}