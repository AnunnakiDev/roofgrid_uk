import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_config_storage.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';

void main() {
  group('LabourPersistedSettings', () {
    test('defaults match starter backend data', () {
      final settings = LabourPersistedSettings.defaults();

      expect(
        settings.backendData.global.directFullDayRatePerMan,
        LabourDefaults.globalConfig.directFullDayRatePerMan,
      );
      expect(settings.quoteConfig.gangSize, 2);
      expect(settings.quoteConfig.targetMarginPercent, 20);
    });

    test('round-trips through json', () {
      final original = LabourPersistedSettings(
        backendData: LabourDefaults.backendData2026,
        quoteConfig: const LabourQuoteConfig(
          gangSize: 3,
          difficultyUpliftPercent: 10,
          travelMiles: 25,
          overnightNights: 2,
          targetMarginPercent: 30,
        ),
      );

      final restored = LabourPersistedSettings.fromJson(original.toJson());

      expect(
        restored.backendData.global.costPerMile,
        original.backendData.global.costPerMile,
      );
      expect(restored.quoteConfig.gangSize, 3);
      expect(restored.quoteConfig.difficultyUpliftPercent, 10);
      expect(restored.quoteConfig.travelMiles, 25);
      expect(restored.quoteConfig.overnightNights, 2);
      expect(restored.quoteConfig.targetMarginPercent, 30);
    });
  });
}