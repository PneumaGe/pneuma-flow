// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceSettingsAdapter extends TypeAdapter<DeviceSettings> {
  @override
  final int typeId = 6;

  @override
  DeviceSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceSettings(
      deviceId: fields[0] as String,
      pumpSpeed: fields[1] as String,
      channelVisibility: (fields[2] as Map).cast<String, bool>(),
      filterConfigs: (fields[3] as Map?)?.cast<String, FilterConfig>(),
      kalmanConfigs: (fields[4] as Map?)?.cast<String, KalmanConfig>(),
    );
  }

  @override
  void write(BinaryWriter writer, DeviceSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.pumpSpeed)
      ..writeByte(2)
      ..write(obj.channelVisibility)
      ..writeByte(3)
      ..write(obj.filterConfigs)
      ..writeByte(4)
      ..write(obj.kalmanConfigs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
