import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_material_line.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_backend_data.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_dual_quote_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_money_rates.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_project_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_rate_profile.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_rates.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_backend_migration.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_section_calculator.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_section_method_resolver.dart';

/// Pure Dart labour quote engine — no Flutter, Firestore, or Hive.
class LabourPricingEngine {
  LabourPricingEngine._();

  /// Legacy v1 entry point — delegates through migrated backend data.
  static LabourQuoteResult calculate({
    required LabourQuoteInput input,
    required LabourRates rates,
    required LabourQuoteConfig config,
  }) {
    final backend = LabourBackendMigration.fromLegacyRates(rates);
    return calculateDual(
      input: input,
      backend: backend,
      config: config,
      selectedMethod: LabourQuoteMethod.timingBased,
    ).methodB;
  }

  /// Runs Method A (rate-based) and Method B (timing-based) for one section.
  ///
  /// When [includeProjectExtras] is false, travel, overnight, and margin are
  /// omitted — used for per-section labour within [calculateProject].
  static LabourDualQuoteResult calculateDual({
    required LabourQuoteInput input,
    required LabourBackendData backend,
    required LabourQuoteConfig config,
    required LabourQuoteMethod selectedMethod,
    bool includeProjectExtras = true,
    double additionalHours = 0,
    LabourRoofType? stripRoofType,
    double installAreaMultiplier = 1,
    List<LabourMaterialLine> materialLines = const [],
  }) {
    final rateSet = backend.rateSetFor(input.roofType);
    final isDirect = input.mode == LabourPricingMode.direct;
    final moneyRates = isDirect ? rateSet.directMoney : rateSet.subMoney;
    final timingProfile = isDirect ? rateSet.directTiming : rateSet.subTiming;
    final dayRate = backend.global.fullDayRateFor(isDirect);

    final methodA = _calculateRateBased(
      input: input,
      moneyRates: moneyRates,
      config: config,
      backend: backend,
      includeProjectExtras: includeProjectExtras,
      stripRoofType: stripRoofType,
      installAreaMultiplier: installAreaMultiplier,
      materialLines: materialLines,
    );

    final methodB = _calculateTimingBased(
      input: input,
      profile: timingProfile,
      dayRate: dayRate,
      config: config,
      backend: backend,
      includeProjectExtras: includeProjectExtras,
      additionalHours: additionalHours,
      stripRoofType: stripRoofType,
      installAreaMultiplier: installAreaMultiplier,
    );

    return LabourDualQuoteResult(
      methodA: methodA,
      methodB: methodB,
      selectedMethod: selectedMethod,
    );
  }

  /// Multi-section project — section labour summed, extras applied once.
  static LabourProjectResult calculateProject({
    required LabourQuoteProject project,
    required LabourBackendData backend,
    required LabourQuoteConfig config,
  }) {
    final sectionResults = <LabourSectionResult>[];

    var labourA = 0.0;
    var labourB = 0.0;
    var labourActive = 0.0;
    var baseHoursA = 0.0;
    var upliftedHoursA = 0.0;
    var manDaysA = 0.0;
    var baseHoursB = 0.0;
    var upliftedHoursB = 0.0;
    var manDaysB = 0.0;
    var baseHoursActive = 0.0;
    var upliftedHoursActive = 0.0;
    var manDaysActive = 0.0;

    for (final section in project.sections) {
      final effectiveInput = LabourSectionCalculator.effectiveInput(section);
      final calcParams = LabourSectionCalculator.calcParams(section);
      if (!effectiveInput.hasQuantities && calcParams.additionalHours <= 0) {
        continue;
      }

      final sectionConfig = LabourSectionCalculator.configWithSectionUplift(
        baseConfig: config,
        section: section,
      );

      final dual = calculateDual(
        input: effectiveInput,
        backend: backend,
        config: sectionConfig,
        selectedMethod: section.selectedMethod,
        includeProjectExtras: false,
        additionalHours: calcParams.additionalHours,
        stripRoofType: calcParams.stripRoofType,
        installAreaMultiplier: calcParams.installAreaMultiplier,
        materialLines: project.materialLinesFor(section),
      );

      sectionResults.add(
        LabourSectionResult(section: section, dualResult: dual),
      );

      labourA += dual.methodA.baseLabourCostGbp;
      labourB += dual.methodB.baseLabourCostGbp;
      labourActive += LabourSectionMethodResolver.activeLabourCostGbp(
        section: section,
        dual: dual,
      );

      baseHoursA += dual.methodA.baseHours;
      upliftedHoursA += dual.methodA.upliftedHours;
      manDaysA += dual.methodA.manDays;

      baseHoursB += dual.methodB.baseHours;
      upliftedHoursB += dual.methodB.upliftedHours;
      manDaysB += dual.methodB.manDays;

      final active = LabourSectionMethodResolver.activeResult(
        section: section,
        dual: dual,
      );
      baseHoursActive += active.baseHours;
      upliftedHoursActive += active.upliftedHours;
      manDaysActive += active.manDays;
    }

    return LabourProjectResult(
      sectionResults: sectionResults,
      rollup: _finalizeProjectRollup(
        baseLabourCostGbp: labourActive,
        baseHours: baseHoursActive,
        upliftedHours: upliftedHoursActive,
        manDays: manDaysActive,
        config: config,
        backend: backend,
        contingencyPercent: project.contingencyPercent,
      ),
      methodARollup: _finalizeProjectRollup(
        baseLabourCostGbp: labourA,
        baseHours: baseHoursA,
        upliftedHours: upliftedHoursA,
        manDays: manDaysA,
        config: config,
        backend: backend,
        contingencyPercent: project.contingencyPercent,
      ),
      methodBRollup: _finalizeProjectRollup(
        baseLabourCostGbp: labourB,
        baseHours: baseHoursB,
        upliftedHours: upliftedHoursB,
        manDays: manDaysB,
        config: config,
        backend: backend,
        contingencyPercent: project.contingencyPercent,
      ),
    );
  }

  /// Method A — strip/install m² × £/m² plus linear/ancillary (hours × £/h proxy).
  static LabourQuoteResult _calculateRateBased({
    required LabourQuoteInput input,
    required LabourPricingMoneyRates moneyRates,
    required LabourQuoteConfig config,
    required LabourBackendData backend,
    bool includeProjectExtras = true,
    LabourRoofType? stripRoofType,
    double installAreaMultiplier = 1,
    List<LabourMaterialLine> materialLines = const [],
  }) {
    final breakdown = <LabourQuoteBreakdownLine>[];
    var areaCost = 0.0;
    final isDirect = input.mode == LabourPricingMode.direct;

    if (input.includeStrip && input.roofAreaSqm > 0) {
      final stripType = stripRoofType ?? input.roofType;
      final stripRateSet = backend.rateSetFor(stripType);
      final stripMoney =
          isDirect ? stripRateSet.directMoney : stripRateSet.subMoney;
      final cost = input.roofAreaSqm * stripMoney.stripPerSqm;
      areaCost += cost;
      breakdown.add(
        LabourQuoteBreakdownLine(
          label: 'Strip (${stripType.label})',
          hours: 0,
          costGbp: cost,
        ),
      );
    }

    if (input.roofAreaSqm > 0) {
      final installArea = input.roofAreaSqm * installAreaMultiplier;
      final cost = installArea * moneyRates.installPerSqm;
      areaCost += cost;
      final installLabel = installAreaMultiplier > 1
          ? 'Install (${input.roofType.label}, ×${installAreaMultiplier.toStringAsFixed(2)})'
          : 'Install (${input.roofType.label})';
      breakdown.add(
        LabourQuoteBreakdownLine(
          label: installLabel,
          hours: 0,
          costGbp: cost,
        ),
      );
    }

    final rateSet = backend.rateSetFor(input.roofType);
    final timingProfile = input.mode == LabourPricingMode.direct
        ? rateSet.directTiming
        : rateSet.subTiming;
    final itemMoney = input.mode == LabourPricingMode.direct
        ? rateSet.directItemMoney
        : rateSet.subItemMoney;
    final hourlyRate =
        backend.global.fullDayRateFor(input.mode == LabourPricingMode.direct) /
            backend.global.hoursPerManDay;

    var linearCost = 0.0;
    for (final item in LabourLinearItem.values) {
      final metres = input.linearMetresFor(item);
      if (metres <= 0) continue;
      final hours = metres * timingProfile.hoursPerMetreFor(item);
      final ratePerMetre = itemMoney.linearRateFor(item);
      final cost = ratePerMetre > 0
          ? metres * ratePerMetre
          : hours * hourlyRate;
      linearCost += cost;
      breakdown.add(
        LabourQuoteBreakdownLine(
          label: item.label,
          hours: hours,
          costGbp: cost,
        ),
      );
    }

    var ancillaryCost = 0.0;
    for (final ancillary in LabourAncillary.values) {
      final count = input.ancillaryCountFor(ancillary);
      if (count <= 0) continue;
      final hours = count * timingProfile.hoursEachFor(ancillary);
      final rateEach = itemMoney.ancillaryRateFor(ancillary);
      final cost =
          rateEach > 0 ? count * rateEach : hours * hourlyRate;
      ancillaryCost += cost;
      breakdown.add(
        LabourQuoteBreakdownLine(
          label: '${ancillary.label} × $count',
          hours: hours,
          costGbp: cost,
        ),
      );
    }

    var materialCost = 0.0;
    for (final line in materialLines) {
      if (!line.hasQuantity) continue;
      materialCost += line.lineTotalGbp;
      breakdown.add(
        LabourQuoteBreakdownLine(
          label: 'Material: ${line.description}',
          hours: 0,
          costGbp: line.lineTotalGbp,
        ),
      );
    }

    final baseLabourCostGbp =
        areaCost + linearCost + ancillaryCost + materialCost;
    return _finalizeQuote(
      baseHours: 0,
      upliftedHours: 0,
      manDays: 0,
      baseLabourCostGbp: baseLabourCostGbp,
      config: config,
      backend: backend,
      breakdown: breakdown,
      includeProjectExtras: includeProjectExtras,
    );
  }

  /// Method B — hours from timings, convert to gang-days × day rate.
  static LabourQuoteResult _calculateTimingBased({
    required LabourQuoteInput input,
    required LabourRateProfile profile,
    required double dayRate,
    required LabourQuoteConfig config,
    required LabourBackendData backend,
    bool includeProjectExtras = true,
    double additionalHours = 0,
    LabourRoofType? stripRoofType,
    double installAreaMultiplier = 1,
  }) {
    final breakdown = <LabourQuoteBreakdownLine>[];
    var baseHours = 0.0;
    final isDirect = input.mode == LabourPricingMode.direct;

    if (input.includeStrip && input.roofAreaSqm > 0) {
      final stripType = stripRoofType ?? input.roofType;
      final stripRateSet = backend.rateSetFor(stripType);
      final stripProfile =
          isDirect ? stripRateSet.directTiming : stripRateSet.subTiming;
      final hours = input.roofAreaSqm * stripProfile.stripHoursPerSqm;
      baseHours += hours;
      breakdown.add(
        LabourQuoteBreakdownLine(
          label: 'Strip (${stripType.label})',
          hours: hours,
        ),
      );
    }

    if (input.roofAreaSqm > 0) {
      final installArea = input.roofAreaSqm * installAreaMultiplier;
      final hours = installArea * profile.installHoursPerSqm;
      baseHours += hours;
      final installLabel = installAreaMultiplier > 1
          ? 'Install (${input.roofType.label}, ×${installAreaMultiplier.toStringAsFixed(2)})'
          : 'Install (${input.roofType.label})';
      breakdown.add(
        LabourQuoteBreakdownLine(
          label: installLabel,
          hours: hours,
        ),
      );
    }

    for (final item in LabourLinearItem.values) {
      final metres = input.linearMetresFor(item);
      if (metres <= 0) continue;
      final hours = metres * profile.hoursPerMetreFor(item);
      baseHours += hours;
      breakdown.add(
        LabourQuoteBreakdownLine(
          label: item.label,
          hours: hours,
        ),
      );
    }

    for (final ancillary in LabourAncillary.values) {
      final count = input.ancillaryCountFor(ancillary);
      if (count <= 0) continue;
      final hours = count * profile.hoursEachFor(ancillary);
      baseHours += hours;
      breakdown.add(
        LabourQuoteBreakdownLine(
          label: '${ancillary.label} × $count',
          hours: hours,
        ),
      );
    }

    if (additionalHours > 0) {
      baseHours += additionalHours;
      breakdown.add(
        LabourQuoteBreakdownLine(
          label: 'Complexity-derived hours',
          hours: additionalHours,
        ),
      );
    }

    final upliftFactor = 1 + (config.difficultyUpliftPercent / 100);
    final upliftedHours = baseHours * upliftFactor;
    if (config.difficultyUpliftPercent > 0) {
      breakdown.add(
        LabourQuoteBreakdownLine(
          label:
              'Difficulty uplift (${config.difficultyUpliftPercent.toStringAsFixed(0)}%)',
          hours: upliftedHours - baseHours,
        ),
      );
    }

    final gangSize = config.gangSize.clamp(1, 99);
    final hoursPerManDay =
        config.hoursPerManDay <= 0 ? backend.global.hoursPerManDay : config.hoursPerManDay;
    final manDays = upliftedHours / (gangSize * hoursPerManDay);

    final baseLabourCostGbp = _labourCostFromManDays(
      manDays: manDays,
      gangSize: gangSize,
      dayRatePerMan: dayRate,
    );

    return _finalizeQuote(
      baseHours: baseHours,
      upliftedHours: upliftedHours,
      manDays: manDays,
      baseLabourCostGbp: baseLabourCostGbp,
      config: config,
      backend: backend,
      breakdown: breakdown,
      includeProjectExtras: includeProjectExtras,
    );
  }

  static LabourQuoteResult _finalizeQuote({
    required double baseHours,
    required double upliftedHours,
    required double manDays,
    required double baseLabourCostGbp,
    required LabourQuoteConfig config,
    required LabourBackendData backend,
    required List<LabourQuoteBreakdownLine> breakdown,
    bool includeProjectExtras = true,
    double contingencyPercent = 0,
  }) {
    final upliftFactor = 1 + (config.difficultyUpliftPercent / 100);
    final adjustedLabourCost = baseHours > 0
        ? baseLabourCostGbp
        : baseLabourCostGbp * upliftFactor;

    if (!includeProjectExtras) {
      return LabourQuoteResult(
        baseHours: baseHours,
        upliftedHours: upliftedHours,
        manDays: manDays,
        baseLabourCostGbp: adjustedLabourCost,
        travelCostGbp: 0,
        overnightCostGbp: 0,
        subtotalCostGbp: adjustedLabourCost,
        quoteTotalGbp: adjustedLabourCost,
        profitableDayRatePerManGbp: 0,
        profitableDayRatePerGangGbp: 0,
        breakdown: breakdown,
      );
    }

    return _finalizeProjectRollup(
      baseLabourCostGbp: adjustedLabourCost,
      baseHours: baseHours,
      upliftedHours: upliftedHours,
      manDays: manDays,
      config: config,
      backend: backend,
      contingencyPercent: contingencyPercent,
      breakdown: breakdown,
    );
  }

  static LabourQuoteResult _finalizeProjectRollup({
    required double baseLabourCostGbp,
    required double baseHours,
    required double upliftedHours,
    required double manDays,
    required LabourQuoteConfig config,
    required LabourBackendData backend,
    double contingencyPercent = 0,
    List<LabourQuoteBreakdownLine> breakdown = const [],
  }) {
    final travelCostGbp =
        config.travelMiles * backend.global.costPerMile * 2;
    final overnightCostGbp =
        config.overnightNights * backend.global.overnightCostPerNight;
    final preContingency =
        baseLabourCostGbp + travelCostGbp + overnightCostGbp;
    final contingencyCostGbp =
        preContingency * (contingencyPercent / 100).clamp(0.0, 100.0);
    final subtotalCostGbp = preContingency + contingencyCostGbp;

    final marginFraction =
        (config.targetMarginPercent / 100).clamp(0.0, 0.95).toDouble();
    final quoteTotalGbp = subtotalCostGbp / (1 - marginFraction);

    final gangSize = config.gangSize.clamp(1, 99);
    final hoursPerManDay = config.hoursPerManDay <= 0
        ? backend.global.hoursPerManDay
        : config.hoursPerManDay;
    final manDayCapacity = manDays > 0
        ? manDays * gangSize
        : (upliftedHours > 0 ? upliftedHours / hoursPerManDay : 0);

    final profitableDayRatePerManGbp =
        manDayCapacity > 0 ? quoteTotalGbp / manDayCapacity : 0.0;
    final profitableDayRatePerGangGbp =
        manDays > 0 ? quoteTotalGbp / manDays : 0.0;

    return LabourQuoteResult(
      baseHours: baseHours,
      upliftedHours: upliftedHours,
      manDays: manDays,
      baseLabourCostGbp: baseLabourCostGbp,
      travelCostGbp: travelCostGbp,
      overnightCostGbp: overnightCostGbp,
      subtotalCostGbp: subtotalCostGbp,
      quoteTotalGbp: quoteTotalGbp,
      profitableDayRatePerManGbp: profitableDayRatePerManGbp,
      profitableDayRatePerGangGbp: profitableDayRatePerGangGbp,
      breakdown: breakdown,
    );
  }

  /// Bills gang-days rounded up to the nearest half day, then × gang × day rate.
  static double _labourCostFromManDays({
    required double manDays,
    required int gangSize,
    required double dayRatePerMan,
  }) {
    if (manDays <= 0 || gangSize <= 0) return 0;

    final billedGangDays = (manDays * 2).ceil() / 2;
    return billedGangDays * gangSize * dayRatePerMan;
  }
}