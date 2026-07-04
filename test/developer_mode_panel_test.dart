import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/models/developer_mode_config.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';
import 'package:roofgrid_uk/widgets/developer_mode_panel.dart';

class _TestCalculatorNotifier extends CalculatorNotifier {
  @override
  CalculatorState build() => CalculatorState();
}

class _TestDeveloperModeNotifier extends DeveloperModeNotifier {
  @override
  DeveloperModeState build() => const DeveloperModeState();

  @override
  Future<void> setProOverride(ProOverrideMode mode) async {
    state = state.copyWith(proOverride: mode);
  }

  @override
  Future<void> setForceOffline(bool enabled) async {
    setForceOfflineOverride(enabled);
    state = state.copyWith(forceOffline: enabled);
  }
}

UserModel _adminUser() {
  return UserModel(
    id: 'admin-test',
    email: 'hgwarner1307@gmail.com',
    role: UserRole.admin,
    createdAt: DateTime.now(),
    proTrialEndDate: DateTime.now().subtract(const Duration(days: 1)),
  );
}

void main() {
  tearDown(() {
    setForceOfflineOverride(false);
  });

  testWidgets('DeveloperModePanel renders admin controls', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          developerModeProvider.overrideWith(_TestDeveloperModeNotifier.new),
          calculatorProvider.overrideWith(_TestCalculatorNotifier.new),
          currentUserProvider.overrideWith(
            (ref) => Stream<UserModel?>.value(_adminUser()),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeveloperModePanel(user: _adminUser()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Developer Mode'), findsOneWidget);
    expect(find.text('Local only'), findsOneWidget);
    expect(find.text('Pro UI Override'), findsOneWidget);
    expect(find.text('Force Offline Mode'), findsOneWidget);
    expect(find.text('Reset Local Data'), findsOneWidget);
    expect(find.text('Seed UK Tiles'), findsOneWidget);
    expect(find.text('Debug Info'), findsOneWidget);
    expect(find.textContaining('Effective isPro'), findsOneWidget);
  });

  testWidgets('Pro override switches effective isPro for admin', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          developerModeProvider.overrideWith(_TestDeveloperModeNotifier.new),
          calculatorProvider.overrideWith(_TestCalculatorNotifier.new),
          currentUserProvider.overrideWith(
            (ref) => Stream<UserModel?>.value(_adminUser()),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeveloperModePanel(user: _adminUser()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Effective isPro:'), findsOneWidget);
    expect(find.text('false'), findsWidgets);

    await tester.tap(find.text('Pro'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('true'), findsWidgets);
    expect(find.text('pro'), findsWidgets);
  });

  testWidgets('Force offline toggle updates debug connectivity', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          developerModeProvider.overrideWith(_TestDeveloperModeNotifier.new),
          calculatorProvider.overrideWith(_TestCalculatorNotifier.new),
          currentUserProvider.overrideWith(
            (ref) => Stream<UserModel?>.value(_adminUser()),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeveloperModePanel(user: _adminUser()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('forced offline'), findsOneWidget);
    expect(await isDeviceOnline(), isFalse);
  });
}