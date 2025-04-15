// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';

class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String? tooltip;

  const BottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.tooltip,
  });
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: items
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.activeIcon),
                label: item.label,
                tooltip: item.tooltip,
              ))
          .toList(),
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 8,
    );
  }
}
