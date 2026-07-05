import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_project_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_new_covering.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_complexity_panel.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_decimal_text_field.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_grouped_inputs.dart';
import 'package:roofgrid_uk/utils/decimal_input_utils.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_new_covering_panel.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_section_materials_panel.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_stripping_panel.dart';

class LabourSectionList extends ConsumerWidget {
  const LabourSectionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(labourPricingProvider);
    final notifier = ref.read(labourPricingProvider.notifier);
    final sections = state.project.sections;
    final sectionResults = state.projectResult?.sectionResults ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++)
          _LabourSectionTile(
            key: ValueKey(sections[i].id),
            section: sections[i],
            sectionResult: _sectionResultFor(
              sectionResults,
              sections[i].id,
            ),
            canRemove: sections.length > 1,
            initiallyExpanded: i == 0,
            onLabelChanged: (label) =>
                notifier.updateSectionLabel(sections[i].id, label),
            onDuplicate: () => notifier.duplicateSection(sections[i].id),
            onRemove: () => notifier.removeSection(sections[i].id),
            onSectionChanged: (section) =>
                notifier.updateSection(sections[i].id, section),
            onInputChanged: (input) =>
                notifier.updateSectionInput(sections[i].id, input),
            onMethodChanged: (method) =>
                notifier.setSectionMethod(sections[i].id, method),
            onManualOverrideChanged: (value) => notifier.setSectionManualOverride(
              sections[i].id,
              value,
            ),
            canMoveUp: i > 0,
            canMoveDown: i < sections.length - 1,
            onMoveUp: () => notifier.moveSectionUp(sections[i].id),
            onMoveDown: () => notifier.moveSectionDown(sections[i].id),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: notifier.addSection,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add section'),
        ),
      ],
    );
  }

  static LabourSectionResult? _sectionResultFor(
    List<LabourSectionResult> results,
    String sectionId,
  ) {
    final index = results.indexWhere((result) => result.section.id == sectionId);
    if (index < 0) return null;
    return results[index];
  }
}

class _LabourSectionTile extends StatefulWidget {
  final LabourRoofSection section;
  final LabourSectionResult? sectionResult;
  final bool canRemove;
  final bool initiallyExpanded;
  final ValueChanged<String> onLabelChanged;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;
  final ValueChanged<LabourRoofSection> onSectionChanged;
  final ValueChanged<LabourQuoteInput> onInputChanged;
  final ValueChanged<LabourQuoteMethod> onMethodChanged;
  final ValueChanged<double?> onManualOverrideChanged;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _LabourSectionTile({
    super.key,
    required this.section,
    required this.sectionResult,
    required this.canRemove,
    required this.initiallyExpanded,
    required this.onLabelChanged,
    required this.onDuplicate,
    required this.onRemove,
    required this.onSectionChanged,
    required this.onInputChanged,
    required this.onMethodChanged,
    required this.onManualOverrideChanged,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  State<_LabourSectionTile> createState() => _LabourSectionTileState();
}

class _LabourSectionTileState extends State<_LabourSectionTile> {
  late final TextEditingController _labelController;
  late final TextEditingController _manualController;
  late final FocusNode _manualFocusNode;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.section.label);
    _manualFocusNode = FocusNode();
    _manualController = TextEditingController(
      text: _manualTextFor(widget.section.manualOverrideGbp),
    );
  }

  @override
  void didUpdateWidget(covariant _LabourSectionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.label != widget.section.label &&
        _labelController.text != widget.section.label) {
      _labelController.text = widget.section.label;
    }
    if (!_manualFocusNode.hasFocus &&
        oldWidget.section.manualOverrideGbp != widget.section.manualOverrideGbp) {
      _manualController.text = _manualTextFor(widget.section.manualOverrideGbp);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _manualController.dispose();
    _manualFocusNode.dispose();
    super.dispose();
  }

  String _manualTextFor(double? value) =>
      value == null || value <= 0 ? '' : decimalInputDisplayText(value);

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final input = section.input;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: widget.initiallyExpanded,
        title: Text(
          section.label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${input.roofType.label} · ${input.roofAreaSqm.toStringAsFixed(1)} m²',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Section name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: widget.onLabelChanged,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.canMoveUp ? widget.onMoveUp : null,
                      icon: const Icon(Icons.arrow_upward_rounded),
                      tooltip: 'Move section up',
                    ),
                    IconButton(
                      onPressed: widget.canMoveDown ? widget.onMoveDown : null,
                      icon: const Icon(Icons.arrow_downward_rounded),
                      tooltip: 'Move section down',
                    ),
                    TextButton.icon(
                      onPressed: widget.onDuplicate,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Duplicate'),
                    ),
                    if (widget.canRemove)
                      TextButton.icon(
                        onPressed: widget.onRemove,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Remove'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                LabourComplexityPanel(
                  section: section,
                  onSectionChanged: widget.onSectionChanged,
                ),
                const SizedBox(height: 12),
                _DropdownField<LabourPricingMode>(
                  label: 'Pricing mode',
                  value: input.mode,
                  items: LabourPricingMode.values,
                  itemLabel: (mode) => mode.label,
                  onChanged: (mode) {
                    if (mode == null) return;
                    widget.onInputChanged(input.copyWith(mode: mode));
                  },
                ),
                const SizedBox(height: 12),
                _DropdownField<LabourRoofType>(
                  label: 'Roof type',
                  value: input.roofType,
                  items: LabourRoofType.values,
                  itemLabel: (type) => type.label,
                  onChanged: (type) {
                    if (type == null) return;
                    widget.onSectionChanged(
                      section.copyWith(
                        input: input.copyWith(roofType: type),
                        newCovering: SectionNewCovering.forRoofType(type),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                LabourDecimalTextField(
                  label: 'Roof area (m²)',
                  value: input.roofAreaSqm,
                  onChanged: (value) =>
                      widget.onInputChanged(input.copyWith(roofAreaSqm: value)),
                ),
                const SizedBox(height: 12),
                LabourStrippingPanel(
                  section: section,
                  onSectionChanged: widget.onSectionChanged,
                ),
                const SizedBox(height: 12),
                LabourNewCoveringPanel(
                  section: section,
                  onSectionChanged: widget.onSectionChanged,
                ),
                const SizedBox(height: 12),
                Text(
                  'Linear & detail work',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                LabourGroupedLinearInputs(
                  roofType: input.roofType,
                  input: input,
                  onMetresChanged: (item, value) =>
                      _updateLinear(input, item, value),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ancillaries',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                LabourGroupedAncillaryInputs(
                  roofType: input.roofType,
                  input: input,
                  onCountChanged: (ancillary, value) =>
                      _updateAncillary(input, ancillary, value),
                ),
                const SizedBox(height: 12),
                LabourSectionMaterialsPanel(
                  sectionId: section.id,
                  section: section,
                ),
                const SizedBox(height: 12),
                _SectionMethodPicker(
                  section: section,
                  sectionResult: widget.sectionResult,
                  manualController: _manualController,
                  manualFocusNode: _manualFocusNode,
                  onMethodChanged: widget.onMethodChanged,
                  onManualOverrideChanged: widget.onManualOverrideChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateLinear(
    LabourQuoteInput input,
    LabourLinearItem item,
    double value,
  ) {
    final next = Map<LabourLinearItem, double>.from(input.linearMetres);
    if (value <= 0) {
      next.remove(item);
    } else {
      next[item] = value;
    }
    widget.onInputChanged(input.copyWith(linearMetres: next));
  }

  void _updateAncillary(
    LabourQuoteInput input,
    LabourAncillary ancillary,
    int value,
  ) {
    final next = Map<LabourAncillary, int>.from(input.ancillaryCounts);
    if (value <= 0) {
      next.remove(ancillary);
    } else {
      next[ancillary] = value;
    }
    widget.onInputChanged(input.copyWith(ancillaryCounts: next));
  }
}

class _SectionMethodPicker extends StatelessWidget {
  final LabourRoofSection section;
  final LabourSectionResult? sectionResult;
  final TextEditingController manualController;
  final FocusNode manualFocusNode;
  final ValueChanged<LabourQuoteMethod> onMethodChanged;
  final ValueChanged<double?> onManualOverrideChanged;

  const _SectionMethodPicker({
    required this.section,
    required this.sectionResult,
    required this.manualController,
    required this.manualFocusNode,
    required this.onMethodChanged,
    required this.onManualOverrideChanged,
  });

  @override
  Widget build(BuildContext context) {
    final gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');
    final colorScheme = Theme.of(context).colorScheme;
    final dual = sectionResult?.dualResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quote method for this section',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        if (dual != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MethodTotalChip(
                  label: 'Method A',
                  value: gbp.format(dual.methodA.baseLabourCostGbp),
                  isSelected:
                      section.selectedMethod == LabourQuoteMethod.rateBased,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MethodTotalChip(
                  label: 'Method B',
                  value: gbp.format(dual.methodB.baseLabourCostGbp),
                  isSelected:
                      section.selectedMethod == LabourQuoteMethod.timingBased,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LabourQuoteMethod.values.map((method) {
            final selected = section.selectedMethod == method;
            return ChoiceChip(
              label: Text(method.shortLabel),
              selected: selected,
              onSelected: (_) => onMethodChanged(method),
            );
          }).toList(),
        ),
        if (section.selectedMethod == LabourQuoteMethod.manualOverride) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: manualController,
            focusNode: manualFocusNode,
            decoration: const InputDecoration(
              labelText: 'Manual section labour (£)',
              border: OutlineInputBorder(),
              prefixText: '£ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: (text) {
              if (text.trim().isEmpty) {
                onManualOverrideChanged(null);
                return;
              }
              applyDecimalInputChange(text, (parsed) {
                onManualOverrideChanged(parsed > 0 ? parsed : null);
              });
            },
          ),
        ],
        if (section.selectedMethod == LabourQuoteMethod.average && dual != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Using average: ${gbp.format((dual.methodA.baseLabourCostGbp + dual.methodB.baseLabourCostGbp) / 2)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _MethodTotalChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final ColorScheme colorScheme;

  const _MethodTotalChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? colorScheme.secondary
              : colorScheme.outline.withValues(alpha: 0.35),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? colorScheme.secondary.withValues(alpha: 0.08)
            : colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(itemLabel(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

