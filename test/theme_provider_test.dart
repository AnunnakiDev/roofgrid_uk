import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:roofgrid_uk/providers/theme_provider.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final hivePath =
        'test_hive_theme_${DateTime.now().microsecondsSinceEpoch}';
    Hive.init(hivePath);
    if (Hive.isBoxOpen('appState')) {
      await Hive.box('appState').close();
    }
    try {
      await Hive.deleteBoxFromDisk('appState');
    } catch (_) {}
  });

  tearDown(() async {
    if (Hive.isBoxOpen('appState')) {
      await Hive.box('appState').close();
    }
    try {
      await Hive.deleteBoxFromDisk('appState');
    } catch (_) {}
  });

  Future<ThemeNotifier> initializedNotifier() async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(themeProvider.notifier);
    await notifier.initialize();
    return notifier;
  }

  test('defaults to Slate Professional when no scheme is stored', () async {
    final notifier = await initializedNotifier();

    expect(
      notifier.state.colorSchemeId,
      AppColorSchemeId.slateProfessional,
    );
  });

  test('initialize loads persisted colour scheme from Hive', () async {
    final box = await Hive.openBox('appState');
    await box.put('colorSchemeId', 'heritage_classic');
    await box.close();

    final notifier = await initializedNotifier();

    expect(notifier.state.colorSchemeId, AppColorSchemeId.heritageClassic);
  });

  test('legacy customPrimaryColor key is removed on read', () async {
    final box = await Hive.openBox('appState');
    await box.put('customPrimaryColor', 0xFFE53935);
    await box.close();

    final notifier = await initializedNotifier();

    final reopened = await Hive.openBox('appState');
    expect(reopened.get('customPrimaryColor'), isNull);
    expect(
      notifier.state.colorSchemeId,
      AppColorSchemeId.slateProfessional,
    );
  });

  test('setColorSchemeId persists to Hive without Firestore sync', () async {
    final notifier = await initializedNotifier();

    await notifier.setColorSchemeId(AppColorSchemeId.modernDarkFirst);

    expect(
      notifier.state.colorSchemeId,
      AppColorSchemeId.modernDarkFirst,
    );

    final box = await Hive.openBox('appState');
    expect(box.get('colorSchemeId'), 'modern_dark_first');
  });

  test('applyUserColorSchemeFromCloud applies remote scheme locally', () async {
    final notifier = await initializedNotifier();

    await notifier.applyUserColorSchemeFromCloud(
      AppColorSchemeId.heritageClassic,
    );

    expect(notifier.state.colorSchemeId, AppColorSchemeId.heritageClassic);

    final box = await Hive.openBox('appState');
    expect(box.get('colorSchemeId'), 'heritage_classic');
  });

  test('applyUserColorSchemeFromCloud with null is a no-op', () async {
    final notifier = await initializedNotifier();
    await notifier.setColorSchemeId(AppColorSchemeId.modernDarkFirst);

    await notifier.applyUserColorSchemeFromCloud(null);

    expect(
      notifier.state.colorSchemeId,
      AppColorSchemeId.modernDarkFirst,
    );
  });

  test('setThemeMode persists preference to Hive', () async {
    final notifier = await initializedNotifier();

    await notifier.setThemeMode(ThemeMode.dark);

    expect(notifier.state.themeMode, ThemeMode.dark);
    final box = await Hive.openBox('appState');
    expect(box.get('themePreference'), 'dark');
  });
}