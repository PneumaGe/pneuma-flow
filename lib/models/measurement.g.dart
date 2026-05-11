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

part of 'measurement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeasurementStatsAdapter extends TypeAdapter<MeasurementStats> {
  @override
  final int typeId = 9;

  @override
  MeasurementStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementStats(
      flux: fields[0] as double,
      fluxError: fields[1] as double,
      rSquared: fields[2] as double,
      slope: fields[3] as double,
      inlierCount: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementStats obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.flux)
      ..writeByte(1)
      ..write(obj.fluxError)
      ..writeByte(2)
      ..write(obj.rSquared)
      ..writeByte(3)
      ..write(obj.slope)
      ..writeByte(4)
      ..write(obj.inlierCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GpsLocationAdapter extends TypeAdapter<GpsLocation> {
  @override
  final int typeId = 3;

  @override
  GpsLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GpsLocation(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      altitude: fields[2] as double?,
      quality: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, GpsLocation obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.altitude)
      ..writeByte(3)
      ..write(obj.quality);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GpsLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SampleAdapter extends TypeAdapter<Sample> {
  @override
  final int typeId = 2;

  @override
  Sample read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sample(
      timestamp: fields[0] as DateTime,
      channelValues: (fields[1] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, Sample obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.channelValues);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SampleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MeasurementAdapter extends TypeAdapter<Measurement> {
  @override
  final int typeId = 1;

  @override
  Measurement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Measurement(
      id: fields[0] as String,
      projectId: fields[1] as String,
      location: fields[2] as GpsLocation,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime?,
      deviceId: fields[5] as String,
      samples: (fields[6] as List).cast<Sample>(),
      notes: fields[7] as String?,
      fitBoundaries: (fields[8] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<int>())),
      statistics: (fields[9] as Map?)?.cast<String, MeasurementStats>(),
    );
  }

  @override
  void write(BinaryWriter writer, Measurement obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.deviceId)
      ..writeByte(6)
      ..write(obj.samples)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.fitBoundaries)
      ..writeByte(9)
      ..write(obj.statistics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
