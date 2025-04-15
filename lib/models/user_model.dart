// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Enum representing user roles in the RoofGrid UK app.
enum UserRole {
  free,
  pro,
  admin,
}

/// Model class representing a user with authentication and subscription details.
class UserModel {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final UserRole role;
  final DateTime? proTrialStartDate;
  final DateTime? proTrialEndDate;
  final DateTime? subscriptionEndDate;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.photoURL,
    this.role = UserRole.free,
    this.proTrialStartDate,
    this.proTrialEndDate,
    this.subscriptionEndDate,
    this.isAdmin = false,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Creates a UserModel from a Firebase User object.
  UserModel.fromFirebaseUser(
    User user, {
    UserRole role = UserRole.free,
    bool isPro = false,
    DateTime? proTrialStartDate,
    DateTime? proTrialEndDate,
    DateTime? subscriptionEndDate,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) : this(
          id: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoURL: user.photoURL,
          role: isPro
              ? UserRole.pro
              : (isAdmin == true ? UserRole.admin : UserRole.free),
          proTrialStartDate: proTrialStartDate,
          proTrialEndDate: proTrialEndDate,
          subscriptionEndDate: subscriptionEndDate,
          isAdmin: isAdmin ?? false,
          createdAt: createdAt ?? DateTime.now(),
          lastLoginAt: lastLoginAt ?? DateTime.now(),
        );

  /// Creates a UserModel from a Firestore DocumentSnapshot.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('User data not found for ID: ${doc.id}');
    }

    return UserModel(
      id: doc.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      role: UserRole.values.firstWhere(
        (r) =>
            r.toString().split('.').last == (data['role'] as String? ?? 'free'),
        orElse: () => UserRole.free,
      ),
      isAdmin: data['isAdmin'] as bool? ?? false,
      proTrialStartDate: data['proTrialStartDate'] != null
          ? (data['proTrialStartDate'] as Timestamp).toDate()
          : null,
      proTrialEndDate: data['proTrialEndDate'] != null
          ? (data['proTrialEndDate'] as Timestamp).toDate()
          : null,
      subscriptionEndDate: data['subscriptionEndDate'] != null
          ? (data['subscriptionEndDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Creates a copy of this UserModel with updated fields.
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? role,
    bool? isAdmin,
    DateTime? proTrialStartDate,
    DateTime? proTrialEndDate,
    DateTime? subscriptionEndDate,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      proTrialStartDate: proTrialStartDate ?? this.proTrialStartDate,
      proTrialEndDate: proTrialEndDate ?? this.proTrialEndDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Converts this UserModel to a JSON-compatible map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.toString().split('.').last,
      'isAdmin': isAdmin,
      'proTrialStartDate': proTrialStartDate != null
          ? Timestamp.fromDate(proTrialStartDate!)
          : null,
      'proTrialEndDate':
          proTrialEndDate != null ? Timestamp.fromDate(proTrialEndDate!) : null,
      'subscriptionEndDate': subscriptionEndDate != null
          ? Timestamp.fromDate(subscriptionEndDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  /// Creates a UserModel from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      role: UserRole.values.firstWhere(
        (r) =>
            r.toString().split('.').last == (json['role'] as String? ?? 'free'),
        orElse: () => UserRole.free,
      ),
      isAdmin: json['isAdmin'] as bool? ?? false,
      proTrialStartDate: json['proTrialStartDate'] != null
          ? DateTime.parse(json['proTrialStartDate'] as String)
          : null,
      proTrialEndDate: json['proTrialEndDate'] != null
          ? DateTime.parse(json['proTrialEndDate'] as String)
          : null,
      subscriptionEndDate: json['subscriptionEndDate'] != null
          ? DateTime.parse(json['subscriptionEndDate'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }

  /// Whether the user is currently on an active trial.
  bool get isTrialActive =>
      role == UserRole.pro &&
      proTrialEndDate != null &&
      proTrialEndDate!.isAfter(DateTime.now());

  /// Whether the user’s trial has expired.
  bool get isTrialExpired =>
      role == UserRole.pro &&
      proTrialEndDate != null &&
      proTrialEndDate!.isBefore(DateTime.now());

  /// Whether the trial is about to expire (within 7 days).
  bool get isTrialAboutToExpire => isTrialActive && remainingTrialDays <= 7;

  /// Whether the user has an active paid subscription.
  bool get isSubscribed =>
      role == UserRole.pro &&
      subscriptionEndDate != null &&
      subscriptionEndDate!.isAfter(DateTime.now());

  /// Whether the user has Pro status (either trial or subscribed).
  bool get isPro => role == UserRole.pro && (isTrialActive || isSubscribed);

  /// Number of days remaining in the trial period.
  int get remainingTrialDays {
    if (isTrialActive && proTrialEndDate != null) {
      return proTrialEndDate!.difference(DateTime.now()).inDays;
    }
    return 0;
  }
}
