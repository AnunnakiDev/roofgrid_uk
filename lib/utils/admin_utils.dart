import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:roofgrid_uk/models/user_model.dart';

/// Emails that are automatically granted admin + Pro access on sign-up or login.
///
/// Current designated admins:
/// - support@roofgrid.uk (production support account)
/// - hgwarner1307@gmail.com (project owner)
const designatedAdminEmails = {
  'support@roofgrid.uk',
  'hgwarner1307@gmail.com',
};

/// Lifetime Pro entitlement for designated admin accounts.
final DateTime designatedAdminSubscriptionEnd = DateTime.utc(2099, 12, 31);

bool isDesignatedAdminEmail(String? email) {
  if (email == null) return false;
  return designatedAdminEmails.contains(email.trim().toLowerCase());
}

/// Whether a designated admin still needs role/subscription provisioning.
bool needsDesignatedAdminProvisioning(UserModel user) {
  if (!isDesignatedAdminEmail(user.email)) return false;
  return user.role != UserRole.admin ||
      user.subscriptionEndDate == null ||
      !user.subscriptionEndDate!.isAfter(DateTime.now());
}

/// Applies admin role and lifetime Pro subscription fields.
UserModel withDesignatedAdminDefaults(UserModel user) {
  return UserModel(
    id: user.id,
    email: user.email,
    displayName: user.displayName,
    photoURL: user.photoURL,
    phone: user.phone,
    subscription: user.subscription ?? 'admin',
    profileImage: user.profileImage,
    role: UserRole.admin,
    proTrialStartDate: null,
    proTrialEndDate: null,
    subscriptionEndDate: designatedAdminSubscriptionEnd,
    createdAt: user.createdAt,
    lastLoginAt: user.lastLoginAt,
    labourCalculatorActive: user.labourCalculatorActive,
    customerQuoteActive: user.customerQuoteActive,
  );
}

Map<String, dynamic> designatedAdminFirestoreFields() {
  return {
    'role': 'admin',
    'subscription': 'admin',
    'subscriptionEndDate': Timestamp.fromDate(designatedAdminSubscriptionEnd),
    'proTrialStartDate': FieldValue.delete(),
    'proTrialEndDate': FieldValue.delete(),
  };
}

/// New-user role for sign-up: designated emails become admin, others follow [defaultRole].
UserRole initialRoleForEmail(
  String? email, {
  UserRole defaultRole = UserRole.free,
}) {
  return isDesignatedAdminEmail(email) ? UserRole.admin : defaultRole;
}

/// Builds a new user model with designated admin defaults when applicable.
UserModel newUserModelForAuthUser(
  User user, {
  UserRole defaultRole = UserRole.free,
  DateTime? proTrialStartDate,
  DateTime? proTrialEndDate,
  DateTime? createdAt,
  DateTime? lastLoginAt,
}) {
  final base = UserModel.fromFirebaseUser(
    user,
    role: initialRoleForEmail(user.email, defaultRole: defaultRole),
    proTrialStartDate: proTrialStartDate,
    proTrialEndDate: proTrialEndDate,
    createdAt: createdAt,
    lastLoginAt: lastLoginAt,
  );
  if (!isDesignatedAdminEmail(user.email)) return base;
  return withDesignatedAdminDefaults(base);
}

/// Ensures designated admin emails have admin + Pro in Firestore and Hive.
Future<UserModel> promoteDesignatedAdminIfNeeded(
  UserModel userModel,
  FirebaseFirestore firestore,
  Box<UserModel> userBox,
) async {
  if (!needsDesignatedAdminProvisioning(userModel)) {
    return userModel;
  }

  final updatedUser = withDesignatedAdminDefaults(userModel);
  await firestore.collection('users').doc(userModel.id).set(
        designatedAdminFirestoreFields(),
        SetOptions(merge: true),
      );
  await userBox.put(userModel.id, updatedUser);
  return updatedUser;
}