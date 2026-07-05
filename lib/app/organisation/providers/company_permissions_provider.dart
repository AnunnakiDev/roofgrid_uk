import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/organisation/company_permissions.dart';
import 'package:roofgrid_uk/app/organisation/models/company_role.dart';
import 'package:roofgrid_uk/app/organisation/providers/organisation_provider.dart';

final currentCompanyRoleProvider = Provider<CompanyRole?>((ref) {
  return ref.watch(currentOrgMembershipProvider).value?.role;
});

final canManageCompanyTeamProvider = Provider<bool>((ref) {
  return CompanyPermissions.canManageTeam(ref.watch(currentCompanyRoleProvider));
});

final canViewLabourPricingForCompanyProvider = Provider<bool>((ref) {
  return CompanyPermissions.canViewLabourPricing(
    ref.watch(currentCompanyRoleProvider),
  );
});

final canCreateQuotesForCompanyProvider = Provider<bool>((ref) {
  return CompanyPermissions.canCreateQuotes(
    ref.watch(currentCompanyRoleProvider),
  );
});

final canAssignJobsForCompanyProvider = Provider<bool>((ref) {
  return CompanyPermissions.canAssignJobs(
    ref.watch(currentCompanyRoleProvider),
  );
});

final isInstallerRoleProvider = Provider<bool>((ref) {
  return ref.watch(currentCompanyRoleProvider) == CompanyRole.installer;
});