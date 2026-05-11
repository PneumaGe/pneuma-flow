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
