import 'package:flutter/material.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';
import 'package:roofgrid_uk/widgets/info_row.dart';

class JobWorkingsSheet extends StatelessWidget {
  final JobWorkingsData data;

  const JobWorkingsSheet({
    super.key,
    required this.data,
  });

  static Future<void> show(BuildContext context, JobWorkingsData data) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => JobWorkingsSheet(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontSize =
        MediaQuery.of(context).size.width >= 600 ? 15.0 : 14.0;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Check inputs & workings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (data.tileRows.isNotEmpty)
                _Section(
                  title: 'Tile',
                  rows: data.tileRows,
                  fontSize: fontSize,
                ),
              if (data.verticalInputRows.isNotEmpty)
                _Section(
                  title: data.verticalInputsTitle,
                  rows: data.verticalInputRows,
                  fontSize: fontSize,
                ),
              if (data.horizontalInputRows.isNotEmpty)
                _Section(
                  title: data.horizontalInputsTitle,
                  rows: data.horizontalInputRows,
                  fontSize: fontSize,
                ),
              if (data.verticalWorkings.isNotEmpty) ...[
                Text(
                  data.verticalWorkingsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                ),
                const SizedBox(height: 8),
                for (final section in data.verticalWorkings)
                  _Section(
                    title: section.title,
                    rows: section.rows,
                    fontSize: fontSize,
                    nested: true,
                  ),
              ],
              if (data.horizontalWorkings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  data.horizontalWorkingsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                ),
                const SizedBox(height: 8),
                for (final section in data.horizontalWorkings)
                  _Section(
                    title: section.title,
                    rows: section.rows,
                    fontSize: fontSize,
                    nested: true,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<ResultDisplayRow> rows;
  final double fontSize;
  final bool nested;

  const _Section({
    required this.title,
    required this.rows,
    required this.fontSize,
    this.nested = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: nested ? 8 : 16),
      child: Card(
        elevation: nested ? 0 : 1,
        color: nested
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: nested ? fontSize - 1 : fontSize,
                ),
              ),
              const Divider(),
              ...rows.map(
                (row) => InfoRow(label: row.label, value: row.value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}