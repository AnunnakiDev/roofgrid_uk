import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';

const labourQuotesStorageKey = 'labourQuotes';

class LabourQuotesStorage {
  LabourQuotesStorage._();

  static List<LabourSavedQuote> loadFromBox(Box<Map> box) {
    final raw = box.get(labourQuotesStorageKey);
    if (raw == null) return [];

    try {
      final list = raw['quotes'] as List<dynamic>? ?? const [];
      final quotes = list
          .map(
            (entry) => LabourSavedQuote.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();
      quotes.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return quotes;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveToBox(
    Box<Map> box,
    List<LabourSavedQuote> quotes,
  ) async {
    await box.put(labourQuotesStorageKey, {
      'quotes': quotes.map((quote) => quote.toJson()).toList(),
    });
  }
}