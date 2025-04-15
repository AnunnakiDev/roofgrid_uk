import 'package:cloud_firestore/cloud_firestore.dart';

enum TileSlateType {
  slate,
  fibreCementSlate,
  interlockingTile,
  plainTile,
  concreteTile,
  pantile,
  unknown,
}

class TileModel {
  final String id;
  final String name;
  final String manufacturer;
  final TileSlateType materialType;
  final String description;
  final bool isPublic;
  final bool isApproved;
  final String createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double slateTileHeight;
  final double tileCoverWidth;
  final double minGauge;
  final double maxGauge;
  final double minSpacing;
  final double maxSpacing;
  final double? leftHandTileWidth;
  final bool defaultCrossBonded;

  TileModel({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.materialType,
    required this.description,
    required this.isPublic,
    required this.isApproved,
    required this.createdById,
    required this.createdAt,
    DateTime? updatedAt,
    required this.slateTileHeight,
    required this.tileCoverWidth,
    required this.minGauge,
    required this.maxGauge,
    required this.minSpacing,
    required this.maxSpacing,
    this.leftHandTileWidth,
    required this.defaultCrossBonded,
  }) : updatedAt = updatedAt ?? DateTime.now();

  String get materialTypeString => materialType.toString().split('.').last;

  factory TileModel.fromJson(Map<String, dynamic> json) {
    return TileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      manufacturer: json['manufacturer'] as String,
      materialType: TileSlateType.values.firstWhere(
        (e) => e.toString() == 'TileSlateType.${json['materialType']}',
        orElse: () => TileSlateType.unknown,
      ),
      description: json['description'] as String,
      isPublic: json['isPublic'] as bool,
      isApproved: json['isApproved'] as bool,
      createdById: json['createdById'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      slateTileHeight: (json['slateTileHeight'] as num).toDouble(),
      tileCoverWidth: (json['tileCoverWidth'] as num).toDouble(),
      minGauge: (json['minGauge'] as num).toDouble(),
      maxGauge: (json['maxGauge'] as num).toDouble(),
      minSpacing: (json['minSpacing'] as num).toDouble(),
      maxSpacing: (json['maxSpacing'] as num).toDouble(),
      leftHandTileWidth: json['leftHandTileWidth'] != null
          ? (json['leftHandTileWidth'] as num).toDouble()
          : null,
      defaultCrossBonded: json['defaultCrossBonded'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'materialType': materialTypeString,
      'description': description,
      'isPublic': isPublic,
      'isApproved': isApproved,
      'createdById': createdById,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'slateTileHeight': slateTileHeight,
      'tileCoverWidth': tileCoverWidth,
      'minGauge': minGauge,
      'maxGauge': maxGauge,
      'minSpacing': minSpacing,
      'maxSpacing': maxSpacing,
      if (leftHandTileWidth != null) 'leftHandTileWidth': leftHandTileWidth,
      'defaultCrossBonded': defaultCrossBonded,
    };
  }

  TileModel copyWith({
    String? id,
    String? name,
    String? manufacturer,
    TileSlateType? materialType,
    String? description,
    bool? isPublic,
    bool? isApproved,
    String? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? slateTileHeight,
    double? tileCoverWidth,
    double? minGauge,
    double? maxGauge,
    double? minSpacing,
    double? maxSpacing,
    double? leftHandTileWidth,
    bool? defaultCrossBonded,
  }) {
    return TileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      materialType: materialType ?? this.materialType,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      isApproved: isApproved ?? this.isApproved,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      slateTileHeight: slateTileHeight ?? this.slateTileHeight,
      tileCoverWidth: tileCoverWidth ?? this.tileCoverWidth,
      minGauge: minGauge ?? this.minGauge,
      maxGauge: maxGauge ?? this.maxGauge,
      minSpacing: minSpacing ?? this.minSpacing,
      maxSpacing: maxSpacing ?? this.maxSpacing,
      leftHandTileWidth: leftHandTileWidth ?? this.leftHandTileWidth,
      defaultCrossBonded: defaultCrossBonded ?? this.defaultCrossBonded,
    );
  }
}
