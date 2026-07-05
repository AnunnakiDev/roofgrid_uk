import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_category.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_price_entry.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_materials_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/material_csv_service.dart';
import 'package:share_plus/share_plus.dart';

class LabourMaterialsPriceListTab extends ConsumerWidget {
  final bool Function(String label) searchMatches;

  const LabourMaterialsPriceListTab({
    super.key,
    required this.searchMatches,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsState = ref.watch(labourMaterialsProvider);
    final notifier = ref.read(labourMaterialsProvider.notifier);
    final gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');

    if (!materialsState.isHydrated) {
      return const Center(child: CircularProgressIndicator());
    }

    final entries = materialsState.entries
        .where(
          (entry) =>
              searchMatches(entry.description) ||
              searchMatches(entry.category.label),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Personal material price list used for BoQ suggestions and Method A '
          'material costs.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportCsv(context, ref),
                icon: const Icon(Icons.upload_rounded),
                label: const Text('Export CSV'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _importCsv(context, ref),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Import CSV'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _showEntryDialog(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add material'),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          Text(
            'No materials yet. Import a CSV or add your first price list row.',
            style: GoogleFonts.poppins(fontSize: 13),
          )
        else
          ...entries.map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  entry.description,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${entry.category.label} · ${entry.unit} · '
                  'cover ${entry.coveragePerUnit} · '
                  'waste ${entry.wastePercent.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: Text(
                  gbp.format(entry.unitPrice),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                onTap: () => _showEntryDialog(context, ref, existing: entry),
                onLongPress: () => _confirmDelete(context, ref, entry),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final csv = ref.read(labourMaterialsProvider.notifier).exportCsv();
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/roofgrid_materials_${DateTime.now().millisecondsSinceEpoch}.csv';
    await File(path).writeAsString(csv, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'text/csv')],
        text: 'RoofGrid UK material price list',
      ),
    );
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (result == null || result.files.single.path == null) return;

    final raw = await File(result.files.single.path!).readAsString();
    final importResult =
        await ref.read(labourMaterialsProvider.notifier).importFromCsv(raw);
    if (!context.mounted) return;

    await _showImportSummary(context, importResult);
  }

  Future<void> _showImportSummary(
    BuildContext context,
    MaterialCsvImportResult result,
  ) async {
    final buffer = StringBuffer()
      ..writeln('Imported: ${result.imported}')
      ..writeln('Updated: ${result.updated}');
    if (result.errors.isNotEmpty) {
      buffer.writeln('Errors: ${result.errors.length}');
      buffer.writeln(result.errors.take(5).join('\n'));
      if (result.errors.length > 5) {
        buffer.writeln('…and ${result.errors.length - 5} more');
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('CSV import summary'),
        content: SingleChildScrollView(child: Text(buffer.toString())),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MaterialPriceEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete material?'),
        content: Text('Remove "${entry.description}" from your price list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    ref.read(labourMaterialsProvider.notifier).deleteEntry(entry.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted "${entry.description}"')),
    );
  }

  Future<void> _showEntryDialog(
    BuildContext context,
    WidgetRef ref, {
    MaterialPriceEntry? existing,
  }) async {
    final notifier = ref.read(labourMaterialsProvider.notifier);
    var category = existing?.category ?? MaterialCategory.tilesSlates;
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final unitController = TextEditingController(text: existing?.unit ?? 'each');
    final coverageController = TextEditingController(
      text: existing?.coveragePerUnit == null || existing!.coveragePerUnit == 0
          ? ''
          : existing.coveragePerUnit.toString(),
    );
    final wasteController = TextEditingController(
      text: existing?.wastePercent == null
          ? defaultMaterialWastePercent.toString()
          : existing!.wastePercent.toString(),
    );
    final priceController = TextEditingController(
      text: existing?.unitPrice == null || existing!.unitPrice == 0
          ? ''
          : existing.unitPrice.toString(),
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add material' : 'Edit material'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<MaterialCategory>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: MaterialCategory.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => category = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: coverageController,
                      decoration: const InputDecoration(
                        labelText: 'Coverage per unit',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: wasteController,
                      decoration: const InputDecoration(
                        labelText: 'Waste %',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Unit price (£)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      descriptionController.dispose();
      unitController.dispose();
      coverageController.dispose();
      wasteController.dispose();
      priceController.dispose();
      notesController.dispose();
      return;
    }

    final description = descriptionController.text.trim();
    final unit = unitController.text.trim();
    final coverage = double.tryParse(coverageController.text.trim());
    final waste =
        double.tryParse(wasteController.text.trim()) ?? defaultMaterialWastePercent;
    final price = double.tryParse(priceController.text.trim());
    final notes = notesController.text.trim();

    descriptionController.dispose();
    unitController.dispose();
    coverageController.dispose();
    wasteController.dispose();
    priceController.dispose();
    notesController.dispose();

    if (!context.mounted) return;
    if (description.isEmpty || unit.isEmpty || coverage == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Description, unit, coverage, and unit price are required'),
        ),
      );
      return;
    }

    final entry = MaterialPriceEntry(
      id: existing?.id ?? 'material_${DateTime.now().millisecondsSinceEpoch}',
      category: category,
      description: description,
      unit: unit,
      coveragePerUnit: coverage,
      wastePercent: waste,
      unitPrice: price,
      notes: notes,
    );

    if (existing == null) {
      notifier.addEntry(entry);
    } else {
      notifier.updateEntry(entry);
    }
  }
}