import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:roofgrid_uk/utils/saved_result_inputs.dart';

part 'saved_result.g.dart'; // Generated file for Hive

@HiveType(typeId: 6)
class SavedResult {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String projectName;

  @HiveField(3)
  final CalculationType type;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final Map<String, dynamic> inputs;

  @HiveField(6)
  final Map<String, dynamic> outputs;

  @HiveField(7)
  final Map<String, dynamic> tile;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final String? linkedQuoteId;

  SavedResult({
    required this.id,
    required this.userId,
    required this.projectName,
    required this.type,
    required this.timestamp,
    required this.inputs,
    required this.outputs,
    required this.tile,
    required this.createdAt,
    required this.updatedAt,
    this.linkedQuoteId,
  });

  SavedResult copyWith({
    String? id,
    String? userId,
    String? projectName,
    CalculationType? type,
    DateTime? timestamp,
    Map<String, dynamic>? inputs,
    Map<String, dynamic>? outputs,
    Map<String, dynamic>? tile,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedQuoteId,
    bool clearLinkedQuoteId = false,
  }) {
    return SavedResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectName: projectName ?? this.projectName,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      tile: tile ?? this.tile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedQuoteId:
          clearLinkedQuoteId ? null : (linkedQuoteId ?? this.linkedQuoteId),
    );
  }

  // Add this helper method to the SavedResult class
  static List<Map<String, dynamic>> _safeParseList(dynamic rawList) {
    if (rawList == null) return [];
    if (rawList is! List) return [];

    return List<Map<String, dynamic>>.from(rawList.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      } else if (item is Map) {
        return Map<String, dynamic>.from(item);
      }
      return {'label': 'Unknown', 'value': 0.0};
    }));
  }

  // Update fromJson method to use the safe parser
  factory SavedResult.fromJson(Map<String, dynamic> json) {
    final type = CalculationType.values[json['type'] as int];
    final inputs = normalizeSavedResultInputsMap(
      type,
      Map<String, dynamic>.from(json['inputs'] as Map),
    );
    return SavedResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      projectName: json['projectName'] as String,
      type: type,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      inputs: inputs,
      outputs: Map<String, dynamic>.from(json['outputs'] as Map),
      tile: Map<String, dynamic>.from(json['tile'] as Map),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      linkedQuoteId: json['linkedQuoteId'] as String?,
    );
  }

  // toJson for general serialization (e.g., Hive)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'projectName': projectName,
      'type': type.index,
      'timestamp': timestamp,
      'inputs': inputs,
      'outputs': outputs,
      'tile': tile,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (linkedQuoteId != null) 'linkedQuoteId': linkedQuoteId,
    };
  }

  // toFirestoreJson for Firestore serialization
  Map<String, dynamic> toFirestoreJson() {
    return {
      'id': id,
      'userId': userId,
      'projectName': projectName,
      'type': type.index,
      'timestamp': Timestamp.fromDate(timestamp),
      'inputs': inputs,
      'outputs': outputs,
      'tile': tile,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (linkedQuoteId != null) 'linkedQuoteId': linkedQuoteId,
    };
  }
}

@HiveType(typeId: 4)
enum CalculationType {
  @HiveField(0)
  vertical,

  @HiveField(1)
  horizontal,

  @HiveField(2)
  combined, // Added for combined calculations
}

@HiveType(typeId: 5)
class DateTimeAdapter extends TypeAdapter<DateTime> {
  @override
  final int typeId = 5;

  @override
  DateTime read(BinaryReader reader) {
    final millis = reader.readInt();
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}
