import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_new_covering.dart';

class LabourNewCoveringPanel extends StatelessWidget {
  final LabourRoofSection section;
  final ValueChanged<LabourRoofSection> onSectionChanged;

  const LabourNewCoveringPanel({
    super.key,
    required this.section,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final covering = section.newCovering;
    final isSlate = section.input.roofType == LabourRoofType.naturalSlate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'New covering',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (isSlate) ...[
          DropdownButtonFormField<SlateSizeOption>(
            decoration: const InputDecoration(
              labelText: 'Slate size',
              border: OutlineInputBorder(),
            ),
            value: covering.slateSize == SlateSizeOption.notApplicable
                ? SlateSizeOption.standard
                : covering.slateSize,
            items: const [
              SlateSizeOption.standard,
              SlateSizeOption.largeFormat,
              SlateSizeOption.randomCourtyard,
            ]
                .map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: Text(size.label),
                  ),
                )
                .toList(),
            onChanged: (size) {
              if (size == null) return;
              onSectionChanged(
                section.copyWith(
                  newCovering: covering.copyWith(slateSize: size),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        TextFormField(
          initialValue: covering.underlayNotes,
          decoration: const InputDecoration(
            labelText: 'Underlay notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (value) => onSectionChanged(
            section.copyWith(
              newCovering: covering.copyWith(underlayNotes: value),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: covering.battenNotes,
          decoration: InputDecoration(
            labelText: section.input.roofType.isFlat
                ? 'Deck / substrate notes'
                : 'Batten notes',
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (value) => onSectionChanged(
            section.copyWith(
              newCovering: covering.copyWith(battenNotes: value),
            ),
          ),
        ),
      ],
    );
  }
}