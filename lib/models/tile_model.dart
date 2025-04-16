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
  final String? dataSheet; // Added field for datasheet URL
  final String? image; // Added field for image URL

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
    this.dataSheet,
    this.image,
  }) : updatedAt = updatedAt ?? DateTime.now();

  String get materialTypeString {
    switch (materialType) {
      case TileSlateType.slate:
        return 'Slate';
      case TileSlateType.fibreCementSlate:
        return 'Fibre Cement Slate';
      case TileSlateType.interlockingTile:
        return 'Interlocking Tile';
      case TileSlateType.plainTile:
        return 'Plain Tile';
      case TileSlateType.concreteTile:
        return 'Concrete Tile';
      case TileSlateType.pantile:
        return 'Pantile';
      case TileSlateType.unknown:
        return 'Unknown';
    }
  }

  factory TileModel.fromJson(Map<String, dynamic> json) {
    // Map Firestore TileSlateType string to TileSlateType enum
    TileSlateType parseTileSlateType(String? type) {
      switch (type?.trim()) {
        case 'Slate':
          return TileSlateType.slate;
        case 'Fibre Cement Slate':
          return TileSlateType.fibreCementSlate;
        case 'Interlocking Tile':
          return TileSlateType.interlockingTile;
        case 'Plain Tile':
          return TileSlateType.plainTile;
        case 'Concrete Tile':
          return TileSlateType.concreteTile;
        case 'Pantile':
          return TileSlateType.pantile;
        case 'Unknown':
        default:
          return TileSlateType.unknown;
      }
    }

    // Helper to parse a value that might be a string or number into a double
    double parseNumber(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return TileModel(
      id: json['id'].toString(), // Handles int or String
      name: json['name'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      materialType: parseTileSlateType(json['TileSlateType'] as String?),
      description: json['description'] as String? ?? '',
      isPublic: json['isPublic'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? false,
      createdById: json['createdById'].toString(), // Handles int or String
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      slateTileHeight: parseNumber(json['slateTileHeight']),
      tileCoverWidth: parseNumber(json['tileCoverWidth']),
      minGauge: parseNumber(json['minGauge']),
      maxGauge: parseNumber(json['maxGauge']),
      minSpacing: parseNumber(json['minSpacing']),
      maxSpacing: parseNumber(json['maxSpacing']),
      leftHandTileWidth:
          json['LHTileWidth'] != null ? parseNumber(json['LHTileWidth']) : null,
      defaultCrossBonded: json['defaultCrossBonded'] as bool? ?? false,
      dataSheet: json['dataSheet'] as String?,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'TileSlateType': materialTypeString, // Store as human-readable string
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
      if (leftHandTileWidth != null) 'LHTileWidth': leftHandTileWidth,
      'defaultCrossBonded': defaultCrossBonded,
      if (dataSheet != null) 'dataSheet': dataSheet,
      if (image != null) 'image': image,
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
    String? dataSheet,
    String? image,
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
      dataSheet: dataSheet ?? this.dataSheet,
      image: image ?? this.image,
    );
  }
}
