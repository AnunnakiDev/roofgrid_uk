import 'package:flutter/material.dart';
import 'package:roofgrid_uk/app/theme/app_theme.dart';
import 'package:roofgrid_uk/routing/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';

class RoofGridApp extends ConsumerWidget {
  const RoofGridApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp.router(
      title: 'RoofGrid UK',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router(authState),
    );
  }
}
