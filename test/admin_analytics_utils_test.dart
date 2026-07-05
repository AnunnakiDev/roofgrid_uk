import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/utils/admin_analytics_utils.dart';

void main() {
  final now = DateTime(2026, 7, 4);

  UserModel user({
    UserRole role = UserRole.free,
    DateTime? subscriptionEndDate,
    DateTime? proTrialEndDate,
  }) {
    return UserModel(
      id: 'u1',
      role: role,
      createdAt: DateTime(2026, 1, 1),
      subscriptionEndDate: subscriptionEndDate,
      proTrialEndDate: proTrialEndDate,
    );
  }

  group('isNonAdminUser', () {
    test('returns false for admin', () {
      expect(isNonAdminUser(user(role: UserRole.admin)), isFalse);
    });

    test('returns true for free and pro', () {
      expect(isNonAdminUser(user()), isTrue);
      expect(isNonAdminUser(user(role: UserRole.pro)), isTrue);
    });
  });

  group('countNonAdminUsers', () {
    test('excludes admins', () {
      final count = countNonAdminUsers([
        user(),
        user(role: UserRole.pro),
        user(role: UserRole.admin),
      ]);
      expect(count, 2);
    });
  });

  group('isMembershipExpiringSoon', () {
    test('detects subscription expiring within 30 days', () {
      final u = user(
        role: UserRole.pro,
        subscriptionEndDate: now.add(const Duration(days: 14)),
      );
      expect(isMembershipExpiringSoon(u, now), isTrue);
    });

    test('detects trial expiring within 30 days', () {
      final u = user(
        role: UserRole.pro,
        proTrialEndDate: now.add(const Duration(days: 7)),
      );
      expect(isMembershipExpiringSoon(u, now), isTrue);
    });

    test('ignores free users', () {
      expect(isMembershipExpiringSoon(user(), now), isFalse);
    });

    test('ignores admin users', () {
      final u = user(
        role: UserRole.admin,
        subscriptionEndDate: now.add(const Duration(days: 3)),
      );
      expect(isMembershipExpiringSoon(u, now), isFalse);
    });

    test('ignores expiry beyond 30 days', () {
      final u = user(
        role: UserRole.pro,
        subscriptionEndDate: now.add(const Duration(days: 45)),
      );
      expect(isMembershipExpiringSoon(u, now), isFalse);
    });
  });

  group('isPendingPersonalTile', () {
    test('true for private unapproved tiles', () {
      expect(
        isPendingPersonalTile({'isPublic': false, 'isApproved': false}),
        isTrue,
      );
    });

    test('false for approved private tiles', () {
      expect(
        isPendingPersonalTile({'isPublic': false, 'isApproved': true}),
        isFalse,
      );
    });

    test('false for public tiles', () {
      expect(
        isPendingPersonalTile({'isPublic': true, 'isApproved': false}),
        isFalse,
      );
    });
  });
}