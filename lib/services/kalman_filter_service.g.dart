// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kalman_filter_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KalmanConfigAdapter extends TypeAdapter<KalmanConfig> {
  @override
  final int typeId = 8;

  @override
  KalmanConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KalmanConfig(
      channelId: fields[0] as String,
      r: fields[1] as double,
      baseQ: fields[2] as double,
      enabled: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, KalmanConfig obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.channelId)
      ..writeByte(1)
      ..write(obj.r)
      ..writeByte(2)
      ..write(obj.baseQ)
      ..writeByte(3)
      ..write(obj.enabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KalmanConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
