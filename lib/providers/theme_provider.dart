import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// FutureProvider to handle theme initialization
final themeInitializerProvider = FutureProvider<void>((ref) async {
  final themeNotifier = ref.read(themeProvider.notifier);
  await themeNotifier.initialize();
});

// Combined provider to ensure themeProvider is only accessed after initialization
final themeStateProvider = Provider<ThemeState>((ref) {
  final initializer = ref.watch(themeInitializerProvider);
  final themeState = ref.watch(themeProvider);

  // Return the theme state only if initialized, otherwise provide a default
  return initializer.when(
    data: (_) => themeState,
    loading: () => ThemeState(themeMode: ThemeMode.light, isInitialized: false),
    error: (_, __) =>
        ThemeState(themeMode: ThemeMode.light, isInitialized: false),
  );
});

class ThemeState {
  final ThemeMode themeMode;
  final Color customPrimaryColor; // Now non-nullable with a default
  final bool isInitialized;

  ThemeState({
    required this.themeMode,
    this.customPrimaryColor = Colors.blue, // Default color
    this.isInitialized = false,
  });
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themePreferenceKey = 'themePreference';
  static const String _customPrimaryColorKey = 'customPrimaryColor';
  Box? _box;

  ThemeNotifier() : super(ThemeState(themeMode: ThemeMode.light));

  Future<void> initialize() async {
    try {
      _box = Hive.box('appState');
      await _loadThemePreference();
      await _loadCustomPrimaryColor();
      state = ThemeState(
        themeMode: state.themeMode,
        customPrimaryColor: state.customPrimaryColor,
        isInitialized: true,
      );
    } catch (e) {
      debugPrint('Error initializing theme: $e');
      // Fallback to default theme
      state = ThemeState(
        themeMode: ThemeMode.light,
        isInitialized: true,
      );
    }
  }

  Future<void> _loadThemePreference() async {
    if (_box == null) return;
    final themeString =
        _box!.get(_themePreferenceKey, defaultValue: 'light') as String;
    state = ThemeState(
      themeMode: themeString == 'dark' ? ThemeMode.dark : ThemeMode.light,
      customPrimaryColor: state.customPrimaryColor,
      isInitialized: state.isInitialized,
    );
  }

  Future<void> _loadCustomPrimaryColor() async {
    if (_box == null) return;
    final colorValue = _box!.get(_customPrimaryColorKey);
    if (colorValue != null) {
      state = ThemeState(
        themeMode: state.themeMode,
        customPrimaryColor: Color(colorValue),
        isInitialized: state.isInitialized,
      );
    }
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    state = ThemeState(
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      customPrimaryColor: state.customPrimaryColor,
      isInitialized: state.isInitialized,
    );
    if (_box != null) {
      await _box!.put(_themePreferenceKey, isDarkMode ? 'dark' : 'light');
    }
  }

  Future<void> setCustomPrimaryColor(Color color) async {
    state = ThemeState(
      themeMode: state.themeMode,
      customPrimaryColor: color,
      isInitialized: state.isInitialized,
    );
    if (_box != null) {
      await _box!.put(_customPrimaryColorKey, color.value);
    }
  }

  void clearCustomPrimaryColor() {
    state = ThemeState(
      themeMode: state.themeMode,
      customPrimaryColor: Colors.blue, // Reset to default
      isInitialized: state.isInitialized,
    );
    if (_box != null) {
      _box!.delete(_customPrimaryColorKey);
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
