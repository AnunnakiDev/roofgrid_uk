import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the currentUserProvider to determine the user's state
    final userAsync = ref.watch(currentUserProvider);

    // Use a Future.delayed to ensure we don't navigate too quickly
    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return; // Check if the widget is still mounted

      userAsync.when(
        data: (user) {
          if (user == null) {
            // If no user is logged in, navigate to login
            context.go('/auth/login');
          } else {
            // If user is logged in, navigate to home
            context.go('/home');
          }
        },
        loading: () {
          // If still loading after 2 seconds, navigate to login as a fallback
          context.go('/auth/login');
        },
        error: (error, stackTrace) {
          // If there's an error, navigate to login and show an error message
          context.go('/auth/login');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading user data: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 100), // Replace with your app's logo
            SizedBox(height: 16),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'RoofGrid UK',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
