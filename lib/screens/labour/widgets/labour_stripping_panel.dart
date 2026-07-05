import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_stripping.dart';

class LabourStrippingPanel extends StatelessWidget {
  final LabourRoofSection section;
  final ValueChanged<LabourRoofSection> onSectionChanged;

  const LabourStrippingPanel({
    super.key,
    required this.section,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final stripping = section.stripping;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Stripping',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Include strip', style: GoogleFonts.poppins()),
          value: stripping.includeStrip,
          onChanged: (value) {
            onSectionChanged(
              section.copyWith(
                stripping: stripping.copyWith(includeStrip: value),
                input: section.input.copyWith(includeStrip: value),
              ),
            );
          },
        ),
        if (stripping.includeStrip) ...[
          DropdownButtonFormField<LabourRoofType>(
            decoration: const InputDecoration(
              labelText: 'Old roof type (strip rates)',
              border: OutlineInputBorder(),
            ),
            value: stripping.oldRoofType,
            items: [
              const DropdownMenuItem<LabourRoofType>(
                value: null,
                child: Text('Same as new covering'),
              ),
              ...LabourRoofType.values.map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                ),
              ),
            ],
            onChanged: (type) {
              onSectionChanged(
                section.copyWith(
                  stripping: type == null
                      ? stripping.copyWith(clearOldRoofType: true)
                      : stripping.copyWith(oldRoofType: type),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: stripping.conditionNotes,
            decoration: const InputDecoration(
              labelText: 'Strip condition notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) => onSectionChanged(
              section.copyWith(
                stripping: stripping.copyWith(conditionNotes: value),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<StripDisposalOption>(
            decoration: const InputDecoration(
              labelText: 'Disposal option',
              border: OutlineInputBorder(),
            ),
            value: stripping.disposalOption,
            items: StripDisposalOption.values
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            onChanged: (option) {
              if (option == null) return;
              onSectionChanged(
                section.copyWith(
                  stripping: stripping.copyWith(disposalOption: option),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}