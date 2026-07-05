import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_category.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_price_entry.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/boq_suggestion_service.dart';

void main() {
  group('BoqSuggestionService', () {
    test('suggests tile quantity from roof area', () {
      const section = LabourRoofSection(
        id: 's1',
        label: 'Main',
        input: LabourQuoteInput(
          mode: LabourPricingMode.direct,
          roofType: LabourRoofType.traditionalPantile,
          roofAreaSqm: 40,
        ),
      );
      const priceList = [
        MaterialPriceEntry(
          id: 'tile-1',
          category: MaterialCategory.tilesSlates,
          description: 'Pantile red',
          unit: 'each',
          coveragePerUnit: 10,
          wastePercent: 10,
          unitPrice: 0.9,
        ),
      ];

      final lines = BoqSuggestionService.suggestForSection(
        section: section,
        priceList: priceList,
      );

      expect(lines, hasLength(1));
      expect(lines.first.description, 'Pantile red');
      expect(lines.first.suggestedQty, 440);
    });

    test('maps ridge lm entry to ridge linear quantity', () {
      final section = LabourRoofSection(
        id: 's1',
        label: 'Main',
        input: LabourQuoteInput(
          mode: LabourPricingMode.direct,
          roofType: LabourRoofType.traditionalPantile,
          roofAreaSqm: 30,
          linearMetres: {LabourLinearItem.ridge: 12},
        ),
      );
      const priceList = [
        MaterialPriceEntry(
          id: 'ridge-1',
          category: MaterialCategory.other,
          description: 'Dry ridge kit',
          unit: 'lm',
          coveragePerUnit: 1,
          unitPrice: 8.5,
        ),
      ];

      final lines = BoqSuggestionService.suggestForSection(
        section: section,
        priceList: priceList,
      );

      expect(lines, hasLength(1));
      expect(lines.first.suggestedQty, 12);
    });
  });
}