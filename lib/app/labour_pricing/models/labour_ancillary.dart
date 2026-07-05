enum LabourAncillary {
  chimney,
  dormer,
  skylight,
  soilVent,
  ventilationTile,
  leadApron,
  chimneySoakerSet,
  abutmentLead,
  flatUpstandUnit,
  flatOutletUnit,
  flatEdgeDetail,
}

extension LabourAncillaryLabels on LabourAncillary {
  String get label {
    switch (this) {
      case LabourAncillary.chimney:
        return 'Chimney';
      case LabourAncillary.dormer:
        return 'Dormer';
      case LabourAncillary.skylight:
        return 'Skylight';
      case LabourAncillary.soilVent:
        return 'Soil vent';
      case LabourAncillary.ventilationTile:
        return 'Ventilation tile';
      case LabourAncillary.leadApron:
        return 'Lead apron';
      case LabourAncillary.chimneySoakerSet:
        return 'Chimney soaker set';
      case LabourAncillary.abutmentLead:
        return 'Abutment lead';
      case LabourAncillary.flatUpstandUnit:
        return 'Flat upstand unit';
      case LabourAncillary.flatOutletUnit:
        return 'Flat outlet unit';
      case LabourAncillary.flatEdgeDetail:
        return 'Flat edge detail';
    }
  }
}