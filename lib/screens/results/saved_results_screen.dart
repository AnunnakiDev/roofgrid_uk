import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';

import 'package:roofgrid_uk/app/auth/providers/permissions_provider.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';
import 'package:roofgrid_uk/utils/saved_result_dates.dart';

import 'package:roofgrid_uk/theme/app_color_schemes.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SavedResultsScreen extends ConsumerStatefulWidget {
  const SavedResultsScreen({super.key});

  @override
  ConsumerState<SavedResultsScreen> createState() => _SavedResultsScreenState();
}

class _SavedResultsScreenState extends ConsumerState<SavedResultsScreen> {
  String _searchQuery = '';
  bool _isOnline = true;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      setState(() {
        _isOnline = isOnlineFromResults(result);
      });
      if (_isOnline && ref.read(effectiveIsProProvider)) {
        final userId = ref.read(currentUserProvider).value?.id ?? '';
        if (userId.isNotEmpty) {
          ref.invalidate(savedResultsProvider(userId));
        }
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final online = await isDeviceOnline();
    if (!mounted) return;
    setState(() {
      _isOnline = online;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userAsync = ref.watch(currentUserProvider);

    // Early check for authentication state to prevent provider calls
    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/auth/login');
      });
      return const Scaffold(
        body: Center(child: Text('Please log in to access this feature')),
      );
    }

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('User not found. Please sign in again.')),
          );
        }

        final effectiveIsPro = ref.watch(effectiveIsProProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Jobs'),
          ),
          drawer: const MainDrawer(),
          body: effectiveIsPro
              ? Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(child: _buildResultsList(user)),
                  ],
                )
              : _buildFreeUserContent(),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Semantics(
        label: 'Search my jobs',
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search jobs by name or type',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    tooltip: 'Clear search',
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppColorSchemes.inputRadius),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildFreeUserContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'My Jobs',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade to Pro to save and manage calculation results.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/subscription'),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Upgrade to Pro'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(UserModel user) {
    final resultsAsync = ref.watch(savedResultsProvider(user.id));

    return resultsAsync.when(
      data: (results) {
        if (_isOnline) {
          final resultsBox = Hive.box<SavedResult>('resultsBox');
          for (var result in results) {
            resultsBox.put(result.id, result);
          }
        }
        if (!_isOnline) {
          final resultsBox = Hive.box<SavedResult>('resultsBox');
          results = resultsBox.values.toList();
        }

        final filteredResults = _searchQuery.isEmpty
            ? Future.value(results)
            : _isOnline
                ? ref
                    .read(resultsServiceProvider)
                    .searchResults(user.id, _searchQuery)
                : Future.value(_filterResultsLocally(results, _searchQuery));

        return FutureBuilder<List<SavedResult>>(
          future: filteredResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No jobs found.'));
            }

            final resultsList = snapshot.data!;

            return ListView.builder(
              itemCount: resultsList.length,
              itemBuilder: (context, index) {
                final result = resultsList[index];
                return _buildResultCard(result);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        final resultsBox = Hive.box<SavedResult>('resultsBox');
        final results = resultsBox.values.toList();
        if (results.isNotEmpty) {
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return _buildResultCard(result);
            },
          );
        }
        return Center(
          child: Text(
            'Error loading results: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
      },
    );
  }

  List<SavedResult> _filterResultsLocally(
    List<SavedResult> results,
    String query,
  ) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return results;
    return results.where((result) {
      final projectNameMatch =
          result.projectName.toLowerCase().contains(needle);
      final typeMatch = result.type.toString().toLowerCase().contains(needle);
      return projectNameMatch || typeMatch;
    }).toList();
  }

  Widget _buildResultCard(SavedResult result) {
    final canAccessLabour = ref.watch(canAccessLabourCalculatorProvider);
    final typeText = savedCalculationTypeLabel(result.type);
    final updatedLine =
        formatSavedUpdatedLine(result.createdAt, result.updatedAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(
          result.projectName,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.tile['name'] ?? 'Unknown tile'} · $typeText',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            if (savedResultSetoutSnippet(result).isNotEmpty)
              Text(
                savedResultSetoutSnippet(result),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              'Saved: ${formatSavedDate(result.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (updatedLine != null)
              Text(
                updatedLine,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Quote job ${result.projectName}',
              child: IconButton(
                icon: Icon(
                  canAccessLabour
                      ? Icons.request_quote_outlined
                      : Icons.lock_outline_rounded,
                ),
                onPressed: () => navigateToLabourCalculatorWithJob(
                  context,
                  result.id,
                  canAccessLabour: canAccessLabour,
                ),
                tooltip: canAccessLabour ? 'Quote this job' : 'Quote (add-on)',
              ),
            ),
            Semantics(
              label: 'Recalculate result ${result.projectName}',
              child: IconButton(
                icon: const Icon(Icons.calculate_outlined),
                onPressed: () {
                  context.push('/calculator', extra: result);
                },
                tooltip: 'Recalculate',
              ),
            ),
            Semantics(
              label: 'Visualize result ${result.projectName}',
              child: IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () {
                  context.push('/result-detail', extra: result);
                },
                tooltip: 'View',
              ),
            ),
            Semantics(
              label: 'Delete result ${result.projectName}',
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Theme.of(context).colorScheme.error,
                onPressed: () => _confirmDelete(result),
                tooltip: 'Delete',
              ),
            ),
          ],
        ),
        onTap: () {
          context.push('/result-detail', extra: result);
        },
      ),
    ).animate().fadeIn();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _confirmDelete(SavedResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Result'),
        content:
            Text('Are you sure you want to delete "${result.projectName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider).value;
              if (user != null) {
                try {
                  await ref
                      .read(resultsServiceProvider)
                      .deleteResult(user.id, result.id);
                  final resultsBox = Hive.box<SavedResult>('resultsBox');
                  await resultsBox.delete(result.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Result deleted')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting result: $e')),
                    );
                  }
                }
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
