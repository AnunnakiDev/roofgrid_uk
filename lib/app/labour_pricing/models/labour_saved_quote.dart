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

  const LabourSavedQuote({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.project,
    required this.quoteConfig,
    this.importedProjectName,
  });

  LabourSavedQuote copyWith({
    String? id,
    String? name,
    DateTime? savedAt,
    LabourQuoteProject? project,
    LabourQuoteConfig? quoteConfig,
    String? importedProjectName,
    bool clearImportedProjectName = false,
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
      };

  factory LabourSavedQuote.fromJson(Map<String, dynamic> json) {
    return LabourSavedQuote(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled quote',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
      project: LabourQuoteProject.fromJson(
        Map<String, dynamic>.from(json['project'] as Map),
      ),
      quoteConfig: LabourQuoteConfig.fromJson(
        Map<String, dynamic>.from(json['quoteConfig'] as Map),
      ),
      importedProjectName: json['importedProjectName'] as String?,
    );
  }
}