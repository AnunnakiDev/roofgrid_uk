import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/navigation/app_shell.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/widgets/admin_access_guard.dart';
import 'package:roofgrid_uk/screens/admin/admin_dashboard_screen.dart';
import 'package:roofgrid_uk/screens/admin/admin_stats_screen.dart';
import 'package:roofgrid_uk/screens/admin/admin_tile_management_screen.dart';
import 'package:roofgrid_uk/screens/admin/user_management_screen.dart';
import 'package:roofgrid_uk/screens/auth/email_link_screen.dart';
import 'package:roofgrid_uk/screens/auth/forgot_password_screen.dart';
import 'package:roofgrid_uk/screens/auth/login_screen.dart';
import 'package:roofgrid_uk/screens/auth/register_screen.dart';
import 'package:roofgrid_uk/screens/calculator/calculator_screen.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/screens/calculator/tile_selector_screen.dart';
import 'package:roofgrid_uk/screens/home_screen.dart';
import 'package:roofgrid_uk/screens/profile_screen.dart';
import 'package:roofgrid_uk/screens/results/result_detail_screen.dart';
import 'package:roofgrid_uk/screens/results/saved_results_screen.dart';
import 'package:roofgrid_uk/screens/splash_screen.dart';
import 'package:roofgrid_uk/screens/subscription/cancel_page.dart';
import 'package:roofgrid_uk/screens/subscription/success_page.dart';
import 'package:roofgrid_uk/screens/subscription_screen.dart';
import 'package:roofgrid_uk/screens/support/contact_screen.dart';
import 'package:roofgrid_uk/screens/support/faq_screen.dart';
import 'package:roofgrid_uk/screens/support/legal_screen.dart';
import 'package:roofgrid_uk/screens/tile_management_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();

  var refreshScheduled = false;
  late final GoRouter router;

  void scheduleRefresh() {
    if (refreshScheduled) return;
    refreshScheduled = true;
    scheduleMicrotask(() {
      refreshScheduled = false;
      router.refresh();
    });
  }

  router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final isSplash = state.matchedLocation == '/splash';
      final location = state.matchedLocation;

      if (isSplash) {
        await ref.read(authProvider.notifier).applyRememberMePolicy();
        if (!ref.mounted) return null;
      }

      final currentUser = ref.read(currentUserProvider).value;
      final devMode = ref.read(developerModeProvider);
      final effectiveIsPro = resolveEffectiveIsPro(currentUser, devMode);
      final isAuthenticated = ref.read(authProvider).isAuthenticated;

      return resolveAppRedirect(
        location: location,
        isAuthenticated: isAuthenticated,
        effectiveIsPro: effectiveIsPro,
        currentUser: currentUser,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calculator',
                builder: (context, state) {
                  final savedResult = state.extra is SavedResult
                      ? state.extra as SavedResult
                      : null;
                  return CalculatorScreen(
                    savedResult: savedResult,
                    initialMode: savedResult == null
                        ? parseCalculatorModeQuery(
                            state.uri.queryParameters['mode'],
                          )
                        : null,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'tile-select',
                    builder: (context, state) => const TileSelectorScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/results',
                builder: (context, state) => const SavedResultsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tiles',
                builder: (context, state) => const TileManagementScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final tab =
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return ProfileScreen(initialTabIndex: tab);
        },
      ),
      GoRoute(
        path: '/result-detail',
        builder: (context, state) => ResultDetailScreen(
          result: state.extra as SavedResult,
        ),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
        routes: [
          GoRoute(
            path: 'success',
            builder: (context, state) => const SuccessPage(),
          ),
          GoRoute(
            path: 'cancel',
            builder: (context, state) => const CancelPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/email-link',
        builder: (context, state) => const EmailLinkScreen(),
      ),
      GoRoute(
        path: '/support/contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/support/faq',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/support/legal',
        builder: (context, state) => const LegalScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminAccessGuard(
          child: AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/stats',
        builder: (context, state) => const AdminAccessGuard(
          child: AdminStatsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/tiles',
        builder: (context, state) => AdminAccessGuard(
          child: AdminTileManagementScreen(
            initialTab: state.uri.queryParameters['tab'],
          ),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => AdminAccessGuard(
          child: UserManagementScreen(
            initialFilter: state.uri.queryParameters['filter'],
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );

  ref.listen(authProvider, (_, __) => scheduleRefresh());
  ref.listen(currentUserProvider, (_, __) => scheduleRefresh());
  ref.listen(developerModeProvider, (_, __) => scheduleRefresh());
  ref.onDispose(router.dispose);

  return router;
});