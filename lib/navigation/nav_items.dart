import 'package:flutter/material.dart';
import 'package:roofgrid_uk/widgets/bottom_nav_bar.dart';

/// Canonical main-app bottom navigation tabs.
const List<BottomNavItem> mainShellNavItems = [
  BottomNavItem(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
  ),
  BottomNavItem(
    label: 'Calculator',
    icon: Icons.calculate_outlined,
    activeIcon: Icons.calculate,
  ),
  BottomNavItem(
    label: 'My Jobs',
    icon: Icons.save_outlined,
    activeIcon: Icons.save,
  ),
  BottomNavItem(
    label: 'Tiles',
    icon: Icons.grid_view_outlined,
    activeIcon: Icons.grid_view,
  ),
];