// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 5;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      units: fields[0] as String,
      volumeButtonsEnabled: fields[1] as bool,
      creatorName: fields[2] == null ? '' : fields[2] as String,
      organization: fields[3] == null ? '' : fields[3] as String,
      operatorId: fields[4] == null ? '' : fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.units)
      ..writeByte(1)
      ..write(obj.volumeButtonsEnabled)
      ..writeByte(2)
      ..write(obj.creatorName)
      ..writeByte(3)
      ..write(obj.organization)
      ..writeByte(4)
      ..write(obj.operatorId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
