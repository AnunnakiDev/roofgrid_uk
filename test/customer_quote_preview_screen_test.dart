import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/auth/providers/permissions_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/customer_quote_branding.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/customer_quote_branding_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_backend_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_materials_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_pricing_engine.dart';
import 'package:roofgrid_uk/screens/labour/customer_quote_preview_screen.dart';
import 'package:roofgrid_uk/utils/app_theme.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';

class _TestLabourBackendNotifier extends LabourBackendNotifier {
  @override
  LabourBackendState build() {
    return LabourBackendState(
      backendData: LabourDefaults.backendData2026,
      quoteConfig: const LabourQuoteConfig(),
      isHydrated: true,
    );
  }
}

class _TestLabourMaterialsNotifier extends LabourMaterialsNotifier {
  @override
  LabourMaterialsState build() {
    return const LabourMaterialsState(isHydrated: true);
  }
}

class _TestCustomerQuoteBrandingNotifier extends CustomerQuoteBrandingNotifier {
  @override
  CustomerQuoteBrandingState build() {
    return const CustomerQuoteBrandingState(
      branding: CustomerQuoteBranding(companyName: 'Test Roofing Ltd'),
      isHydrated: true,
    );
  }
}

class _TestLabourPricingNotifier extends LabourPricingNotifier {
  @override
  LabourPricingState build() {
    const config = LabourQuoteConfig();
    final backend = LabourDefaults.backendData2026;
    final project = LabourQuoteProject(
      sections: [
        const LabourRoofSection(
          id: 's1',
          label: 'Main roof',
          input: LabourQuoteInput(
            mode: LabourPricingMode.direct,
            roofType: LabourRoofType.traditionalPantile,
            roofAreaSqm: 40,
          ),
        ),
      ],
    );
    final projectResult = LabourPricingEngine.calculateProject(
      project: project,
      backend: backend,
      config: config,
    );
    return LabourPricingState(
      project: project,
      quoteConfig: config,
      projectResult: projectResult,
    );
  }
}

void main() {
  Widget themed(Widget child) {
    return ProviderScope(
      overrides: [
        canAccessCustomerQuoteProvider.overrideWithValue(true),
        labourBackendProvider.overrideWith(_TestLabourBackendNotifier.new),
        labourMaterialsProvider.overrideWith(_TestLabourMaterialsNotifier.new),
        labourPricingProvider.overrideWith(_TestLabourPricingNotifier.new),
        customerQuoteBrandingProvider
            .overrideWith(_TestCustomerQuoteBrandingNotifier.new),
      ],
      child: MaterialApp(
        theme: AppTheme.themeFor(
          schemeId: AppColorSchemeId.slateProfessional,
          brightness: Brightness.light,
        ),
        home: child,
      ),
    );
  }

  testWidgets('customer quote preview renders branded layout when entitled',
      (tester) async {
    await tester.pumpWidget(
      themed(const CustomerQuotePreviewScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer Quote'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Test Roofing Ltd'), findsOneWidget);
    expect(find.text('QUOTATION'), findsOneWidget);
    expect(find.text('Quoted works'), findsOneWidget);
    expect(find.text('Total quotation'), findsOneWidget);
    expect(find.textContaining('Main roof'), findsOneWidget);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
  });
}