import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/utils/layout_utils.dart';

void main() {
  test('isNarrowLayoutWidth uses 600px breakpoint', () {
    expect(isNarrowLayoutWidth(420), isTrue);
    expect(isNarrowLayoutWidth(599), isTrue);
    expect(isNarrowLayoutWidth(600), isFalse);
  });

  testWidgets('isNarrowLayout reads MediaQuery width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(420, 912)),
          child: Builder(
            builder: (context) {
              return Text(isNarrowLayout(context) ? 'narrow' : 'wide');
            },
          ),
        ),
      ),
    );

    expect(find.text('narrow'), findsOneWidget);
  });
}