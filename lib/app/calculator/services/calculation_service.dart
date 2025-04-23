import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:roofgrid_uk/app/calculator/services/horizontal_calculation_service.dart';
import 'package:roofgrid_uk/app/calculator/services/vertical_calculation_service.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';

class CalculationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<Map> _calculationsBox = Hive.box<Map>('calculationsBox');

  CalculationService() {
    // Initialize Hive box if not already opened
    if (!_calculationsBox.isOpen) {
      Hive.openBox<Map>('calculationsBox');
    }
  }

  /// Calculates vertical batten gauge
  Future<VerticalCalculationResult> calculateVertical({
    required VerticalCalculationInput input,
    required String materialType,
    required double slateTileHeight,
    required double maxGauge,
    required double minGauge,
  }) async {
    debugPrint('CalculationService: Calculating vertical with input: $input');
    return VerticalCalculationService.calculateVertical(
      input: input,
      materialType: materialType,
      slateTileHeight: slateTileHeight,
      maxGauge: maxGauge,
      minGauge: minGauge,
    );
  }

  /// Calculates horizontal tile spacing
  Future<HorizontalCalculationResult> calculateHorizontal(
      HorizontalCalculationInput input) async {
    debugPrint('CalculationService: Calculating horizontal with input: $input');
    return HorizontalCalculationService.calculateHorizontal(input);
  }

  /// Calculates both vertical and horizontal results
  Future<Map<String, dynamic>> calculateCombined({
    required List<double> rafterHeights,
    required List<double> widths,
    required String materialType,
    required double slateTileHeight,
    required double maxGauge,
    required double minGauge,
    required double tileCoverWidth,
    required double minSpacing,
    required double maxSpacing,
    required double lhTileWidth,
    required double gutterOverhang,
    required String useDryRidge,
    required String useDryVerge,
    required String abutmentSide,
    required String useLHTile,
    required String crossBonded,
  }) async {
    debugPrint('CalculationService: Calculating combined results');
    final verticalResult = await calculateVertical(
      input: VerticalCalculationInput(
        rafterHeights: rafterHeights,
        gutterOverhang: gutterOverhang,
        useDryRidge: useDryRidge,
      ),
      materialType: materialType,
      slateTileHeight: slateTileHeight,
      maxGauge: maxGauge,
      minGauge: minGauge,
    );

    final horizontalResult = await calculateHorizontal(
      HorizontalCalculationInput(
        widths: widths,
        tileCoverWidth: tileCoverWidth,
        minSpacing: minSpacing,
        maxSpacing: maxSpacing,
        lhTileWidth: lhTileWidth,
        useDryVerge: useDryVerge,
        abutmentSide: abutmentSide,
        useLHTile: useLHTile,
        crossBonded: crossBonded,
      ),
    );

    return {
      'verticalResult': verticalResult.toJson(),
      'horizontalResult': horizontalResult.toJson(),
    };
  }

  /// Saves a calculation to Firestore and Hive
  Future<void> saveCalculation({
    required String id,
    required String userId,
    required String tileId,
    required String type,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> result,
    required Map<String, dynamic> tile,
    required bool success,
  }) async {
    final timestamp = DateTime.now();
    final calculationForFirestore = {
      'id': id,
      'userId': userId,
      'tileId': tileId,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'inputs': inputs,
      'result': result,
      'tile': tile,
      'success': success,
    };

    final calculationForHive = {
      'id': id,
      'userId': userId,
      'tileId': tileId,
      'type': type,
      'timestamp':
          timestamp.millisecondsSinceEpoch, // Store as milliseconds for Hive
      'inputs': inputs,
      'result': result,
      'tile': tile,
      'success': success,
    };

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      // Save to Firestore
      try {
        await _firestore
            .collection('calculations')
            .doc(id)
            .set(calculationForFirestore);
        print("Calculation $id saved to Firestore");
      } catch (e) {
        print("Error saving calculation to Firestore: $e");
        // Fall back to Hive if Firestore fails
        await _saveToHive(id, calculationForHive);
        throw Exception("Failed to save calculation to Firestore: $e");
      }
    } else {
      // Save to Hive if offline
      await _saveToHive(id, calculationForHive);
      print("Calculation $id saved to Hive (offline)");
    }

    // Save to Hive for local caching
    await _saveToHive(id, calculationForHive);
  }

  /// Saves a calculation to Hive
  Future<void> _saveToHive(String id, Map<String, dynamic> calculation) async {
    await _calculationsBox.put(id, calculation);
  }

  /// Syncs locally stored calculations to Firestore when online
  Future<void> syncCalculations() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (!isOnline) {
      print("Cannot sync calculations: Device is offline");
      return;
    }

    final calculationsToSync = _calculationsBox.values.toList();
    if (calculationsToSync.isEmpty) {
      print("No calculations to sync");
      return;
    }

    for (var calculationDynamic in calculationsToSync) {
      // Convert from Map<dynamic, dynamic> to Map<String, dynamic>
      final Map<String, dynamic> calculation =
          Map<String, dynamic>.from(calculationDynamic);

      // Convert timestamp back to Timestamp for Firestore
      final timestampMillis = calculation['timestamp'] as int;
      calculation['timestamp'] =
          Timestamp.fromMillisecondsSinceEpoch(timestampMillis);

      final id = calculation['id'] as String;
      try {
        await _firestore.collection('calculations').doc(id).set(calculation);
        print("Synced calculation $id to Firestore");
      } catch (e) {
        print("Error syncing calculation $id: $e");
      }
    }

    // Optionally clear Hive after successful sync
    // await _calculationsBox.clear();
    // print("Cleared local calculations after sync");
  }

  /// Fetches all calculations for a user (for stats purposes)
  Stream<List<Map<String, dynamic>>> getCalculations(String userId) {
    return _firestore
        .collection('calculations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Fetches all calculations (for admin stats)
  Stream<List<Map<String, dynamic>>> getAllCalculations() {
    return _firestore
        .collection('calculations')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
