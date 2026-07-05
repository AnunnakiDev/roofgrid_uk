import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_analytics.dart';

final labourQuotesAnalyticsProvider = Provider<LabourQuotesAnalytics>((ref) {
  return LabourQuotesAnalytics();
});