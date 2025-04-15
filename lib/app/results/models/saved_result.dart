// lib/app/results/models/saved_result.dart
enum CalculationType { vertical, horizontal }

class SavedResult {
  final String id;
  final String userId;
  final String projectName;
  final CalculationType type;
  final DateTime timestamp;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final Map<String, dynamic> tile;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    };
  }
}
