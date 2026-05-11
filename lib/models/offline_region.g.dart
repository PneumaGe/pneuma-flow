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

part of 'offline_region.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineRegionAdapter extends TypeAdapter<OfflineRegion> {
  @override
  final int typeId = 10;

  @override
  OfflineRegion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineRegion(
      id: fields[0] as String,
      name: fields[1] as String,
      northLat: fields[2] as double,
      southLat: fields[3] as double,
      eastLng: fields[4] as double,
      westLng: fields[5] as double,
      minZoom: fields[6] as int,
      maxZoom: fields[7] as int,
      downloadedAt: fields[8] as DateTime,
      sizeBytes: fields[9] as int,
      mapboxRegionId: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineRegion obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.northLat)
      ..writeByte(3)
      ..write(obj.southLat)
      ..writeByte(4)
      ..write(obj.eastLng)
      ..writeByte(5)
      ..write(obj.westLng)
      ..writeByte(6)
      ..write(obj.minZoom)
      ..writeByte(7)
      ..write(obj.maxZoom)
      ..writeByte(8)
      ..write(obj.downloadedAt)
      ..writeByte(9)
      ..write(obj.sizeBytes)
      ..writeByte(10)
      ..write(obj.mapboxRegionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineRegionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
