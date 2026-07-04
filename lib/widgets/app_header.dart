import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showMenuButton;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.showMenuButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(
        top: MediaQuery.of(context).padding.top + 8.0, // Account for status bar
      ),
      child: Row(
        children: [
          if (showMenuButton)
            Semantics(
              label: 'Open navigation drawer',
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: 'Open navigation drawer',
              ),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
