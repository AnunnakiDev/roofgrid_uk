import 'package:flutter/foundation.dart';

/// Cloud Functions API base (no trailing slash).
///
/// Override for local emulator:
/// `flutter run --dart-define=ROOFGRID_API_BASE=http://10.0.2.2:5002/roofgriduk-f2f56/us-central1/api`
/// (Android emulator) or `http://127.0.0.1:5002/roofgriduk-f2f56/us-central1/api` (web/desktop).
const String _productionApiBase = 'https://api-gbtz2ngl6q-uc.a.run.app';

const String _configuredApiBase = String.fromEnvironment(
  'ROOFGRID_API_BASE',
  defaultValue: _productionApiBase,
);

String get roofgridApiBaseUrl {
  if (_configuredApiBase != _productionApiBase) {
    return _configuredApiBase;
  }
  return _productionApiBase;
}

Uri roofgridApiUri(String path) {
  final normalized = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$roofgridApiBaseUrl$normalized');
}

bool get isUsingEmulatorApi =>
    kDebugMode && roofgridApiBaseUrl != _productionApiBase;