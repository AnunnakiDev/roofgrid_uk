import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

class ResultsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<SavedResult>> getSavedResults(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_results')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedResult.fromJson(doc.data()))
            .toList());
  }

  Future<List<SavedResult>> searchResults(String userId, String query) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_results')
        .orderBy('createdAt', descending: true)
        .get();

    final results =
        snapshot.docs.map((doc) => SavedResult.fromJson(doc.data())).toList();

    if (query.isEmpty) return results;

    return results.where((result) {
      final projectNameMatch =
          result.projectName.toLowerCase().contains(query.toLowerCase());
      final typeMatch =
          result.type.toString().toLowerCase().contains(query.toLowerCase());
      return projectNameMatch || typeMatch;
    }).toList();
  }

  Future<void> saveResult(String userId, SavedResult result) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_results')
        .doc(result.id)
        .set(result.toJson());
  }

  Future<void> deleteResult(String userId, String resultId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_results')
        .doc(resultId)
        .delete();
  }

  Future<bool> renameInput(
      SavedResult result, String inputType, int index, String newLabel) async {
    final inputs = Map<String, dynamic>.from(result.inputs);
    final inputList =
        List<Map<String, dynamic>>.from(inputs[inputType] as List);
    inputList[index]['label'] = newLabel;

    inputs[inputType] = inputList;

    await _firestore
        .collection('users')
        .doc(result.userId)
        .collection('saved_results')
        .doc(result.id)
        .update({
      'inputs': inputs,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    return true;
  }

  Future<bool> updateProjectName(SavedResult result, String newName) async {
    await _firestore
        .collection('users')
        .doc(result.userId)
        .collection('saved_results')
        .doc(result.id)
        .update({
      'projectName': newName,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    return true;
  }

  Future<String?> exportResultAsPdf(SavedResult result) async {
    // TODO: Implement PDF export (requires 'pdf' package)
    return null;
  }
}
