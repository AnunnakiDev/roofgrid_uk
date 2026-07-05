import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/firebase_options.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/theme_provider.dart';
import 'package:roofgrid_uk/widgets/session_sync_listener.dart';
import 'package:roofgrid_uk/widgets/user_theme_sync_listener.dart';
import 'package:roofgrid_uk/routing/router.dart';
import 'package:roofgrid_uk/services/email_link_handler.dart';
import 'package:roofgrid_uk/services/firebase_bootstrap.dart';
import 'package:roofgrid_uk/services/hive_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  if (kDebugMode) debugPrint('Starting app initialization');

  await Hive.initFlutter();
  if (kDebugMode) debugPrint('Hive initialized');

  if (!Hive.isAdapterRegistered(TileSlateTypeAdapter().typeId)) {
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

  try {
    await Future.wait([
      HiveService.init(),
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
    ]);
    await configureFirebaseForPlatform();
    unawaited(FirebaseAnalytics.instance.logAppOpen());
  } catch (e) {
    debugPrint('Startup initialization failed: $e');
    rethrow;
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailLinkInitializer = ref.watch(emailLinkHandlerInitializerProvider);
    final themeState = ref.watch(themeStateProvider);

    if (!themeState.isInitialized || emailLinkInitializer.isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return emailLinkInitializer.when(
      data: (_) => SessionSyncListener(
        child: UserThemeSyncListener(
          child: MaterialApp.router(
            title: 'RoofGrid UK',
            theme: themeState.themeFor(Brightness.light),
            darkTheme: themeState.themeFor(Brightness.dark),
            themeMode: themeState.themeMode,
            themeAnimationDuration: Duration.zero,
            themeAnimationCurve: Curves.linear,
            routerConfig: ref.read(goRouterProvider),
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) {
        debugPrint('Email link handler initialization error: $error');
        return SessionSyncListener(
          child: UserThemeSyncListener(
            child: MaterialApp.router(
              title: 'RoofGrid UK',
              theme: themeState.themeFor(Brightness.light),
              darkTheme: themeState.themeFor(Brightness.dark),
              themeMode: themeState.themeMode,
              routerConfig: ref.read(goRouterProvider),
              debugShowCheckedModeBanner: false,
            ),
          ),
        );
      },
    );
  }
}