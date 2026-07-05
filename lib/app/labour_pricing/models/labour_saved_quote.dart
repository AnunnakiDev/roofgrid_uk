import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';

/// Persisted labour quote snapshot (project + config at save time).
class LabourSavedQuote {
  final String id;
  final String name;
  final DateTime savedAt;
  final LabourQuoteProject project;
  final LabourQuoteConfig quoteConfig;
  final String? importedProjectName;
  final String? sourceJobId;

  const LabourSavedQuote({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.project,
    required this.quoteConfig,
    this.importedProjectName,
    this.sourceJobId,
  });

  LabourSavedQuote copyWith({
    String? id,
    String? name,
    DateTime? savedAt,
    LabourQuoteProject? project,
    LabourQuoteConfig? quoteConfig,
    String? importedProjectName,
    String? sourceJobId,
    bool clearImportedProjectName = false,
    bool clearSourceJobId = false,
  }) {
    return LabourSavedQuote(
      id: id ?? this.id,
      name: name ?? this.name,
      savedAt: savedAt ?? this.savedAt,
      project: project ?? this.project,
      quoteConfig: quoteConfig ?? this.quoteConfig,
      importedProjectName: clearImportedProjectName
          ? null
          : (importedProjectName ?? this.importedProjectName),
      sourceJobId:
          clearSourceJobId ? null : (sourceJobId ?? this.sourceJobId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'savedAt': savedAt.toIso8601String(),
        'project': project.toJson(),
        'quoteConfig': quoteConfig.toJson(),
        if (importedProjectName != null)
          'importedProjectName': importedProjectName,
        if (sourceJobId != null) 'sourceJobId': sourceJobId,
      };

  static DateTime _parseSavedAt(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw as String? ?? '') ?? DateTime.now();
  }

  factory LabourSavedQuote.fromJson(Map<String, dynamic> json) {
    return LabourSavedQuote(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled quote',
      savedAt: _parseSavedAt(json['savedAt']),
      project: LabourQuoteProject.fromJson(
        Map<String, dynamic>.from(json['project'] as Map),
      ),
      quoteConfig: LabourQuoteConfig.fromJson(
        Map<String, dynamic>.from(json['quoteConfig'] as Map),
      ),
      importedProjectName: json['importedProjectName'] as String?,
      sourceJobId: json['sourceJobId'] as String?,
    );
  }
}