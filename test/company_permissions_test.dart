import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/organisation/company_permissions.dart';
import 'package:roofgrid_uk/app/organisation/models/company_role.dart';

void main() {
  group('CompanyPermissions', () {
    test('owner can manage team and view labour pricing', () {
      expect(CompanyPermissions.canManageTeam(CompanyRole.owner), isTrue);
      expect(CompanyPermissions.canViewLabourPricing(CompanyRole.owner), isTrue);
      expect(CompanyPermissions.canCreateQuotes(CompanyRole.owner), isTrue);
    });

    test('estimator can quote but not manage team', () {
      expect(CompanyPermissions.canManageTeam(CompanyRole.estimator), isFalse);
      expect(CompanyPermissions.canViewLabourPricing(CompanyRole.estimator), isTrue);
      expect(CompanyPermissions.canCreateQuotes(CompanyRole.estimator), isTrue);
      expect(CompanyPermissions.canEditLabourRates(CompanyRole.estimator), isFalse);
    });

    test('installer can run set-out but not labour pricing', () {
      expect(CompanyPermissions.canRunSetOut(CompanyRole.installer), isTrue);
      expect(CompanyPermissions.canViewLabourPricing(CompanyRole.installer), isFalse);
      expect(CompanyPermissions.canCreateQuotes(CompanyRole.installer), isFalse);
    });

    test('solo users without company role keep full access', () {
      expect(CompanyPermissions.canViewLabourPricing(null), isTrue);
      expect(CompanyPermissions.canCreateQuotes(null), isTrue);
    });
  });
}