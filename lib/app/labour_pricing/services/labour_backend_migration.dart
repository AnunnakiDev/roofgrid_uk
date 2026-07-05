import 'package:roofgrid_uk/app/labour_pricing/models/labour_backend_data.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_global_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_money_rates.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_rate_profile.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_rates.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type_rate_set.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_rate_maps.dart';

/// Upgrades persisted v1 labour config JSON to [LabourBackendData].
class LabourBackendMigration {
  LabourBackendMigration._();

  static const _legacyMultipliers = <String, double>{
    'pantile': 1.0,
    'plainTile': 1.05,
    'fibreCement': 1.10,
    'slate': 1.25,
  };

  static LabourBackendData fromPersistedJson(Map<String, dynamic> json) {
    if (json.containsKey('backendData')) {
      return LabourBackendData.fromJson(
        Map<String, dynamic>.from(json['backendData'] as Map),
      );
    }

    if (json.containsKey('rates')) {
      return fromLegacyRates(
        LabourRates.fromJson(
          Map<String, dynamic>.from(json['rates'] as Map),
        ),
      );
    }

    return LabourDefaults.backendData2026;
  }

  static LabourBackendData fromLegacyRates(LabourRates rates) {
    final defaults = LabourDefaults.backendData2026;
    final sets = <LabourRoofType, LabourRoofTypeRateSet>{};

    for (final roofType in LabourRoofType.values) {
      final multiplier = _multiplierFor(roofType, rates);
      sets[roofType] = _rateSetFromLegacyProfiles(
        direct: rates.direct,
        sub: rates.subContractor,
        multiplier: multiplier,
        fallback: defaults.rateSetFor(roofType),
      );
    }

    return LabourBackendData(
      rateSets: sets,
      global: LabourGlobalConfig(
        directFullDayRatePerMan: rates.direct.fullDayRatePerMan,
        directHalfDayRatePerMan: rates.direct.halfDayRatePerMan,
        subFullDayRatePerMan: rates.subContractor.fullDayRatePerMan,
        subHalfDayRatePerMan: rates.subContractor.halfDayRatePerMan,
        costPerMile: rates.costPerMile,
        overnightCostPerNight: rates.overnightCostPerNight,
      ),
    );
  }

  static double _multiplierFor(LabourRoofType roofType, LabourRates rates) {
    final legacyKey = _legacyKeyFor(roofType);
    if (legacyKey != null && rates.roofTypeMultipliers.isNotEmpty) {
      for (final entry in rates.roofTypeMultipliers.entries) {
        if (entry.key.name == legacyKey) return entry.value;
      }
    }
    return LabourDefaults.roofTypeMultipliers[roofType] ?? 1.0;
  }

  static String? _legacyKeyFor(LabourRoofType roofType) {
    switch (roofType) {
      case LabourRoofType.traditionalPantile:
        return 'pantile';
      case LabourRoofType.plainTile:
        return 'plainTile';
      case LabourRoofType.modernInterlocking:
        return 'fibreCement';
      case LabourRoofType.naturalSlate:
        return 'slate';
      default:
        return null;
    }
  }

  static LabourRoofTypeRateSet _rateSetFromLegacyProfiles({
    required LabourRateProfile direct,
    required LabourRateProfile sub,
    required double multiplier,
    required LabourRoofTypeRateSet fallback,
  }) {
    final directHoursPerDay = direct.fullDayRatePerMan / 8;
    final subHoursPerDay = sub.fullDayRatePerMan / 8;

    final directTiming = fallback.directTiming.copyWith(
      fullDayRatePerMan: direct.fullDayRatePerMan,
      halfDayRatePerMan: direct.halfDayRatePerMan,
      stripHoursPerSqm: direct.stripHoursPerSqm * multiplier,
      installHoursPerSqm: direct.installHoursPerSqm * multiplier,
      hoursPerMetre: {
        ...fallback.directTiming.hoursPerMetre,
        ...direct.hoursPerMetre,
      },
      hoursEach: {
        ...fallback.directTiming.hoursEach,
        ...direct.hoursEach,
      },
    );
    final subTiming = fallback.subTiming.copyWith(
      fullDayRatePerMan: sub.fullDayRatePerMan,
      halfDayRatePerMan: sub.halfDayRatePerMan,
      stripHoursPerSqm: sub.stripHoursPerSqm * multiplier,
      installHoursPerSqm: sub.installHoursPerSqm * multiplier,
      hoursPerMetre: {
        ...fallback.subTiming.hoursPerMetre,
        ...sub.hoursPerMetre,
      },
      hoursEach: {
        ...fallback.subTiming.hoursEach,
        ...sub.hoursEach,
      },
    );

    return LabourRoofTypeRateSet(
      directMoney: LabourPricingMoneyRates(
        stripPerSqm: direct.stripHoursPerSqm * multiplier * directHoursPerDay,
        installPerSqm:
            direct.installHoursPerSqm * multiplier * directHoursPerDay,
      ),
      subMoney: LabourPricingMoneyRates(
        stripPerSqm: sub.stripHoursPerSqm * multiplier * subHoursPerDay,
        installPerSqm: sub.installHoursPerSqm * multiplier * subHoursPerDay,
      ),
      directItemMoney: LabourRateMaps.moneyRatesFromProfile(directTiming),
      subItemMoney: LabourRateMaps.moneyRatesFromProfile(subTiming),
      directTiming: directTiming,
      subTiming: subTiming,
    );
  }

  static double legacyMultiplierFromName(String name) =>
      _legacyMultipliers[name] ?? 1.0;
}