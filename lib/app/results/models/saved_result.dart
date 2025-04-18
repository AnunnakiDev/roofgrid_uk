import 'package:hive/hive.dart';

part 'saved_result.g.dart'; // This will be generated by build_runner

@HiveType(typeId: 4)
enum CalculationType {
  @HiveField(0)
  vertical,
  @HiveField(1)
  horizontal,
}

@HiveType(typeId: 5)
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
  final String title;

  SavedResult(
    this.title, {
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

  factory SavedResult.fromJson(Map<String, dynamic> json) {
    return SavedResult(
      json['title'] as String,
      id: json['id'] as String,
      userId: json['userId'] as String,
      projectName: json['projectName'] as String,
      type: json['type'] == 'vertical'
          ? CalculationType.vertical
          : CalculationType.horizontal,
      timestamp: DateTime.parse(json['timestamp'] as String),
      inputs: Map<String, dynamic>.from(json['inputs'] as Map),
      outputs: Map<String, dynamic>.from(json['outputs'] as Map),
      tile: Map<String, dynamic>.from(json['tile'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'projectName': projectName,
      'type': type == CalculationType.vertical ? 'vertical' : 'horizontal',
      'timestamp': timestamp.toIso8601String(),
      'inputs': inputs,
      'outputs': outputs,
      'tile': tile,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'title': title,
    };
  }
}
