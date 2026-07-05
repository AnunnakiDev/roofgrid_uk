import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_backend_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_materials_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/widgets/labour/labour_rates_editor.dart';

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

void main() {
  testWidgets('LabourRatesEditor shows pricing fields and reset', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          labourBackendProvider.overrideWith(_TestLabourBackendNotifier.new),
          labourMaterialsProvider.overrideWith(_TestLabourMaterialsNotifier.new),
        ],
        child: const MaterialApp(
          home: Scaffold(body: LabourRatesEditor()),
        ),
      ),
    );

    expect(find.text('Labour rates'), findsOneWidget);
    expect(find.text('Export JSON'), findsOneWidget);
    expect(find.text('Import JSON'), findsOneWidget);
    expect(find.text('Pricing'), findsOneWidget);
    expect(find.text('Linear'), findsOneWidget);
    expect(find.text('Config'), findsOneWidget);
    expect(find.text('Materials'), findsOneWidget);
  });
}