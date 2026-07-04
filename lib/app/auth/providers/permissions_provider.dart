import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/models/developer_mode_config.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/utils/tile_access.dart';

/// Provider that exposes permission checks based on user type
final permissionsProvider = Provider<PermissionsService>((ref) {
  final devMode = ref.watch(developerModeProvider);
  return PermissionsService(devMode: devMode);
});

/// Service for handling user permissions and feature access
class PermissionsService {
  final DeveloperModeState devMode;

  const PermissionsService({this.devMode = const DeveloperModeState()});

  // Constants for maximum allowed features by user type
  static const int _maxRaftersForFree = 1;
  static const int _maxWidthsForFree = 1;
// Free users don't get access to tile database
  static const bool _allowCustomTilesForFree = false;
  static const bool _allowExportForFree = false;
  static const bool _allowSaveProjectsForFree =
      false; // Free users cannot save results
  static const bool _allowAdvancedOptionsForFree = false;
  static const bool _allowTileDatabaseAccessForFree =
      false; // Permission for tile database access
  static const int TRIAL_DURATION_DAYS = 14;
  static const int WARNING_DAYS = 7;

  /// Determines if a user can save calculation results
  bool canSaveCalculationResults(UserModel? user) {
    if (user == null) return _allowSaveProjectsForFree;
    return _allowSaveProjectsForFree || user.isPro || user.isTrialActive;
  }

  /// Determines if a user can use advanced calculation options
  bool canUseAdvancedOptions(UserModel? user) {
    if (user == null) return _allowAdvancedOptionsForFree;
    return user.isPro || user.isTrialActive || _allowAdvancedOptionsForFree;
  }

  /// Gets the maximum number of rafters a user can calculate with
  int getMaxAllowedRafters(UserModel? user) {
    if (user == null) return _maxRaftersForFree;
    if (user.isPro || user.isTrialActive) {
      return 10; // Pro users can use up to 10 rafters
    }
    return _maxRaftersForFree; // Free users can only use 1 rafter
  }

  /// Gets the maximum number of width measurements a user can use
  int getMaxAllowedWidths(UserModel? user) {
    if (user == null) return _maxWidthsForFree;
    if (user.isPro || user.isTrialActive) return 10;
    return _maxWidthsForFree;
  }

  /// Determines if a user can export results
  bool canExportResults(UserModel? user) {
    if (user == null) return _allowExportForFree;
    return user.isPro || user.isTrialActive || _allowExportForFree;
  }

  /// Determines if a user can create custom tiles
  bool canCreateCustomTiles(UserModel? user) {
    if (user == null) return _allowCustomTilesForFree;
    return canSavePersonalTiles(user, devMode) || _allowCustomTilesForFree;
  }

  /// Determines if a user can access the tile database
  bool canAccessTileDatabase(UserModel? user) {
    if (user == null) return _allowTileDatabaseAccessForFree;
    return canBrowseTileDatabase(user, devMode) ||
        _allowTileDatabaseAccessForFree;
  }

  /// Determines if a user's trial is about to expire
  bool isTrialAboutToExpire(UserModel? user) {
    if (user == null || !user.isTrialActive) return false;
    return getRemainingTrialDays(user) <= WARNING_DAYS;
  }

  /// Gets the number of days remaining in a user's trial
  int getRemainingTrialDays(UserModel user) {
    return user.remainingTrialDays;
  }

  /// Checks if the user has pro status (either paid or trial)
  bool isPro(UserModel? user) {
    if (user == null) return false;
    return resolveEffectiveIsPro(user, devMode);
  }
}
