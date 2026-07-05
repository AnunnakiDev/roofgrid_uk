/// Role within a roofing company account (separate from subscription UserRole).
enum CompanyRole {
  owner,
  estimator,
  installer,
}

extension CompanyRoleLabels on CompanyRole {
  String get label {
    switch (this) {
      case CompanyRole.owner:
        return 'Owner';
      case CompanyRole.estimator:
        return 'Estimator';
      case CompanyRole.installer:
        return 'Installer';
    }
  }
}

CompanyRole companyRoleFromName(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'owner':
      return CompanyRole.owner;
    case 'estimator':
      return CompanyRole.estimator;
    case 'installer':
      return CompanyRole.installer;
    default:
      return CompanyRole.installer;
  }
}