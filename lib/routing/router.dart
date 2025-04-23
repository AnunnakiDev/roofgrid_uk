import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/screens/admin/admin_dashboard_screen.dart';
import 'package:roofgrid_uk/screens/admin/admin_stats_screen.dart';
import 'package:roofgrid_uk/screens/admin/admin_tile_management_screen.dart';
import 'package:roofgrid_uk/screens/admin/user_management_screen.dart';
import 'package:roofgrid_uk/screens/auth/forgot_password_screen.dart';
import 'package:roofgrid_uk/screens/auth/login_screen.dart';
import 'package:roofgrid_uk/screens/auth/register_screen.dart';
import 'package:roofgrid_uk/screens/calculator/calculator_screen.dart';
import 'package:roofgrid_uk/screens/calculator/tile_selector_screen.dart';
import 'package:roofgrid_uk/screens/home_screen.dart';
import 'package:roofgrid_uk/screens/results/result_detail_screen.dart'; // Updated path
import 'package:roofgrid_uk/screens/results/saved_results_screen.dart'; // Updated path
import 'package:roofgrid_uk/screens/splash_screen.dart';
import 'package:roofgrid_uk/screens/subscription/cancel_page.dart';
import 'package:roofgrid_uk/screens/subscription/success_page.dart';
import 'package:roofgrid_uk/screens/subscription_screen.dart';
import 'package:roofgrid_uk/screens/support/contact_screen.dart';
import 'package:roofgrid_uk/screens/support/faq_screen.dart';
import 'package:roofgrid_uk/screens/support/legal_screen.dart';
import 'package:roofgrid_uk/screens/tile_management_screen.dart';
import 'package:roofgrid_uk/widgets/result_visualization.dart'; // Updated path

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      print(
          "Router redirect: matchedLocation=${state.matchedLocation}, authState.isAuthenticated=$isAuthenticated");

      if (isSplash) {
        return isAuthenticated ? '/home' : '/auth/login';
      }

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
          ),
        ],
      ),
      GoRoute(
        path: '/results',
        builder: (context, state) => const SavedResultsScreen(),
      ),
      GoRoute(
        path: '/result-detail',
        builder: (context, state) => ResultDetailScreen(
          result: state.extra as SavedResult,
        ),
      ),
      GoRoute(
        path: '/result-visualization',
        builder: (context, state) => ResultVisualization(
          result: state.extra as SavedResult,
        ),
      ),
      GoRoute(
        path: '/tiles',
        builder: (context, state) => const TileManagementScreen(),
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
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/stats',
        builder: (context, state) => const AdminStatsScreen(),
      ),
      GoRoute(
        path: '/admin/tiles',
        builder: (context, state) => const AdminTileManagementScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserManagementScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
});
