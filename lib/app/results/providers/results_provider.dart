import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/services/results_service.dart';

// Provider for the results service
final resultsServiceProvider = Provider<ResultsService>((ref) {
  return ResultsService();
});

// Stream provider for saved results
final savedResultsProvider = StreamProvider<List<SavedResult>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final resultsService = ref.read(resultsServiceProvider);

  if (user == null) return Stream.value([]);
  return resultsService.getSavedResults(user.id);
});

// Provider for searching results
final searchResultsProvider =
    FutureProvider.family<List<SavedResult>, String>((ref, query) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final resultsService = ref.read(resultsServiceProvider);

  if (user == null) return [];
  return await resultsService.searchResults(user.id, query);
});

// Provider for the currently selected result
final selectedResultProvider = StateProvider<SavedResult?>((ref) => null);

// Provider for result export status
final exportStatusProvider =
    StateProvider<AsyncValue<String?>>((ref) => const AsyncValue.data(null));

// Provider for managing edited results
final editedResultProvider = StateProvider<SavedResult?>((ref) => null);

// Provider for comparing original and edited results
final isComparingResultsProvider = StateProvider<bool>((ref) => false);
