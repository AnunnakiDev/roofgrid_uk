import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_price_entry.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_materials_storage.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/material_csv_service.dart';
import 'package:roofgrid_uk/services/hive_service.dart';

class LabourMaterialsState {
  final List<MaterialPriceEntry> entries;
  final bool isHydrated;

  const LabourMaterialsState({
    this.entries = const [],
    this.isHydrated = false,
  });

  MaterialPriceEntry? entryById(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  LabourMaterialsState copyWith({
    List<MaterialPriceEntry>? entries,
    bool? isHydrated,
  }) {
    return LabourMaterialsState(
      entries: entries ?? this.entries,
      isHydrated: isHydrated ?? this.isHydrated,
    );
  }
}

class LabourMaterialsNotifier extends Notifier<LabourMaterialsState> {
  Timer? _persistDebounce;

  @override
  LabourMaterialsState build() {
    ref.onDispose(() => _persistDebounce?.cancel());
    _hydrateFromHive();
    return const LabourMaterialsState();
  }

  Future<void> _hydrateFromHive() async {
    try {
      await ref.read(hiveServiceInitializerProvider.future);
      final box = await HiveService.ensureLabourMaterialsBox();
      final entries = LabourMaterialsStorage.loadFromBox(box);
      state = state.copyWith(entries: entries, isHydrated: true);
    } catch (_) {
      state = state.copyWith(isHydrated: true);
    }
  }

  Future<void> _persist() async {
    try {
      final box = await HiveService.ensureLabourMaterialsBox();
      await LabourMaterialsStorage.saveToBox(box, state.entries);
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

  void _setEntries(List<MaterialPriceEntry> entries) {
    state = state.copyWith(entries: entries);
    _schedulePersist();
  }

  void addEntry(MaterialPriceEntry entry) {
    _setEntries([...state.entries, entry]);
  }

  void updateEntry(MaterialPriceEntry entry) {
    final next = state.entries
        .map((existing) => existing.id == entry.id ? entry : existing)
        .toList();
    _setEntries(next);
  }

  bool deleteEntry(String id) {
    final next = state.entries.where((entry) => entry.id != id).toList();
    if (next.length == state.entries.length) return false;
    _setEntries(next);
    return true;
  }

  Future<void> replaceAll(List<MaterialPriceEntry> entries) async {
    state = state.copyWith(entries: entries);
    await _persist();
  }

  MaterialPriceEntry createEntry({
    required MaterialPriceEntry template,
  }) {
    return template.copyWith(
      id: 'material_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  String exportCsv() => MaterialCsvService.exportCsv(state.entries);

  Future<MaterialCsvImportResult> importFromCsv(String csvContent) async {
    final prefix = 'material_${DateTime.now().millisecondsSinceEpoch}';
    final parsed = MaterialCsvService.parseImport(
      csvContent,
      idPrefix: prefix,
    );

    if (parsed.entries.isEmpty && parsed.errors.isNotEmpty) {
      return MaterialCsvImportResult(errors: parsed.errors);
    }

    final existing = [...state.entries];
    var imported = 0;
    var updated = 0;
    var skipped = 0;

    for (final row in parsed.entries) {
      final index = existing.indexWhere((entry) => entry.matchKey == row.matchKey);
      if (index >= 0) {
        existing[index] = row.copyWith(id: existing[index].id);
        updated += 1;
      } else {
        existing.add(
          row.copyWith(id: '${prefix}_new_$imported'),
        );
        imported += 1;
      }
    }

    skipped = parsed.errors.length;
    await replaceAll(existing);

    return MaterialCsvImportResult(
      imported: imported,
      updated: updated,
      skipped: skipped,
      errors: parsed.errors,
    );
  }
}

final labourMaterialsProvider =
    NotifierProvider<LabourMaterialsNotifier, LabourMaterialsState>(
  LabourMaterialsNotifier.new,
);