import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/screens/auth/login_screen.dart';
import 'package:roofgrid_uk/screens/auth/forgot_password_screen.dart';
import 'package:roofgrid_uk/screens/auth/register_screen.dart';
import 'package:roofgrid_uk/screens/calculator/calculator_screen.dart';
import 'package:roofgrid_uk/screens/home_screen.dart';
import 'package:roofgrid_uk/screens/splash_screen.dart';
import 'package:roofgrid_uk/screens/admin/admin_dashboard_screen.dart';
import 'package:roofgrid_uk/screens/admin/admin_stats_screen.dart';
import 'package:roofgrid_uk/screens/admin/user_management_screen.dart';
import 'package:roofgrid_uk/screens/admin/admin_tile_management_screen.dart';
import 'package:roofgrid_uk/screens/support/faq_screen.dart';
import 'package:roofgrid_uk/screens/support/legal_screen.dart';
import 'package:roofgrid_uk/screens/support/contact_screen.dart';
import 'package:roofgrid_uk/screens/subscription_screen.dart';
import 'package:roofgrid_uk/screens/saved_results_screen.dart';
import 'package:roofgrid_uk/screens/tile_management_screen.dart';
import 'package:roofgrid_uk/screens/calculator/tile_selector_screen.dart';
import 'package:roofgrid_uk/screens/subscription/success_page.dart';
import 'package:roofgrid_uk/screens/subscription/cancel_page.dart';
import 'package:roofgrid_uk/widgets/add_tile_widget.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Global key to access the navigator state
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  bool isRedirecting = false; // Guard against redirect loops

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/loading',
    redirect: (context, state) async {
      if (isRedirecting) {
        print("Redirect loop detected, aborting redirect");
        return null;
      }
      isRedirecting = true;

      try {
        final isGoingToAuth = state.uri.path.startsWith('/auth');
        final isLoading = state.uri.path == '/loading';
        final isSplash = state.uri.path == '/splash';
        final isSupport = state.uri.path.startsWith('/support');
        final isSubscriptionRedirect =
            state.uri.path.startsWith('/subscription') &&
                state.uri.path != '/subscription';

        // Use ref.read instead of ref.watch to avoid rebuilding the router on auth state changes
        final authState = ref.read(authProvider);
        print(
            "Router redirect: matchedLocation=${state.uri.path}, authState.isAuthenticated=${authState.isAuthenticated}");

        if (isLoading) {
          print("Staying on loading screen");
          return null;
        }

        if (isSplash) {
          print("Redirecting from splash to loading");
          return '/loading';
        }

        if (isSupport) {
          print("Allowing access to support page: ${state.uri.path}");
          return null; // Allow access to support pages for all users
        }

        if (isSubscriptionRedirect) {
          print(
              "Allowing access to subscription redirect pages: ${state.uri.path}");
          return null; // Allow access to /subscription/success and /subscription/cancel
        }

        // Use authProvider state for redirect decisions
        final isLoggedIn = authState.isAuthenticated;

        if (!isLoggedIn && !isGoingToAuth) {
          print("Redirecting to /auth/login because user is not logged in");
          return '/auth/login';
        }

        if (isLoggedIn && isGoingToAuth) {
          print("Redirecting to /home because user is logged in");
          return '/home';
        }

        try {
          await FirebaseAnalytics.instance.logScreenView(
            screenName: state.uri.path,
          );
        } catch (e) {
          print("Error logging screen view: $e");
        }

        return null;
      } finally {
        isRedirecting = false;
      }
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) {
          // Use ref here since ProviderScope is available
          final ref = ProviderScope.containerOf(context);
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              final user = ref.read(currentUserProvider).value;
              if (user != null && user.role == UserRole.admin) {
                print("Redirecting to /admin for admin user");
                GoRouter.of(context).go('/admin');
              } else {
                print("Redirecting to /home for non-admin user");
                GoRouter.of(context).go('/home');
              }
            } catch (e) {
              print("Error redirecting from loading: $e");
              GoRouter.of(context).go('/home');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
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
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/calculator',
            builder: (context, state) => CalculatorScreen(
              savedResult: state.extra as SavedResult?,
            ),
            routes: [
              GoRoute(
                path: 'tile-select',
                builder: (context, state) => const TileSelectorScreen(),
                routes: [
                  GoRoute(
                    path: 'add-tile',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      return AddTileWidget(
                        userRole: extra?['userRole'] as UserRole,
                        userId: extra?['userId'] as String,
                        onTileCreated: extra?['onTileCreated'] as void Function(
                            TileModel)?,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/calculator/main',
            builder: (context, state) => CalculatorScreen(
              savedResult: state.extra as SavedResult?,
            ),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) {
              final ref = ProviderScope.containerOf(context);
              final user = ref.read(currentUserProvider).value;
              if (user == null || user.role != UserRole.admin) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await FirebaseAnalytics.instance.logEvent(
                    name: 'access_denied',
                    parameters: {
                      'route': state.uri.path,
                      'role': user?.role.toString() ?? 'null'
                    },
                  );
                  GoRouter.of(context).go('/home');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return const AdminDashboardScreen();
            },
            routes: [
              GoRoute(
                path: 'users',
                builder: (context, state) => const UserManagementScreen(),
              ),
              GoRoute(
                path: 'tiles',
                builder: (context, state) => const AdminTileManagementScreen(),
              ),
              GoRoute(
                path: 'stats',
                builder: (context, state) => const AdminStatsScreen(),
              ),
              GoRoute(
                path: 'add-tile',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return AddTileWidget(
                    userRole: extra?['userRole'] as UserRole,
                    userId: extra?['userId'] as String,
                  );
                },
              ),
              GoRoute(
                path: 'edit-tile/:tileId',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return AddTileWidget(
                    userRole: extra?['userRole'] as UserRole,
                    userId: extra?['userId'] as String,
                    tile: extra?['tile'] as TileModel,
                  );
                },
              ),
            ],
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
            path: '/support/contact',
            builder: (context, state) => const ContactScreen(),
          ),
          GoRoute(
            path: '/subscription',
            builder: (context, state) => const SubscriptionScreen(),
          ),
          GoRoute(
            path: '/subscription/success',
            builder: (context, state) => const SuccessPage(),
          ),
          GoRoute(
            path: '/subscription/cancel',
            builder: (context, state) => const CancelPage(),
          ),
          GoRoute(
            path: '/results',
            builder: (context, state) => const SavedResultsScreen(),
          ),
          GoRoute(
            path: '/tiles',
            builder: (context, state) => const TileManagementScreen(),
            routes: [
              GoRoute(
                path: 'add-tile',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return AddTileWidget(
                    userRole: extra?['userRole'] as UserRole,
                    userId: extra?['userId'] as String,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      print("Router error: ${state.error}");
      return Scaffold(
        body: Center(
          child: Text(
            'Route not found: ${state.uri.path}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      );
    },
  );
});
