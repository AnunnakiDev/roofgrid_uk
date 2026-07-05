enum LabourQuoteSyncOperation {
  save,
  delete;

  static LabourQuoteSyncOperation fromName(String? raw) {
    return LabourQuoteSyncOperation.values.firstWhere(
      (op) => op.name == raw,
      orElse: () => LabourQuoteSyncOperation.save,
    );
  }
}

/// Pending cloud operation for a labour quote (processed FIFO on reconnect).
class LabourQuoteSyncEntry {
  final String quoteId;
  final LabourQuoteSyncOperation operation;
  final DateTime queuedAt;

  const LabourQuoteSyncEntry({
    required this.quoteId,
    required this.operation,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => {
        'quoteId': quoteId,
        'operation': operation.name,
        'queuedAt': queuedAt.toIso8601String(),
      };

  factory LabourQuoteSyncEntry.fromJson(Map<String, dynamic> json) {
    return LabourQuoteSyncEntry(
      quoteId: json['quoteId'] as String,
      operation: LabourQuoteSyncOperation.fromName(json['operation'] as String?),
      queuedAt: DateTime.tryParse(json['queuedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}