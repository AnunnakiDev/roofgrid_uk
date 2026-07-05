import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_firestore_service.dart';

final labourQuotesFirestoreServiceProvider =
    Provider<LabourQuotesFirestoreService>((ref) {
  return LabourQuotesFirestoreService();
});