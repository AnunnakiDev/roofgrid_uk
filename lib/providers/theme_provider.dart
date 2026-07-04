import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:roofgrid_uk/services/hive_service.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';
import 'package:roofgrid_uk/utils/app_theme.dart';

final themeStateProvider = Provider<ThemeState>((ref) {
  return ref.watch(themeProvider);
});

class ThemeState {
  final ThemeMode themeMode;
  final AppColorSchemeId colorSchemeId;
  final bool isInitialized;

  ThemeState({
    required this.themeMode,
    this.colorSchemeId = AppTheme.defaultColorScheme,
    this.isInitialized = false,
  });

  ThemeData themeFor(Brightness brightness) {
    return AppTheme.themeFor(
      schemeId: colorSchemeId,
      brightness: brightness,
    );
  }

  AppSchemeTokens tokensFor(Brightness brightness) {
    return AppColorSchemes.tokensFor(colorSchemeId, brightness);
  }

  ThemeState copyWith({
    ThemeMode? themeMode,
    AppColorSchemeId? colorSchemeId,
    bool? isInitialized,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      colorSchemeId: colorSchemeId ?? this.colorSchemeId,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const String _themePreferenceKey = 'themePreference';
  static const String _colorSchemeIdKey = 'colorSchemeId';
  static const String _legacyCustomPrimaryColorKey = 'customPrimaryColor';
  Box? _box;

  @override
  ThemeState build() {
    _box = _resolveAppStateBox();
    if (_box == null) {
      return ThemeState(
        themeMode: ThemeMode.system,
        isInitialized: true,
      );
    }
    return _readStateFromBox(_box!);
  }

  Box? _resolveAppStateBox() {
    final serviceBox = HiveService.appStateBox;
    if (serviceBox != null && serviceBox.isOpen) {
      return serviceBox;
    }
    if (Hive.isBoxOpen('appState')) {
      return Hive.box('appState');
    }
    return null;
  }

  ThemeState _readStateFromBox(Box box) {
    final themeString =
        box.get(_themePreferenceKey, defaultValue: 'system') as String;
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

    final schemeString = box.get(_colorSchemeIdKey) as String?;
    final colorSchemeId = appColorSchemeIdFromStorage(schemeString);

    if (box.get(_legacyCustomPrimaryColorKey) != null) {
      box.delete(_legacyCustomPrimaryColorKey);
    }

    return ThemeState(
      themeMode: themeMode,
      colorSchemeId: colorSchemeId,
      isInitialized: true,
    );
  }

  Future<void> initialize() async {
    try {
      _box = _resolveAppStateBox() ??
          (Hive.isBoxOpen('appState')
              ? Hive.box('appState')
              : await Hive.openBox('appState'));
      state = _readStateFromBox(_box!);
    } catch (e) {
      debugPrint('Error initializing theme: $e');
      state = ThemeState(
        themeMode: ThemeMode.system,
        isInitialized: true,
      );
      if (kIsWeb) {
        debugPrint('Web storage issue detected. Using system theme.');
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    if (_box != null) {
      await _box!.put(_themePreferenceKey, mode.toString().split('.').last);
    }
  }

  Future<void> setColorSchemeId(
    AppColorSchemeId schemeId, {
    String? syncUserId,
  }) async {
    state = state.copyWith(colorSchemeId: schemeId);
    if (_box != null) {
      await _box!.put(_colorSchemeIdKey, schemeId.storageKey);
      await _box!.delete(_legacyCustomPrimaryColorKey);
    }

    if (syncUserId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(syncUserId)
            .update({
          'settings.colorSchemeId': schemeId.storageKey,
          'settings.primaryColor': FieldValue.delete(),
        });
      } catch (e) {
        debugPrint('Failed to sync colour scheme to Firestore: $e');
      }
    }
  }

  /// Applies scheme from Firestore without writing back to the cloud.
  Future<void> applyUserColorSchemeFromCloud(AppColorSchemeId? schemeId) async {
    if (schemeId == null) return;

    state = state.copyWith(colorSchemeId: schemeId);
    if (_box != null) {
      await _box!.put(_colorSchemeIdKey, schemeId.storageKey);
      await _box!.delete(_legacyCustomPrimaryColorKey);
    }
  }
}

final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);