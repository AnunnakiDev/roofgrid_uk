import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_backend_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_materials_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_section_panel.dart';

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

Widget _testApp(Widget child) {
  return ProviderScope(
    overrides: [
      labourBackendProvider.overrideWith(_TestLabourBackendNotifier.new),
      labourMaterialsProvider.overrideWith(_TestLabourMaterialsNotifier.new),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('LabourSectionList reflects add and remove via provider', (tester) async {
    await tester.pumpWidget(_testApp(const LabourSectionList()));

    expect(find.text('Add section'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LabourSectionList)),
    );
    final notifier = container.read(labourPricingProvider.notifier);

    expect(container.read(labourPricingProvider).project.sections.length, 1);

    notifier.addSection();
    await tester.pumpAndSettle();

    var sections = container.read(labourPricingProvider).project.sections;
    expect(sections.length, 2);
    expect(sections.map((s) => s.label), ['Section 1', 'Section 2']);

    notifier.removeSection(sections.last.id);
    await tester.pumpAndSettle();

    sections = container.read(labourPricingProvider).project.sections;
    expect(sections.length, 1);
    expect(sections.first.label, 'Section 1');
  });

  testWidgets('cannot remove last section', (tester) async {
    await tester.pumpWidget(_testApp(const LabourSectionList()));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LabourSectionList)),
    );
    final notifier = container.read(labourPricingProvider.notifier);
    notifier.removeSection(
      container.read(labourPricingProvider).project.sections.first.id,
    );
    await tester.pump();

    expect(
      container.read(labourPricingProvider).project.sections.length,
      1,
    );
  });
}