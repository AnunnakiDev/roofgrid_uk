import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_flow_step.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_step_progress.dart';

void main() {
  testWidgets('LabourStepProgress shows full labels when not compact',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabourStepProgress(
            currentStep: LabourFlowStep.materials,
            compact: false,
          ),
        ),
      ),
    );

    for (final label in LabourFlowStep.labels) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('LabourStepProgress hides labels in compact mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabourStepProgress(
            currentStep: LabourFlowStep.quote,
            compact: true,
          ),
        ),
      ),
    );

    for (final label in LabourFlowStep.labels) {
      expect(find.text(label), findsNothing);
    }

    expect(find.text('4'), findsOneWidget);
  });
}