import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

enum LabourLinearGroup {
  ridgeHip,
  valleys,
  vergesAbutments,
  leadWork,
  penetrations,
  eavesVentilation,
  dormerSpecial,
  flatRoofDetails,
}

extension LabourLinearGroupLabels on LabourLinearGroup {
  String get label {
    switch (this) {
      case LabourLinearGroup.ridgeHip:
        return 'Ridge & hip systems';
      case LabourLinearGroup.valleys:
        return 'Valleys';
      case LabourLinearGroup.vergesAbutments:
        return 'Verges & abutments';
      case LabourLinearGroup.leadWork:
        return 'Lead work';
      case LabourLinearGroup.penetrations:
        return 'Penetrations & cutting';
      case LabourLinearGroup.eavesVentilation:
        return 'Eaves & ventilation';
      case LabourLinearGroup.dormerSpecial:
        return 'Dormer & special details';
      case LabourLinearGroup.flatRoofDetails:
        return 'Flat roof details';
    }
  }
}

/// Grouped catalogue of permanent linear item types (day 1).
class LabourLinearCatalog {
  LabourLinearCatalog._();

  static const Map<LabourLinearGroup, List<LabourLinearItem>> itemsByGroup = {
    LabourLinearGroup.ridgeHip: [
      LabourLinearItem.ridge,
      LabourLinearItem.hip,
      LabourLinearItem.dryRidge,
    ],
    LabourLinearGroup.valleys: [
      LabourLinearItem.valley,
      LabourLinearItem.openValley,
      LabourLinearItem.closedValley,
      LabourLinearItem.secretGutter,
    ],
    LabourLinearGroup.vergesAbutments: [
      LabourLinearItem.verge,
      LabourLinearItem.dryVerge,
      LabourLinearItem.abutment,
      LabourLinearItem.partyWall,
    ],
    LabourLinearGroup.leadWork: [
      LabourLinearItem.leadBay,
      LabourLinearItem.steppedFlashing,
      LabourLinearItem.apron,
      LabourLinearItem.chimneySoaker,
      LabourLinearItem.pipeCollar,
      LabourLinearItem.leadDrip,
      LabourLinearItem.heritageLead,
    ],
    LabourLinearGroup.penetrations: [
      LabourLinearItem.cutting,
      LabourLinearItem.pipePenetration,
    ],
    LabourLinearGroup.eavesVentilation: [
      LabourLinearItem.eaves,
      LabourLinearItem.ventilationStrip,
    ],
    LabourLinearGroup.dormerSpecial: [
      LabourLinearItem.dormerCheek,
      LabourLinearItem.dormerTop,
    ],
    LabourLinearGroup.flatRoofDetails: [
      LabourLinearItem.flatUpstand,
      LabourLinearItem.flatDrip,
      LabourLinearItem.flatOutlet,
      LabourLinearItem.edgeTrim,
      LabourLinearItem.angleFillet,
      LabourLinearItem.leadLinedGutter,
    ],
  };

  static const List<LabourLinearGroup> allGroups =
      LabourLinearGroup.values;

  static List<LabourLinearItem> itemsForGroup(LabourLinearGroup group) =>
      itemsByGroup[group] ?? const [];

  static LabourLinearGroup? groupForItem(LabourLinearItem item) {
    for (final entry in itemsByGroup.entries) {
      if (entry.value.contains(item)) return entry.key;
    }
    return null;
  }

  static bool isGroupRelevant(LabourLinearGroup group, LabourRoofType roofType) {
    if (group == LabourLinearGroup.flatRoofDetails) return roofType.isFlat;
    if (roofType.isFlat &&
        (group == LabourLinearGroup.ridgeHip ||
            group == LabourLinearGroup.valleys ||
            group == LabourLinearGroup.dormerSpecial)) {
      return false;
    }
    return true;
  }

  /// Lead work is always editable; other groups grey out when not relevant.
  static bool isGroupEnabled(LabourLinearGroup group, LabourRoofType roofType) {
    if (group == LabourLinearGroup.leadWork) return true;
    return isGroupRelevant(group, roofType);
  }

  /// All eight groups are always visible in the calculator (Slice 5).
  static List<LabourLinearGroup> visibleGroups() => allGroups;

  static List<LabourLinearGroup> groupsForRoofType(LabourRoofType roofType) =>
      allGroups.where((g) => isGroupRelevant(g, roofType)).toList();
}

LabourLinearItem? tryParseLabourLinearItem(String name) {
  try {
    return LabourLinearItem.values.byName(name);
  } catch (_) {
    return null;
  }
}