import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary_catalog.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_global_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_catalog.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type_rate_set.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_backend_provider.dart';
import 'package:roofgrid_uk/widgets/labour/customer_quote_branding_tab.dart';
import 'package:roofgrid_uk/widgets/labour/labour_materials_price_list_tab.dart';
import 'package:roofgrid_uk/widgets/labour/labour_rate_fields.dart';
import 'package:share_plus/share_plus.dart';

/// Full Profile labour rates editor with labour + material price list tabs.
class LabourRatesEditor extends ConsumerStatefulWidget {
  const LabourRatesEditor({super.key});

  @override
  ConsumerState<LabourRatesEditor> createState() => _LabourRatesEditorState();
}

class _LabourRatesEditorState extends ConsumerState<LabourRatesEditor>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  LabourRoofType _selectedRoofType = LabourRoofType.traditionalPantile;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _searchQuery => _searchController.text.trim().toLowerCase();

  bool _matches(String label) =>
      _searchQuery.isEmpty || label.toLowerCase().contains(_searchQuery);

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset labour rates?'),
        content: const Text(
          'This restores all UK 2026 default rates and timings on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(labourBackendProvider.notifier).resetToDefaults();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Labour rates reset to defaults')),
    );
  }

  Future<void> _exportJson() async {
    final json = ref.read(labourBackendProvider).exportJson;
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/roofgrid_labour_rates_${DateTime.now().millisecondsSinceEpoch}.json';
    await File(path).writeAsString(json, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/json')],
        text: 'RoofGrid UK labour rates export',
      ),
    );
  }

  Future<void> _importJson() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    final raw = await File(result.files.single.path!).readAsString();
    final ok =
        await ref.read(labourBackendProvider.notifier).importFromJsonString(raw);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Labour rates imported' : 'Could not import — invalid JSON',
        ),
      ),
    );
  }

  void _updateRateSet(LabourRoofTypeRateSet Function(LabourRoofTypeRateSet) fn) {
    final backend = ref.read(labourBackendProvider).backendData;
    final current = backend.rateSetFor(_selectedRoofType);
    ref
        .read(labourBackendProvider.notifier)
        .updateRateSet(_selectedRoofType, fn(current));
  }

  @override
  Widget build(BuildContext context) {
    final backendState = ref.watch(labourBackendProvider);
    final rateSet = backendState.backendData.rateSetFor(_selectedRoofType);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Labour rates',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Saved on this device. Changes apply immediately to open quotes.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search items',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportJson,
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Export JSON'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _importJson,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Import JSON'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pricing'),
            Tab(text: 'Linear'),
            Tab(text: 'Ancillaries'),
            Tab(text: 'Timing'),
            Tab(text: 'Config'),
            Tab(text: 'Materials'),
            Tab(text: 'Customer Quote'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PricingTab(
                roofType: _selectedRoofType,
                rateSet: rateSet,
                onRoofTypeChanged: (v) => setState(() => _selectedRoofType = v),
                onUpdate: _updateRateSet,
              ),
              _LinearRatesTab(
                roofType: _selectedRoofType,
                rateSet: rateSet,
                searchMatches: _matches,
                onRoofTypeChanged: (v) => setState(() => _selectedRoofType = v),
                onUpdate: _updateRateSet,
              ),
              _AncillaryRatesTab(
                roofType: _selectedRoofType,
                rateSet: rateSet,
                searchMatches: _matches,
                onRoofTypeChanged: (v) => setState(() => _selectedRoofType = v),
                onUpdate: _updateRateSet,
              ),
              _TimingTab(
                roofType: _selectedRoofType,
                rateSet: rateSet,
                searchMatches: _matches,
                onRoofTypeChanged: (v) => setState(() => _selectedRoofType = v),
                onUpdate: _updateRateSet,
              ),
              _ConfigTab(
                global: backendState.backendData.global,
                onReset: _confirmReset,
              ),
              LabourMaterialsPriceListTab(searchMatches: _matches),
              const CustomerQuoteBrandingTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoofTypePicker extends StatelessWidget {
  final LabourRoofType value;
  final ValueChanged<LabourRoofType> onChanged;

  const _RoofTypePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<LabourRoofType>(
      decoration: const InputDecoration(
        labelText: 'Roof type',
        border: OutlineInputBorder(),
      ),
      value: value,
      items: LabourRoofType.values
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Text(type.label),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _PricingTab extends StatelessWidget {
  final LabourRoofType roofType;
  final LabourRoofTypeRateSet rateSet;
  final ValueChanged<LabourRoofType> onRoofTypeChanged;
  final void Function(LabourRoofTypeRateSet Function(LabourRoofTypeRateSet)) onUpdate;

  const _PricingTab({
    required this.roofType,
    required this.rateSet,
    required this.onRoofTypeChanged,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoofTypePicker(value: roofType, onChanged: onRoofTypeChanged),
          const SizedBox(height: 16),
          Text('Direct — £/m²', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          LabourMoneyField(
            label: 'Strip',
            value: rateSet.directMoney.stripPerSqm,
            onChanged: (v) => onUpdate(
              (r) => r.copyWith(
                directMoney: r.directMoney.copyWith(stripPerSqm: v),
              ),
            ),
          ),
          LabourMoneyField(
            label: 'Install',
            value: rateSet.directMoney.installPerSqm,
            onChanged: (v) => onUpdate(
              (r) => r.copyWith(
                directMoney: r.directMoney.copyWith(installPerSqm: v),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Sub — £/m²', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          LabourMoneyField(
            label: 'Strip',
            value: rateSet.subMoney.stripPerSqm,
            onChanged: (v) => onUpdate(
              (r) => r.copyWith(subMoney: r.subMoney.copyWith(stripPerSqm: v)),
            ),
          ),
          LabourMoneyField(
            label: 'Install',
            value: rateSet.subMoney.installPerSqm,
            onChanged: (v) => onUpdate(
              (r) => r.copyWith(subMoney: r.subMoney.copyWith(installPerSqm: v)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinearRatesTab extends StatelessWidget {
  final LabourRoofType roofType;
  final LabourRoofTypeRateSet rateSet;
  final bool Function(String) searchMatches;
  final ValueChanged<LabourRoofType> onRoofTypeChanged;
  final void Function(LabourRoofTypeRateSet Function(LabourRoofTypeRateSet)) onUpdate;

  const _LinearRatesTab({
    required this.roofType,
    required this.rateSet,
    required this.searchMatches,
    required this.onRoofTypeChanged,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final groups = LabourLinearCatalog.allGroups;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _RoofTypePicker(value: roofType, onChanged: onRoofTypeChanged),
          const SizedBox(height: 8),
          ...groups.map((group) {
            final items = LabourLinearCatalog.itemsForGroup(group)
                .where((item) => searchMatches(item.label))
                .toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return ExpansionTile(
              title: Text(
                group.label,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label, style: GoogleFonts.poppins(fontSize: 13)),
                      LabourMoneyField(
                        label: 'Direct £/lm',
                        value: rateSet.directItemMoney.linearRateFor(item),
                        onChanged: (v) => onUpdate((r) {
                          final next = Map<LabourLinearItem, double>.from(
                            r.directItemMoney.linearRatePerMetre,
                          );
                          next[item] = v;
                          return r.copyWith(
                            directItemMoney: r.directItemMoney.copyWith(
                              linearRatePerMetre: next,
                            ),
                          );
                        }),
                      ),
                      LabourMoneyField(
                        label: 'Sub £/lm',
                        value: rateSet.subItemMoney.linearRateFor(item),
                        onChanged: (v) => onUpdate((r) {
                          final next = Map<LabourLinearItem, double>.from(
                            r.subItemMoney.linearRatePerMetre,
                          );
                          next[item] = v;
                          return r.copyWith(
                            subItemMoney: r.subItemMoney.copyWith(
                              linearRatePerMetre: next,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _AncillaryRatesTab extends StatelessWidget {
  final LabourRoofType roofType;
  final LabourRoofTypeRateSet rateSet;
  final bool Function(String) searchMatches;
  final ValueChanged<LabourRoofType> onRoofTypeChanged;
  final void Function(LabourRoofTypeRateSet Function(LabourRoofTypeRateSet)) onUpdate;

  const _AncillaryRatesTab({
    required this.roofType,
    required this.rateSet,
    required this.searchMatches,
    required this.onRoofTypeChanged,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _RoofTypePicker(value: roofType, onChanged: onRoofTypeChanged),
          const SizedBox(height: 8),
          ...LabourAncillaryCatalog.allGroups.map((group) {
            final items = (LabourAncillaryCatalog.itemsByGroup[group] ?? [])
                .where((item) => searchMatches(item.label))
                .toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return ExpansionTile(
              title: Text(
                group.label,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label, style: GoogleFonts.poppins(fontSize: 13)),
                      LabourMoneyField(
                        label: 'Direct £/unit',
                        value: rateSet.directItemMoney.ancillaryRateFor(item),
                        onChanged: (v) => onUpdate((r) {
                          final next = Map<LabourAncillary, double>.from(
                            r.directItemMoney.ancillaryRateEach,
                          );
                          next[item] = v;
                          return r.copyWith(
                            directItemMoney: r.directItemMoney.copyWith(
                              ancillaryRateEach: next,
                            ),
                          );
                        }),
                      ),
                      LabourMoneyField(
                        label: 'Sub £/unit',
                        value: rateSet.subItemMoney.ancillaryRateFor(item),
                        onChanged: (v) => onUpdate((r) {
                          final next = Map<LabourAncillary, double>.from(
                            r.subItemMoney.ancillaryRateEach,
                          );
                          next[item] = v;
                          return r.copyWith(
                            subItemMoney: r.subItemMoney.copyWith(
                              ancillaryRateEach: next,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _TimingTab extends StatelessWidget {
  final LabourRoofType roofType;
  final LabourRoofTypeRateSet rateSet;
  final bool Function(String) searchMatches;
  final ValueChanged<LabourRoofType> onRoofTypeChanged;
  final void Function(LabourRoofTypeRateSet Function(LabourRoofTypeRateSet)) onUpdate;

  const _TimingTab({
    required this.roofType,
    required this.rateSet,
    required this.searchMatches,
    required this.onRoofTypeChanged,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoofTypePicker(value: roofType, onChanged: onRoofTypeChanged),
          const SizedBox(height: 12),
          Text('Area hours / m²', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          LabourDecimalField(
            label: 'Direct strip h/m²',
            value: rateSet.directTiming.stripHoursPerSqm,
            onChanged: (v) => onUpdate(
              (r) => r.copyWith(
                directTiming: r.directTiming.copyWith(stripHoursPerSqm: v),
              ),
            ),
          ),
          LabourDecimalField(
            label: 'Direct install h/m²',
            value: rateSet.directTiming.installHoursPerSqm,
            onChanged: (v) => onUpdate(
              (r) => r.copyWith(
                directTiming: r.directTiming.copyWith(installHoursPerSqm: v),
              ),
            ),
          ),
          LabourDecimalField(
            label: 'Sub strip h/m²',
            value: rateSet.subTiming.stripHoursPerSqm,
            onChanged: (v) => onUpdate(
              (r) => r.copyWith(
                subTiming: r.subTiming.copyWith(stripHoursPerSqm: v),
              ),
            ),
          ),
          LabourDecimalField(
            label: 'Sub install h/m²',
            value: rateSet.subTiming.installHoursPerSqm,
            onChanged: (v) => onUpdate(
              (r) => r.copyWith(
                subTiming: r.subTiming.copyWith(installHoursPerSqm: v),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Linear hours / lm', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ...LabourLinearItem.values.where((item) => searchMatches(item.label)).map(
            (item) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: GoogleFonts.poppins(fontSize: 13)),
                LabourDecimalField(
                  label: 'Direct h/lm',
                  value: rateSet.directTiming.hoursPerMetreFor(item),
                  onChanged: (v) => onUpdate((r) {
                    final next = Map<LabourLinearItem, double>.from(
                      r.directTiming.hoursPerMetre,
                    );
                    next[item] = v;
                    return r.copyWith(
                      directTiming: r.directTiming.copyWith(hoursPerMetre: next),
                    );
                  }),
                ),
                LabourDecimalField(
                  label: 'Sub h/lm',
                  value: rateSet.subTiming.hoursPerMetreFor(item),
                  onChanged: (v) => onUpdate((r) {
                    final next = Map<LabourLinearItem, double>.from(
                      r.subTiming.hoursPerMetre,
                    );
                    next[item] = v;
                    return r.copyWith(
                      subTiming: r.subTiming.copyWith(hoursPerMetre: next),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Ancillary hours / unit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ...LabourAncillary.values.where((a) => searchMatches(a.label)).map(
            (ancillary) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ancillary.label, style: GoogleFonts.poppins(fontSize: 13)),
                LabourDecimalField(
                  label: 'Direct h/unit',
                  value: rateSet.directTiming.hoursEachFor(ancillary),
                  onChanged: (v) => onUpdate((r) {
                    final next = Map<LabourAncillary, double>.from(
                      r.directTiming.hoursEach,
                    );
                    next[ancillary] = v;
                    return r.copyWith(
                      directTiming: r.directTiming.copyWith(hoursEach: next),
                    );
                  }),
                ),
                LabourDecimalField(
                  label: 'Sub h/unit',
                  value: rateSet.subTiming.hoursEachFor(ancillary),
                  onChanged: (v) => onUpdate((r) {
                    final next = Map<LabourAncillary, double>.from(
                      r.subTiming.hoursEach,
                    );
                    next[ancillary] = v;
                    return r.copyWith(
                      subTiming: r.subTiming.copyWith(hoursEach: next),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigTab extends ConsumerWidget {
  final LabourGlobalConfig global;
  final Future<void> Function() onReset;

  const _ConfigTab({required this.global, required this.onReset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(labourBackendProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Day rates', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          LabourMoneyField(
            label: 'Direct full day / man',
            value: global.directFullDayRatePerMan,
            onChanged: (v) =>
                notifier.updateGlobalConfig(global.copyWith(directFullDayRatePerMan: v)),
          ),
          LabourMoneyField(
            label: 'Direct half day / man',
            value: global.directHalfDayRatePerMan,
            onChanged: (v) =>
                notifier.updateGlobalConfig(global.copyWith(directHalfDayRatePerMan: v)),
          ),
          LabourMoneyField(
            label: 'Sub full day / man',
            value: global.subFullDayRatePerMan,
            onChanged: (v) =>
                notifier.updateGlobalConfig(global.copyWith(subFullDayRatePerMan: v)),
          ),
          LabourMoneyField(
            label: 'Sub half day / man',
            value: global.subHalfDayRatePerMan,
            onChanged: (v) =>
                notifier.updateGlobalConfig(global.copyWith(subHalfDayRatePerMan: v)),
          ),
          const SizedBox(height: 12),
          Text('Travel & overnight', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          LabourMoneyField(
            label: 'Cost per mile',
            value: global.costPerMile,
            onChanged: (v) =>
                notifier.updateGlobalConfig(global.copyWith(costPerMile: v)),
          ),
          LabourMoneyField(
            label: 'Overnight / night',
            value: global.overnightCostPerNight,
            onChanged: (v) =>
                notifier.updateGlobalConfig(global.copyWith(overnightCostPerNight: v)),
          ),
          LabourDecimalField(
            label: 'Hours per man-day',
            value: global.hoursPerManDay,
            onChanged: (v) =>
                notifier.updateGlobalConfig(global.copyWith(hoursPerManDay: v)),
          ),
          LabourIntField(
            label: 'Default gang size',
            value: global.defaultGangSize,
            onChanged: (v) =>
                notifier.updateGlobalConfig(global.copyWith(defaultGangSize: v)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Reset to UK defaults'),
          ),
        ],
      ),
    );
  }
}