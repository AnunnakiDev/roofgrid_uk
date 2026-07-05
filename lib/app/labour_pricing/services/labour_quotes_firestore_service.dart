import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';

class LabourQuotesFirestoreService {
  final FirebaseFirestore _firestore;

  LabourQuotesFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<LabourSavedQuote>> fetchQuotes(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('labour_quotes')
        .orderBy('savedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => LabourSavedQuote.fromJson(doc.data()))
        .toList();
  }

  Future<void> saveQuote(String userId, LabourSavedQuote quote) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('labour_quotes')
        .doc(quote.id)
        .set({
      ...quote.toJson(),
      'savedAt': Timestamp.fromDate(quote.savedAt),
    });
  }

  Future<void> deleteQuote(String userId, String quoteId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('labour_quotes')
        .doc(quoteId)
        .delete();
  }
}