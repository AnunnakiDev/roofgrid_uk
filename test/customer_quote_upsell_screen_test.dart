import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/screens/labour/customer_quote_upsell_screen.dart';
import 'package:roofgrid_uk/utils/app_theme.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';

void main() {
  Widget themed(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.themeFor(
          schemeId: AppColorSchemeId.slateProfessional,
          brightness: Brightness.light,
        ),
        home: child,
      ),
    );
  }

  testWidgets('customer quote upsell shows add-on messaging', (tester) async {
    await tester.pumpWidget(
      themed(const CustomerQuoteUpsellScreen()),
    );

    expect(find.text('Professional customer quotes'), findsOneWidget);
    expect(find.text('Separate add-on'), findsOneWidget);
    expect(find.text('Subscribe to customer quote'), findsOneWidget);
    expect(find.text('Request add-on access'), findsOneWidget);
  });
}