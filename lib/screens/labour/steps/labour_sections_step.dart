import 'package:flutter/material.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_section_panel.dart';
import 'package:roofgrid_uk/utils/layout_utils.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';

class LabourSectionsStep extends StatelessWidget {
  final bool embedded;

  const LabourSectionsStep({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = screenHorizontalPadding(context);
    const content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Roof sections',
          subtitle: 'Add and configure each roof area',
        ),
        SizedBox(height: 16),
        LabourSectionList(),
      ],
    );

    if (embedded) return content;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        24,
      ),
      child: content,
    );
  }
}