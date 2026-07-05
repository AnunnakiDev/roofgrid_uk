import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_storage.dart';
import 'package:roofgrid_uk/services/hive_service.dart';

class LabourQuotesNotifier extends AsyncNotifier<List<LabourSavedQuote>> {
  @override
  Future<List<LabourSavedQuote>> build() async {
    final box = await HiveService.ensureLabourQuotesBox();
    return LabourQuotesStorage.loadFromBox(box);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final box = await HiveService.ensureLabourQuotesBox();
      return LabourQuotesStorage.loadFromBox(box);
    });
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
    return quote;
  }

  Future<bool> deleteQuote(String id) async {
    final box = await HiveService.ensureLabourQuotesBox();
    final quotes = LabourQuotesStorage.loadFromBox(box);
    final next = quotes.where((quote) => quote.id != id).toList();
    if (next.length == quotes.length) return false;
    await LabourQuotesStorage.saveToBox(box, next);
    state = AsyncData(next);
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
    );
    return saveQuote(duplicate);
  }
}

final labourQuotesProvider =
    AsyncNotifierProvider<LabourQuotesNotifier, List<LabourSavedQuote>>(
  LabourQuotesNotifier.new,
);