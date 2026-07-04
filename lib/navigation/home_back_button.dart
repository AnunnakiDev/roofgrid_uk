import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Reusable AppBar action that navigates to the home hub.
class HomeBackButton extends StatelessWidget {
  const HomeBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home_outlined),
      tooltip: 'Home',
      onPressed: () => context.go('/home'),
    );
  }
}