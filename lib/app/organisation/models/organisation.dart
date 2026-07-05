import 'package:cloud_firestore/cloud_firestore.dart';

class Organisation {
  final String id;
  final String name;
  final String createdByUserId;
  final DateTime createdAt;
  final int seatLimit;

  const Organisation({
    required this.id,
    required this.name,
    required this.createdByUserId,
    required this.createdAt,
    this.seatLimit = 5,
  });

  Organisation copyWith({
    String? id,
    String? name,
    String? createdByUserId,
    DateTime? createdAt,
    int? seatLimit,
  }) {
    return Organisation(
      id: id ?? this.id,
      name: name ?? this.name,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      seatLimit: seatLimit ?? this.seatLimit,
    );
  }

  Map<String, dynamic> toFirestoreJson() => {
        'id': id,
        'name': name,
        'createdByUserId': createdByUserId,
        'createdAt': Timestamp.fromDate(createdAt),
        'seatLimit': seatLimit,
      };

  factory Organisation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Organisation(
      id: doc.id,
      name: data['name'] as String? ?? 'Company',
      createdByUserId: data['createdByUserId'] as String? ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      seatLimit: data['seatLimit'] as int? ?? 5,
    );
  }
}