import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';

class LabourQuoteDocumentTooLargeException implements Exception {
  final int byteLength;

  const LabourQuoteDocumentTooLargeException(this.byteLength);

  @override
  String toString() =>
      'Labour quote document exceeds safe Firestore size ($byteLength bytes)';
}

class LabourQuotesFirestoreService {
  static const int maxQuoteDocumentBytes = 900 * 1024;

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

  Future<LabourSavedQuote?> fetchQuote(String userId, String quoteId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('labour_quotes')
        .doc(quoteId)
        .get();
    if (!doc.exists) return null;
    return LabourSavedQuote.fromJson(doc.data()!);
  }

  Future<void> saveQuote(String userId, LabourSavedQuote quote) async {
    final payload = _payloadForQuote(quote);
    _assertDocumentSize(payload);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('labour_quotes')
        .doc(quote.id)
        .set(payload, SetOptions(merge: true));
  }

  Future<void> deleteQuote(String userId, String quoteId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('labour_quotes')
        .doc(quoteId)
        .delete();
  }

  static Map<String, dynamic> _payloadForQuote(LabourSavedQuote quote) {
    return {
      ...quote.toJson(),
      'savedAt': Timestamp.fromDate(quote.savedAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  static int estimateDocumentBytes(LabourSavedQuote quote) {
    return _encodedPayloadBytes(_payloadForQuote(quote));
  }

  static void _assertDocumentSize(Map<String, dynamic> payload) {
    final byteLength = _encodedPayloadBytes(payload);
    if (byteLength > maxQuoteDocumentBytes) {
      throw LabourQuoteDocumentTooLargeException(byteLength);
    }
  }

  static int _encodedPayloadBytes(Map<String, dynamic> payload) {
    final copy = Map<String, dynamic>.from(payload)..remove('updatedAt');
    final savedAt = copy['savedAt'];
    if (savedAt is Timestamp) {
      copy['savedAt'] = savedAt.toDate().toIso8601String();
    }
    return utf8.encode(jsonEncode(copy)).length;
  }
}