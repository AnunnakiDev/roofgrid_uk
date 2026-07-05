import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/labour_pricing/utils/labour_quote_lookup.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job_status.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';

void main() {
  LabourSavedQuote quote({required String id, String name = 'Quote'}) {
    return LabourSavedQuote(
      id: id,
      name: name,
      savedAt: DateTime(2026, 5, 1),
      project: LabourQuoteProject.singleSection(
        input: const LabourQuoteInput(
          mode: LabourPricingMode.direct,
          roofType: LabourRoofType.plainTile,
          roofAreaSqm: 20,
        ),
      ),
      quoteConfig: const LabourQuoteConfig(),
    );
  }

  SavedResult savedResult({required String id, String? linkedQuoteId}) {
    final at = DateTime(2026, 5, 1);
    return SavedResult(
      id: id,
      userId: 'user-1',
      projectName: 'Project $id',
      type: CalculationType.vertical,
      tile: const {'id': 'tile-1', 'name': 'Plain'},
      inputs: const {},
      outputs: const {},
      timestamp: at,
      createdAt: at,
      updatedAt: at,
      linkedQuoteId: linkedQuoteId,
    );
  }

  OrgJob orgJob({required String id, String? linkedQuoteId}) {
    return OrgJob(
      id: id,
      orgId: 'org-1',
      projectName: 'Org $id',
      status: OrgJobStatus.surveyed,
      savedResultId: id,
      linkedQuoteId: linkedQuoteId,
      lockedTile: const {'id': 'tile-1', 'name': 'Plain'},
      inputs: const {},
      outputs: const {},
      calculationTypeIndex: CalculationType.vertical.index,
      createdByUserId: 'user-1',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );
  }

  group('labour quote lookup helpers', () {
    test('findLabourQuoteById returns matching quote', () {
      final quotes = [quote(id: 'q1', name: 'Alpha'), quote(id: 'q2')];

      final found = findLabourQuoteById(quotes, 'q1');

      expect(found?.name, 'Alpha');
    });

    test('savedResultsLinkedToQuote filters by linkedQuoteId', () {
      final results = [
        savedResult(id: 'job-1', linkedQuoteId: 'q1'),
        savedResult(id: 'job-2', linkedQuoteId: 'q2'),
        savedResult(id: 'job-3'),
      ];

      final linked = savedResultsLinkedToQuote(results, 'q1');

      expect(linked.map((r) => r.id), ['job-1']);
    });

    test('orgJobsLinkedToQuote filters by linkedQuoteId', () {
      final jobs = [
        orgJob(id: 'job-1', linkedQuoteId: 'q1'),
        orgJob(id: 'job-2'),
      ];

      final linked = orgJobsLinkedToQuote(jobs, 'q1');

      expect(linked.map((j) => j.id), ['job-1']);
    });
  });
}