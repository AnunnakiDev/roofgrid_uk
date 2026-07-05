import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_item_money_rates.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_rate_profile.dart';

/// Builds complete linear/ancillary hour and money maps from starter tables.
class LabourRateMaps {
  LabourRateMaps._();

  static const Map<LabourLinearItem, double> directLinearHours = {
    LabourLinearItem.ridge: 0.25,
    LabourLinearItem.hip: 0.30,
    LabourLinearItem.dryRidge: 0.22,
    LabourLinearItem.valley: 0.35,
    LabourLinearItem.openValley: 0.38,
    LabourLinearItem.closedValley: 0.40,
    LabourLinearItem.secretGutter: 0.45,
    LabourLinearItem.verge: 0.20,
    LabourLinearItem.abutment: 0.40,
    LabourLinearItem.partyWall: 0.42,
    LabourLinearItem.leadBay: 0.55,
    LabourLinearItem.steppedFlashing: 0.50,
    LabourLinearItem.apron: 0.48,
    LabourLinearItem.chimneySoaker: 0.35,
    LabourLinearItem.pipeCollar: 0.30,
    LabourLinearItem.leadDrip: 0.28,
    LabourLinearItem.heritageLead: 0.65,
    LabourLinearItem.cutting: 0.18,
    LabourLinearItem.pipePenetration: 0.25,
    LabourLinearItem.eaves: 0.15,
    LabourLinearItem.ventilationStrip: 0.12,
    LabourLinearItem.dormerCheek: 0.45,
    LabourLinearItem.dormerTop: 0.40,
    LabourLinearItem.flatUpstand: 0.32,
    LabourLinearItem.flatDrip: 0.28,
    LabourLinearItem.flatOutlet: 0.35,
    LabourLinearItem.edgeTrim: 0.22,
    LabourLinearItem.angleFillet: 0.26,
    LabourLinearItem.leadLinedGutter: 0.50,
  };

  static const Map<LabourLinearItem, double> subLinearHours = {
    LabourLinearItem.ridge: 0.22,
    LabourLinearItem.hip: 0.27,
    LabourLinearItem.dryRidge: 0.20,
    LabourLinearItem.valley: 0.32,
    LabourLinearItem.openValley: 0.34,
    LabourLinearItem.closedValley: 0.36,
    LabourLinearItem.secretGutter: 0.40,
    LabourLinearItem.verge: 0.18,
    LabourLinearItem.abutment: 0.36,
    LabourLinearItem.partyWall: 0.38,
    LabourLinearItem.leadBay: 0.50,
    LabourLinearItem.steppedFlashing: 0.45,
    LabourLinearItem.apron: 0.43,
    LabourLinearItem.chimneySoaker: 0.32,
    LabourLinearItem.pipeCollar: 0.27,
    LabourLinearItem.leadDrip: 0.25,
    LabourLinearItem.heritageLead: 0.58,
    LabourLinearItem.cutting: 0.16,
    LabourLinearItem.pipePenetration: 0.22,
    LabourLinearItem.eaves: 0.14,
    LabourLinearItem.ventilationStrip: 0.11,
    LabourLinearItem.dormerCheek: 0.40,
    LabourLinearItem.dormerTop: 0.36,
    LabourLinearItem.flatUpstand: 0.28,
    LabourLinearItem.flatDrip: 0.24,
    LabourLinearItem.flatOutlet: 0.30,
    LabourLinearItem.edgeTrim: 0.20,
    LabourLinearItem.angleFillet: 0.23,
    LabourLinearItem.leadLinedGutter: 0.45,
  };

  static const Map<LabourAncillary, double> directAncillaryHours = {
    LabourAncillary.chimney: 4.0,
    LabourAncillary.dormer: 8.0,
    LabourAncillary.skylight: 2.5,
    LabourAncillary.soilVent: 0.75,
    LabourAncillary.ventilationTile: 1.0,
    LabourAncillary.leadApron: 3.5,
    LabourAncillary.chimneySoakerSet: 2.5,
    LabourAncillary.abutmentLead: 3.0,
    LabourAncillary.flatUpstandUnit: 2.0,
    LabourAncillary.flatOutletUnit: 1.5,
    LabourAncillary.flatEdgeDetail: 1.25,
  };

  static const Map<LabourAncillary, double> subAncillaryHours = {
    LabourAncillary.chimney: 3.5,
    LabourAncillary.dormer: 7.0,
    LabourAncillary.skylight: 2.0,
    LabourAncillary.soilVent: 0.60,
    LabourAncillary.ventilationTile: 0.85,
    LabourAncillary.leadApron: 3.0,
    LabourAncillary.chimneySoakerSet: 2.2,
    LabourAncillary.abutmentLead: 2.6,
    LabourAncillary.flatUpstandUnit: 1.75,
    LabourAncillary.flatOutletUnit: 1.3,
    LabourAncillary.flatEdgeDetail: 1.1,
  };

  static LabourItemMoneyRates moneyRatesFromProfile(LabourRateProfile profile) {
    final hourly = profile.fullDayRatePerMan / 8;
    return LabourItemMoneyRates(
      linearRatePerMetre: {
        for (final entry in profile.hoursPerMetre.entries)
          entry.key: entry.value * hourly,
      },
      ancillaryRateEach: {
        for (final entry in profile.hoursEach.entries)
          entry.key: entry.value * hourly,
      },
    );
  }
}