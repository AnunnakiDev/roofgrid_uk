import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/screens/calculator/view_results_step.dart';
import 'package:roofgrid_uk/widgets/save_result_dialog.dart';

UserModel _testUser() {
  return UserModel(
    id: 'user-1',
    email: 'test@example.com',
    role: UserRole.pro,
    createdAt: DateTime(2026, 1, 1),
  );
}

const _verticalResult = VerticalCalculationResult(
  inputRafter: 5000,
  totalCourses: 24,
  solution: 'Valid',
  ridgeOffset: 50,
  firstBatten: 100,
  gauge: '30 @ 190',
);

const _horizontalResult = HorizontalCalculationResult(
  width: 4200,
  solution: 'Valid',
  newWidth: 4200,
  firstMark: 100,
  marks: '20 @ 210',
);

class _BothResultsCalculatorNotifier extends CalculatorNotifier {
  @override
  CalculatorState build() => CalculatorState(
        verticalResult: _verticalResult,
        horizontalResult: _horizontalResult,
      );
}

class _VerticalOnlyCalculatorNotifier extends CalculatorNotifier {
  @override
  CalculatorState build() =>
      CalculatorState(verticalResult: _verticalResult);
}

class _CombinedInvalidHorizontalNotifier extends CalculatorNotifier {
  @override
  CalculatorState build() => CalculatorState(
        verticalResult: _verticalResult,
        horizontalResult: const HorizontalCalculationResult(
          width: 400,
          solution: 'Invalid',
          newWidth: 0,
          firstMark: 0,
          marks: 'N/A',
          warning: 'Width values must be at least 500mm.',
        ),
      );
}

class _InvalidVerticalCalculatorNotifier extends CalculatorNotifier {
  @override
  CalculatorState build() => CalculatorState(
        verticalResult: const VerticalCalculationResult(
          inputRafter: 250,
          totalCourses: 0,
          solution: 'Invalid',
          ridgeOffset: 0,
          firstBatten: 0,
          gauge: 'N/A',
          warning: 'Rafter height is too short.',
        ),
      );
}

Widget _wrap(Widget child, CalculatorNotifier Function() notifierFactory) {
  return ProviderScope(
    overrides: [
      calculatorProvider.overrideWith(notifierFactory),
      effectiveIsProProvider.overrideWithValue(true),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('ViewResultsStep results layout', () {
    testWidgets('shows only vertical results for vertical-only calculations',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ViewResultsStep(
            user: _testUser(),
            verticalInputs: VerticalInputs(
              rafterHeights: const [
                {'label': 'Front Slope', 'value': 5000},
              ],
            ),
            horizontalInputs: HorizontalInputs(
              widths: const [
                {'label': 'Main Roof', 'value': 4200},
              ],
            ),
            calculationType: CalculationTypeSelection.verticalOnly,
            lastVerticalCalculationData: const {'inputs': {}},
            lastHorizontalCalculationData: const {'inputs': {}},
            onBack: () {},
            onSaveCombined: (_) {},
            onSaveResult: (_, __, ___, {saveAction = SaveResultAction.saveAsNew}) async => null,
          ),
          _BothResultsCalculatorNotifier.new,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Vertical set-out'), findsOneWidget);
      expect(find.text('Horizontal set-out'), findsNothing);
      expect(find.text('Combined'), findsNothing);
      expect(find.text('Visualization'), findsNothing);
    });

    testWidgets('shows both result panels for combined calculation type',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ViewResultsStep(
            user: _testUser(),
            verticalInputs: VerticalInputs(
              rafterHeights: const [
                {'label': 'Front Slope', 'value': 5000},
              ],
            ),
            horizontalInputs: HorizontalInputs(
              widths: const [
                {'label': 'Main Roof', 'value': 4200},
              ],
            ),
            calculationType: CalculationTypeSelection.both,
            lastVerticalCalculationData: const {'inputs': {}},
            lastHorizontalCalculationData: const {'inputs': {}},
            onBack: () {},
            onSaveCombined: (_) {},
            onSaveResult: (_, __, ___, {saveAction = SaveResultAction.saveAsNew}) async => null,
          ),
          _BothResultsCalculatorNotifier.new,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Vertical set-out'), findsOneWidget);
      expect(find.text('Horizontal set-out'), findsOneWidget);
      expect(find.text('Combined'), findsNothing);
    });

    testWidgets('combined mode shows only Save Combined, not per-panel saves',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ViewResultsStep(
            user: _testUser(),
            verticalInputs: VerticalInputs(
              rafterHeights: const [
                {'label': 'Front Slope', 'value': 5000},
              ],
            ),
            horizontalInputs: HorizontalInputs(
              widths: const [
                {'label': 'Main Roof', 'value': 4200},
              ],
            ),
            calculationType: CalculationTypeSelection.both,
            lastVerticalCalculationData: const {'inputs': {}},
            lastHorizontalCalculationData: const {'inputs': {}},
            onBack: () {},
            onSaveCombined: (_) {},
            onSaveResult: (_, __, ___, {saveAction = SaveResultAction.saveAsNew}) async => null,
          ),
          _BothResultsCalculatorNotifier.new,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Save Combined'), findsOneWidget);
      expect(find.text('Save Result'), findsNothing);
    });

    testWidgets('omits visualization for invalid vertical results', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ViewResultsStep(
            user: _testUser(),
            verticalInputs: VerticalInputs(
              rafterHeights: const [
                {'label': 'Rafter 1', 'value': 250},
              ],
            ),
            horizontalInputs: HorizontalInputs(),
            calculationType: CalculationTypeSelection.verticalOnly,
            lastVerticalCalculationData: const {'inputs': {}},
            lastHorizontalCalculationData: null,
            onBack: () {},
            onSaveCombined: (_) {},
            onSaveResult: (_, __, ___, {saveAction = SaveResultAction.saveAsNew}) async => null,
          ),
          _InvalidVerticalCalculatorNotifier.new,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Vertical set-out'), findsOneWidget);
      expect(find.text('No valid vertical solution'), findsOneWidget);
      expect(find.text('Visualization'), findsNothing);
    });

    testWidgets('combined mode hides Save Combined when horizontal is invalid',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ViewResultsStep(
            user: _testUser(),
            verticalInputs: VerticalInputs(
              rafterHeights: const [
                {'label': 'Front Slope', 'value': 5000},
              ],
            ),
            horizontalInputs: HorizontalInputs(
              widths: const [
                {'label': 'Main Roof', 'value': 400},
              ],
            ),
            calculationType: CalculationTypeSelection.both,
            lastVerticalCalculationData: const {'inputs': {}},
            lastHorizontalCalculationData: const {'inputs': {}},
            onBack: () {},
            onSaveCombined: (_) {},
            onSaveResult: (_, __, ___, {saveAction = SaveResultAction.saveAsNew}) async => null,
          ),
          _CombinedInvalidHorizontalNotifier.new,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Vertical set-out'), findsOneWidget);
      expect(find.text('Horizontal set-out'), findsOneWidget);
      expect(find.text('Save Combined'), findsNothing);
    });

    testWidgets('never renders visualization on calculator results step',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ViewResultsStep(
            user: _testUser(),
            verticalInputs: VerticalInputs(
              rafterHeights: const [
                {'label': 'Front Slope', 'value': 5000},
              ],
            ),
            horizontalInputs: HorizontalInputs(
              widths: const [
                {'label': 'Main Roof', 'value': 4200},
              ],
            ),
            calculationType: CalculationTypeSelection.both,
            lastVerticalCalculationData: const {'inputs': {}},
            lastHorizontalCalculationData: const {'inputs': {}},
            onBack: () {},
            onSaveCombined: (_) {},
            onSaveResult: (_, __, ___, {saveAction = SaveResultAction.saveAsNew}) async => null,
          ),
          _BothResultsCalculatorNotifier.new,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Vertical set-out'), findsOneWidget);
      expect(find.text('Horizontal set-out'), findsOneWidget);
      expect(find.text('Visualization'), findsNothing);
    });
  });
}