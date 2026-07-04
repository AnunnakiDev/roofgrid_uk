import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/services/results_service.dart';

// Service provider for managing results
final resultsServiceProvider = Provider<ResultsService>((ref) {
  return ResultsService();
});

// Notifier to store the currently selected result (migrated for Riverpod 3)
class SelectedResultNotifier extends Notifier<SavedResult?> {
  @override
  SavedResult? build() => null;

  void set(SavedResult? value) => state = value;
}

final selectedResultProvider =
    NotifierProvider<SelectedResultNotifier, SavedResult?>(SelectedResultNotifier.new);

// Provider for fetching saved results for a specific user
final savedResultsProvider =
    StreamProvider.family<List<SavedResult>, String>((ref, userId) {
  return ref.read(resultsServiceProvider).getSavedResults(userId);
});

// Add other result-related providers here as needed
