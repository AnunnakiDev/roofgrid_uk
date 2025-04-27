import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/routing/router.dart';
import 'package:roofgrid_uk/utils/app_theme.dart';
import 'package:roofgrid_uk/firebase_options.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/services/hive_service.dart';
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

  // Register Hive adapters only if not already registered
  if (!Hive.isAdapterRegistered(TileSlateTypeAdapter().typeId)) {
    debugPrint('Registering Hive adapters');
    try {
      Hive.registerAdapter(TileSlateTypeAdapter());
      Hive.registerAdapter(TileModelAdapter());
      Hive.registerAdapter(UserRoleAdapter());
      Hive.registerAdapter(UserModelAdapter());
      Hive.registerAdapter(CalculationTypeAdapter());
      Hive.registerAdapter(SavedResultAdapter());
    } catch (e) {
      debugPrint('Error registering Hive adapters: $e');
      rethrow;
    }
  }

  // Initialize HiveService
  debugPrint('Initializing HiveService');
  try {
    await HiveService.init();
  } catch (e) {
    debugPrint('Error initializing HiveService: $e');
    rethrow;
  }

  // Initialize Firebase
  debugPrint('Initializing Firebase');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAnalytics.instance.logAppOpen();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    rethrow;
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('Building MyApp widget');

    // Watch themeInitializerProvider to ensure initialization
    final themeInitializer = ref.watch(themeInitializerProvider);
    final themeState = ref.watch(themeStateProvider);

    return themeInitializer.when(
      data: (_) => MaterialApp.router(
        title: 'RoofGrid UK',
        theme: AppTheme.lightTheme(primaryColor: themeState.customPrimaryColor),
        darkTheme:
            AppTheme.darkTheme(primaryColor: themeState.customPrimaryColor),
        themeMode: themeState.themeMode,
        routerConfig: ref.watch(goRouterProvider),
        debugShowCheckedModeBanner: false,
      ),
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) {
        debugPrint('Theme initialization error: $error');
        return MaterialApp(
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.system,
          home: Scaffold(
            body: Center(child: Text('Error initializing theme: $error')),
          ),
        );
      },
    );
  }
}
