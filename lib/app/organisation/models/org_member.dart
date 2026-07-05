import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgrid_uk/app/organisation/models/company_role.dart';

class OrgMember {
  final String orgId;
  final String userId;
  final CompanyRole role;
  final String? email;
  final String? displayName;
  final DateTime joinedAt;

  const OrgMember({
    required this.orgId,
    required this.userId,
    required this.role,
    this.email,
    this.displayName,
    required this.joinedAt,
  });

  Map<String, dynamic> toFirestoreJson() => {
        'orgId': orgId,
        'userId': userId,
        'role': role.name,
        'email': email,
        'displayName': displayName,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };

  factory OrgMember.fromFirestore(String orgId, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OrgMember(
      orgId: orgId,
      userId: doc.id,
      role: companyRoleFromName(data['role'] as String?),
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      joinedAt: data['joinedAt'] is Timestamp
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}