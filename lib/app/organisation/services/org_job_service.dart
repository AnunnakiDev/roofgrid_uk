import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job_status.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

class OrgJobService {
  final FirebaseFirestore _firestore;

  OrgJobService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _jobs(String orgId) =>
      _firestore.collection('organisations').doc(orgId).collection('jobs');

  Future<OrgJob> upsertFromSavedResult({
    required String orgId,
    required SavedResult result,
    OrgJobStatus? status,
  }) async {
    final now = DateTime.now();
    final ref = _jobs(orgId).doc(result.id);
    final existing = await ref.get();

    final nextStatus = status ??
        (existing.exists
            ? OrgJob.fromFirestore(existing).status
            : OrgJobStatus.surveyed);

    final job = OrgJob(
      id: result.id,
      orgId: orgId,
      projectName: result.projectName,
      status: nextStatus,
      savedResultId: result.id,
      linkedQuoteId: result.linkedQuoteId,
      lockedTile: Map<String, dynamic>.from(result.tile),
      inputs: Map<String, dynamic>.from(result.inputs),
      outputs: Map<String, dynamic>.from(result.outputs),
      calculationTypeIndex: result.type.index,
      createdByUserId: result.userId,
      createdAt: existing.exists
          ? OrgJob.fromFirestore(existing).createdAt
          : now,
      updatedAt: now,
    );

    await ref.set(job.toFirestoreJson(), SetOptions(merge: true));
    return job;
  }

  Future<void> updateStatus({
    required String orgId,
    required String jobId,
    required OrgJobStatus status,
  }) async {
    await _jobs(orgId).doc(jobId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> linkQuote({
    required String orgId,
    required String jobId,
    required String quoteId,
  }) async {
    await _jobs(orgId).doc(jobId).set({
      'linkedQuoteId': quoteId,
      'status': OrgJobStatus.quoted.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Future<void> unlinkQuote({
    required String orgId,
    required String jobId,
  }) async {
    await _jobs(orgId).doc(jobId).update({
      'linkedQuoteId': FieldValue.delete(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> assignToInstaller({
    required String orgId,
    required String jobId,
    required String installerUserId,
  }) async {
    await _jobs(orgId).doc(jobId).set({
      'assignedToUserId': installerUserId,
      'status': OrgJobStatus.onSite.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Stream<List<OrgJob>> watchOrgJobs(String orgId) {
    return _jobs(orgId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => OrgJob.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<OrgJob>> watchAssignedJobs({
    required String orgId,
    required String userId,
  }) {
    return _jobs(orgId)
        .where('assignedToUserId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => OrgJob.fromFirestore(doc)).toList(),
        );
  }

  Future<OrgJob?> fetchJob({
    required String orgId,
    required String jobId,
  }) async {
    final doc = await _jobs(orgId).doc(jobId).get();
    if (!doc.exists) return null;
    return OrgJob.fromFirestore(doc);
  }
}