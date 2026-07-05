import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/screens/labour/labour_pricing_upsell_screen.dart';
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

  testWidgets('upsell screen shows add-on messaging and CTAs', (tester) async {
    await tester.pumpWidget(
      themed(const LabourPricingUpsellScreen()),
    );

    expect(find.text('Labour Pricing Calculator'), findsOneWidget);
    expect(find.text('Separate add-on'), findsOneWidget);
    expect(find.text('Subscribe to labour add-on'), findsOneWidget);
    expect(find.text('Request add-on access'), findsOneWidget);
    expect(find.text('View set-out Pro plans'), findsOneWidget);
  });
}