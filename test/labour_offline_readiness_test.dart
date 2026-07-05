import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_config_storage.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_storage.dart';

void main() {
  group('offline labour persistence', () {
    late Box<Map> configBox;
    late Box<Map> quotesBox;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('labour_offline_test_');
      Hive.init(tempDir.path);
      configBox = await Hive.openBox<Map>('test_labour_config_offline');
      quotesBox = await Hive.openBox<Map>('test_labour_quotes_offline');
      await configBox.clear();
      await quotesBox.clear();
    });

    tearDown(() async {
      if (configBox.isOpen) {
        await configBox.clear();
        await configBox.close();
      }
      if (quotesBox.isOpen) {
        await quotesBox.clear();
        await quotesBox.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('rates and quote config survive box reload without network', () async {
      final settings = LabourPersistedSettings(
        backendData: LabourDefaults.backendData2026,
        quoteConfig: const LabourQuoteConfig(
          gangSize: 4,
          travelMiles: 30,
          targetMarginPercent: 25,
        ),
      );

      await LabourConfigStorage.saveToBox(configBox, settings);
      final reloaded = LabourConfigStorage.loadFromBox(configBox);

      expect(reloaded.quoteConfig.gangSize, 4);
      expect(reloaded.quoteConfig.travelMiles, 30);
      expect(
        reloaded.backendData.global.directFullDayRatePerMan,
        LabourDefaults.globalConfig.directFullDayRatePerMan,
      );
    });

    test('saved quotes and rates load together from local Hive', () async {
      final settings = LabourPersistedSettings(
        backendData: LabourDefaults.backendData2026,
        quoteConfig: const LabourQuoteConfig(gangSize: 3),
      );
      final quote = LabourSavedQuote(
        id: 'quote-offline-1',
        name: 'Offline quote',
        savedAt: DateTime(2026, 4, 1),
        project: LabourQuoteProject.singleSection(
          input: const LabourQuoteInput(
            mode: LabourPricingMode.direct,
            roofType: LabourRoofType.plainTile,
            roofAreaSqm: 28,
          ),
        ).copyWith(customerName: 'Offline Customer'),
        quoteConfig: settings.quoteConfig,
      );

      await LabourConfigStorage.saveToBox(configBox, settings);
      await LabourQuotesStorage.saveToBox(quotesBox, [quote]);

      final loadedSettings = LabourConfigStorage.loadFromBox(configBox);
      final loadedQuotes = LabourQuotesStorage.loadFromBox(quotesBox);

      expect(loadedSettings.quoteConfig.gangSize, 3);
      expect(loadedQuotes, hasLength(1));
      expect(loadedQuotes.first.name, 'Offline quote');
      expect(loadedQuotes.first.project.customerName, 'Offline Customer');
      expect(loadedQuotes.first.quoteConfig.gangSize, 3);
    });
  });
}