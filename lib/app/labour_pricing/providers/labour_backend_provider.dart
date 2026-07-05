import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_backend_data.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_global_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_money_rates.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type_rate_set.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_config_storage.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/services/hive_service.dart';

class LabourBackendState {
  final LabourBackendData backendData;
  final LabourQuoteConfig quoteConfig;
  final bool isHydrated;

  const LabourBackendState({
    required this.backendData,
    required this.quoteConfig,
    this.isHydrated = false,
  });

  factory LabourBackendState.initial() {
    final defaults = LabourPersistedSettings.defaults();
    return LabourBackendState(
      backendData: defaults.backendData,
      quoteConfig: defaults.quoteConfig,
    );
  }

  String get exportJson =>
      const JsonEncoder.withIndent('  ').convert(backendData.toJson());

  LabourBackendState copyWith({
    LabourBackendData? backendData,
    LabourQuoteConfig? quoteConfig,
    bool? isHydrated,
  }) {
    return LabourBackendState(
      backendData: backendData ?? this.backendData,
      quoteConfig: quoteConfig ?? this.quoteConfig,
      isHydrated: isHydrated ?? this.isHydrated,
    );
  }
}

class LabourBackendNotifier extends Notifier<LabourBackendState> {
  Timer? _persistDebounce;

  @override
  LabourBackendState build() {
    ref.onDispose(() => _persistDebounce?.cancel());
    _hydrateFromHive();
    return LabourBackendState.initial();
  }

  Future<void> _hydrateFromHive() async {
    try {
      await ref.read(hiveServiceInitializerProvider.future);
      final box = await HiveService.ensureLabourConfigBox();
      final persisted = LabourConfigStorage.loadFromBox(box);
      state = state.copyWith(
        backendData: persisted.backendData,
        quoteConfig: persisted.quoteConfig,
        isHydrated: true,
      );
    } catch (_) {
      state = state.copyWith(isHydrated: true);
    }
  }

  Future<void> _persist() async {
    try {
      final box = await HiveService.ensureLabourConfigBox();
      await LabourConfigStorage.saveToBox(
        box,
        LabourPersistedSettings(
          backendData: state.backendData,
          quoteConfig: state.quoteConfig,
        ),
      );
    } catch (_) {
      // Local-first: ignore persistence errors during session edits.
    }
  }

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_persist());
    });
  }

  void updateQuoteConfig(LabourQuoteConfig quoteConfig) {
    final gangSize = quoteConfig.gangSize < 1 ? 1 : quoteConfig.gangSize;
    state = state.copyWith(
      quoteConfig: quoteConfig.copyWith(gangSize: gangSize),
    );
    _schedulePersist();
  }

  void updateGlobalConfig(LabourGlobalConfig global) {
    state = state.copyWith(
      backendData: state.backendData.copyWith(global: global),
    );
    _schedulePersist();
  }

  void updatePricingRates({
    required LabourRoofType roofType,
    required LabourPricingMoneyRates directMoney,
    required LabourPricingMoneyRates subMoney,
  }) {
    final current = state.backendData.rateSetFor(roofType);
    state = state.copyWith(
      backendData: state.backendData.updateRateSet(
        roofType,
        current.copyWith(directMoney: directMoney, subMoney: subMoney),
      ),
    );
    _schedulePersist();
  }

  void updateRateSet(LabourRoofType roofType, LabourRoofTypeRateSet rateSet) {
    state = state.copyWith(
      backendData: state.backendData.updateRateSet(roofType, rateSet),
    );
    _schedulePersist();
  }

  Future<bool> importFromJsonString(String raw) async {
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map) return false;
      final backend = LabourBackendData.fromJson(
        Map<String, dynamic>.from(parsed),
      );
      state = state.copyWith(backendData: backend);
      await _persist();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetToDefaults() async {
    state = state.copyWith(
      backendData: LabourDefaults.backendData2026,
      quoteConfig: const LabourQuoteConfig(),
    );
    await _persist();
  }
}

final labourBackendProvider =
    NotifierProvider<LabourBackendNotifier, LabourBackendState>(
  LabourBackendNotifier.new,
);