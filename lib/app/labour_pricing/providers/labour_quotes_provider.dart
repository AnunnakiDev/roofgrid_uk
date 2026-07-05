import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_quotes_firestore_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_storage.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_sync_utils.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/services/hive_service.dart';

class LabourQuotesNotifier extends AsyncNotifier<List<LabourSavedQuote>> {
  @override
  Future<List<LabourSavedQuote>> build() async {
    return _fetchAndMerge();
  }

  Future<List<LabourSavedQuote>> _fetchAndMerge() async {
    final box = await HiveService.ensureLabourQuotesBox();
    final local = LabourQuotesStorage.loadFromBox(box);
    final userId = ref.read(currentUserProvider).value?.id;
    if (userId == null || userId.isEmpty) return local;

    try {
      final firestore = ref.read(labourQuotesFirestoreServiceProvider);
      final remote = await firestore.fetchQuotes(userId);
      final merged = LabourQuotesSyncUtils.mergeQuotes(local, remote);
      await LabourQuotesStorage.saveToBox(box, merged);

      final uploads = LabourQuotesSyncUtils.quotesNeedingUpload(local, remote);
      for (final quote in uploads) {
        try {
          await firestore.saveQuote(userId, quote);
        } catch (_) {
          // Local-first: upload failures are retried on next refresh/save.
        }
      }

      return merged;
    } catch (_) {
      return local;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAndMerge);
  }

  Future<LabourSavedQuote?> saveQuote(LabourSavedQuote quote) async {
    final box = await HiveService.ensureLabourQuotesBox();
    final quotes = LabourQuotesStorage.loadFromBox(box);
    final next = [
      quote,
      ...quotes.where((existing) => existing.id != quote.id),
    ];
    await LabourQuotesStorage.saveToBox(box, next);
    state = AsyncData(next);

    final userId = ref.read(currentUserProvider).value?.id;
    if (userId != null && userId.isNotEmpty) {
      try {
        await ref
            .read(labourQuotesFirestoreServiceProvider)
            .saveQuote(userId, quote);
      } catch (_) {
        // Local-first: cloud backup is best-effort until Phase 2 queue.
      }
    }
    return quote;
  }

  Future<bool> deleteQuote(String id) async {
    final box = await HiveService.ensureLabourQuotesBox();
    final quotes = LabourQuotesStorage.loadFromBox(box);
    final next = quotes.where((quote) => quote.id != id).toList();
    if (next.length == quotes.length) return false;
    await LabourQuotesStorage.saveToBox(box, next);
    state = AsyncData(next);

    final userId = ref.read(currentUserProvider).value?.id;
    if (userId != null && userId.isNotEmpty) {
      try {
        await ref
            .read(labourQuotesFirestoreServiceProvider)
            .deleteQuote(userId, id);
      } catch (_) {
        // Local-first: cloud delete retried on next refresh.
      }
    }
    return true;
  }

  Future<LabourSavedQuote?> duplicateQuote(String id) async {
    final quotes = state.value ?? await future;
    final index = quotes.indexWhere((quote) => quote.id == id);
    if (index < 0) return null;
    final source = quotes[index];

    final duplicate = source.copyWith(
      id: 'quote_${DateTime.now().millisecondsSinceEpoch}',
      name: '${source.name} (copy)',
      savedAt: DateTime.now(),
      clearSourceJobId: true,
    );
    return saveQuote(duplicate);
  }
}

final labourQuotesProvider =
    AsyncNotifierProvider<LabourQuotesNotifier, List<LabourSavedQuote>>(
  LabourQuotesNotifier.new,
);