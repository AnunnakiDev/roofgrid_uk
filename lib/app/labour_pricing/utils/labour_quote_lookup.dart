import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

LabourSavedQuote? findLabourQuoteById(
  List<LabourSavedQuote> quotes,
  String? quoteId,
) {
  if (quoteId == null || quoteId.isEmpty) return null;
  for (final quote in quotes) {
    if (quote.id == quoteId) return quote;
  }
  return null;
}

List<SavedResult> savedResultsLinkedToQuote(
  List<SavedResult> results,
  String quoteId,
) {
  return results.where((result) => result.linkedQuoteId == quoteId).toList();
}

List<OrgJob> orgJobsLinkedToQuote(List<OrgJob> jobs, String quoteId) {
  return jobs.where((job) => job.linkedQuoteId == quoteId).toList();
}