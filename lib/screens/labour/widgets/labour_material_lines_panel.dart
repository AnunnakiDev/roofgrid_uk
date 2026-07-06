import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_material_line.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_category.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_price_entry.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_materials_provider.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_decimal_text_field.dart';
import 'package:roofgrid_uk/utils/layout_utils.dart';

class LabourMaterialLinesPanel extends ConsumerWidget {
  final List<LabourMaterialLine> lines;
  final ValueChanged<List<LabourMaterialLine>> onChanged;
  final VoidCallback? onSuggest;
  final String suggestLabel;

  const LabourMaterialLinesPanel({
    super.key,
    required this.lines,
    required this.onChanged,
    this.onSuggest,
    this.suggestLabel = 'Suggest from price list',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');
    final priceList = ref.watch(labourMaterialsProvider).entries;
    final total = lines.fold<double>(0, (sum, line) => sum + line.lineTotalGbp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onSuggest != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: priceList.isEmpty ? null : onSuggest,
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(suggestLabel),
            ),
          ),
          if (priceList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Add materials in Profile → Labour Rates → Materials first.',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
          const SizedBox(height: 10),
        ],
        if (lines.isEmpty)
          Text(
            'No material lines yet.',
            style: GoogleFonts.poppins(fontSize: 13),
          )
        else
          ...lines.asMap().entries.map((entry) {
            final index = entry.key;
            final line = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            line.description,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () {
                            final next = [...lines]..removeAt(index);
                            onChanged(next);
                          },
                          tooltip: 'Remove line',
                        ),
                      ],
                    ),
                    Text(
                      '${line.unit} · ${gbp.format(line.unitPrice)} each',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    _buildQtyRow(
                      context,
                      gbp: gbp,
                      line: line,
                      lines: lines,
                      index: index,
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ),
            );
          }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: priceList.isEmpty
                ? null
                : () => _showAddFromPriceList(context, priceList),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add from price list'),
          ),
        ),
        if (lines.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Materials subtotal: ${gbp.format(total)}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Widget _buildQtyRow(
    BuildContext context, {
    required NumberFormat gbp,
    required LabourMaterialLine line,
    required List<LabourMaterialLine> lines,
    required int index,
    required ValueChanged<List<LabourMaterialLine>> onChanged,
  }) {
    final narrow = isNarrowLayout(context);
    final suggested = _QtyField(
      label: 'Suggested',
      value: line.suggestedQty,
      enabled: false,
    );
    final actual = _QtyField(
      label: 'Actual qty',
      value: line.overrideQty ?? line.suggestedQty,
      onChanged: (qty) {
        final next = [...lines];
        next[index] = line.copyWith(overrideQty: qty);
        onChanged(next);
      },
    );
    final total = Text(
      gbp.format(line.lineTotalGbp),
      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          suggested,
          const SizedBox(height: 8),
          actual,
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: total),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: suggested),
        const SizedBox(width: 8),
        Expanded(child: actual),
        const SizedBox(width: 8),
        total,
      ],
    );
  }

  Future<void> _showAddFromPriceList(
    BuildContext context,
    List<MaterialPriceEntry> entries,
  ) async {
    final selected = await showModalBottomSheet<MaterialPriceEntry>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: entries
                .map(
                  (entry) => ListTile(
                    title: Text(entry.description),
                    subtitle: Text('${entry.unit} · ${entry.category.label}'),
                    onTap: () => Navigator.pop(context, entry),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (selected == null) return;

    onChanged([
      ...lines,
      LabourMaterialLine(
        priceListEntryId: selected.id,
        description: selected.description,
        unit: selected.unit,
        unitPrice: selected.unitPrice,
        notes: selected.notes,
      ),
    ]);
  }
}

class _QtyField extends StatelessWidget {
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double>? onChanged;

  const _QtyField({
    required this.label,
    required this.value,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LabourDecimalTextField(
      label: label,
      value: value,
      enabled: enabled && onChanged != null,
      isDense: true,
      maxDecimalPlaces: 2,
      onChanged: onChanged ?? (_) {},
    );
  }
}