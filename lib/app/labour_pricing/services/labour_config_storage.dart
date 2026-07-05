import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_backend_data.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_backend_migration.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';

const labourConfigStorageKey = 'labourConfig';

class LabourPersistedSettings {
  final LabourBackendData backendData;
  final LabourQuoteConfig quoteConfig;

  const LabourPersistedSettings({
    required this.backendData,
    required this.quoteConfig,
  });

  Map<String, dynamic> toJson() => {
        'backendData': backendData.toJson(),
        'quoteConfig': quoteConfig.toJson(),
      };

  factory LabourPersistedSettings.fromJson(Map<String, dynamic> json) {
    return LabourPersistedSettings(
      backendData: LabourBackendMigration.fromPersistedJson(json),
      quoteConfig: LabourQuoteConfig.fromJson(
        Map<String, dynamic>.from(json['quoteConfig'] as Map),
      ),
    );
  }

  static LabourPersistedSettings defaults() => LabourPersistedSettings(
        backendData: LabourDefaults.backendData2026,
        quoteConfig: const LabourQuoteConfig(),
      );
}

class LabourConfigStorage {
  LabourConfigStorage._();

  static LabourPersistedSettings loadFromBox(Box<Map> box) {
    final raw = box.get(labourConfigStorageKey);
    if (raw == null) return LabourPersistedSettings.defaults();

    try {
      return LabourPersistedSettings.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } catch (_) {
      return LabourPersistedSettings.defaults();
    }
  }

  static Future<void> saveToBox(
    Box<Map> box,
    LabourPersistedSettings settings,
  ) async {
    await box.put(labourConfigStorageKey, settings.toJson());
  }
}