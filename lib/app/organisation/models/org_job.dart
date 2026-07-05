import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job_status.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

/// Shared company job — set-out, quote, and install lifecycle.
class OrgJob {
  final String id;
  final String orgId;
  final String projectName;
  final OrgJobStatus status;
  final String? savedResultId;
  final String? linkedQuoteId;
  final String? assignedToUserId;
  final Map<String, dynamic> lockedTile;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final int calculationTypeIndex;
  final String createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrgJob({
    required this.id,
    required this.orgId,
    required this.projectName,
    required this.status,
    this.savedResultId,
    this.linkedQuoteId,
    this.assignedToUserId,
    required this.lockedTile,
    this.inputs = const {},
    this.outputs = const {},
    this.calculationTypeIndex = 2,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  OrgJob copyWith({
    String? id,
    String? orgId,
    String? projectName,
    OrgJobStatus? status,
    String? savedResultId,
    String? linkedQuoteId,
    String? assignedToUserId,
    Map<String, dynamic>? lockedTile,
    Map<String, dynamic>? inputs,
    Map<String, dynamic>? outputs,
    int? calculationTypeIndex,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearAssignedTo = false,
    bool clearLinkedQuote = false,
  }) {
    return OrgJob(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      projectName: projectName ?? this.projectName,
      status: status ?? this.status,
      savedResultId: savedResultId ?? this.savedResultId,
      linkedQuoteId:
          clearLinkedQuote ? null : (linkedQuoteId ?? this.linkedQuoteId),
      assignedToUserId:
          clearAssignedTo ? null : (assignedToUserId ?? this.assignedToUserId),
      lockedTile: lockedTile ?? this.lockedTile,
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      calculationTypeIndex: calculationTypeIndex ?? this.calculationTypeIndex,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestoreJson() => {
        'id': id,
        'orgId': orgId,
        'projectName': projectName,
        'status': status.name,
        if (savedResultId != null) 'savedResultId': savedResultId,
        if (linkedQuoteId != null) 'linkedQuoteId': linkedQuoteId,
        if (assignedToUserId != null) 'assignedToUserId': assignedToUserId,
        'lockedTile': lockedTile,
        'inputs': inputs,
        'outputs': outputs,
        'calculationTypeIndex': calculationTypeIndex,
        'createdByUserId': createdByUserId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory OrgJob.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OrgJob(
      id: doc.id,
      orgId: data['orgId'] as String? ?? '',
      projectName: data['projectName'] as String? ?? 'Job',
      status: orgJobStatusFromName(data['status'] as String?),
      savedResultId: data['savedResultId'] as String?,
      linkedQuoteId: data['linkedQuoteId'] as String?,
      assignedToUserId: data['assignedToUserId'] as String?,
      lockedTile: Map<String, dynamic>.from(
        data['lockedTile'] as Map? ?? const {},
      ),
      inputs: Map<String, dynamic>.from(data['inputs'] as Map? ?? const {}),
      outputs: Map<String, dynamic>.from(data['outputs'] as Map? ?? const {}),
      calculationTypeIndex: data['calculationTypeIndex'] as int? ?? 2,
      createdByUserId: data['createdByUserId'] as String? ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  SavedResult toSavedResult() {
    return SavedResult(
      id: savedResultId ?? id,
      userId: createdByUserId,
      projectName: projectName,
      type: CalculationType.values[calculationTypeIndex.clamp(0, 2)],
      timestamp: updatedAt,
      inputs: inputs,
      outputs: outputs,
      tile: lockedTile,
      createdAt: createdAt,
      updatedAt: updatedAt,
      linkedQuoteId: linkedQuoteId,
    );
  }
}