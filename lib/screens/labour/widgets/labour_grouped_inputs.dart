import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary_catalog.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_catalog.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_decimal_text_field.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_int_text_field.dart';

typedef LabourMetresChanged = void Function(LabourLinearItem item, double value);
typedef LabourAncillaryChanged = void Function(LabourAncillary ancillary, int value);

class LabourGroupedLinearInputs extends StatelessWidget {
  final LabourRoofType roofType;
  final LabourQuoteInput input;
  final LabourMetresChanged onMetresChanged;

  const LabourGroupedLinearInputs({
    super.key,
    required this.roofType,
    required this.input,
    required this.onMetresChanged,
  });

  @override
  Widget build(BuildContext context) {
    final groups = LabourLinearCatalog.visibleGroups();
    return Column(
      children: groups.map((group) {
        final enabled = LabourLinearCatalog.isGroupEnabled(group, roofType);
        final items = LabourLinearCatalog.itemsForGroup(group);
        return ExpansionTile(
          title: Text(
            group.label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: enabled
                  ? null
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          subtitle: enabled
              ? null
              : Text(
                  'Not typical for ${roofType.label}',
                  style: GoogleFonts.poppins(fontSize: 11),
                ),
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: LabourDecimalTextField(
                label: '${item.label} (m)',
                value: input.linearMetresFor(item),
                enabled: enabled,
                onChanged: (v) => onMetresChanged(item, v),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class LabourGroupedAncillaryInputs extends StatelessWidget {
  final LabourRoofType roofType;
  final LabourQuoteInput input;
  final LabourAncillaryChanged onCountChanged;

  const LabourGroupedAncillaryInputs({
    super.key,
    required this.roofType,
    required this.input,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final groups = LabourAncillaryCatalog.visibleGroups();
    return Column(
      children: groups.map((group) {
        final enabled = LabourAncillaryCatalog.isGroupEnabled(group, roofType);
        final items = LabourAncillaryCatalog.itemsByGroup[group] ?? const [];
        return ExpansionTile(
          title: Text(
            group.label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: enabled
                  ? null
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          subtitle: enabled
              ? null
              : Text(
                  'Not typical for ${roofType.label}',
                  style: GoogleFonts.poppins(fontSize: 11),
                ),
          children: items.map((ancillary) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: LabourIntTextField(
                label: ancillary.label,
                value: input.ancillaryCountFor(ancillary),
                enabled: enabled,
                onChanged: (v) => onCountChanged(ancillary, v),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

