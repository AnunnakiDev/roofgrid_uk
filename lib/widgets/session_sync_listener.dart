import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_quotes_provider.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/services/session_tracker_service.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';

final _sessionTrackerInitializerProvider = Provider<void>((ref) {
  final userId = ref.watch(authProvider.select((state) => state.userId));
  final tracker = ref.read(sessionTrackerServiceProvider);

  if (userId == null || userId.isEmpty) {
    unawaited(tracker.stop());
  } else {
    unawaited(tracker.start(userId));
  }

  ref.onDispose(() => unawaited(tracker.stop()));
});

/// Starts session heartbeats when authenticated; refreshes labour quotes on
/// login and flushes pending cloud sync when connectivity returns.
class SessionSyncListener extends ConsumerStatefulWidget {
  const SessionSyncListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionSyncListener> createState() =>
      _SessionSyncListenerState();
}

class _SessionSyncListenerState extends ConsumerState<SessionSyncListener>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOnline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initConnectivity());
  }

  Future<void> _initConnectivity() async {
    _wasOnline = await isDeviceOnline();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = isOnlineFromResults(results);
      if (!_wasOnline && isOnline) {
        unawaited(ref.read(labourQuotesProvider.notifier).flushPendingSync());
      }
      _wasOnline = isOnline;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(sessionTrackerServiceProvider).recordNow());
      unawaited(ref.read(labourQuotesProvider.notifier).flushPendingSync());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(_sessionTrackerInitializerProvider);

    ref.listen<String?>(
      authProvider.select((state) => state.userId),
      (previous, next) {
        final hadUser = previous != null && previous.isNotEmpty;
        final hasUser = next != null && next.isNotEmpty;
        if (!hadUser && hasUser) {
          unawaited(ref.read(labourQuotesProvider.notifier).refresh());
        }
      },
    );

    return widget.child;
  }
}