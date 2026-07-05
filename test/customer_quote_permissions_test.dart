import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/auth/providers/permissions_provider.dart';
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

  group('canAccessCustomerQuote', () {
    test('returns false for null user', () {
      expect(permissions.canAccessCustomerQuote(null), isFalse);
    });

    test('returns false without labour add-on', () {
      expect(
        permissions.canAccessCustomerQuote(
          user(customerQuoteActive: true),
        ),
        isFalse,
      );
    });

    test('returns false with labour only', () {
      expect(
        permissions.canAccessCustomerQuote(
          user(labourCalculatorActive: true),
        ),
        isFalse,
      );
    });

    test('returns true when both add-ons are active', () {
      expect(
        permissions.canAccessCustomerQuote(
          user(
            labourCalculatorActive: true,
            customerQuoteActive: true,
          ),
        ),
        isTrue,
      );
    });

    test('returns true for admin with labour access', () {
      expect(
        permissions.canAccessCustomerQuote(
          user(role: UserRole.admin, labourCalculatorActive: true),
        ),
        isTrue,
      );
    });
  });
}