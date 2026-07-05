import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/organisation/models/job_assignment.dart';
import 'package:roofgrid_uk/app/organisation/models/org_invite.dart';
import 'package:roofgrid_uk/app/organisation/models/org_member.dart';
import 'package:roofgrid_uk/app/organisation/models/organisation.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job.dart';
import 'package:roofgrid_uk/app/organisation/services/organisation_service.dart';
import 'package:roofgrid_uk/app/organisation/services/org_job_service.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';

final organisationServiceProvider = Provider<OrganisationService>((ref) {
  return OrganisationService();
});

final orgJobServiceProvider = Provider<OrgJobService>((ref) {
  return OrgJobService();
});

final currentOrganisationProvider = StreamProvider<Organisation?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(null);
  return ref
      .watch(organisationServiceProvider)
      .watchOrganisation(user.primaryOrgId);
});

final currentOrgMembershipProvider = StreamProvider<OrgMember?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(organisationServiceProvider).watchMembership(
        orgId: user.primaryOrgId,
        userId: user.id,
      );
});

final orgMembersProvider = StreamProvider<List<OrgMember>>((ref) {
  final org = ref.watch(currentOrganisationProvider).value;
  if (org == null) return Stream.value(const []);
  return ref.watch(organisationServiceProvider).watchMembers(org.id);
});

final orgPendingInvitesProvider = StreamProvider<List<OrgInvite>>((ref) {
  final org = ref.watch(currentOrganisationProvider).value;
  if (org == null) return Stream.value(const []);
  return ref.watch(organisationServiceProvider).watchPendingInvites(org.id);
});

final orgJobsProvider = StreamProvider<List<OrgJob>>((ref) {
  final org = ref.watch(currentOrganisationProvider).value;
  if (org == null) return Stream.value(const []);
  return ref.watch(orgJobServiceProvider).watchOrgJobs(org.id);
});

final myAssignedOrgJobsProvider = StreamProvider<List<OrgJob>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  final orgId = user?.primaryOrgId;
  if (user == null || orgId == null || orgId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(orgJobServiceProvider).watchAssignedJobs(
        orgId: orgId,
        userId: user.id,
      );
});

final myJobAssignmentsProvider = StreamProvider<List<JobAssignment>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  final orgId = user?.primaryOrgId;
  if (user == null || orgId == null || orgId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(organisationServiceProvider).watchAssignmentsForUser(
        orgId: orgId,
        userId: user.id,
      );
});