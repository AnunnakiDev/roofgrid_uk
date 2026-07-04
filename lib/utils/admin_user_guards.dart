import 'package:roofgrid_uk/models/user_model.dart';

/// Client-side validation before admin delete API calls.
String? validateAdminDeleteTarget({
  required UserModel target,
  required String? currentUserId,
}) {
  if (currentUserId != null && target.id == currentUserId) {
    return 'You cannot delete your own account.';
  }
  if (target.role == UserRole.admin) {
    return 'Admin accounts cannot be deleted from the app.';
  }
  return null;
}