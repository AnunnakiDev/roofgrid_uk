import 'package:flutter/material.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_project_materials_panel.dart';
import 'package:roofgrid_uk/utils/layout_utils.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';

class LabourMaterialsStep extends StatelessWidget {
  final bool embedded;

  const LabourMaterialsStep({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = screenHorizontalPadding(context);
    const content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Project materials',
          subtitle: 'Materials applied across all roof sections',
        ),
        SizedBox(height: 16),
        LabourProjectMaterialsPanel(),
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