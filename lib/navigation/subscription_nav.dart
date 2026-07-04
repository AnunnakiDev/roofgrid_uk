import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Minimal bottom nav for Free users on subscription-related screens.
class FreeSubscriptionNav extends StatelessWidget {
  final int currentIndex;

  const FreeSubscriptionNav({super.key, this.currentIndex = 1});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 0) context.go('/home');
        if (index == 1) context.go('/subscription');
      },
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.workspace_premium),
          label: 'Upgrade',
        ),
      ],
    );
  }
}