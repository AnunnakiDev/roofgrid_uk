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

  debugPrint('Starting app initialization');

  // Initialize Hive
  debugPrint('Initializing Hive');
  await Hive.initFlutter();
  debugPrint('Hive initialized');

  // Register Hive adapters
  debugPrint('Registering Hive adapters');
  try {
    Hive.registerAdapter(TileSlateTypeAdapter());
    debugPrint('TileSlateTypeAdapter registered');
    Hive.registerAdapter(TileModelAdapter());
    debugPrint('TileModelAdapter registered');
    Hive.registerAdapter(UserRoleAdapter());
    debugPrint('UserRoleAdapter registered');
    Hive.registerAdapter(UserModelAdapter());
    debugPrint('UserModelAdapter registered');
    Hive.registerAdapter(CalculationTypeAdapter());
    debugPrint('CalculationTypeAdapter registered');
    Hive.registerAdapter(DateTimeAdapter());
    debugPrint('DateTimeAdapter registered');
    Hive.registerAdapter(SavedResultAdapter());
    debugPrint('SavedResultAdapter registered');
  } catch (e) {
    debugPrint('Error registering Hive adapters: $e');
    rethrow;
  }

  // Open Hive boxes
  debugPrint('Opening Hive boxes');
  try {
    await Hive.openBox('appState');
    debugPrint('appState box opened');
    await Hive.openBox<TileModel>('tilesBox');
    debugPrint('tilesBox opened');
    await Hive.openBox<UserModel>('userBox');
    debugPrint('userBox opened');
    await Hive.openBox<SavedResult>('resultsBox');
    debugPrint('resultsBox opened');
    await Hive.openBox<Map>('calculationsBox');
    debugPrint('calculationsBox opened');
  } catch (e) {
    debugPrint('Error opening Hive boxes: $e');
    rethrow;
  }

  // Initialize Firebase
  debugPrint('Initializing Firebase');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Firebase Analytics
  debugPrint('Initializing Firebase Analytics');
  try {
    await FirebaseAnalytics.instance.logAppOpen();
    debugPrint('Firebase Analytics logged app open');
  } catch (e) {
    debugPrint('Firebase Analytics initialization failed: $e');
  }

  debugPrint('Running app with ProviderScope');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('Building MyApp widget');

    // Access routerProvider
    debugPrint('Attempting to access routerProvider');
    final router = ref.watch(routerProvider);
    debugPrint('routerProvider accessed successfully: $router');

    // Watch themeProvider to get the current theme mode and custom primary color
    debugPrint;
    ('Accessing themeProvider');
    final themeState = ref.watch(themeProvider);
    final themeMode = themeState.themeMode;
    final customPrimaryColor = themeState.customPrimaryColor;
    debugPrint(
        'themeProvider accessed: themeMode=$themeMode, customPrimaryColor=$customPrimaryColor');

    // Ensure auth state is initialized before routing
    debugPrint('Scheduling auth state check');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('Checking persistent login on app start');
      await ref.read(authProvider.notifier).checkPersistentLogin();
      debugPrint('Persistent login check completed');
      await ref.read(authProvider.notifier).initializeDefaultTiles();
      debugPrint('Default tiles initialized');
    });

    debugPrint('Building MaterialApp.router');
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
