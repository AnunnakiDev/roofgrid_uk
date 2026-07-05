import 'package:roofgrid_uk/app/organisation/models/company_role.dart';

/// Pure role-based feature gates for company accounts.
class CompanyPermissions {
  const CompanyPermissions._();

  static bool canManageTeam(CompanyRole? role) => role == CompanyRole.owner;

  static bool canInviteMembers(CompanyRole? role) => role == CompanyRole.owner;

  static bool canViewLabourPricing(CompanyRole? role) {
    if (role == null) return true;
    return role == CompanyRole.owner || role == CompanyRole.estimator;
  }

  static bool canEditLabourRates(CompanyRole? role) {
    if (role == null) return true;
    return role == CompanyRole.owner;
  }

  static bool canCreateQuotes(CompanyRole? role) {
    if (role == null) return true;
    return role == CompanyRole.owner || role == CompanyRole.estimator;
  }

  static bool canAssignJobs(CompanyRole? role) {
    if (role == null) return true;
    return role == CompanyRole.owner || role == CompanyRole.estimator;
  }

  static bool canRunSetOut(CompanyRole? role) {
    if (role == null) return true;
    return true;
  }

  static bool canViewQuoteMargins(CompanyRole? role) {
    if (role == null) return true;
    return role == CompanyRole.owner || role == CompanyRole.estimator;
  }
}