import 'package:flutter/material.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';

class SetoutHeroStrip extends StatelessWidget {
  final List<ResultDisplayRow> rows;
  final List<String> positionChips;
  final double fontSize;
  final int? crossAxisCount;

  const SetoutHeroStrip({
    super.key,
    required this.rows,
    this.positionChips = const [],
    this.fontSize = 14,
    this.crossAxisCount,
  });

  bool get _isError =>
      rows.length == 1 &&
      (rows.first.label == 'No valid solution' ||
          rows.first.label.isEmpty && rows.first.value.isNotEmpty);

  String _displayValue(ResultDisplayRow row) {
    final value = row.value;
    if (row.label == 'Battens') return value;
    if (value.contains('@') || value == 'Varies' || value.contains('+')) {
      return value.endsWith(' mm') ? value : '$value mm';
    }
    if (value.endsWith(' mm')) return value;
    final parsed = int.tryParse(value);
    if (parsed != null) return '$parsed mm';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    if (_isError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          rows.first.value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = crossAxisCount ??
                (rows.length >= 3
                    ? 3
                    : constraints.maxWidth >= 520
                        ? 4
                        : 2);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: columns >= 3 ? 1.05 : 1.15,
              ),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                return _MetricTile(
                  label: row.label,
                  value: _displayValue(row),
                  fontSize: fontSize,
                );
              },
            );
          },
        ),
        if (positionChips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: positionChips
                .map(
                  (chip) => Chip(
                    label: Text(
                      chip,
                      style: TextStyle(fontSize: fontSize - 2),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final double fontSize;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColorSchemes.inputRadius),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize + 10,
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1.05,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize - 1,
              color: colorScheme.onSurfaceVariant,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}