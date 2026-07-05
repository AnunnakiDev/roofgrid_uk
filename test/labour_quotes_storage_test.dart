import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_storage.dart';

void main() {
  group('LabourSavedQuote', () {
    test('round-trips through json', () {
      final savedAt = DateTime(2026, 3, 15, 10, 30);
      final original = LabourSavedQuote(
        id: 'quote-1',
        name: 'Smith roof',
        savedAt: savedAt,
        project: LabourQuoteProject.singleSection(
          input: const LabourQuoteInput(
            mode: LabourPricingMode.direct,
            roofType: LabourRoofType.plainTile,
            roofAreaSqm: 42,
          ),
        ).copyWith(
          quoteRef: 'Q-100',
          customerName: 'Smith',
          siteAddress: '1 High Street',
        ),
        quoteConfig: const LabourQuoteConfig(
          gangSize: 3,
          travelMiles: 12,
        ),
        importedProjectName: 'Set-out job',
      );

      final restored = LabourSavedQuote.fromJson(original.toJson());

      expect(restored.id, 'quote-1');
      expect(restored.name, 'Smith roof');
      expect(restored.savedAt, savedAt);
      expect(restored.project.quoteRef, 'Q-100');
      expect(restored.project.sections.first.input.roofAreaSqm, 42);
      expect(restored.quoteConfig.gangSize, 3);
      expect(restored.importedProjectName, 'Set-out job');
    });
  });

  group('LabourQuotesStorage', () {
    late Box<Map> box;

    setUp(() async {
      Hive.init('labour_quotes_storage_test');
      box = await Hive.openBox<Map>('test_labour_quotes');
      await box.clear();
    });

    tearDown(() async {
      await box.clear();
      await box.close();
    });

    test('save and load round-trip preserves quotes', () async {
      final quote = LabourSavedQuote(
        id: 'quote-1',
        name: 'Bay roof',
        savedAt: DateTime(2026, 1, 2),
        project: LabourQuoteProject.singleSection(
          input: const LabourQuoteInput(
            mode: LabourPricingMode.direct,
            roofType: LabourRoofType.traditionalPantile,
            roofAreaSqm: 25,
          ),
        ),
        quoteConfig: const LabourQuoteConfig(),
      );

      await LabourQuotesStorage.saveToBox(box, [quote]);
      final loaded = LabourQuotesStorage.loadFromBox(box);

      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'quote-1');
      expect(loaded.first.name, 'Bay roof');
      expect(loaded.first.project.sections.first.input.roofAreaSqm, 25);
    });

    test('returns empty list when box is empty', () {
      expect(LabourQuotesStorage.loadFromBox(box), isEmpty);
    });
  });
}