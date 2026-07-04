import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/utils/calculator_input_colors.dart';

void main() {
  test('calculatorInputColorForIndex returns stable theme-aligned colours', () {
    const primary = Color(0xFF1E3A5F);
    const accent = Color(0xFFBC4A2F);

    expect(
      calculatorInputColorForIndex(0, primary: primary, accent: accent),
      primary,
    );
    expect(
      calculatorInputColorForIndex(1, primary: primary, accent: accent),
      accent,
    );
    expect(
      calculatorInputColorForIndex(8, primary: primary, accent: accent),
      primary,
    );
  });

  testWidgets('calculatorInputColorFromTheme uses active color scheme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1E3A5F),
            secondary: Color(0xFFBC4A2F),
          ),
        ),
        home: Builder(
          builder: (context) {
            final color = calculatorInputColorFromTheme(context, 1);
            expect(color, const Color(0xFFBC4A2F));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}