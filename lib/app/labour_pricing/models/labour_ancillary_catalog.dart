import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

enum LabourAncillaryGroup {
  standard,
  leadWork,
  flatRoof,
}

extension LabourAncillaryGroupLabels on LabourAncillaryGroup {
  String get label {
    switch (this) {
      case LabourAncillaryGroup.standard:
        return 'Standard';
      case LabourAncillaryGroup.leadWork:
        return 'Lead work';
      case LabourAncillaryGroup.flatRoof:
        return 'Flat roofing';
    }
  }
}

class LabourAncillaryCatalog {
  LabourAncillaryCatalog._();

  static const Map<LabourAncillaryGroup, List<LabourAncillary>> itemsByGroup = {
    LabourAncillaryGroup.standard: [
      LabourAncillary.chimney,
      LabourAncillary.dormer,
      LabourAncillary.skylight,
      LabourAncillary.soilVent,
      LabourAncillary.ventilationTile,
    ],
    LabourAncillaryGroup.leadWork: [
      LabourAncillary.leadApron,
      LabourAncillary.chimneySoakerSet,
      LabourAncillary.abutmentLead,
    ],
    LabourAncillaryGroup.flatRoof: [
      LabourAncillary.flatUpstandUnit,
      LabourAncillary.flatOutletUnit,
      LabourAncillary.flatEdgeDetail,
    ],
  };

  static const List<LabourAncillaryGroup> allGroups =
      LabourAncillaryGroup.values;

  static bool isGroupRelevant(
    LabourAncillaryGroup group,
    LabourRoofType roofType,
  ) {
    if (group == LabourAncillaryGroup.flatRoof) return roofType.isFlat;
    return true;
  }

  /// Lead ancillaries always editable; flat group greyed on pitched roofs.
  static bool isGroupEnabled(
    LabourAncillaryGroup group,
    LabourRoofType roofType,
  ) {
    if (group == LabourAncillaryGroup.leadWork) return true;
    return isGroupRelevant(group, roofType);
  }

  static List<LabourAncillaryGroup> visibleGroups() => allGroups;

  static List<LabourAncillaryGroup> groupsForRoofType(LabourRoofType roofType) =>
      allGroups.where((g) => isGroupRelevant(g, roofType)).toList();
}

LabourAncillary? tryParseLabourAncillary(String name) {
  try {
    return LabourAncillary.values.byName(name);
  } catch (_) {
    return null;
  }
}