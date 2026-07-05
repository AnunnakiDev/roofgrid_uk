import 'package:firebase_analytics/firebase_analytics.dart';

typedef LabourQuotesAnalyticsLog = Future<void> Function({
  required String name,
  Map<String, Object>? parameters,
});

/// Firebase Analytics events for labour quote cloud sync.
class LabourQuotesAnalytics {
  final LabourQuotesAnalyticsLog _logEvent;

  LabourQuotesAnalytics({
    LabourQuotesAnalyticsLog? logEvent,
    FirebaseAnalytics? analytics,
  }) : _logEvent = logEvent ??
            (({required name, parameters}) => (analytics ?? FirebaseAnalytics.instance)
                .logEvent(name: name, parameters: parameters));

  Future<void> logSyncSuccess({
    required String operation,
    required String quoteId,
  }) async {
    try {
      await _logEvent(
        name: 'sync_labour_quote',
        parameters: {
          'operation': operation,
          'quote_id': quoteId,
        },
      );
    } catch (_) {}
  }

  Future<void> logSyncFailed({
    required String operation,
    required String quoteId,
    String? reason,
  }) async {
    try {
      await _logEvent(
        name: 'sync_labour_quote_failed',
        parameters: {
          'operation': operation,
          'quote_id': quoteId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
    } catch (_) {}
  }
}