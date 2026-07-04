import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:roofgrid_uk/models/user_model.dart';

/// Emails that are automatically granted the admin role on sign-up or login.
///
/// Current designated admins:
/// - support@roofgrid.uk (production support account)
/// - hgwarner1307@gmail.com (project owner)
const designatedAdminEmails = {
  'support@roofgrid.uk',
  'hgwarner1307@gmail.com',
};

bool isDesignatedAdminEmail(String? email) {
  if (email == null) return false;
  return designatedAdminEmails.contains(email.toLowerCase());
}

/// Promotes a designated admin email to [UserRole.admin] in Firestore and Hive.
Future<UserModel> promoteDesignatedAdminIfNeeded(
  UserModel userModel,
  FirebaseFirestore firestore,
  Box<UserModel> userBox,
) async {
  if (!isDesignatedAdminEmail(userModel.email) ||
      userModel.role == UserRole.admin) {
    return userModel;
  }

  final updatedUser = userModel.copyWith(role: UserRole.admin);
  await firestore.collection('users').doc(userModel.id).set({
    'role': 'admin',
  }, SetOptions(merge: true));
  await userBox.put(userModel.id, updatedUser);
  return updatedUser;
}