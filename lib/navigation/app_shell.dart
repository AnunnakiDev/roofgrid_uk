import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/navigation/app_bottom_nav.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTabSelected: (index) {
          if (index == 1) {
            showCalculatorModePicker(context);
            return;
          }
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