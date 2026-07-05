import 'package:roofgrid_uk/app/labour_pricing/models/complexity_measurement.dart';

enum LabourComplexityFeatureType {
  dormer,
  leadBay,
  chimneyDetail,
  skylight,
  flatUpstand,
  abutmentDetail,
}

enum LabourComplexityGroup {
  dormerSpecial,
  leadWork,
  penetrations,
  flatDetails,
}

extension LabourComplexityFeatureTypeLabels on LabourComplexityFeatureType {
  String get label {
    switch (this) {
      case LabourComplexityFeatureType.dormer:
        return 'Dormer';
      case LabourComplexityFeatureType.leadBay:
        return 'Lead bay';
      case LabourComplexityFeatureType.chimneyDetail:
        return 'Chimney detail';
      case LabourComplexityFeatureType.skylight:
        return 'Skylight / roof window';
      case LabourComplexityFeatureType.flatUpstand:
        return 'Flat roof upstand';
      case LabourComplexityFeatureType.abutmentDetail:
        return 'Abutment detail';
    }
  }
}

/// One complexity feature with quantity-driven measurement instances.
class LabourComplexityFeature {
  final LabourComplexityFeatureType type;
  final int quantity;
  final List<ComplexityMeasurement> instances;

  const LabourComplexityFeature({
    required this.type,
    this.quantity = 0,
    this.instances = const [],
  });

  factory LabourComplexityFeature.empty(LabourComplexityFeatureType type) {
    return LabourComplexityFeature(type: type);
  }

  LabourComplexityFeature withQuantity(int nextQuantity) {
    final qty = nextQuantity.clamp(0, 20);
    if (qty == quantity && instances.length == qty) return this;

    final nextInstances = <ComplexityMeasurement>[];
    for (var i = 0; i < qty; i++) {
      nextInstances.add(
        i < instances.length ? instances[i] : const ComplexityMeasurement(),
      );
    }
    return copyWith(quantity: qty, instances: nextInstances);
  }

  LabourComplexityFeature updateInstance(
    int index,
    ComplexityMeasurement measurement,
  ) {
    if (index < 0 || index >= instances.length) return this;
    final next = [...instances];
    next[index] = measurement;
    return copyWith(instances: next);
  }

  LabourComplexityFeature copyWith({
    LabourComplexityFeatureType? type,
    int? quantity,
    List<ComplexityMeasurement>? instances,
  }) {
    return LabourComplexityFeature(
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      instances: instances ?? this.instances,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'quantity': quantity,
        'instances': instances.map((m) => m.toJson()).toList(),
      };

  factory LabourComplexityFeature.fromJson(Map<String, dynamic> json) {
    final type =
        LabourComplexityFeatureType.values.byName(json['type'] as String);
    final rawInstances = json['instances'] as List<dynamic>? ?? const [];
    return LabourComplexityFeature(
      type: type,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      instances: rawInstances
          .map(
            (raw) =>
                ComplexityMeasurement.fromJson(raw as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}