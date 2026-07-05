import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_category.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_price_entry.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_materials_storage.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/material_csv_service.dart';

void main() {
  group('material CSV merge logic', () {
    test('updates existing entry when category and description match', () {
      const existing = MaterialPriceEntry(
        id: 'keep-id',
        category: MaterialCategory.tilesSlates,
        description: 'Plain tile',
        unit: 'each',
        coveragePerUnit: 10,
        unitPrice: 0.8,
      );

      final csv = MaterialCsvService.exportCsv([
        existing.copyWith(unitPrice: 0.95, wastePercent: 9),
      ]);
      final parsed = MaterialCsvService.parseImport(csv, idPrefix: 'import');

      final merged = <MaterialPriceEntry>[existing];
      for (final row in parsed.entries) {
        final index =
            merged.indexWhere((entry) => entry.matchKey == row.matchKey);
        if (index >= 0) {
          merged[index] = row.copyWith(id: merged[index].id);
        } else {
          merged.add(row);
        }
      }

      expect(merged, hasLength(1));
      expect(merged.first.id, 'keep-id');
      expect(merged.first.unitPrice, 0.95);
      expect(merged.first.wastePercent, 9);
    });
  });

  group('LabourMaterialsStorage with CSV data', () {
    late Box<Map> box;

    setUp(() async {
      Hive.init('labour_materials_provider_test');
      box = await Hive.openBox<Map>('test_materials_csv_box');
      await box.clear();
    });

    tearDown(() async {
      await box.clear();
      await box.close();
    });

    test('persisted entries reload after CSV-style save', () async {
      final parsed = MaterialCsvService.parseImport(
        '''
Category,Description,Unit,CoveragePerUnit,UnitPrice
FlatRoof,GRP resin,kg,2.5,42
''',
        idPrefix: 'csv',
      );

      await LabourMaterialsStorage.saveToBox(box, parsed.entries);
      final loaded = LabourMaterialsStorage.loadFromBox(box);

      expect(loaded, hasLength(1));
      expect(loaded.first.category, MaterialCategory.flatRoof);
      expect(loaded.first.unitPrice, 42);
    });
  });
}