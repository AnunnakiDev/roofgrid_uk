import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/widgets/admin_access_guard.dart';

void main() {
  group('isAdminUser', () {
    test('returns true for admin role', () {
      final user = UserModel(
        id: '1',
        email: 'admin@test.com',
        role: UserRole.admin,
        createdAt: DateTime(2026),
      );
      expect(isAdminUser(user), isTrue);
    });

    test('returns false for pro and free users', () {
      final proUser = UserModel(
        id: '2',
        email: 'pro@test.com',
        role: UserRole.pro,
        createdAt: DateTime(2026),
      );
      final freeUser = UserModel(
        id: '3',
        email: 'free@test.com',
        role: UserRole.free,
        createdAt: DateTime(2026),
      );

      expect(isAdminUser(proUser), isFalse);
      expect(isAdminUser(freeUser), isFalse);
      expect(isAdminUser(null), isFalse);
    });
  });
}