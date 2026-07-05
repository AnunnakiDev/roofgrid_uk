import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgrid_uk/app/organisation/models/company_role.dart';
import 'package:roofgrid_uk/app/organisation/models/job_assignment.dart';
import 'package:roofgrid_uk/app/organisation/models/org_invite.dart';
import 'package:roofgrid_uk/app/organisation/models/org_member.dart';
import 'package:roofgrid_uk/app/organisation/models/organisation.dart';
import 'package:roofgrid_uk/models/user_model.dart';

class OrganisationService {
  final FirebaseFirestore _firestore;

  OrganisationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orgs =>
      _firestore.collection('organisations');

  Future<Organisation> createOrganisation({
    required String name,
    required UserModel owner,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Company name is required');
    }

    final orgRef = _orgs.doc();
    final now = DateTime.now();
    final org = Organisation(
      id: orgRef.id,
      name: trimmed,
      createdByUserId: owner.id,
      createdAt: now,
    );

    final ownerMember = OrgMember(
      orgId: org.id,
      userId: owner.id,
      role: CompanyRole.owner,
      email: owner.email,
      displayName: owner.displayName,
      joinedAt: now,
    );

    final batch = _firestore.batch();
    batch.set(orgRef, org.toFirestoreJson());
    batch.set(
      orgRef.collection('members').doc(owner.id),
      ownerMember.toFirestoreJson(),
    );
    batch.update(
      _firestore.collection('users').doc(owner.id),
      {
        'primaryOrgId': org.id,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
    return org;
  }

  Stream<Organisation?> watchOrganisation(String? orgId) {
    if (orgId == null || orgId.isEmpty) {
      return Stream<Organisation?>.value(null);
    }
    return _orgs.doc(orgId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Organisation.fromFirestore(doc);
    });
  }

  Stream<OrgMember?> watchMembership({
    required String? orgId,
    required String userId,
  }) {
    if (orgId == null || orgId.isEmpty) {
      return Stream<OrgMember?>.value(null);
    }
    return _orgs
        .doc(orgId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return OrgMember.fromFirestore(orgId, doc);
    });
  }

  Stream<List<OrgMember>> watchMembers(String orgId) {
    return _orgs
        .doc(orgId)
        .collection('members')
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrgMember.fromFirestore(orgId, doc))
              .toList(),
        );
  }

  Stream<List<OrgInvite>> watchPendingInvites(String orgId) {
    return _orgs
        .doc(orgId)
        .collection('invites')
        .where('status', isEqualTo: OrgInviteStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => OrgInvite.fromFirestore(doc)).toList(),
        );
  }

  Future<void> inviteMember({
    required Organisation org,
    required UserModel inviter,
    required String email,
    required CompanyRole role,
    required int currentMemberCount,
    required int pendingInviteCount,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw ArgumentError('Enter a valid email address');
    }
    if (role == CompanyRole.owner) {
      throw ArgumentError('Cannot invite another owner');
    }
    if (currentMemberCount + pendingInviteCount >= org.seatLimit) {
      throw StateError('Seat limit reached (${org.seatLimit})');
    }

    final inviteRef =
        _orgs.doc(org.id).collection('invites').doc();
    final invite = OrgInvite(
      id: inviteRef.id,
      orgId: org.id,
      email: normalized,
      role: role,
      invitedByUserId: inviter.id,
      createdAt: DateTime.now(),
    );
    await inviteRef.set(invite.toFirestoreJson());
  }

  Future<int> acceptPendingInvitesForUser(UserModel user) async {
    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return 0;

    final snapshot = await _firestore
        .collectionGroup('invites')
        .where('email', isEqualTo: email)
        .where('status', isEqualTo: OrgInviteStatus.pending.name)
        .get();

    var accepted = 0;
    for (final doc in snapshot.docs) {
      final invite = OrgInvite.fromFirestore(doc);
      final member = OrgMember(
        orgId: invite.orgId,
        userId: user.id,
        role: invite.role,
        email: user.email,
        displayName: user.displayName,
        joinedAt: DateTime.now(),
      );

      final batch = _firestore.batch();
      batch.set(
        _orgs.doc(invite.orgId).collection('members').doc(user.id),
        member.toFirestoreJson(),
      );
      batch.update(doc.reference, {'status': OrgInviteStatus.accepted.name});
      if (user.primaryOrgId == null || user.primaryOrgId!.isEmpty) {
        batch.update(
          _firestore.collection('users').doc(user.id),
          {
            'primaryOrgId': invite.orgId,
            'lastUpdated': FieldValue.serverTimestamp(),
          },
        );
      }
      await batch.commit();
      accepted++;
    }
    return accepted;
  }

  Future<void> assignJobToInstaller({
    required String orgId,
    required String savedResultId,
    required String projectName,
    required String installerUserId,
    required String assignedByUserId,
  }) async {
    final assignmentRef =
        _orgs.doc(orgId).collection('assignments').doc();
    final assignment = JobAssignment(
      id: assignmentRef.id,
      orgId: orgId,
      savedResultId: savedResultId,
      projectName: projectName,
      assignedToUserId: installerUserId,
      assignedByUserId: assignedByUserId,
      status: JobAssignmentStatus.assigned,
      assignedAt: DateTime.now(),
    );
    await assignmentRef.set(assignment.toFirestoreJson());
  }

  Stream<List<JobAssignment>> watchAssignmentsForUser({
    required String orgId,
    required String userId,
  }) {
    return _orgs
        .doc(orgId)
        .collection('assignments')
        .where('assignedToUserId', isEqualTo: userId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JobAssignment.fromFirestore(doc))
              .toList(),
        );
  }
}