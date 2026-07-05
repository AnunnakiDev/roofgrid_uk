import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/auth/providers/permissions_provider.dart';
import 'package:roofgrid_uk/models/developer_mode_config.dart';
import 'package:roofgrid_uk/models/user_model.dart';

void main() {
  const permissions = PermissionsService();

  UserModel user({
    UserRole role = UserRole.free,
    bool labourCalculatorActive = false,
    bool customerQuoteActive = false,
  }) {
    return UserModel(
      id: 'u1',
      email: 'user@example.com',
      role: role,
      labourCalculatorActive: labourCalculatorActive,
      customerQuoteActive: customerQuoteActive,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('canAccessLabourCalculator', () {
    test('returns false for null user', () {
      expect(permissions.canAccessLabourCalculator(null), isFalse);
    });

    test('returns false for free user without add-on', () {
      expect(permissions.canAccessLabourCalculator(user()), isFalse);
    });

    test('returns true when labour add-on is active', () {
      expect(
        permissions.canAccessLabourCalculator(
          user(labourCalculatorActive: true),
        ),
        isTrue,
      );
    });

    test('returns true for admin without add-on flag', () {
      expect(
        permissions.canAccessLabourCalculator(user(role: UserRole.admin)),
        isTrue,
      );
    });

    test('is independent from set-out pro status', () {
      final proWithoutLabour = user(
        role: UserRole.pro,
        labourCalculatorActive: false,
      );
      expect(proWithoutLabour.isPro, isFalse);
      expect(permissions.canAccessLabourCalculator(proWithoutLabour), isFalse);
    });
  });

  group('canAccessCustomerQuote', () {
    test('requires labour add-on before customer quote', () {
      expect(
        permissions.canAccessCustomerQuote(
          user(customerQuoteActive: true),
        ),
        isFalse,
      );
    });
  });
}