import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/utils/app_theme.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_step_progress.dart';
import 'package:roofgrid_uk/widgets/calculator_launch_cards.dart';
import 'package:roofgrid_uk/widgets/home_welcome_banner.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget themed(Widget child) {
    return MaterialApp(
      theme: AppTheme.themeFor(
        schemeId: AppColorSchemeId.slateProfessional,
        brightness: Brightness.light,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('HomeWelcomeBanner', () {
    testWidgets('shows welcome hierarchy and pro chip', (tester) async {
      await tester.pumpWidget(
        themed(
          HomeWelcomeBanner(
            displayName: 'Alex Slater',
            isPro: true,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Alex Slater'), findsOneWidget);
      expect(find.text('Pro account'), findsOneWidget);
    });
  });

  group('CalculatorLaunchCards', () {
    testWidgets('renders all three calculator modes', (tester) async {
      await tester.pumpWidget(
        themed(
          CalculatorLaunchCards(onLaunch: (_) {}),
        ),
      );

      expect(find.text('Vertical'), findsOneWidget);
      expect(find.text('Horizontal'), findsOneWidget);
      expect(find.text('Combined'), findsOneWidget);
      expect(find.text('Batten gauge'), findsOneWidget);
      expect(find.text('Marking out'), findsOneWidget);
    });

    testWidgets('invokes callback for combined launch', (tester) async {
      CalculationTypeSelection? launched;

      await tester.pumpWidget(
        themed(
          CalculatorLaunchCards(
            onLaunch: (type) => launched = type,
          ),
        ),
      );

      await tester.tap(find.text('Combined'));
      await tester.pump();

      expect(launched, CalculationTypeSelection.both);
    });
  });

  group('CalculatorStepProgress', () {
    testWidgets('shows four wizard steps including type', (tester) async {
      await tester.pumpWidget(
        themed(
          const CalculatorStepProgress(
            currentStep: CalculatorFlowStep.selectType,
          ),
        ),
      );

      expect(find.text('Tile'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Measurements'), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);
    });
  });

  group('SectionHeader', () {
    testWidgets('renders title and optional subtitle', (tester) async {
      await tester.pumpWidget(
        themed(
          const SectionHeader(
            title: 'Roofing Calculators',
            subtitle: 'Choose a set-out mode to begin',
          ),
        ),
      );

      expect(find.text('Roofing Calculators'), findsOneWidget);
      expect(find.text('Choose a set-out mode to begin'), findsOneWidget);
    });
  });
}