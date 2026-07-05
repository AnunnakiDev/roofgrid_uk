import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_sync_entry.dart';

const labourQuotesPendingSyncKey = 'pendingSync';

class LabourQuotesSyncQueueStorage {
  LabourQuotesSyncQueueStorage._();

  static List<LabourQuoteSyncEntry> loadFromBox(Box<Map> box) {
    final raw = box.get(labourQuotesPendingSyncKey);
    if (raw == null) return [];

    try {
      final list = raw['entries'] as List<dynamic>? ?? const [];
      return list
          .map(
            (entry) => LabourQuoteSyncEntry.fromJson(
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
    List<LabourQuoteSyncEntry> entries,
  ) async {
    await box.put(labourQuotesPendingSyncKey, {
      'entries': entries.map((entry) => entry.toJson()).toList(),
    });
  }

  /// Appends [entry], replacing any prior ops for the same [quoteId].
  static Future<List<LabourQuoteSyncEntry>> enqueue(
    Box<Map> box,
    LabourQuoteSyncEntry entry,
  ) async {
    final next = [
      ...loadFromBox(box).where((existing) => existing.quoteId != entry.quoteId),
      entry,
    ];
    await saveToBox(box, next);
    return next;
  }

  static Future<List<LabourQuoteSyncEntry>> dequeueHead(Box<Map> box) async {
    final queue = loadFromBox(box);
    if (queue.isEmpty) return queue;
    final next = queue.sublist(1);
    await saveToBox(box, next);
    return next;
  }

  static Future<List<LabourQuoteSyncEntry>> removeForQuote(
    Box<Map> box,
    String quoteId,
  ) async {
    final next =
        loadFromBox(box).where((entry) => entry.quoteId != quoteId).toList();
    await saveToBox(box, next);
    return next;
  }
}