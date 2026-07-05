import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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

  group('LabourQuotesFirestoreService CRUD', () {
    late FakeFirebaseFirestore firestore;
    late LabourQuotesFirestoreService service;
    const userId = 'user-labour-test';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = LabourQuotesFirestoreService(firestore: firestore);
    });

    test('saveQuote writes doc under users/{uid}/labour_quotes', () async {
      final quote = sampleQuote();

      await service.saveQuote(userId, quote);

      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('labour_quotes')
          .doc(quote.id)
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['name'], quote.name);
      expect(doc.data()?['id'], quote.id);
    });

    test('fetchQuotes returns saved quotes ordered newest first', () async {
      final older = sampleQuote().copyWith(
        id: 'quote_old',
        savedAt: DateTime(2026, 1, 1),
      );
      final newer = sampleQuote().copyWith(
        id: 'quote_new',
        savedAt: DateTime(2026, 6, 1),
      );

      await service.saveQuote(userId, older);
      await service.saveQuote(userId, newer);

      final fetched = await service.fetchQuotes(userId);

      expect(fetched.map((q) => q.id), ['quote_new', 'quote_old']);
    });

    test('deleteQuote removes document', () async {
      final quote = sampleQuote();
      await service.saveQuote(userId, quote);

      await service.deleteQuote(userId, quote.id);

      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('labour_quotes')
          .doc(quote.id)
          .get();
      expect(doc.exists, isFalse);
    });
  });
}