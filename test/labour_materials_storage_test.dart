import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_material_line.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_category.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_price_entry.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_materials_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_materials_storage.dart';

void main() {
  group('MaterialPriceEntry', () {
    test('round-trips through json', () {
      const original = MaterialPriceEntry(
        id: 'mat-1',
        category: MaterialCategory.tilesSlates,
        description: 'Plain tile',
        unit: 'each',
        coveragePerUnit: 10,
        wastePercent: 8,
        unitPrice: 0.85,
        notes: 'Red',
      );

      final restored = MaterialPriceEntry.fromJson(original.toJson());

      expect(restored.id, 'mat-1');
      expect(restored.category, MaterialCategory.tilesSlates);
      expect(restored.description, 'Plain tile');
      expect(restored.coveragePerUnit, 10);
      expect(restored.wastePercent, 8);
      expect(restored.unitPrice, 0.85);
      expect(restored.notes, 'Red');
    });
  });

  group('LabourMaterialLine', () {
    test('effectiveQty prefers override over suggested', () {
      const line = LabourMaterialLine(
        description: 'Ridge tile',
        unit: 'each',
        suggestedQty: 40,
        overrideQty: 42,
        unitPrice: 2.5,
      );

      expect(line.effectiveQty, 42);
      expect(line.lineTotalGbp, 105);
    });

    test('effectiveQty falls back to suggested when override absent', () {
      const line = LabourMaterialLine(
        description: 'Underlay roll',
        unit: 'roll',
        suggestedQty: 3,
        unitPrice: 48,
      );

      expect(line.effectiveQty, 3);
      expect(line.lineTotalGbp, 144);
    });
  });

  group('LabourQuoteProject materials', () {
    test('materialLinesFor respects section materials mode', () {
      const projectLine = LabourMaterialLine(
        description: 'Project tile',
        unit: 'each',
        suggestedQty: 100,
        unitPrice: 1,
      );
      const sectionLine = LabourMaterialLine(
        description: 'Section tile',
        unit: 'each',
        suggestedQty: 50,
        unitPrice: 1,
      );
      final project = LabourQuoteProject(
        projectMaterialLines: const [projectLine],
        sections: [
          const LabourRoofSection(
            id: 'inherit',
            label: 'Inherit',
            input: LabourQuoteInput(
              mode: LabourPricingMode.direct,
              roofType: LabourRoofType.plainTile,
              roofAreaSqm: 30,
            ),
          ),
          LabourRoofSection(
            id: 'override',
            label: 'Override',
            input: const LabourQuoteInput(
              mode: LabourPricingMode.direct,
              roofType: LabourRoofType.plainTile,
              roofAreaSqm: 20,
            ),
            materialsMode: SectionMaterialsMode.sectionOverride,
            materialLines: const [sectionLine],
          ),
          const LabourRoofSection(
            id: 'none',
            label: 'None',
            input: LabourQuoteInput(
              mode: LabourPricingMode.direct,
              roofType: LabourRoofType.plainTile,
              roofAreaSqm: 10,
            ),
            materialsMode: SectionMaterialsMode.none,
          ),
        ],
      );

      expect(
        project.materialLinesFor(project.sections[0]),
        const [projectLine],
      );
      expect(
        project.materialLinesFor(project.sections[1]),
        const [sectionLine],
      );
      expect(project.materialLinesFor(project.sections[2]), isEmpty);
    });

    test('round-trips project and section material fields through json', () {
      final original = LabourQuoteProject.singleSection(
        input: const LabourQuoteInput(
          mode: LabourPricingMode.direct,
          roofType: LabourRoofType.plainTile,
          roofAreaSqm: 25,
        ),
      ).copyWith(
        projectMaterialLines: const [
          LabourMaterialLine(
            priceListEntryId: 'mat-1',
            description: 'Tile',
            unit: 'each',
            suggestedQty: 250,
            unitPrice: 0.9,
          ),
        ],
        sections: [
          LabourRoofSection(
            id: 'section-1',
            label: 'Main',
            input: const LabourQuoteInput(
              mode: LabourPricingMode.direct,
              roofType: LabourRoofType.plainTile,
              roofAreaSqm: 25,
            ),
            materialsMode: SectionMaterialsMode.sectionOverride,
            materialLines: const [
              LabourMaterialLine(
                description: 'Custom line',
                unit: 'lm',
                overrideQty: 12,
                unitPrice: 4.5,
              ),
            ],
          ),
        ],
      );

      final restored = LabourQuoteProject.fromJson(original.toJson());

      expect(restored.projectMaterialLines, hasLength(1));
      expect(restored.projectMaterialLines.first.suggestedQty, 250);
      expect(restored.sections.first.materialsMode,
          SectionMaterialsMode.sectionOverride);
      expect(restored.sections.first.materialLines.first.overrideQty, 12);
    });
  });

  group('LabourMaterialsStorage', () {
    late Box<Map> box;

    setUp(() async {
      Hive.init('labour_materials_storage_test');
      box = await Hive.openBox<Map>('test_labour_materials');
      await box.clear();
    });

    tearDown(() async {
      await box.clear();
      await box.close();
    });

    test('save and load round-trip preserves entries', () async {
      const entry = MaterialPriceEntry(
        id: 'mat-1',
        category: MaterialCategory.underlay,
        description: 'Breathable membrane',
        unit: 'roll',
        coveragePerUnit: 50,
        unitPrice: 72,
      );

      await LabourMaterialsStorage.saveToBox(box, [entry]);
      final loaded = LabourMaterialsStorage.loadFromBox(box);

      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'mat-1');
      expect(loaded.first.description, 'Breathable membrane');
      expect(loaded.first.unitPrice, 72);
    });

    test('returns empty list when box is empty', () {
      expect(LabourMaterialsStorage.loadFromBox(box), isEmpty);
    });
  });

  group('materialCategoryFromCsv', () {
    test('parses spec PascalCase values', () {
      expect(
        materialCategoryFromCsv('TilesSlates'),
        MaterialCategory.tilesSlates,
      );
      expect(
        materialCategoryFromCsv('LeadFlashings'),
        MaterialCategory.leadFlashings,
      );
      expect(materialCategoryFromCsv('unknown'), MaterialCategory.other);
    });
  });
}