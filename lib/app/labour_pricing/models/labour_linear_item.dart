enum LabourLinearItem {
  ridge,
  hip,
  dryRidge,
  dryVerge,
  valley,
  openValley,
  closedValley,
  secretGutter,
  verge,
  abutment,
  partyWall,
  leadBay,
  steppedFlashing,
  apron,
  chimneySoaker,
  pipeCollar,
  leadDrip,
  heritageLead,
  cutting,
  pipePenetration,
  eaves,
  ventilationStrip,
  dormerCheek,
  dormerTop,
  flatUpstand,
  flatDrip,
  flatOutlet,
  edgeTrim,
  angleFillet,
  leadLinedGutter,
}

extension LabourLinearItemLabels on LabourLinearItem {
  String get label {
    switch (this) {
      case LabourLinearItem.ridge:
        return 'Ridge';
      case LabourLinearItem.hip:
        return 'Hip';
      case LabourLinearItem.dryRidge:
        return 'Dry ridge system';
      case LabourLinearItem.dryVerge:
        return 'Dry verge system';
      case LabourLinearItem.valley:
        return 'Valley';
      case LabourLinearItem.openValley:
        return 'Open valley';
      case LabourLinearItem.closedValley:
        return 'Closed valley';
      case LabourLinearItem.secretGutter:
        return 'Secret gutter';
      case LabourLinearItem.verge:
        return 'Verge';
      case LabourLinearItem.abutment:
        return 'Abutment';
      case LabourLinearItem.partyWall:
        return 'Party wall';
      case LabourLinearItem.leadBay:
        return 'Lead bay';
      case LabourLinearItem.steppedFlashing:
        return 'Stepped flashing';
      case LabourLinearItem.apron:
        return 'Apron';
      case LabourLinearItem.chimneySoaker:
        return 'Chimney soaker';
      case LabourLinearItem.pipeCollar:
        return 'Pipe collar';
      case LabourLinearItem.leadDrip:
        return 'Lead drip';
      case LabourLinearItem.heritageLead:
        return 'Heritage lead';
      case LabourLinearItem.cutting:
        return 'Cutting';
      case LabourLinearItem.pipePenetration:
        return 'Pipe penetration';
      case LabourLinearItem.eaves:
        return 'Eaves';
      case LabourLinearItem.ventilationStrip:
        return 'Ventilation strip';
      case LabourLinearItem.dormerCheek:
        return 'Dormer cheek';
      case LabourLinearItem.dormerTop:
        return 'Dormer top';
      case LabourLinearItem.flatUpstand:
        return 'Upstand';
      case LabourLinearItem.flatDrip:
        return 'Drip';
      case LabourLinearItem.flatOutlet:
        return 'Outlet';
      case LabourLinearItem.edgeTrim:
        return 'Edge trim';
      case LabourLinearItem.angleFillet:
        return 'Angle fillet';
      case LabourLinearItem.leadLinedGutter:
        return 'Lead-lined gutter';
    }
  }
}