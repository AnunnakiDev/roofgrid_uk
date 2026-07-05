import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/auth/providers/permissions_provider.dart';
import 'package:roofgrid_uk/app/organisation/providers/company_permissions_provider.dart';
import 'package:roofgrid_uk/widgets/organisation/installer_assignments_card.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/widgets/brand_wordmark.dart';

import 'package:roofgrid_uk/widgets/home_welcome_banner.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/quick_access_row.dart';
import 'package:roofgrid_uk/widgets/roof_grid_pattern.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _analytics = FirebaseAnalytics.instance;

  Future<void> _logAnalyticsEvent(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    try {
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

  void _openNewCalculation() {
    _logAnalyticsEvent('open_calculator');
    navigateToNewCalculation(context);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            RoofGridPattern(
              lineColor: onPrimary.withValues(alpha: 0.07),
              cellSize: 24,
            ),
          ],
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandWordmark.compact(
              color: onPrimary,
              fontSize: 20,
              letterSpacing: 2.5,
            ),
            const SizedBox(width: 6),
            Text(
              'UK',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: onPrimary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        actions: [
          userAsync.when(
            data: (user) => user == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: CircleAvatar(
                      radius: 15,
                      backgroundColor: onPrimary.withValues(alpha: 0.15),
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? Text(
                              _getInitials(user.displayName ?? 'U'),
                              style: TextStyle(
                                fontSize: 12,
                                color: onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    onPressed: () => context.go('/profile'),
                    tooltip: 'My Profile',
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: userAsync.when(
        data: (user) => _buildHomeContent(context, user, isLargeScreen),
        loading: () {
          final cachedUser = userAsync.value;
          if (cachedUser != null) {
            return _buildHomeContent(context, cachedUser, isLargeScreen);
          }
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading user data: $error',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return 'U';
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
  }

  Widget _buildHomeContent(
    BuildContext context,
    UserModel? user,
    bool isLargeScreen,
  ) {
    if (user == null) {
      return const Center(
        child: Text('User data not found. Please sign in again.'),
      );
    }

    final isPro = ref.watch(effectiveIsProProvider);
    final canAccessLabour = ref.watch(canAccessLabourCalculatorProvider);
    final isInstaller = ref.watch(isInstallerRoleProvider);
    final horizontalPadding = isLargeScreen ? 24.0 : 18.0;
    final sectionSpacing = isLargeScreen ? 36.0 : 28.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        20,
        horizontalPadding,
        sectionSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeWelcomeBanner(
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            isPro: isPro,
            onTap: () => context.go('/profile'),
          ),
          if (isInstaller) ...[
            const InstallerAssignmentsCard(),
            SizedBox(height: sectionSpacing),
          ],
          const SectionHeader(
            title: 'Roofing Calculator',
            subtitle: 'Select your tile, then choose vertical, horizontal, or combined set-out',
          ),
          const SizedBox(height: 18),
          Semantics(
            label: 'Start a new roofing calculation',
            button: true,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _openNewCalculation,
                child: Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 20 : 18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.roofing_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New calculation',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tile → set-out type → measurements → results',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!isInstaller) ...[
            SizedBox(height: sectionSpacing),
            const SectionHeader(
              title: 'Labour Pricing',
              subtitle: 'Quote profitable day rates from UK labour timings',
            ),
            const SizedBox(height: 18),
            Semantics(
              label: canAccessLabour
                  ? 'Open labour pricing calculator'
                  : 'Labour pricing calculator add-on required',
              button: true,
              child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  if (!canAccessLabour) {
                    showLabourGateSnackBar(context);
                  }
                  navigateToLabourCalculator(context);
                },
                child: Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 20 : 18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          canAccessLabour
                              ? Icons.calculate_rounded
                              : Icons.lock_outline_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              canAccessLabour
                                  ? 'Labour pricing calculator'
                                  : 'Labour pricing (add-on)',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              canAccessLabour
                                  ? 'Rates, gang size, margin → day rate quote'
                                  : 'Separate add-on — request access to unlock',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
            SizedBox(height: sectionSpacing),
          ],
          const SectionHeader(title: 'Quick Access'),
          const SizedBox(height: 16),
          QuickAccessRow(
            items: [
              QuickAccessItem(
                icon: Icons.save_alt_rounded,
                label: 'My Jobs',
                locked: !isPro,
                onTap: () {
                  if (!isPro) {
                    navigateToProSubscription(context);
                  } else {
                    _logAnalyticsEvent('view_results');
                    context.go('/results');
                  }
                },
              ),
              QuickAccessItem(
                icon: Icons.grid_view_rounded,
                label: 'Tiles',
                locked: !isPro,
                onTap: () {
                  if (!isPro) {
                    navigateToProSubscription(context);
                  } else {
                    _logAnalyticsEvent('manage_tiles');
                    context.go('/tiles');
                  }
                },
              ),
              QuickAccessItem(
                icon: Icons.help_outline_rounded,
                label: 'Support',
                onTap: () {
                  _logAnalyticsEvent('open_support');
                  context.go('/support/contact');
                },
              ),
              if (!isPro)
                QuickAccessItem(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Upgrade',
                  onTap: () => context.go('/subscription'),
                )
              else
                QuickAccessItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  onTap: () => context.go('/profile'),
                ),
            ],
          ),
          if (user.isAdmin) ...[
            SizedBox(height: sectionSpacing),
            ActionChip(
              avatar: Icon(
                Icons.admin_panel_settings_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.secondary,
              ),
              label: const Text('Admin Dashboard'),
              onPressed: () => context.go('/admin/dashboard'),
            ),
          ],
        ],
      ),
    );
  }
}