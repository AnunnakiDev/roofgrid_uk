import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/screens/auth/login_screen.dart';
import 'package:roofgrid_uk/screens/auth/forgot_password_screen.dart';
import 'package:roofgrid_uk/screens/auth/register_screen.dart';
import 'package:roofgrid_uk/screens/calculator_screen.dart';
import 'package:roofgrid_uk/screens/home_screen.dart';
import 'package:roofgrid_uk/screens/splash_screen.dart';
import 'package:roofgrid_uk/screens/admin_dashboard_screen.dart';
import 'package:roofgrid_uk/screens/support/faq_screen.dart';
import 'package:roofgrid_uk/screens/support/legal_screen.dart';
import 'package:roofgrid_uk/screens/support/contact_screen.dart';
import 'package:roofgrid_uk/screens/subscription_screen.dart';
import 'package:roofgrid_uk/screens/saved_results_screen.dart';
import 'package:roofgrid_uk/screens/tile_management_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final userAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final isLoggedIn = authState.isAuthenticated;
      final isGoingToAuth = state.uri.path.startsWith('/auth');
      final isSplash = state.uri.path == '/splash';

      if (isSplash) {
        return null;
      }

      if (!isLoggedIn && !isGoingToAuth) {
        return '/auth/login';
      }

      if (isLoggedIn && isGoingToAuth) {
        return '/home';
      }

      if (isLoggedIn && state.uri.path == '/admin') {
        final user = userAsync.value;
        if (user == null) {
          return '/home';
        }
        if (user.role != UserRole.admin) {
          await FirebaseAnalytics.instance.logEvent(
            name: 'access_denied',
            parameters: {'route': '/admin', 'role': user.role.toString()},
          );
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
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
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
        path: '/results',
        builder: (context, state) => const SavedResultsScreen(),
      ),
      GoRoute(
        path: '/tiles',
        builder: (context, state) => const TileManagementScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Route not found: ${state.uri.path}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ),
    ),
  );
});
