import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateStreamProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final isLoggedIn = authState.asData?.value != null;
      final isGoingToAuth = state.uri.path.startsWith('/auth');
      final isSplash = state.uri.path == '/splash';
      final isSupport = state.uri.path.startsWith('/support');
      final isCalculator = state.uri.path == '/calculator';
      final isSubscriptionRedirect =
          state.uri.path.startsWith('/subscription') &&
              state.uri.path != '/subscription';

      print(
          "Router redirect: isLoggedIn=$isLoggedIn, matchedLocation=${state.uri.path}");

      if (isSplash) {
        print("Staying on splash screen");
        return null;
      }

      if (isSupport) {
        print("Allowing access to support page: ${state.uri.path}");
        return null; // Allow access to support pages for all users
      }

      if (isCalculator) {
        print("Redirecting /calculator to /calculator/tile-select");
        return '/calculator/tile-select';
      }

      if (isSubscriptionRedirect) {
        print(
            "Allowing access to subscription redirect pages: ${state.uri.path}");
        return null; // Allow access to /subscription/success and /subscription/cancel
      }

      if (!isLoggedIn && !isGoingToAuth) {
        print("Redirecting to /auth/login");
        return '/auth/login';
      }

      if (isLoggedIn && isGoingToAuth) {
        print("Redirecting to /home");
        return '/home';
      }

      // Restrict access to all /admin routes for non-admins
      if (isLoggedIn && state.uri.path.startsWith('/admin')) {
        final user = ref.read(currentUserProvider).value;
        if (user == null) {
          print("User not loaded, redirecting to /home");
          return '/home';
        }
        if (user.role != UserRole.admin) {
          await FirebaseAnalytics.instance.logEvent(
            name: 'access_denied',
            parameters: {'route': state.uri.path, 'role': user.role.toString()},
          );
          print("Access denied for ${state.uri.path}, redirecting to /home");
          return '/home';
        }
      }

      await FirebaseAnalytics.instance.logScreenView(
        screenName: state.uri.path,
      );

      return null;
    },
    routes: [
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
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/calculator',
        builder: (context, state) => const CalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/main',
        builder: (context, state) => const CalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/tile-select',
        builder: (context, state) => const TileSelectorScreen(),
        routes: [
          GoRoute(
            path: 'add-tile',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AddTileWidget(
                userRole: extra?['userRole'] as UserRole,
                userId: extra?['userId'] as String,
                onTileCreated:
                    extra?['onTileCreated'] as void Function(TileModel)?,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
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
