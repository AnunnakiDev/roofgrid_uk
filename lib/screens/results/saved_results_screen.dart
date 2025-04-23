import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/bottom_nav_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline) {
        final userId = ref.read(currentUserProvider).value?.id ?? '';
        ref.invalidate(savedResultsProvider(userId));
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

        // Redirect free users to subscription screen
        if (!user.isPro) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Upgrade to Pro to access this feature'),
              ),
            );
            context.go('/subscription');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Saved Results'),
          ),
          drawer: const MainDrawer(),
          body: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _buildResultsList(user),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 3,
            onTap: (index) {
              if (index == 0) context.go('/home');
              if (index == 1) context.go('/home');
              if (index == 2) {
                if (user.isPro) {
                  context.go('/tiles');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Upgrade to Pro to access this feature'),
                    ),
                  );
                  context.go('/subscription');
                }
              }
              if (index == 3) {
                if (user.isPro) {
                  context.go('/results');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Upgrade to Pro to access this feature'),
                    ),
                  );
                  context.go('/subscription');
                }
              }
            },
            items: [
              const BottomNavItem(
                label: 'Home',
                icon: Icons.home,
                activeIcon: Icons.home_filled,
              ),
              const BottomNavItem(
                label: 'Profile',
                icon: Icons.person,
                activeIcon: Icons.person,
              ),
              BottomNavItem(
                label: 'Tiles',
                icon: Icons.grid_view,
                activeIcon: Icons.grid_view,
                tooltip:
                    user.isPro ? 'Tiles' : 'Upgrade to Pro to access tiles',
              ),
              BottomNavItem(
                label: 'Results',
                icon: Icons.save,
                activeIcon: Icons.save,
                tooltip: user.isPro
                    ? 'Saved Results'
                    : 'Upgrade to Pro to access saved results',
              ),
            ],
          ),
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
        label: 'Search saved results',
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by project name or type',
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
              borderRadius: BorderRadius.circular(30.0),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
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
            : ref
                .read(resultsServiceProvider)
                .searchResults(user.id, _searchQuery);

        return FutureBuilder<List<SavedResult>>(
          future: filteredResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No saved results found.'));
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

  Widget _buildResultCard(SavedResult result) {
    String typeText;
    switch (result.type) {
      case CalculationType.vertical:
        typeText = 'Vertical';
        break;
      case CalculationType.horizontal:
        typeText = 'Horizontal';
        break;
      case CalculationType.combined:
        typeText = 'Combined (Vert + Horiz)';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        title: Text(
          result.projectName,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Type: $typeText | Saved: ${_formatDateTime(result.createdAt)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Edit result ${result.projectName}',
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  context.push('/calculator', extra: result);
                },
                tooltip: 'Edit',
              ),
            ),
            Semantics(
              label: 'Visualize result ${result.projectName}',
              child: IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () {
                  context.push('/result-visualization', extra: result);
                },
                tooltip: 'Visualize',
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
