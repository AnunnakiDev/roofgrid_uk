import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';

final sessionTrackerServiceProvider = Provider<SessionTrackerService>((ref) {
  final service = SessionTrackerService();
  ref.onDispose(service.dispose);
  return service;
});

/// Writes periodic heartbeats to Firestore `sessions/{userId}` for admin online metrics.
class SessionTrackerService {
  SessionTrackerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  Timer? _heartbeatTimer;
  String? _activeUserId;

  static const Duration heartbeatInterval = Duration(minutes: 2);

  Future<void> start(String userId) async {
    if (_activeUserId == userId && _heartbeatTimer != null) return;
    await stop();
    _activeUserId = userId;
    await _recordHeartbeat(userId);
    _heartbeatTimer = Timer.periodic(
      heartbeatInterval,
      (_) => unawaited(_recordHeartbeat(userId)),
    );
  }

  Future<void> recordNow() async {
    final userId = _activeUserId;
    if (userId == null) return;
    await _recordHeartbeat(userId);
  }

  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _activeUserId = null;
  }

  Future<void> _recordHeartbeat(String userId) async {
    if (!await isDeviceOnline()) return;
    try {
      await _firestore.collection('sessions').doc(userId).set(
        {
          'userId': userId,
          'lastActive': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Session heartbeat failed: $e');
    }
  }

  void dispose() {
    unawaited(stop());
  }
}