import 'package:connectivity_plus/connectivity_plus.dart';

/// Local-only override set by admin Developer Mode.
bool forceOfflineOverride = false;

void setForceOfflineOverride(bool enabled) {
  forceOfflineOverride = enabled;
}

/// Evaluates connectivity results from connectivity_plus v6+.
bool isOnlineFromResults(List<ConnectivityResult> results) {
  if (forceOfflineOverride) return false;
  return !results.contains(ConnectivityResult.none) && results.isNotEmpty;
}

/// Returns true when the device has an active network connection.
///
/// connectivity_plus v6+ returns a [List<ConnectivityResult>]; compare against
/// [ConnectivityResult.none] via list membership, not direct equality.
Future<bool> isDeviceOnline([Connectivity? connectivity]) async {
  if (forceOfflineOverride) return false;
  final checker = connectivity ?? Connectivity();
  final results = await checker.checkConnectivity();
  return isOnlineFromResults(results);
}