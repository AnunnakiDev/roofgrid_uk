import 'package:cloud_firestore/cloud_firestore.dart';

enum JobAssignmentStatus {
  assigned,
  onSite,
  complete,
}

/// Links a set-out saved job to an installer within a company.
class JobAssignment {
  final String id;
  final String orgId;
  final String savedResultId;
  final String projectName;
  final String assignedToUserId;
  final String assignedByUserId;
  final JobAssignmentStatus status;
  final DateTime assignedAt;

  const JobAssignment({
    required this.id,
    required this.orgId,
    required this.savedResultId,
    required this.projectName,
    required this.assignedToUserId,
    required this.assignedByUserId,
    required this.status,
    required this.assignedAt,
  });

  Map<String, dynamic> toFirestoreJson() => {
        'id': id,
        'orgId': orgId,
        'savedResultId': savedResultId,
        'projectName': projectName,
        'assignedToUserId': assignedToUserId,
        'assignedByUserId': assignedByUserId,
        'status': status.name,
        'assignedAt': Timestamp.fromDate(assignedAt),
      };

  factory JobAssignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return JobAssignment(
      id: doc.id,
      orgId: data['orgId'] as String? ?? '',
      savedResultId: data['savedResultId'] as String? ?? '',
      projectName: data['projectName'] as String? ?? 'Job',
      assignedToUserId: data['assignedToUserId'] as String? ?? '',
      assignedByUserId: data['assignedByUserId'] as String? ?? '',
      status: JobAssignmentStatus.values.firstWhere(
        (value) => value.name == (data['status'] as String? ?? 'assigned'),
        orElse: () => JobAssignmentStatus.assigned,
      ),
      assignedAt: data['assignedAt'] is Timestamp
          ? (data['assignedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}