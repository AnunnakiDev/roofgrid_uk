import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_backend_migration.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';

void main() {
  group('LabourBackendMigration', () {
    test('migrates legacy rates json to backend data', () {
      final legacyJson = {
        'rates': LabourDefaults.starterRates.toJson(),
        'quoteConfig': {'gangSize': 2, 'targetMarginPercent': 20},
      };

      final backend = LabourBackendMigration.fromPersistedJson(legacyJson);

      expect(backend.rateSets.length, LabourRoofType.values.length);
      expect(
        backend.global.directFullDayRatePerMan,
        LabourDefaults.globalConfig.directFullDayRatePerMan,
      );
      expect(
        backend.rateSetFor(LabourRoofType.traditionalPantile).directMoney.stripPerSqm,
        greaterThan(0),
      );
    });

    test('maps legacy roof type names', () {
      expect(
        labourRoofTypeFromName('pantile'),
        LabourRoofType.traditionalPantile,
      );
      expect(
        labourRoofTypeFromName('slate'),
        LabourRoofType.naturalSlate,
      );
      expect(
        labourRoofTypeFromName('fibreCement'),
        LabourRoofType.modernInterlocking,
      );
    });
  });
}