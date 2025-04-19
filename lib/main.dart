import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/routing/router.dart';
import 'package:roofgrid_uk/utils/app_theme.dart';
import 'package:roofgrid_uk/firebase_options.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
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
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Comment out App Check for emulator testing
  // try {
  //   await FirebaseAppCheck.instance.activate(
  //     androidProvider: AndroidProvider.debug,
  //     appleProvider: AppleProvider.debug,
  //   );
  //   final token = await FirebaseAppCheck.instance.getToken(true);
  //   debugPrint('App Check Debug Token: $token');
  // } catch (e) {
  //   debugPrint('App Check initialization failed: $e');
  // }

  try {
    await FirebaseAnalytics.instance.logAppOpen();
  } catch (e) {
    debugPrint('Firebase Analytics initialization failed: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Ensure auth state is initialized before routing
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print("Checking persistent login on app start");
      await ref.read(authProvider.notifier).checkPersistentLogin();
      await ref.read(authProvider.notifier).initializeDefaultTiles();
    });

    return MaterialApp.router(
      title: 'RoofGrid UK',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
