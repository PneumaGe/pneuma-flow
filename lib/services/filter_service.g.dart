// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filter_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FilterConfigAdapter extends TypeAdapter<FilterConfig> {
  @override
  final int typeId = 7;

  @override
  FilterConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FilterConfig(
      channelId: fields[0] as String,
      alpha: fields[1] as double,
      beta: fields[2] as double,
      dt: fields[3] as double,
      enabled: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FilterConfig obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.channelId)
      ..writeByte(1)
      ..write(obj.alpha)
      ..writeByte(2)
      ..write(obj.beta)
      ..writeByte(3)
      ..write(obj.dt)
      ..writeByte(4)
      ..write(obj.enabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
