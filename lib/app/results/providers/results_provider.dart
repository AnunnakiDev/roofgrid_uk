import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/services/results_service.dart';

// Service provider for managing results
final resultsServiceProvider = Provider<ResultsService>((ref) {
  return ResultsService();
});

// Provider to store the currently selected result
final selectedResultProvider = StateProvider<SavedResult?>((ref) => null);

// Provider for fetching saved results for a specific user
final savedResultsProvider =
    StreamProvider.family<List<SavedResult>, String>((ref, userId) {
  return ref.read(resultsServiceProvider).getSavedResults(userId);
});

// Add other result-related providers here as needed
