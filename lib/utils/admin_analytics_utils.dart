import 'package:roofgrid_uk/models/user_model.dart';

/// Non-admin accounts counted in platform user totals.
bool isNonAdminUser(UserModel user) => user.role != UserRole.admin;

/// Active paid subscription or Pro trial ending within [withinDays] (inclusive).
bool isMembershipExpiringSoon(
  UserModel user,
  DateTime now, {
  int withinDays = 30,
}) {
  if (!isNonAdminUser(user)) return false;

  final candidates = <DateTime>[];

  if (user.subscriptionEndDate != null &&
      user.subscriptionEndDate!.isAfter(now)) {
    candidates.add(user.subscriptionEndDate!);
  }

  if (user.proTrialEndDate != null && user.proTrialEndDate!.isAfter(now)) {
    candidates.add(user.proTrialEndDate!);
  }

  if (candidates.isEmpty) return false;

  final nearestExpiry = candidates.reduce(
    (a, b) => a.isBefore(b) ? a : b,
  );
  final daysRemaining = nearestExpiry.difference(now).inDays;
  return daysRemaining >= 0 && daysRemaining <= withinDays;
}

/// Counts non-admin users from Firestore user documents.
int countNonAdminUsers(Iterable<UserModel> users) =>
    users.where(isNonAdminUser).length;

/// Pending pro personal tile submissions (private, not yet approved).
bool isPendingPersonalTile(Map<String, dynamic> data) {
  final isPublic = data['isPublic'] as bool? ?? true;
  final isApproved = data['isApproved'] as bool? ?? false;
  return !isPublic && !isApproved;
}

const String firebaseAnalyticsConsoleUrl =
    'https://console.firebase.google.com/project/roofgriduk-f2f56/analytics/app';