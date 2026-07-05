import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgrid_uk/app/organisation/models/company_role.dart';

enum OrgInviteStatus {
  pending,
  accepted,
  revoked,
}

class OrgInvite {
  final String id;
  final String orgId;
  final String email;
  final CompanyRole role;
  final String invitedByUserId;
  final DateTime createdAt;
  final OrgInviteStatus status;

  const OrgInvite({
    required this.id,
    required this.orgId,
    required this.email,
    required this.role,
    required this.invitedByUserId,
    required this.createdAt,
    this.status = OrgInviteStatus.pending,
  });

  Map<String, dynamic> toFirestoreJson() => {
        'id': id,
        'orgId': orgId,
        'email': email,
        'role': role.name,
        'invitedByUserId': invitedByUserId,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status.name,
      };

  factory OrgInvite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OrgInvite(
      id: doc.id,
      orgId: data['orgId'] as String? ?? '',
      email: (data['email'] as String? ?? '').trim().toLowerCase(),
      role: companyRoleFromName(data['role'] as String?),
      invitedByUserId: data['invitedByUserId'] as String? ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: OrgInviteStatus.values.firstWhere(
        (value) => value.name == (data['status'] as String? ?? 'pending'),
        orElse: () => OrgInviteStatus.pending,
      ),
    );
  }
}