// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedResultAdapter extends TypeAdapter<SavedResult> {
  @override
  final int typeId = 6;

  @override
  SavedResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedResult(
      id: fields[0] as String,
      userId: fields[1] as String,
      projectName: fields[2] as String,
      type: fields[3] as CalculationType,
      timestamp: fields[4] as DateTime,
      inputs: (fields[5] as Map).cast<String, dynamic>(),
      outputs: (fields[6] as Map).cast<String, dynamic>(),
      tile: (fields[7] as Map).cast<String, dynamic>(),
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SavedResult obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.projectName)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.inputs)
      ..writeByte(6)
      ..write(obj.outputs)
      ..writeByte(7)
      ..write(obj.tile)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DateTimeAdapterAdapter extends TypeAdapter<DateTimeAdapter> {
  @override
  final int typeId = 5;

  @override
  DateTimeAdapter read(BinaryReader reader) {
    return DateTimeAdapter();
  }

  @override
  void write(BinaryWriter writer, DateTimeAdapter obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateTimeAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CalculationTypeAdapter extends TypeAdapter<CalculationType> {
  @override
  final int typeId = 4;

  @override
  CalculationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CalculationType.vertical;
      case 1:
        return CalculationType.horizontal;
      case 2:
        return CalculationType.combined;
      default:
        return CalculationType.vertical;
    }
  }

  @override
  void write(BinaryWriter writer, CalculationType obj) {
    switch (obj) {
      case CalculationType.vertical:
        writer.writeByte(0);
        break;
      case CalculationType.horizontal:
        writer.writeByte(1);
        break;
      case CalculationType.combined:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
