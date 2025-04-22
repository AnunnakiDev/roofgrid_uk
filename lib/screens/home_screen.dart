import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/theme_provider.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/profile_management_widget.dart';
import 'package:roofgrid_uk/widgets/profile_summary_widget.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _analytics = FirebaseAnalytics.instance;
  bool _isProfileExpanded = false;

  Future<void> _logAnalyticsEvent(String name,
      [Map<String, Object>? parameters]) async {
    try {
      // Ensure Firebase is initialized before logging
      await Firebase.initializeApp();
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Failed to log analytics event "$name": $e');
    }
  }

  Future<void> _signOut() async {
    await _logAnalyticsEvent('sign_out');
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    // Watch themeProvider to get the current theme mode
    final isDarkMode = ref.watch(themeProvider).themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RoofGrid UK',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            children: [
              Icon(
                isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                color: isDarkMode ? Colors.yellow[200] : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Semantics(
                label: 'Toggle theme to ${isDarkMode ? "light" : "dark"} mode',
                child: Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).toggleTheme(value);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.withOpacity(0.5),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _signOut,
                tooltip: 'Sign out',
              ),
            ],
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: userAsync.when(
        data: (user) => _buildHomeContent(context, user, isLargeScreen),
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
      bottomNavigationBar: Consumer(
        builder: (context, ref, child) {
          final user = ref.watch(currentUserProvider).value;
          return BottomNavigationBar(
            currentIndex: 0,
            onTap: (index) {
              if (index == 0) context.go('/home');
              if (index == 1) context.go('/calculator');
              if (index == 2) {
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calculate),
                label: 'Calculator',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.save),
                label: 'Results',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view),
                label: 'Tiles',
              ),
            ],
          );
        },
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
    required int index,
    bool isCalculator = false,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        constraints: BoxConstraints(
          minHeight: isCalculator ? 110 : 100,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: Padding(
          padding: isCalculator
              ? const EdgeInsets.all(16)
              : const EdgeInsets.all(12),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: enabled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      size: isCalculator ? 32 : 28,
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
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
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
                const SizedBox(height: 4),
                Text(
                  title,
                  style: isCalculator
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: isCalculator ? 13 : 12,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .slideY(
          begin: isCalculator ? 0.7 : 0.5,
          end: 0,
          duration: 400.ms,
          delay: (100 * index).ms,
          curve: Curves.easeOut,
        )
        .fadeIn(
          duration: 400.ms,
          delay: (100 * index).ms,
        )
        .scale(
          begin:
              isCalculator ? const Offset(0.85, 0.85) : const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOut,
        )
        .then()
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildHomeContent(
      BuildContext context, UserModel? user, bool isLargeScreen) {
    if (user == null) {
      return const Center(
        child: Text('User data not found. Please sign in again.'),
      );
    }

    final isPro = user.isPro;
    final sectionSpacing = isLargeScreen ? 32.0 : 24.0;
    final padding =
        isLargeScreen ? const EdgeInsets.all(24.0) : const EdgeInsets.all(12.0);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, child) {
              return Column(
                children: [
                  ProfileSummaryWidget(
                    user: user,
                    isExpanded: _isProfileExpanded,
                    onToggle: () {
                      setState(() {
                        _isProfileExpanded = !_isProfileExpanded;
                      });
                    },
                  ).animate().slideY(
                        begin: _isProfileExpanded ? -0.2 : 0.2,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                  if (_isProfileExpanded) ...[
                    SizedBox(height: sectionSpacing),
                    const ProfileManagementWidget().animate().fadeIn(
                          duration: 400.ms,
                          delay: 100.ms,
                        ),
                  ],
                ],
              );
            },
          ),
          SizedBox(height: sectionSpacing),
          Text(
            'Roofing Calculators',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Tap to calculate batten gauge',
                  child: _buildFeatureCard(
                    context,
                    title: 'Vertical',
                    subtitle: 'Batten Gauge',
                    icon: Icons.straighten,
                    index: 0,
                    onTap: () {
                      _logAnalyticsEvent(
                          'open_calculator', {'type': 'vertical'});
                      context.go('/calculator');
                    },
                    isCalculator: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Semantics(
                  label: 'Tap to calculate marking out',
                  child: _buildFeatureCard(
                    context,
                    title: 'Horizontal',
                    subtitle: 'Marking Out',
                    icon: Icons.auto_awesome_mosaic,
                    index: 1,
                    onTap: () {
                      _logAnalyticsEvent(
                          'open_calculator', {'type': 'horizontal'});
                      context.go('/calculator');
                    },
                    isCalculator: true,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sectionSpacing),
          Text(
            'Saved Results',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Tap to view saved calculations',
            child: _buildFeatureCard(
              context,
              title: 'Saved Calculations',
              subtitle: 'View and manage your saved results',
              icon: Icons.save_alt,
              index: 2,
              onTap: () {
                if (!isPro) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Upgrade to Pro to access this feature'),
                    ),
                  );
                  context.go('/subscription');
                } else {
                  _logAnalyticsEvent('view_results');
                  context.go('/results');
                }
              },
              isProFeature: true,
              enabled: isPro,
            ),
          ),
          SizedBox(height: sectionSpacing),
          Text(
            'Tile Management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Tap to manage tiles',
            child: _buildFeatureCard(
              context,
              title: 'Manage Tiles',
              subtitle: 'Create and edit tile profiles',
              icon: Icons.grid_view,
              index: 3,
              onTap: () {
                if (!isPro) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Upgrade to Pro to access this feature'),
                    ),
                  );
                  context.go('/subscription');
                } else {
                  _logAnalyticsEvent('manage_tiles');
                  context.go('/tiles');
                }
              },
              isProFeature: true,
              enabled: isPro,
            ),
          ),
          SizedBox(height: sectionSpacing),
          Text(
            'Help & Support',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Tap to get help and support',
            child: _buildFeatureCard(
              context,
              title: 'Support',
              subtitle: 'Get help and contact support',
              icon: Icons.help_outline,
              index: 4,
              onTap: () {
                _logAnalyticsEvent('open_support');
                context.go('/support/contact');
              },
            ),
          ),
          SizedBox(height: sectionSpacing),
        ],
      ),
    );
  }
}
