import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/routing/router.dart';
import 'package:roofgrid_uk/utils/app_theme.dart';
import 'package:roofgrid_uk/firebase_options.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/services/hive_service.dart';
import 'package:roofgrid_uk/utils/theme_provider_widget.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Starting app initialization');

  // Wrap the entire app in ProviderScope
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  Future<void> _initializeApp() async {
    // Initialize Hive
    debugPrint('Initializing Hive');
    await Hive.initFlutter();
    debugPrint('Hive initialized');

    // Register Hive adapters only if not already registered
    if (!Hive.isAdapterRegistered(TileSlateTypeAdapter().typeId)) {
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
        Hive.registerAdapter(SavedResultAdapter());
        debugPrint('SavedResultAdapter registered');
      } catch (e) {
        debugPrint('Error registering Hive adapters: $e');
        rethrow;
      }
    } else {
      debugPrint('Hive adapters already registered, skipping registration');
    }

    // Initialize HiveService (which opens all necessary boxes)
    debugPrint('Initializing HiveService');
    try {
      await HiveService.init();
      debugPrint('HiveService initialized successfully');
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
      debugPrint('Firebase initialized successfully');
      // Initialize Firebase Analytics after Firebase is ready
      debugPrint('Initializing Firebase Analytics');
      await FirebaseAnalytics.instance.logAppOpen();
      debugPrint('Firebase Analytics logged app open');
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('Building MyApp widget');

    return FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('Waiting for app initialization');
          return MaterialApp(
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: ThemeMode.system,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('App initialization error: ${snapshot.error}');
          return MaterialApp(
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: ThemeMode.system,
            home: Scaffold(
              body: Center(
                child: Text('Error initializing app: ${snapshot.error}'),
              ),
            ),
          );
        }

        // Access routerProvider
        debugPrint('Attempting to access routerProvider');
        final router = ref.watch(routerProvider);
        debugPrint('routerProvider accessed successfully: $router');

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
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.system,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return ThemeProvider(child: child!);
          },
        );
      },
    );
  }
}
