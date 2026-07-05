import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';

/// Pure merge/upload helpers for labour quote cloud sync.
class LabourQuotesSyncUtils {
  LabourQuotesSyncUtils._();

  /// Merges [local] and [remote] by id; newest [LabourSavedQuote.savedAt] wins.
  /// When timestamps tie, [remote] wins.
  static List<LabourSavedQuote> mergeQuotes(
    List<LabourSavedQuote> local,
    List<LabourSavedQuote> remote,
  ) {
    final byId = <String, LabourSavedQuote>{
      for (final quote in local) quote.id: quote,
    };
    for (final quote in remote) {
      final existing = byId[quote.id];
      if (existing == null || !existing.savedAt.isAfter(quote.savedAt)) {
        byId[quote.id] = quote;
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return merged;
  }

  /// Quotes that should be uploaded after a merge pull.
  static List<LabourSavedQuote> quotesNeedingUpload(
    List<LabourSavedQuote> local,
    List<LabourSavedQuote> remote,
  ) {
    final remoteById = {for (final quote in remote) quote.id: quote};
    final uploads = <LabourSavedQuote>[];
    for (final localQuote in local) {
      final remoteQuote = remoteById[localQuote.id];
      if (remoteQuote == null ||
          localQuote.savedAt.isAfter(remoteQuote.savedAt)) {
        uploads.add(localQuote);
      }
    }
    return uploads;
  }
}