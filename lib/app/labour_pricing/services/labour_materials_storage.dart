import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_price_entry.dart';

const labourMaterialsStorageKey = 'materialPriceList';

class LabourMaterialsStorage {
  LabourMaterialsStorage._();

  static List<MaterialPriceEntry> loadFromBox(Box<Map> box) {
    final raw = box.get(labourMaterialsStorageKey);
    if (raw == null) return [];

    try {
      final list = raw['entries'] as List<dynamic>? ?? const [];
      return list
          .map(
            (entry) => MaterialPriceEntry.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveToBox(
    Box<Map> box,
    List<MaterialPriceEntry> entries,
  ) async {
    await box.put(labourMaterialsStorageKey, {
      'entries': entries.map((entry) => entry.toJson()).toList(),
    });
  }
}