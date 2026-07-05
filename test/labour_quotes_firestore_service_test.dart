import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_firestore_service.dart';

void main() {
  LabourSavedQuote sampleQuote() {
    return LabourSavedQuote(
      id: 'quote_test',
      name: 'Sample',
      savedAt: DateTime(2026, 5, 1),
      project: LabourQuoteProject.singleSection(
        input: const LabourQuoteInput(
          mode: LabourPricingMode.direct,
          roofType: LabourRoofType.traditionalPantile,
          roofAreaSqm: 45,
        ),
      ),
      quoteConfig: const LabourQuoteConfig(gangSize: 2),
    );
  }

  test('estimateDocumentBytes stays within safe limit for typical quote', () {
    final bytes = LabourQuotesFirestoreService.estimateDocumentBytes(
      sampleQuote(),
    );

    expect(bytes, lessThan(LabourQuotesFirestoreService.maxQuoteDocumentBytes));
    expect(bytes, greaterThan(100));
  });

  test('LabourSavedQuote round-trips Timestamp savedAt from Firestore payload',
      () {
    final original = sampleQuote();
    final payload = {
      ...original.toJson(),
      'savedAt': original.savedAt,
    };

    final restored = LabourSavedQuote.fromJson(payload);

    expect(restored.id, original.id);
    expect(restored.savedAt, original.savedAt);
  });
}