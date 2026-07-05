import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary_catalog.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_catalog.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';

/// Timing and day-rate table for one pricing mode (direct or sub-contractor).
class LabourRateProfile {
  final double fullDayRatePerMan;
  final double halfDayRatePerMan;
  final double stripHoursPerSqm;
  final double installHoursPerSqm;
  final Map<LabourLinearItem, double> hoursPerMetre;
  final Map<LabourAncillary, double> hoursEach;

  const LabourRateProfile({
    required this.fullDayRatePerMan,
    required this.halfDayRatePerMan,
    required this.stripHoursPerSqm,
    required this.installHoursPerSqm,
    required this.hoursPerMetre,
    required this.hoursEach,
  });

  double hoursPerMetreFor(LabourLinearItem item) => hoursPerMetre[item] ?? 0;

  double hoursEachFor(LabourAncillary ancillary) => hoursEach[ancillary] ?? 0;

  LabourRateProfile copyWith({
    double? fullDayRatePerMan,
    double? halfDayRatePerMan,
    double? stripHoursPerSqm,
    double? installHoursPerSqm,
    Map<LabourLinearItem, double>? hoursPerMetre,
    Map<LabourAncillary, double>? hoursEach,
  }) {
    return LabourRateProfile(
      fullDayRatePerMan: fullDayRatePerMan ?? this.fullDayRatePerMan,
      halfDayRatePerMan: halfDayRatePerMan ?? this.halfDayRatePerMan,
      stripHoursPerSqm: stripHoursPerSqm ?? this.stripHoursPerSqm,
      installHoursPerSqm: installHoursPerSqm ?? this.installHoursPerSqm,
      hoursPerMetre: hoursPerMetre ?? this.hoursPerMetre,
      hoursEach: hoursEach ?? this.hoursEach,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullDayRatePerMan': fullDayRatePerMan,
        'halfDayRatePerMan': halfDayRatePerMan,
        'stripHoursPerSqm': stripHoursPerSqm,
        'installHoursPerSqm': installHoursPerSqm,
        'hoursPerMetre': hoursPerMetre.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'hoursEach': hoursEach.map(
          (key, value) => MapEntry(key.name, value),
        ),
      };

  factory LabourRateProfile.fromJson(Map<String, dynamic> json) {
    return LabourRateProfile(
      fullDayRatePerMan: (json['fullDayRatePerMan'] as num).toDouble(),
      halfDayRatePerMan: (json['halfDayRatePerMan'] as num).toDouble(),
      stripHoursPerSqm: (json['stripHoursPerSqm'] as num).toDouble(),
      installHoursPerSqm: (json['installHoursPerSqm'] as num).toDouble(),
      hoursPerMetre: _parseLinearHours(json['hoursPerMetre']),
      hoursEach: _parseAncillaryHours(json['hoursEach']),
    );
  }

  static Map<LabourLinearItem, double> _parseLinearHours(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <LabourLinearItem, double>{};
    for (final entry in raw.entries) {
      final item = tryParseLabourLinearItem(entry.key as String);
      if (item != null) {
        result[item] = (entry.value as num).toDouble();
      }
    }
    return result;
  }

  static Map<LabourAncillary, double> _parseAncillaryHours(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <LabourAncillary, double>{};
    for (final entry in raw.entries) {
      final item = tryParseLabourAncillary(entry.key as String);
      if (item != null) {
        result[item] = (entry.value as num).toDouble();
      }
    }
    return result;
  }
}