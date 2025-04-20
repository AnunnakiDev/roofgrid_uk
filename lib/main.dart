import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/routing/router.dart';
import 'package:roofgrid_uk/utils/app_theme.dart';
import 'package:roofgrid_uk/firebase_options.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/theme_provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  // Register Hive adapters
  Hive.registerAdapter(TileSlateTypeAdapter());
  Hive.registerAdapter(TileModelAdapter());
  Hive.registerAdapter(UserRoleAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(CalculationTypeAdapter());
  Hive.registerAdapter(SavedResultAdapter());
  // Open Hive boxes
  await Hive.openBox('appState');
  await Hive.openBox<TileModel>('tilesBox');
  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<SavedResult>('resultsBox');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  try {
    await FirebaseAnalytics.instance.logAppOpen();
    debugPrint('Firebase Analytics logged app open');
  } catch (e) {
    debugPrint('Firebase Analytics initialization failed: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('Attempting to access routerProvider');
    final router = ref.watch(routerProvider);
    debugPrint('routerProvider accessed successfully: $router');

    // Watch themeProvider to get the current theme mode and custom primary color
    final themeState = ref.watch(themeProvider);
    final themeMode = themeState.themeMode;
    final customPrimaryColor = themeState.customPrimaryColor;

    // Ensure auth state is initialized before routing
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('Checking persistent login on app start');
      await ref.read(authProvider.notifier).checkPersistentLogin();
      await ref.read(authProvider.notifier).initializeDefaultTiles();
    });

    return MaterialApp.router(
      title: 'RoofGrid UK',
      theme: AppTheme.lightTheme(primaryColor: customPrimaryColor),
      darkTheme: AppTheme.darkTheme(primaryColor: customPrimaryColor),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
