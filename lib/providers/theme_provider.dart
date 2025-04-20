import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:roofgrid_uk/utils/app_theme.dart';

class ThemeState {
  final ThemeMode themeMode;
  final Color? customPrimaryColor;

  ThemeState({required this.themeMode, this.customPrimaryColor});
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themePreferenceKey = 'themePreference';
  static const String _customPrimaryColorKey = 'customPrimaryColor';
  final Box _box;

  ThemeNotifier()
      : _box = Hive.box('appState'),
        super(ThemeState(themeMode: ThemeMode.light)) {
    _loadThemePreference();
    _loadCustomPrimaryColor();
  }

  Future<void> _loadThemePreference() async {
    final themeString =
        _box.get(_themePreferenceKey, defaultValue: 'light') as String;
    state = ThemeState(
      themeMode: themeString == 'dark' ? ThemeMode.dark : ThemeMode.light,
      customPrimaryColor: state.customPrimaryColor,
    );
  }

  Future<void> _loadCustomPrimaryColor() async {
    final colorValue = _box.get(_customPrimaryColorKey);
    if (colorValue != null) {
      state = ThemeState(
        themeMode: state.themeMode,
        customPrimaryColor: Color(colorValue),
      );
    }
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    state = ThemeState(
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      customPrimaryColor: state.customPrimaryColor,
    );
    await _box.put(_themePreferenceKey, isDarkMode ? 'dark' : 'light');
  }

  Future<void> setCustomPrimaryColor(Color color) async {
    state = ThemeState(
      themeMode: state.themeMode,
      customPrimaryColor: color,
    );
    await _box.put(_customPrimaryColorKey, color.value);
  }

  void clearCustomPrimaryColor() {
    state = ThemeState(
      themeMode: state.themeMode,
      customPrimaryColor: null,
    );
    _box.delete(_customPrimaryColorKey);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
