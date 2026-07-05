import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_category.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_price_entry.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/material_csv_service.dart';

void main() {
  group('MaterialCsvService', () {
    const sampleCsv = '''
Category,Description,Unit,CoveragePerUnit,WastePercent,UnitPrice,Notes
TilesSlates,Plain tile,each,10,8,0.85,Red
Underlay,Breathable membrane,roll,50,,72,Supplier A
''';

    test('parseImport reads required columns and default waste', () {
      final result = MaterialCsvService.parseImport(
        sampleCsv,
        idPrefix: 'csv',
      );

      expect(result.errors, isEmpty);
      expect(result.entries, hasLength(2));
      expect(result.entries[0].category, MaterialCategory.tilesSlates);
      expect(result.entries[0].description, 'Plain tile');
      expect(result.entries[0].wastePercent, 8);
      expect(result.entries[1].wastePercent, defaultMaterialWastePercent);
      expect(result.entries[1].unitPrice, 72);
    });

    test('exportCsv produces spec headers and round-trips values', () {
      const entries = [
        MaterialPriceEntry(
          id: 'm1',
          category: MaterialCategory.leadFlashings,
          description: 'Code 4 lead',
          unit: 'lm',
          coveragePerUnit: 3,
          unitPrice: 18.5,
          notes: 'Roll',
        ),
      ];

      final csv = MaterialCsvService.exportCsv(entries);
      final parsed = MaterialCsvService.parseImport(csv, idPrefix: 'roundtrip');

      expect(parsed.errors, isEmpty);
      expect(parsed.entries, hasLength(1));
      expect(parsed.entries.first.category, MaterialCategory.leadFlashings);
      expect(parsed.entries.first.description, 'Code 4 lead');
      expect(parsed.entries.first.coveragePerUnit, 3);
      expect(parsed.entries.first.unitPrice, 18.5);
      expect(parsed.entries.first.notes, 'Roll');
    });

    test('parseImport reports missing headers', () {
      final result = MaterialCsvService.parseImport(
        'Description,Unit\nTile,each',
        idPrefix: 'csv',
      );

      expect(result.entries, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('parseImport captures row-level validation errors', () {
      final result = MaterialCsvService.parseImport(
        '''
Category,Description,Unit,CoveragePerUnit,UnitPrice
TilesSlates,,each,10,1.20
TilesSlates,Valid tile,each,not-a-number,1.20
TilesSlates,Valid tile,each,10,1.20
''',
        idPrefix: 'csv',
      );

      expect(result.entries, hasLength(1));
      expect(result.entries.first.description, 'Valid tile');
      expect(result.errors.length, greaterThanOrEqualTo(2));
    });
  });
}