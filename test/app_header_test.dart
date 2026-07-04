import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/widgets/app_header.dart';

void main() {
  testWidgets('AppHeader hides menu button when showMenuButton is false',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppHeader(
            title: 'Roofing Calculator',
            showMenuButton: false,
          ),
        ),
      ),
    );

    expect(find.byTooltip('Open navigation drawer'), findsNothing);
    expect(find.text('Roofing Calculator'), findsOneWidget);
  });
}