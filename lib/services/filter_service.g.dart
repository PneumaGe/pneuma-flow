// Copyright 2026 PneumaGe Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
