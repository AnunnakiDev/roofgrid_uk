// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TileModelAdapter extends TypeAdapter<TileModel> {
  @override
  final int typeId = 1;

  @override
  TileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TileModel(
      id: fields[0] as String,
      name: fields[1] as String,
      manufacturer: fields[2] as String,
      materialType: fields[3] as TileSlateType,
      description: fields[4] as String,
      isPublic: fields[5] as bool,
      isApproved: fields[6] as bool,
      createdById: fields[7] as String,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime?,
      slateTileHeight: fields[10] as double,
      tileCoverWidth: fields[11] as double,
      minGauge: fields[12] as double,
      maxGauge: fields[13] as double,
      minSpacing: fields[14] as double,
      maxSpacing: fields[15] as double,
      leftHandTileWidth: fields[16] as double?,
      defaultCrossBonded: fields[17] as bool,
      dataSheet: fields[18] as String?,
      image: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TileModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.manufacturer)
      ..writeByte(3)
      ..write(obj.materialType)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.isPublic)
      ..writeByte(6)
      ..write(obj.isApproved)
      ..writeByte(7)
      ..write(obj.createdById)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.slateTileHeight)
      ..writeByte(11)
      ..write(obj.tileCoverWidth)
      ..writeByte(12)
      ..write(obj.minGauge)
      ..writeByte(13)
      ..write(obj.maxGauge)
      ..writeByte(14)
      ..write(obj.minSpacing)
      ..writeByte(15)
      ..write(obj.maxSpacing)
      ..writeByte(16)
      ..write(obj.leftHandTileWidth)
      ..writeByte(17)
      ..write(obj.defaultCrossBonded)
      ..writeByte(18)
      ..write(obj.dataSheet)
      ..writeByte(19)
      ..write(obj.image);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TileSlateTypeAdapter extends TypeAdapter<TileSlateType> {
  @override
  final int typeId = 0;

  @override
  TileSlateType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TileSlateType.slate;
      case 1:
        return TileSlateType.fibreCementSlate;
      case 2:
        return TileSlateType.interlockingTile;
      case 3:
        return TileSlateType.plainTile;
      case 4:
        return TileSlateType.concreteTile;
      case 5:
        return TileSlateType.pantile;
      case 6:
        return TileSlateType.unknown;
      default:
        return TileSlateType.slate;
    }
  }

  @override
  void write(BinaryWriter writer, TileSlateType obj) {
    switch (obj) {
      case TileSlateType.slate:
        writer.writeByte(0);
        break;
      case TileSlateType.fibreCementSlate:
        writer.writeByte(1);
        break;
      case TileSlateType.interlockingTile:
        writer.writeByte(2);
        break;
      case TileSlateType.plainTile:
        writer.writeByte(3);
        break;
      case TileSlateType.concreteTile:
        writer.writeByte(4);
        break;
      case TileSlateType.pantile:
        writer.writeByte(5);
        break;
      case TileSlateType.unknown:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileSlateTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
