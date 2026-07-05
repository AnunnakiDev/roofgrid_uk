import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_material_line.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_category.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_price_entry.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_section_calculator.dart';

/// Suggests BoQ material lines from roof quantities and a material price list.
class BoqSuggestionService {
  BoqSuggestionService._();

  static const _linearUnits = {'lm', 'm', 'metre', 'metres', 'meter', 'meters'};

  static const _linearKeywordMap = <LabourLinearItem, List<String>>{
    LabourLinearItem.ridge: ['ridge'],
    LabourLinearItem.dryRidge: ['dry ridge', 'dryridge'],
    LabourLinearItem.hip: ['hip'],
    LabourLinearItem.valley: ['valley'],
    LabourLinearItem.openValley: ['open valley'],
    LabourLinearItem.closedValley: ['closed valley'],
    LabourLinearItem.verge: ['verge'],
    LabourLinearItem.dryVerge: ['dry verge', 'dryverge'],
    LabourLinearItem.abutment: ['abutment'],
    LabourLinearItem.partyWall: ['party wall', 'partywall'],
    LabourLinearItem.steppedFlashing: ['stepped', 'flashing'],
    LabourLinearItem.apron: ['apron'],
    LabourLinearItem.leadBay: ['lead bay', 'lead roll'],
    LabourLinearItem.chimneySoaker: ['soaker'],
    LabourLinearItem.pipeCollar: ['pipe collar', 'collar'],
    LabourLinearItem.leadDrip: ['drip'],
    LabourLinearItem.heritageLead: ['heritage lead'],
    LabourLinearItem.eaves: ['eaves', 'fascia'],
    LabourLinearItem.ventilationStrip: ['ventilation', 'vent strip'],
    LabourLinearItem.flatUpstand: ['upstand'],
    LabourLinearItem.flatDrip: ['flat drip'],
    LabourLinearItem.edgeTrim: ['edge trim', 'trim'],
  };

  static List<LabourMaterialLine> suggestForSection({
    required LabourRoofSection section,
    required List<MaterialPriceEntry> priceList,
  }) {
    if (priceList.isEmpty) return [];

    final input = LabourSectionCalculator.effectiveInput(section);
    if (input.roofAreaSqm <= 0 && !_hasLinearQuantities(input)) {
      return [];
    }

    return _suggestFromQuantities(
      priceList: priceList,
      roofType: section.input.roofType,
      areaSqm: input.roofAreaSqm,
      input: input,
    );
  }

  static List<LabourMaterialLine> suggestForProject({
    required LabourQuoteProject project,
    required List<MaterialPriceEntry> priceList,
  }) {
    if (priceList.isEmpty || project.sections.isEmpty) return [];

    var totalArea = 0.0;
    final mergedLinear = <LabourLinearItem, double>{};

    for (final section in project.sections) {
      final input = LabourSectionCalculator.effectiveInput(section);
      totalArea += input.roofAreaSqm;
      for (final item in LabourLinearItem.values) {
        final metres = input.linearMetresFor(item);
        if (metres <= 0) continue;
        mergedLinear[item] = (mergedLinear[item] ?? 0) + metres;
      }
    }

    final syntheticInput = LabourQuoteInput(
      mode: project.sections.first.input.mode,
      roofType: project.sections.first.input.roofType,
      roofAreaSqm: totalArea,
      linearMetres: mergedLinear,
    );

    return _suggestFromQuantities(
      priceList: priceList,
      roofType: project.sections.first.input.roofType,
      areaSqm: totalArea,
      input: syntheticInput,
    );
  }

  static List<LabourMaterialLine> _suggestFromQuantities({
    required List<MaterialPriceEntry> priceList,
    required LabourRoofType roofType,
    required double areaSqm,
    required LabourQuoteInput input,
  }) {
    final lines = <LabourMaterialLine>[];

    for (final entry in priceList) {
      if (!_categoryMatchesRoof(entry.category, roofType)) continue;

      final linearQty = _linearQuantityForEntry(entry, input);
      if (linearQty != null && linearQty > 0) {
        lines.add(_lineFromEntry(entry, linearQty));
        continue;
      }

      if (areaSqm <= 0) continue;
      final areaQty = _areaQuantityForEntry(entry, areaSqm);
      if (areaQty != null && areaQty > 0) {
        lines.add(_lineFromEntry(entry, areaQty));
      }
    }

    return lines;
  }

  static bool _hasLinearQuantities(LabourQuoteInput input) {
    for (final item in LabourLinearItem.values) {
      if (input.linearMetresFor(item) > 0) return true;
    }
    return false;
  }

  static bool _categoryMatchesRoof(
    MaterialCategory category,
    LabourRoofType roofType,
  ) {
    if (roofType.isFlat) {
      return category == MaterialCategory.flatRoof ||
          category == MaterialCategory.underlay ||
          category == MaterialCategory.leadFlashings ||
          category == MaterialCategory.ventilation ||
          category == MaterialCategory.other;
    }

    switch (category) {
      case MaterialCategory.flatRoof:
        return false;
      case MaterialCategory.tilesSlates:
        return roofType.isPitched;
      default:
        return true;
    }
  }

  static double? _linearQuantityForEntry(
    MaterialPriceEntry entry,
    LabourQuoteInput input,
  ) {
    final unit = entry.unit.trim().toLowerCase();
    if (!_linearUnits.contains(unit)) return null;

    final description = entry.description.toLowerCase();
    for (final item in LabourLinearItem.values) {
      final metres = input.linearMetresFor(item);
      if (metres <= 0) continue;

      final keywords = _linearKeywordMap[item] ?? [item.label.toLowerCase()];
      if (keywords.any(description.contains)) {
        return metres;
      }
    }
    return null;
  }

  static double? _areaQuantityForEntry(
    MaterialPriceEntry entry,
    double areaSqm,
  ) {
    if (entry.coveragePerUnit <= 0) return null;

    final category = entry.category;
    if (category != MaterialCategory.tilesSlates &&
        category != MaterialCategory.underlay &&
        category != MaterialCategory.flatRoof) {
      return null;
    }

    final wasteFactor = 1 + (entry.wastePercent / 100);
    final unit = entry.unit.trim().toLowerCase();

    if (unit.contains('roll') ||
        unit.contains('sheet') ||
        entry.coveragePerUnit >= 20) {
      return _ceilQty(areaSqm / entry.coveragePerUnit * wasteFactor);
    }

    return _ceilQty(areaSqm * entry.coveragePerUnit * wasteFactor);
  }

  static double _ceilQty(double value) {
    if (value <= 0) return 0;
    final nearest = value.roundToDouble();
    if ((value - nearest).abs() < 1e-6) return nearest;
    return value.ceilToDouble();
  }

  static LabourMaterialLine _lineFromEntry(
    MaterialPriceEntry entry,
    double suggestedQty,
  ) {
    return LabourMaterialLine(
      priceListEntryId: entry.id,
      description: entry.description,
      unit: entry.unit,
      suggestedQty: suggestedQty,
      unitPrice: entry.unitPrice,
      notes: entry.notes,
    );
  }
}