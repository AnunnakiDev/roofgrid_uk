import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeInitializerProvider = FutureProvider<void>((ref) async {
  final themeNotifier = ref.read(themeProvider.notifier);
  await themeNotifier.initialize();
});

final themeStateProvider = Provider<ThemeState>((ref) {
  final initializer = ref.watch(themeInitializerProvider);
  final themeState = ref.watch(themeProvider);

  return initializer.when(
    data: (_) => themeState,
    loading: () =>
        ThemeState(themeMode: ThemeMode.system, isInitialized: false),
    error: (_, __) =>
        ThemeState(themeMode: ThemeMode.system, isInitialized: false),
  );
});

class ThemeState {
  final ThemeMode themeMode;
  final Color customPrimaryColor;
  final bool isInitialized;

  ThemeState({
    required this.themeMode,
    this.customPrimaryColor = Colors.blue,
    this.isInitialized = false,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? customPrimaryColor,
    bool? isInitialized,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      customPrimaryColor: customPrimaryColor ?? this.customPrimaryColor,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themePreferenceKey = 'themePreference';
  static const String _customPrimaryColorKey = 'customPrimaryColor';
  Box? _box;

  ThemeNotifier() : super(ThemeState(themeMode: ThemeMode.system));

  Future<void> initialize() async {
    try {
      _box = await Hive.openBox('appState');
      await _loadThemePreference();
      await _loadCustomPrimaryColor();
      state = state.copyWith(isInitialized: true);
    } catch (e) {
      debugPrint('Error initializing theme: $e');
      try {
        await Hive.deleteBoxFromDisk('appState');
        _box = await Hive.openBox('appState');
        await _loadThemePreference();
        await _loadCustomPrimaryColor();
        state = state.copyWith(isInitialized: true);
      } catch (retryError) {
        debugPrint('Retry failed: $retryError');
        state = state.copyWith(
          themeMode: ThemeMode.system,
          isInitialized: true,
        );
        if (kIsWeb) {
          debugPrint('Web storage issue detected. Using system theme.');
        }
      }
    }
  }

  Future<void> _loadThemePreference() async {
    if (_box == null) return;
    final themeString =
        _box!.get(_themePreferenceKey, defaultValue: 'system') as String;
    ThemeMode themeMode;
    switch (themeString) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeMode = ThemeMode.system;
        break;
    }
    state = state.copyWith(themeMode: themeMode);
  }

  Future<void> _loadCustomPrimaryColor() async {
    if (_box == null) return;
    final colorValue = _box!.get(_customPrimaryColorKey);
    if (colorValue != null) {
      state = state.copyWith(customPrimaryColor: Color(colorValue));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    if (_box != null) {
      await _box!.put(_themePreferenceKey, mode.toString().split('.').last);
    }
  }

  Future<void> setCustomPrimaryColor(Color color) async {
    state = state.copyWith(customPrimaryColor: color);
    if (_box != null) {
      await _box!.put(_customPrimaryColorKey, color.value);
    }
  }

  void clearCustomPrimaryColor() {
    state = state.copyWith(customPrimaryColor: Colors.blue);
    if (_box != null) {
      _box!.delete(_customPrimaryColorKey);
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
