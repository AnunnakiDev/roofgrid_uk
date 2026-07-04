import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/navigation/app_bottom_nav.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';


class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final hideShellNav = hideShellNavForLocation(location);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: hideShellNav
          ? null
          : AppBottomNav(
              currentIndex: navigationShell.currentIndex,
              onTabSelected: (index) {
                navigateToShellTab(
                  context,
                  ref,
                  index,
                  goBranch: (i) => navigationShell.goBranch(i),
                );
              },
            ),
    );
  }
}