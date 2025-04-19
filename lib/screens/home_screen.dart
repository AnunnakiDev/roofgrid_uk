import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/profile_management_widget.dart';
import 'package:roofgrid_uk/widgets/profile_summary_widget.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _analytics = FirebaseAnalytics.instance;
  bool _isProfileExpanded = false;

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).signOut();
    await _analytics.logEvent(name: 'sign_out');
    if (mounted) {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RoofGrid UK'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: userAsync.when(
        data: (user) => _buildHomeContent(context, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading user data: $error',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Highlight Profile tab
        onTap: (index) {
          if (index == 0) context.go('/home'); // Profile
          if (index == 1) context.go('/calculator'); // Calculator
          if (index == 2) {
            // Results
            final user = ref.read(currentUserProvider).value;
            if (user?.isPro != true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Upgrade to Pro to access this feature'),
                ),
              );
              context.go('/subscription');
            } else {
              context.go('/results');
            }
          }
          if (index == 3) {
            // Tiles
            final user = ref.read(currentUserProvider).value;
            if (user?.isPro != true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Upgrade to Pro to access this feature'),
                ),
              );
              context.go('/subscription');
            } else {
              context.go('/tiles');
            }
          }
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.calculate), label: 'Calculator'),
          BottomNavigationBarItem(
            icon: Opacity(
              opacity: ref.watch(currentUserProvider).value?.isPro == true
                  ? 1.0
                  : 0.5,
              child: const Icon(Icons.save),
            ),
            label: 'Results',
          ),
          BottomNavigationBarItem(
            icon: Opacity(
              opacity: ref.watch(currentUserProvider).value?.isPro == true
                  ? 1.0
                  : 0.5,
              child: const Icon(Icons.grid_view),
            ),
            label: 'Tiles',
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return 'U';
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isProFeature = false,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: enabled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      size: 28,
                    ),
                    if (isProFeature) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: enabled
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRO',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                      if (!enabled)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.lock,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: enabled ? null : Colors.grey,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: enabled ? null : Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, UserModel? user) {
    if (user == null) {
      return const Center(
        child: Text('User data not found. Please sign in again.'),
      );
    }

    final isPro = user.isPro;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Home page description',
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
                'Welcome to RoofGrid UK',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(duration: 600.ms),
          ),
          const SizedBox(height: 24),
          ProfileSummaryWidget(
            user: user,
            isExpanded: _isProfileExpanded,
            onToggle: () {
              setState(() {
                _isProfileExpanded = !_isProfileExpanded;
              });
            },
          ),
          if (_isProfileExpanded) ...[
            const SizedBox(height: 16),
            const ProfileManagementWidget(),
          ],
          const SizedBox(height: 24),
          Text(
            'Roofing Calculators',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  context,
                  title: 'Vertical',
                  subtitle: 'Batten Gauge',
                  icon: Icons.straighten,
                  onTap: () {
                    _analytics.logEvent(
                        name: 'open_calculator',
                        parameters: {'type': 'vertical'});
                    context.go('/calculator');
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFeatureCard(
                  context,
                  title: 'Horizontal',
                  subtitle: 'Marking Out',
                  icon: Icons.auto_awesome_mosaic,
                  onTap: () {
                    _analytics.logEvent(
                        name: 'open_calculator',
                        parameters: {'type': 'horizontal'});
                    context.go('/calculator');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Results',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  if (!isPro) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Upgrade to Pro to access this feature'),
                      ),
                    );
                    context.go('/subscription');
                  } else {
                    _analytics.logEvent(name: 'view_results');
                    context.go('/results');
                  }
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Saved Calculations',
            subtitle: 'View and manage your saved results',
            icon: Icons.save_alt,
            onTap: () {
              if (!isPro) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upgrade to Pro to access this feature'),
                  ),
                );
                context.go('/subscription');
              } else {
                _analytics.logEvent(name: 'view_results');
                context.go('/results');
              }
            },
            isProFeature: true,
            enabled: isPro,
          ),
          const SizedBox(height: 24),
          Text(
            'Tile Management',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Manage Tiles',
            subtitle: 'Create and edit tile profiles',
            icon: Icons.grid_view,
            onTap: () {
              if (!isPro) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upgrade to Pro to access this feature'),
                  ),
                );
                context.go('/subscription');
              } else {
                _analytics.logEvent(name: 'manage_tiles');
                context.go('/tiles');
              }
            },
            isProFeature: true,
            enabled: isPro,
          ),
          const SizedBox(height: 24),
          Text(
            'Help & Support',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Support',
            subtitle: 'Get help and contact support',
            icon: Icons.help_outline,
            onTap: () {
              _analytics.logEvent(name: 'open_support');
              context.go('/support/contact');
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
