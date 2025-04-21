import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

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
  });

  // Add fromJson for Firestore deserialization
  factory SavedResult.fromJson(Map<String, dynamic> json) {
    return SavedResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      projectName: json['projectName'] as String,
      type: CalculationType.values[json['type'] as int],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      inputs: Map<String, dynamic>.from(json['inputs'] as Map),
      outputs: Map<String, dynamic>.from(json['outputs'] as Map),
      tile: Map<String, dynamic>.from(json['tile'] as Map),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
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
    };
  }
}

@HiveType(typeId: 4)
enum CalculationType {
  @HiveField(0)
  vertical,

  @HiveField(1)
  horizontal,
}

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
