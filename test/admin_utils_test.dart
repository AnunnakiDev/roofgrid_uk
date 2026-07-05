import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/utils/admin_utils.dart';

void main() {
  UserModel user({
    String email = 'user@example.com',
    UserRole role = UserRole.free,
    DateTime? subscriptionEndDate,
  }) {
    return UserModel(
      id: 'u1',
      email: email,
      role: role,
      createdAt: DateTime(2026, 1, 1),
      subscriptionEndDate: subscriptionEndDate,
    );
  }

  group('isDesignatedAdminEmail', () {
    test('returns true for designated admin emails', () {
      expect(isDesignatedAdminEmail('hgwarner1307@gmail.com'), isTrue);
      expect(isDesignatedAdminEmail('support@roofgrid.uk'), isTrue);
    });

    test('is case insensitive', () {
      expect(isDesignatedAdminEmail('HGWarner1307@Gmail.COM'), isTrue);
      expect(isDesignatedAdminEmail('SUPPORT@ROOFGRID.UK'), isTrue);
    });

    test('returns false for non-admin emails', () {
      expect(isDesignatedAdminEmail('user@example.com'), isFalse);
      expect(isDesignatedAdminEmail('admin@example.com'), isFalse);
    });

    test('returns false for null', () {
      expect(isDesignatedAdminEmail(null), isFalse);
    });
  });

  group('needsDesignatedAdminProvisioning', () {
    test('true for designated email with free role', () {
      expect(
        needsDesignatedAdminProvisioning(
          user(email: 'hgwarner1307@gmail.com'),
        ),
        isTrue,
      );
    });

    test('true for designated email already admin without subscription', () {
      expect(
        needsDesignatedAdminProvisioning(
          user(email: 'hgwarner1307@gmail.com', role: UserRole.admin),
        ),
        isTrue,
      );
    });

    test('false for fully provisioned designated admin', () {
      expect(
        needsDesignatedAdminProvisioning(
          user(
            email: 'hgwarner1307@gmail.com',
            role: UserRole.admin,
            subscriptionEndDate: designatedAdminSubscriptionEnd,
          ),
        ),
        isFalse,
      );
    });

    test('false for regular users', () {
      expect(needsDesignatedAdminProvisioning(user()), isFalse);
    });
  });

  group('withDesignatedAdminDefaults', () {
    test('grants admin role and lifetime subscription', () {
      final updated = withDesignatedAdminDefaults(
        user(email: 'hgwarner1307@gmail.com', role: UserRole.free),
      );
      expect(updated.role, UserRole.admin);
      expect(updated.subscription, 'admin');
      expect(updated.subscriptionEndDate, designatedAdminSubscriptionEnd);
      expect(updated.proTrialStartDate, isNull);
      expect(updated.proTrialEndDate, isNull);
      expect(updated.isPro, isTrue);
      expect(updated.isAdmin, isTrue);
    });
  });

  group('initialRoleForEmail', () {
    test('returns admin for designated email', () {
      expect(
        initialRoleForEmail('hgwarner1307@gmail.com'),
        UserRole.admin,
      );
    });

    test('returns default for other emails', () {
      expect(
        initialRoleForEmail('other@example.com', defaultRole: UserRole.pro),
        UserRole.pro,
      );
    });
  });
}