import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_sync_utils.dart';

void main() {
  LabourSavedQuote quote({
    required String id,
    required DateTime savedAt,
    String name = 'Quote',
  }) {
    return LabourSavedQuote(
      id: id,
      name: name,
      savedAt: savedAt,
      project: LabourQuoteProject.singleSection(
        input: const LabourQuoteInput(
          mode: LabourPricingMode.direct,
          roofType: LabourRoofType.plainTile,
          roofAreaSqm: 30,
        ),
      ),
      quoteConfig: const LabourQuoteConfig(),
    );
  }

  group('LabourQuotesSyncUtils.mergeQuotes', () {
    test('remote newer replaces local for same id', () {
      final local = [quote(id: 'q1', savedAt: DateTime(2026, 1, 1))];
      final remote = [quote(id: 'q1', savedAt: DateTime(2026, 2, 1))];

      final merged = LabourQuotesSyncUtils.mergeQuotes(local, remote);

      expect(merged, hasLength(1));
      expect(merged.first.savedAt, remote.first.savedAt);
    });

    test('local newer keeps local for same id', () {
      final local = [quote(id: 'q1', savedAt: DateTime(2026, 3, 1))];
      final remote = [quote(id: 'q1', savedAt: DateTime(2026, 2, 1))];

      final merged = LabourQuotesSyncUtils.mergeQuotes(local, remote);

      expect(merged.first.savedAt, local.first.savedAt);
    });

    test('equal savedAt prefers remote', () {
      final at = DateTime(2026, 4, 1, 12);
      final local = [quote(id: 'q1', savedAt: at, name: 'Local')];
      final remote = [quote(id: 'q1', savedAt: at, name: 'Remote')];

      final merged = LabourQuotesSyncUtils.mergeQuotes(local, remote);

      expect(merged.first.name, 'Remote');
    });

    test('union merges distinct ids and sorts newest first', () {
      final local = [quote(id: 'q1', savedAt: DateTime(2026, 1, 1))];
      final remote = [quote(id: 'q2', savedAt: DateTime(2026, 6, 1))];

      final merged = LabourQuotesSyncUtils.mergeQuotes(local, remote);

      expect(merged.map((q) => q.id).toList(), ['q2', 'q1']);
    });
  });

  group('LabourQuotesSyncUtils.quotesNeedingUpload', () {
    test('includes local-only quotes', () {
      final local = [quote(id: 'q1', savedAt: DateTime(2026, 1, 1))];
      const remote = <LabourSavedQuote>[];

      final uploads = LabourQuotesSyncUtils.quotesNeedingUpload(local, remote);

      expect(uploads.map((q) => q.id), ['q1']);
    });

    test('includes local quote when newer than remote', () {
      final local = [quote(id: 'q1', savedAt: DateTime(2026, 3, 1))];
      final remote = [quote(id: 'q1', savedAt: DateTime(2026, 2, 1))];

      final uploads = LabourQuotesSyncUtils.quotesNeedingUpload(local, remote);

      expect(uploads, hasLength(1));
      expect(uploads.first.id, 'q1');
    });

    test('skips quote when remote is newer or equal', () {
      final local = [quote(id: 'q1', savedAt: DateTime(2026, 1, 1))];
      final remote = [quote(id: 'q1', savedAt: DateTime(2026, 2, 1))];

      final uploads = LabourQuotesSyncUtils.quotesNeedingUpload(local, remote);

      expect(uploads, isEmpty);
    });
  });
}