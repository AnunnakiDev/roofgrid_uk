import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_sync_entry.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_quotes_analytics_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_quotes_firestore_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_analytics.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_storage.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_sync_queue_storage.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_sync_utils.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/services/hive_service.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';

enum LabourQuotesSyncStatus { synced, pending, offline }

@immutable
class LabourQuotesSyncUiState {
  final int pendingCount;
  final bool isFlushing;

  const LabourQuotesSyncUiState({
    this.pendingCount = 0,
    this.isFlushing = false,
  });

  LabourQuotesSyncUiState copyWith({
    int? pendingCount,
    bool? isFlushing,
  }) {
    return LabourQuotesSyncUiState(
      pendingCount: pendingCount ?? this.pendingCount,
      isFlushing: isFlushing ?? this.isFlushing,
    );
  }
}

class LabourQuotesSyncUiNotifier extends Notifier<LabourQuotesSyncUiState> {
  @override
  LabourQuotesSyncUiState build() => const LabourQuotesSyncUiState();
}

final labourQuotesSyncUiProvider =
    NotifierProvider<LabourQuotesSyncUiNotifier, LabourQuotesSyncUiState>(
  LabourQuotesSyncUiNotifier.new,
);

class LabourQuotesNotifier extends AsyncNotifier<List<LabourSavedQuote>> {
  bool _isFlushing = false;

  @override
  Future<List<LabourSavedQuote>> build() async {
    await _syncPendingCountFromBox();
    return _fetchAndMerge();
  }

  void _setSyncUi(LabourQuotesSyncUiState next) {
    ref.read(labourQuotesSyncUiProvider.notifier).state = next;
  }

  Future<void> _syncPendingCountFromBox() async {
    final box = await HiveService.ensureLabourQuotesBox();
    final count = LabourQuotesSyncQueueStorage.loadFromBox(box).length;
    _setSyncUi(
      ref.read(labourQuotesSyncUiProvider).copyWith(
            pendingCount: count,
            isFlushing: _isFlushing,
          ),
    );
  }

  Future<void> _enqueue(
    String quoteId,
    LabourQuoteSyncOperation operation,
  ) async {
    final box = await HiveService.ensureLabourQuotesBox();
    final queue = await LabourQuotesSyncQueueStorage.enqueue(
      box,
      LabourQuoteSyncEntry(
        quoteId: quoteId,
        operation: operation,
        queuedAt: DateTime.now(),
      ),
    );
    _setSyncUi(
      ref.read(labourQuotesSyncUiProvider).copyWith(pendingCount: queue.length),
    );
  }

  LabourQuotesAnalytics get _analytics =>
      ref.read(labourQuotesAnalyticsProvider);

  Future<void> _logSyncSuccess(String operation, String quoteId) {
    return _analytics.logSyncSuccess(operation: operation, quoteId: quoteId);
  }

  Future<void> _logSyncFailed(
    String operation,
    String quoteId, {
    String? reason,
  }) {
    return _analytics.logSyncFailed(
      operation: operation,
      quoteId: quoteId,
      reason: reason,
    );
  }

  Future<void> _dequeueSuccess() async {
    final box = await HiveService.ensureLabourQuotesBox();
    final queue = await LabourQuotesSyncQueueStorage.dequeueHead(box);
    _setSyncUi(
      ref.read(labourQuotesSyncUiProvider).copyWith(pendingCount: queue.length),
    );
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
          await LabourQuotesSyncQueueStorage.removeForQuote(box, quote.id);
          await _logSyncSuccess('save', quote.id);
        } catch (_) {
          await _enqueue(quote.id, LabourQuoteSyncOperation.save);
          await _logSyncFailed('save', quote.id, reason: 'merge_upload');
        }
      }
      await _syncPendingCountFromBox();

      return merged;
    } catch (_) {
      return local;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAndMerge);
    await flushPendingSync();
  }

  Future<void> flushPendingSync() async {
    if (_isFlushing) return;

    final userId = ref.read(currentUserProvider).value?.id;
    if (userId == null || userId.isEmpty) return;
    if (!await isDeviceOnline()) return;

    _isFlushing = true;
    _setSyncUi(ref.read(labourQuotesSyncUiProvider).copyWith(isFlushing: true));

    try {
      final box = await HiveService.ensureLabourQuotesBox();
      final firestore = ref.read(labourQuotesFirestoreServiceProvider);

      while (true) {
        final queue = LabourQuotesSyncQueueStorage.loadFromBox(box);
        if (queue.isEmpty) break;

        final entry = queue.first;
        final operation =
            entry.operation == LabourQuoteSyncOperation.save ? 'save' : 'delete';
        try {
          switch (entry.operation) {
            case LabourQuoteSyncOperation.save:
              final quotes = LabourQuotesStorage.loadFromBox(box);
              LabourSavedQuote? quote;
              for (final candidate in quotes) {
                if (candidate.id == entry.quoteId) {
                  quote = candidate;
                  break;
                }
              }
              if (quote != null) {
                await firestore.saveQuote(userId, quote);
              }
            case LabourQuoteSyncOperation.delete:
              await firestore.deleteQuote(userId, entry.quoteId);
          }
          await _dequeueSuccess();
          await _logSyncSuccess(operation, entry.quoteId);
        } catch (_) {
          await _logSyncFailed(operation, entry.quoteId, reason: 'flush');
          break;
        }
      }
    } finally {
      _isFlushing = false;
      await _syncPendingCountFromBox();
    }
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
        await LabourQuotesSyncQueueStorage.removeForQuote(box, quote.id);
        await _syncPendingCountFromBox();
        await _logSyncSuccess('save', quote.id);
      } catch (_) {
        await _enqueue(quote.id, LabourQuoteSyncOperation.save);
        await _logSyncFailed('save', quote.id, reason: 'queued');
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
        await LabourQuotesSyncQueueStorage.removeForQuote(box, id);
        await _syncPendingCountFromBox();
        await _logSyncSuccess('delete', id);
      } catch (_) {
        await _enqueue(id, LabourQuoteSyncOperation.delete);
        await _logSyncFailed('delete', id, reason: 'queued');
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