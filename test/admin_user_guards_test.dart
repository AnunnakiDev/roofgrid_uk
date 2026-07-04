import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/utils/admin_user_guards.dart';

UserModel _user({
  required String id,
  UserRole role = UserRole.free,
}) {
  return UserModel(
    id: id,
    email: '$id@example.com',
    role: role,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('validateAdminDeleteTarget', () {
    test('blocks deleting self', () {
      final user = _user(id: 'admin-1', role: UserRole.admin);
      expect(
        validateAdminDeleteTarget(target: user, currentUserId: 'admin-1'),
        'You cannot delete your own account.',
      );
    });

    test('blocks deleting admin accounts', () {
      final user = _user(id: 'other-admin', role: UserRole.admin);
      expect(
        validateAdminDeleteTarget(target: user, currentUserId: 'admin-1'),
        'Admin accounts cannot be deleted from the app.',
      );
    });

    test('allows deleting non-admin users', () {
      final user = _user(id: 'free-user', role: UserRole.free);
      expect(
        validateAdminDeleteTarget(target: user, currentUserId: 'admin-1'),
        isNull,
      );
    });
  });
}