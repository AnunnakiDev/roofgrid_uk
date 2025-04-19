import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SavedResultsScreen extends ConsumerStatefulWidget {
  const SavedResultsScreen({super.key});

  @override
  ConsumerState<SavedResultsScreen> createState() => _SavedResultsScreenState();
}

class _SavedResultsScreenState extends ConsumerState<SavedResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    // Check connectivity on init
    _checkConnectivity();
    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline) {
        // Refresh results when going online
        ref.invalidate(savedResultsProvider);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteResult(String resultId, String userId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Result'),
        content: const Text('Are you sure you want to delete this result?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        final resultsBox = Hive.box<SavedResult>('resultsBox');
        if (_isOnline) {
          await ref.read(resultsServiceProvider).deleteResult(userId, resultId);
          await resultsBox.delete(resultId);
          print("Result $resultId deleted from Firestore and Hive");
        } else {
          // Mark for deletion when online
          await resultsBox.delete(resultId);
          print("Result $resultId deleted from Hive (offline)");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Result deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete result: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final resultsAsync = _isSearching
        ? ref.watch(searchResultsProvider(_searchController.text))
        : ref.watch(savedResultsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search results...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.invalidate(searchResultsProvider(value));
                },
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.invalidate(searchResultsProvider);
                }
              });
            },
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Semantics(
              label: 'Saved results description',
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.0,
                  ),
                ),
                child: const Text(
                  'View your saved calculations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(duration: 600.ms),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(savedResultsProvider);
              },
              child: resultsAsync.when(
                data: (results) {
                  final resultsBox = Hive.box<SavedResult>('resultsBox');

                  // Sync results to Hive if online
                  if (_isOnline) {
                    for (var result in results) {
                      resultsBox.put(result.id, result);
                    }
                    print("Synced ${results.length} results to Hive");
                  }

                  // Use Hive if offline
                  if (!_isOnline) {
                    results = resultsBox.values.toList();
                    print(
                        "Offline: Loaded ${results.length} results from Hive");
                  }

                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save_alt,
                            size: 80,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Saved Results',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Save your calculations to view them here.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text(
                            result.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${result.type.name.toUpperCase()} - ${result.createdAt.toLocal().toString().split('.')[0]}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                tooltip: 'Visualize',
                                onPressed: () {
                                  ref
                                      .read(selectedResultProvider.notifier)
                                      .state = result;
                                  context.push('/result-visualization');
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                tooltip: 'Delete',
                                onPressed: user != null
                                    ? () => _deleteResult(result.id, user.id)
                                    : null,
                              ),
                            ],
                          ),
                          onTap: () {
                            ref.read(selectedResultProvider.notifier).state =
                                result;
                            context.push('/result-detail');
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) {
                  // Fallback to Hive if Firestore fails
                  final resultsBox = Hive.box<SavedResult>('resultsBox');
                  final results = resultsBox.values.toList();
                  if (results.isNotEmpty) {
                    print(
                        "Error loading results from Firestore, using Hive: ${results.length} results");
                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(
                              result.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${result.type.name.toUpperCase()} - ${result.createdAt.toLocal().toString().split('.')[0]}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  tooltip: 'Visualize',
                                  onPressed: () {
                                    ref
                                        .read(selectedResultProvider.notifier)
                                        .state = result;
                                    context.push('/result-visualization');
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  tooltip: 'Delete',
                                  onPressed: user != null
                                      ? () => _deleteResult(result.id, user.id)
                                      : null,
                                ),
                              ],
                            ),
                            onTap: () {
                              ref.read(selectedResultProvider.notifier).state =
                                  result;
                              context.push('/result-detail');
                            },
                          ),
                        );
                      },
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error,
                          size: 80,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Results',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(savedResultsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
