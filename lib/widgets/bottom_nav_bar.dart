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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.35 : 0.1,
            ),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon, size: 24),
                  activeIcon: Icon(item.activeIcon, size: 28),
                  label: item.label,
                  tooltip: item.tooltip,
                ))
            .toList(),
        selectedItemColor: colorScheme.secondary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedFontSize: 13,
        unselectedFontSize: 12,
        selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
        unselectedLabelStyle: theme.bottomNavigationBarTheme.unselectedLabelStyle,
      ),
    );
  }
}
