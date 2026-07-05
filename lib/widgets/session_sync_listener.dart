import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/services/session_tracker_service.dart';

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

/// Starts session heartbeats when authenticated; refreshes on app resume.
class SessionSyncListener extends ConsumerStatefulWidget {
  const SessionSyncListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionSyncListener> createState() =>
      _SessionSyncListenerState();
}

class _SessionSyncListenerState extends ConsumerState<SessionSyncListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(sessionTrackerServiceProvider).recordNow());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(_sessionTrackerInitializerProvider);
    return widget.child;
  }
}