// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 3;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      email: fields[1] as String?,
      displayName: fields[2] as String?,
      photoURL: fields[3] as String?,
      phone: fields[4] as String?,
      subscription: fields[5] as String?,
      profileImage: fields[6] as String?,
      role: fields[7] as UserRole,
      proTrialStartDate: fields[8] as DateTime?,
      proTrialEndDate: fields[9] as DateTime?,
      subscriptionEndDate: fields[10] as DateTime?,
      createdAt: fields[11] as DateTime,
      lastLoginAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.photoURL)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.subscription)
      ..writeByte(6)
      ..write(obj.profileImage)
      ..writeByte(7)
      ..write(obj.role)
      ..writeByte(8)
      ..write(obj.proTrialStartDate)
      ..writeByte(9)
      ..write(obj.proTrialEndDate)
      ..writeByte(10)
      ..write(obj.subscriptionEndDate)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.lastLoginAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 2;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.free;
      case 1:
        return UserRole.pro;
      case 2:
        return UserRole.admin;
      default:
        return UserRole.free;
    }
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    switch (obj) {
      case UserRole.free:
        writer.writeByte(0);
        break;
      case UserRole.pro:
        writer.writeByte(1);
        break;
      case UserRole.admin:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
