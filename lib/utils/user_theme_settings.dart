import 'package:roofgrid_uk/theme/app_color_schemes.dart';

/// Reads colour scheme id persisted on the user document in Firestore.
AppColorSchemeId? colorSchemeIdFromUserData(Map<String, dynamic>? data) {
  if (data == null) return null;

  final settings = data['settings'];
  if (settings is! Map) return null;

  final value = settings['colorSchemeId'];
  if (value is! String || value.isEmpty) return null;

  return appColorSchemeIdFromStorage(value);
}

/// @deprecated Legacy custom accent — ignored when [colorSchemeId] is present.
int? primaryColorFromUserData(Map<String, dynamic>? data) {
  if (data == null) return null;

  final settings = data['settings'];
  if (settings is! Map) return null;

  final value = settings['primaryColor'];
  if (value is int) return value;
  if (value is num) return value.toInt();

  return null;
}