import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/navigation/nav_items.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
import 'package:roofgrid_uk/widgets/bottom_nav_bar.dart';

class AppBottomNav extends ConsumerWidget {
  final int currentIndex;
  final void Function(int index)? onTabSelected;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (onTabSelected != null) {
          onTabSelected!(index);
          return;
        }
        navigateToShellTab(context, ref, index);
      },
      items: mainShellNavItems,
    );
  }

  /// Derive the active tab from the current route.
  static int indexFromState(GoRouterState state) {
    return shellTabIndexFromLocation(state.matchedLocation);
  }
}