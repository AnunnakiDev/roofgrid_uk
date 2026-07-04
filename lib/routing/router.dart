import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/navigation/app_shell.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/routing/deferred_screen.dart';
import 'package:roofgrid_uk/widgets/admin_access_guard.dart';
import 'package:roofgrid_uk/screens/auth/login_screen.dart';
import 'package:roofgrid_uk/screens/calculator/calculator_screen.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/screens/home_screen.dart';
import 'package:roofgrid_uk/screens/splash_screen.dart';

import '../screens/admin/admin_dashboard_screen.dart' deferred as admin_dashboard;
import '../screens/admin/admin_stats_screen.dart' deferred as admin_stats;
import '../screens/admin/admin_tile_management_screen.dart'
    deferred as admin_tile_management;
import '../screens/admin/user_management_screen.dart' deferred as admin_users;
import '../screens/auth/email_link_screen.dart' deferred as email_link;
import '../screens/auth/forgot_password_screen.dart' deferred as forgot_password;
import '../screens/auth/register_screen.dart' deferred as register;
import '../screens/calculator/tile_selector_screen.dart' deferred as tile_selector;
import '../screens/profile_screen.dart' deferred as profile;
import '../screens/results/result_detail_screen.dart' deferred as result_detail;
import '../screens/results/saved_results_screen.dart' deferred as saved_results;
import '../screens/subscription/cancel_page.dart' deferred as subscription_cancel;
import '../screens/subscription/success_page.dart' deferred as subscription_success;
import '../screens/subscription_screen.dart' deferred as subscription;
import '../screens/support/contact_screen.dart' deferred as support_contact;
import '../screens/support/faq_screen.dart' deferred as support_faq;
import '../screens/support/legal_screen.dart' deferred as support_legal;
import '../screens/tile_management_screen.dart' deferred as tile_management;

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
                    builder: (context, state) => DeferredScreen(
                      loadLibrary: tile_selector.loadLibrary,
                      builder: () => tile_selector.TileSelectorScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/results',
                builder: (context, state) => DeferredScreen(
                  loadLibrary: saved_results.loadLibrary,
                  builder: () => saved_results.SavedResultsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tiles',
                builder: (context, state) => DeferredScreen(
                  loadLibrary: tile_management.loadLibrary,
                  builder: () => tile_management.TileManagementScreen(),
                ),
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
          return DeferredScreen(
            loadLibrary: profile.loadLibrary,
            builder: () => profile.ProfileScreen(initialTabIndex: tab),
          );
        },
      ),
      GoRoute(
        path: '/result-detail',
        builder: (context, state) => DeferredScreen(
          loadLibrary: result_detail.loadLibrary,
          builder: () => result_detail.ResultDetailScreen(
            result: state.extra as SavedResult,
          ),
        ),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => DeferredScreen(
          loadLibrary: subscription.loadLibrary,
          builder: () => subscription.SubscriptionScreen(),
        ),
        routes: [
          GoRoute(
            path: 'success',
            builder: (context, state) => DeferredScreen(
              loadLibrary: subscription_success.loadLibrary,
              builder: () => subscription_success.SuccessPage(),
            ),
          ),
          GoRoute(
            path: 'cancel',
            builder: (context, state) => DeferredScreen(
              loadLibrary: subscription_cancel.loadLibrary,
              builder: () => subscription_cancel.CancelPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => DeferredScreen(
          loadLibrary: register.loadLibrary,
          builder: () => register.RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => DeferredScreen(
          loadLibrary: forgot_password.loadLibrary,
          builder: () => forgot_password.ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/email-link',
        builder: (context, state) => DeferredScreen(
          loadLibrary: email_link.loadLibrary,
          builder: () => email_link.EmailLinkScreen(),
        ),
      ),
      GoRoute(
        path: '/support/contact',
        builder: (context, state) => DeferredScreen(
          loadLibrary: support_contact.loadLibrary,
          builder: () => support_contact.ContactScreen(),
        ),
      ),
      GoRoute(
        path: '/support/faq',
        builder: (context, state) => DeferredScreen(
          loadLibrary: support_faq.loadLibrary,
          builder: () => support_faq.FaqScreen(),
        ),
      ),
      GoRoute(
        path: '/support/legal',
        builder: (context, state) => DeferredScreen(
          loadLibrary: support_legal.loadLibrary,
          builder: () => support_legal.LegalScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => DeferredScreen(
          loadLibrary: admin_dashboard.loadLibrary,
          builder: () => AdminAccessGuard(
            child: admin_dashboard.AdminDashboardScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/stats',
        builder: (context, state) => DeferredScreen(
          loadLibrary: admin_stats.loadLibrary,
          builder: () => AdminAccessGuard(
            child: admin_stats.AdminStatsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/tiles',
        builder: (context, state) => DeferredScreen(
          loadLibrary: admin_tile_management.loadLibrary,
          builder: () => AdminAccessGuard(
            child: admin_tile_management.AdminTileManagementScreen(
              initialTab: state.uri.queryParameters['tab'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => DeferredScreen(
          loadLibrary: admin_users.loadLibrary,
          builder: () => AdminAccessGuard(
            child: admin_users.UserManagementScreen(
              initialFilter: state.uri.queryParameters['filter'],
            ),
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