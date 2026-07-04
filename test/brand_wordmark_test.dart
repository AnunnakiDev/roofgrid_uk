import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/widgets/brand_wordmark.dart';

void main() {
  testWidgets('BrandWordmark renders ROOFGRID text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrandWordmark(),
        ),
      ),
    );

    expect(find.text('ROOFGRID'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('BrandWordmark.compact uses smaller styling', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrandWordmark.compact(),
        ),
      ),
    );

    expect(find.text('ROOFGRID'), findsOneWidget);
    final text = tester.widget<Text>(find.text('ROOFGRID'));
    expect(text.style?.fontSize, 22);
  });
}