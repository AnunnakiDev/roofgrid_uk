import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_decimal_text_field.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/complexity_derivation_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/complexity_measurement.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_complexity_catalog.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_complexity_feature.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/complexity_derivation.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_section_uplift.dart';

class LabourComplexityPanel extends StatelessWidget {
  final LabourRoofSection section;
  final ValueChanged<LabourRoofSection> onSectionChanged;

  const LabourComplexityPanel({
    super.key,
    required this.section,
    required this.onSectionChanged,
  });

  static const List<double> pitchOptions = [0, 25, 30, 35, 40, 45, 50, 55];

  @override
  Widget build(BuildContext context) {
    final derived = ComplexityDerivation.derive(section.complexityFeatures);
    final uplift = LabourSectionUplift.totalUpliftPercent(
      pitchDegrees: section.pitchDegrees,
      heritage: section.heritage,
      accessUpliftPercent: section.accessUpliftPercent,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Geometry & complexity',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<double>(
          decoration: const InputDecoration(
            labelText: 'Pitch (°)',
            border: OutlineInputBorder(),
          ),
          value: pitchOptions.contains(section.pitchDegrees)
              ? section.pitchDegrees
              : null,
          items: pitchOptions
              .map(
                (pitch) => DropdownMenuItem(
                  value: pitch,
                  child: Text(pitch == 0 ? 'Not set' : '$pitch°'),
                ),
              )
              .toList(),
          onChanged: (pitch) {
            if (pitch == null) return;
            onSectionChanged(section.copyWith(pitchDegrees: pitch));
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Heritage property (+10%)', style: GoogleFonts.poppins()),
          value: section.heritage,
          onChanged: (value) =>
              onSectionChanged(section.copyWith(heritage: value)),
        ),
        LabourDecimalTextField(
          label: 'Access uplift (%)',
          value: section.accessUpliftPercent,
          onChanged: (value) =>
              onSectionChanged(section.copyWith(accessUpliftPercent: value)),
        ),
        if (uplift > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Section uplift total: ${uplift.toStringAsFixed(0)}%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Complexity features',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final group in LabourComplexityGroup.values)
          if (LabourComplexityCatalog.isGroupVisibleForRoof(
            group,
            section.input.roofType,
          ))
            _ComplexityGroupCard(
              group: group,
              section: section,
              onSectionChanged: onSectionChanged,
            ),
        if (derived.hasDerivedQuantities) ...[
          const SizedBox(height: 12),
          _DerivedPreview(derived: derived),
        ],
      ],
    );
  }
}

class _ComplexityGroupCard extends StatelessWidget {
  final LabourComplexityGroup group;
  final LabourRoofSection section;
  final ValueChanged<LabourRoofSection> onSectionChanged;

  const _ComplexityGroupCard({
    required this.group,
    required this.section,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = LabourComplexityCatalog.typesByGroup[group] ?? const [];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          LabourComplexityCatalog.groupLabels[group] ?? group.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                for (final type in types)
                  _FeatureQuantityRow(
                    type: type,
                    feature: _featureFor(type),
                    onChanged: (feature) => _updateFeature(type, feature),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LabourComplexityFeature _featureFor(LabourComplexityFeatureType type) {
    return section.complexityFeatureOf(type) ??
        LabourComplexityFeature.empty(type);
  }

  void _updateFeature(
    LabourComplexityFeatureType type,
    LabourComplexityFeature feature,
  ) {
    final next = [...section.complexityFeatures];
    final index = next.indexWhere((f) => f.type == type);
    if (feature.quantity <= 0) {
      if (index >= 0) next.removeAt(index);
    } else if (index >= 0) {
      next[index] = feature;
    } else {
      next.add(feature);
    }
    onSectionChanged(section.copyWith(complexityFeatures: next));
  }
}

class _FeatureQuantityRow extends StatelessWidget {
  final LabourComplexityFeatureType type;
  final LabourComplexityFeature feature;
  final ValueChanged<LabourComplexityFeature> onChanged;

  const _FeatureQuantityRow({
    required this.type,
    required this.feature,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(type.label, style: GoogleFonts.poppins()),
            ),
            IconButton(
              onPressed: feature.quantity <= 0
                  ? null
                  : () => onChanged(feature.withQuantity(feature.quantity - 1)),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '${feature.quantity}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            IconButton(
              onPressed: feature.quantity >= 20
                  ? null
                  : () => onChanged(feature.withQuantity(feature.quantity + 1)),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        if (feature.quantity > 0)
          ...[
            for (var i = 0; i < feature.instances.length; i++)
              ComplexityMeasurementCard(
                title: '${type.label} ${i + 1}',
                type: type,
                measurement: feature.instances[i],
                onChanged: (measurement) =>
                    onChanged(feature.updateInstance(i, measurement)),
              ),
          ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class ComplexityMeasurementCard extends StatelessWidget {
  final String title;
  final LabourComplexityFeatureType type;
  final ComplexityMeasurement measurement;
  final ValueChanged<ComplexityMeasurement> onChanged;

  const ComplexityMeasurementCard({
    super.key,
    required this.title,
    required this.type,
    required this.measurement,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fields = LabourComplexityCatalog.fieldsForType[type] ?? const [];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final field in fields)
              if (field == ComplexityMeasurementField.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    initialValue: measurement.notes,
                    decoration: InputDecoration(
                      labelText: LabourComplexityCatalog.fieldLabel(field),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        onChanged(measurement.copyWith(notes: value)),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LabourDecimalTextField(
                    label: LabourComplexityCatalog.fieldLabel(field),
                    value: _valueFor(field),
                    onChanged: (value) => onChanged(_updateField(field, value)),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  double _valueFor(ComplexityMeasurementField field) {
    switch (field) {
      case ComplexityMeasurementField.width:
        return measurement.widthM;
      case ComplexityMeasurementField.height:
        return measurement.heightM;
      case ComplexityMeasurementField.pitch:
        return measurement.pitchDegrees;
      case ComplexityMeasurementField.upstandHeight:
        return measurement.upstandHeightM;
      case ComplexityMeasurementField.projection:
        return measurement.projectionM;
      case ComplexityMeasurementField.notes:
        return 0;
    }
  }

  ComplexityMeasurement _updateField(
    ComplexityMeasurementField field,
    double value,
  ) {
    switch (field) {
      case ComplexityMeasurementField.width:
        return measurement.copyWith(widthM: value);
      case ComplexityMeasurementField.height:
        return measurement.copyWith(heightM: value);
      case ComplexityMeasurementField.pitch:
        return measurement.copyWith(pitchDegrees: value);
      case ComplexityMeasurementField.upstandHeight:
        return measurement.copyWith(upstandHeightM: value);
      case ComplexityMeasurementField.projection:
        return measurement.copyWith(projectionM: value);
      case ComplexityMeasurementField.notes:
        return measurement;
    }
  }
}

class _DerivedPreview extends StatelessWidget {
  final ComplexityDerivationResult derived;

  const _DerivedPreview({required this.derived});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colorScheme.secondary.withValues(alpha: 0.08),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Derived from measurements',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (derived.extraRoofAreaSqm > 0)
            Text(
              'Extra roof area: ${derived.extraRoofAreaSqm.toStringAsFixed(1)} m²',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          for (final entry in derived.extraLinearMetres.entries)
            if (entry.value > 0)
              Text(
                '${entry.key.label}: ${entry.value.toStringAsFixed(1)} m',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
          for (final entry in derived.extraAncillaryCounts.entries)
            if (entry.value > 0)
              Text(
                '${entry.key.label}: ${entry.value}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
          if (derived.extraHours > 0)
            Text(
              'Extra hours: ${derived.extraHours.toStringAsFixed(1)} h',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
        ],
      ),
    );
  }
}

