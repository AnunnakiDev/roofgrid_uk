import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job_status.dart';
import 'package:roofgrid_uk/app/organisation/utils/org_job_saved_result.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

void main() {
  group('OrgJobStatus', () {
    test('parses known status names', () {
      expect(orgJobStatusFromName('quoted'), OrgJobStatus.quoted);
      expect(orgJobStatusFromName('onSite'), OrgJobStatus.onSite);
    });

    test('defaults unknown status to surveyed', () {
      expect(orgJobStatusFromName('invalid'), OrgJobStatus.surveyed);
      expect(orgJobStatusFromName(null), OrgJobStatus.surveyed);
    });

    test('labels are human readable', () {
      expect(OrgJobStatus.onSite.label, 'On site');
      expect(OrgJobStatus.complete.label, 'Complete');
    });
  });

  group('OrgJob', () {
    final createdAt = DateTime(2026, 7, 1, 10);
    final updatedAt = DateTime(2026, 7, 2, 12);

    OrgJob buildJob({Map<String, dynamic>? lockedTile}) {
      return OrgJob(
        id: 'job-1',
        orgId: 'org-1',
        projectName: '12 Oak Street',
        status: OrgJobStatus.surveyed,
        savedResultId: 'job-1',
        lockedTile: lockedTile ??
            const {
              'id': 'tile-1',
              'name': 'Marley Modern',
            },
        inputs: const {'vertical_inputs': {'gutterOverhang': 50}},
        outputs: const {'solution': 'Valid'},
        calculationTypeIndex: 2,
        createdByUserId: 'owner-1',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    test('toFirestoreJson round-trips core fields', () {
      final job = buildJob();
      final json = job.toFirestoreJson();

      expect(json['id'], 'job-1');
      expect(json['orgId'], 'org-1');
      expect(json['projectName'], '12 Oak Street');
      expect(json['status'], 'surveyed');
      expect(json['lockedTile'], isA<Map>());
      expect(json['calculationTypeIndex'], 2);
    });

    test('toSavedResult preserves tile and metadata', () {
      final job = buildJob();
      final result = job.toSavedResult();

      expect(result.id, 'job-1');
      expect(result.userId, 'owner-1');
      expect(result.projectName, '12 Oak Street');
      expect(result.type, CalculationType.combined);
      expect(result.tile['name'], 'Marley Modern');
    });

    test('savedResultFromOrgJob returns null without tile', () {
      final job = buildJob(lockedTile: {});
      expect(savedResultFromOrgJob(job), isNull);
    });

    test('copyWith can clear assignment and quote', () {
      final job = buildJob().copyWith(
        linkedQuoteId: 'quote-1',
        assignedToUserId: 'installer-1',
      );
      final cleared = job.copyWith(clearAssignedTo: true, clearLinkedQuote: true);

      expect(cleared.linkedQuoteId, isNull);
      expect(cleared.assignedToUserId, isNull);
    });
  });
}