import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_analytics.dart';

void main() {
  test('logSyncSuccess swallows analytics failures', () async {
    final analytics = LabourQuotesAnalytics(
      logEvent: ({required name, parameters}) async {
        throw Exception('analytics unavailable');
      },
    );

    await analytics.logSyncSuccess(operation: 'save', quoteId: 'q1');
  });

  test('logSyncFailed swallows analytics failures', () async {
    final analytics = LabourQuotesAnalytics(
      logEvent: ({required name, parameters}) async {
        throw Exception('analytics unavailable');
      },
    );

    await analytics.logSyncFailed(
      operation: 'delete',
      quoteId: 'q1',
      reason: 'queued',
    );
  });
}