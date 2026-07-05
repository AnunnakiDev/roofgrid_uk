import 'package:roofgrid_uk/app/organisation/models/org_job.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

/// Builds a [SavedResult] view from a shared org job (installer-safe).
SavedResult? savedResultFromOrgJob(OrgJob job) {
  if (job.lockedTile.isEmpty) return null;
  return job.toSavedResult();
}