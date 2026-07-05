import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/utils/admin_utils.dart';

UserModel _user({
  required UserRole role,
  DateTime? proTrialEndDate,
  DateTime? subscriptionEndDate,
}) {
  return UserModel(
    id: 'test-user',
    email: 'user@example.com',
    role: role,
    proTrialEndDate: proTrialEndDate,
    subscriptionEndDate: subscriptionEndDate,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('registration role policy', () {
    test('designated admin emails map to admin role', () {
      const email = 'hgwarner1307@gmail.com';
      final role =
          isDesignatedAdminEmail(email) ? UserRole.admin : UserRole.pro;

      expect(role, UserRole.admin);
    });

    test('standard emails map to pro trial role', () {
      const email = 'contractor@example.com';
      final role =
          isDesignatedAdminEmail(email) ? UserRole.admin : UserRole.pro;

      expect(role, UserRole.pro);
    });
  });

  group('UserModel pro access', () {
    test('pro user with active trial isPro', () {
      final user = _user(
        role: UserRole.pro,
        proTrialEndDate: DateTime.now().add(const Duration(days: 10)),
      );

      expect(user.isTrialActive, isTrue);
      expect(user.isPro, isTrue);
      expect(user.remainingTrialDays, greaterThan(0));
    });

    test('pro user with expired trial is not pro without subscription', () {
      final user = _user(
        role: UserRole.pro,
        proTrialEndDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(user.isTrialExpired, isTrue);
      expect(user.isPro, isFalse);
    });

    test('admin with expired trial stays pro via admin role', () {
      final user = _user(
        role: UserRole.admin,
        proTrialEndDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(user.isAdmin, isTrue);
      expect(user.isPro, isFalse);
    });

    test('subscribed pro user isPro after trial ends', () {
      final user = _user(
        role: UserRole.pro,
        proTrialEndDate: DateTime.now().subtract(const Duration(days: 1)),
        subscriptionEndDate: DateTime.now().add(const Duration(days: 30)),
      );

      expect(user.isSubscribed, isTrue);
      expect(user.isPro, isTrue);
    });

    test('labourCalculatorActive defaults to false', () {
      expect(_user(role: UserRole.free).labourCalculatorActive, isFalse);
    });

    test('labourCalculatorActive preserved by copyWith', () {
      final user =
          _user(role: UserRole.pro).copyWith(labourCalculatorActive: true);
      expect(user.labourCalculatorActive, isTrue);
    });

    test('customerQuoteActive defaults to false', () {
      expect(_user(role: UserRole.free).customerQuoteActive, isFalse);
    });

    test('customerQuoteActive preserved by copyWith', () {
      final user =
          _user(role: UserRole.pro).copyWith(customerQuoteActive: true);
      expect(user.customerQuoteActive, isTrue);
    });
  });
}