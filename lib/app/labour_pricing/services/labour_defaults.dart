import 'package:roofgrid_uk/app/labour_pricing/models/labour_backend_data.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_global_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_money_rates.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_rate_profile.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_rates.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type_rate_set.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_rate_maps.dart';

/// UK starter rates — editable per user via Profile → Labour Rates.
class LabourDefaults {
  LabourDefaults._();

  static const Map<LabourRoofType, double> roofTypeMultipliers = {
    LabourRoofType.modernInterlocking: 1.10,
    LabourRoofType.traditionalPantile: 1.0,
    LabourRoofType.plainTile: 1.05,
    LabourRoofType.naturalSlate: 1.25,
    LabourRoofType.fibreCementSlate: 1.12,
    LabourRoofType.shingles: 1.08,
    LabourRoofType.flatFelt: 0.90,
    LabourRoofType.flatGrp: 0.95,
    LabourRoofType.flatLiquid: 0.92,
    LabourRoofType.flatTraditionalLead: 1.15,
    LabourRoofType.flatSinglePly: 0.88,
  };

  static const LabourGlobalConfig globalConfig = LabourGlobalConfig(
    directFullDayRatePerMan: 220,
    directHalfDayRatePerMan: 132,
    subFullDayRatePerMan: 180,
    subHalfDayRatePerMan: 108,
    costPerMile: 0.65,
    overnightCostPerNight: 85,
  );

  static LabourRateProfile get directProfile => LabourRateProfile(
        fullDayRatePerMan: globalConfig.directFullDayRatePerMan,
        halfDayRatePerMan: globalConfig.directHalfDayRatePerMan,
        stripHoursPerSqm: 0.15,
        installHoursPerSqm: 0.35,
        hoursPerMetre: LabourRateMaps.directLinearHours,
        hoursEach: LabourRateMaps.directAncillaryHours,
      );

  static LabourRateProfile get subContractorProfile => LabourRateProfile(
        fullDayRatePerMan: globalConfig.subFullDayRatePerMan,
        halfDayRatePerMan: globalConfig.subHalfDayRatePerMan,
        stripHoursPerSqm: 0.13,
        installHoursPerSqm: 0.30,
        hoursPerMetre: LabourRateMaps.subLinearHours,
        hoursEach: LabourRateMaps.subAncillaryHours,
      );

  static LabourRates get starterRates => LabourRates(
        direct: directProfile,
        subContractor: subContractorProfile,
        roofTypeMultipliers: {
          LabourRoofType.traditionalPantile: 1.0,
          LabourRoofType.plainTile: 1.05,
          LabourRoofType.modernInterlocking: 1.10,
          LabourRoofType.naturalSlate: 1.25,
        },
        costPerMile: globalConfig.costPerMile,
        overnightCostPerNight: globalConfig.overnightCostPerNight,
      );

  static LabourBackendData get backendData2026 {
    final sets = <LabourRoofType, LabourRoofTypeRateSet>{};
    for (final roofType in LabourRoofType.values) {
      sets[roofType] = _rateSetForRoofType(roofType);
    }
    return LabourBackendData(rateSets: sets, global: globalConfig);
  }

  static LabourRoofTypeRateSet _rateSetForRoofType(LabourRoofType roofType) {
    final multiplier = roofTypeMultipliers[roofType] ?? 1.0;
    final directHoursPerDay = globalConfig.directFullDayRatePerMan / 8;
    final subHoursPerDay = globalConfig.subFullDayRatePerMan / 8;

    final directStripHours = directProfile.stripHoursPerSqm * multiplier;
    final directInstallHours = directProfile.installHoursPerSqm * multiplier;
    final subStripHours = subContractorProfile.stripHoursPerSqm * multiplier;
    final subInstallHours = subContractorProfile.installHoursPerSqm * multiplier;

    final directTiming = directProfile.copyWith(
      stripHoursPerSqm: directStripHours,
      installHoursPerSqm: directInstallHours,
    );
    final subTiming = subContractorProfile.copyWith(
      stripHoursPerSqm: subStripHours,
      installHoursPerSqm: subInstallHours,
    );

    return LabourRoofTypeRateSet(
      directMoney: LabourPricingMoneyRates(
        stripPerSqm: directStripHours * directHoursPerDay,
        installPerSqm: directInstallHours * directHoursPerDay,
      ),
      subMoney: LabourPricingMoneyRates(
        stripPerSqm: subStripHours * subHoursPerDay,
        installPerSqm: subInstallHours * subHoursPerDay,
      ),
      directItemMoney: LabourRateMaps.moneyRatesFromProfile(directTiming),
      subItemMoney: LabourRateMaps.moneyRatesFromProfile(subTiming),
      directTiming: directTiming,
      subTiming: subTiming,
    );
  }
}