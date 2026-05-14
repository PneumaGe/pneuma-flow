// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PneumaGeRecordAdapter extends TypeAdapter<PneumaGeRecord> {
  @override
  final int typeId = 1;

  @override
  PneumaGeRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PneumaGeRecord(
      version: fields[0] as String,
      recordUuid: fields[1] as String,
      provenance: fields[2] as Provenance,
      siteContext: fields[3] as SiteContext,
      measurementCycle: fields[4] as MeasurementCycle,
    );
  }

  @override
  void write(BinaryWriter writer, PneumaGeRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.version)
      ..writeByte(1)
      ..write(obj.recordUuid)
      ..writeByte(2)
      ..write(obj.provenance)
      ..writeByte(3)
      ..write(obj.siteContext)
      ..writeByte(4)
      ..write(obj.measurementCycle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PneumaGeRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProvenanceAdapter extends TypeAdapter<Provenance> {
  @override
  final int typeId = 10;

  @override
  Provenance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Provenance(
      creator: fields[0] as String,
      organization: fields[1] as String,
      project: fields[2] as String,
      operatorId: fields[3] as String,
      systemId: fields[4] as String,
      computePlatform: fields[5] as String,
      firmwareVersion: fields[6] as String,
      sensorPayload: (fields[7] as List).cast<SensorPayload>(),
    );
  }

  @override
  void write(BinaryWriter writer, Provenance obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.creator)
      ..writeByte(1)
      ..write(obj.organization)
      ..writeByte(2)
      ..write(obj.project)
      ..writeByte(3)
      ..write(obj.operatorId)
      ..writeByte(4)
      ..write(obj.systemId)
      ..writeByte(5)
      ..write(obj.computePlatform)
      ..writeByte(6)
      ..write(obj.firmwareVersion)
      ..writeByte(7)
      ..write(obj.sensorPayload);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProvenanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SensorPayloadAdapter extends TypeAdapter<SensorPayload> {
  @override
  final int typeId = 11;

  @override
  SensorPayload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SensorPayload(
      type: fields[0] as String,
      model: fields[1] as String,
      serial: fields[2] as String?,
      precision: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SensorPayload obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.model)
      ..writeByte(2)
      ..write(obj.serial)
      ..writeByte(3)
      ..write(obj.precision);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorPayloadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SiteContextAdapter extends TypeAdapter<SiteContext> {
  @override
  final int typeId = 12;

  @override
  SiteContext read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SiteContext(
      activeDomain: fields[0] as String,
      standardsCompliance: (fields[1] as List).cast<String>(),
      coordinates: fields[2] as Coordinates,
      environmentalData: fields[3] as EnvironmentalData,
      domainSpecifics: fields[4] as DomainSpecifics,
    );
  }

  @override
  void write(BinaryWriter writer, SiteContext obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.activeDomain)
      ..writeByte(1)
      ..write(obj.standardsCompliance)
      ..writeByte(2)
      ..write(obj.coordinates)
      ..writeByte(3)
      ..write(obj.environmentalData)
      ..writeByte(4)
      ..write(obj.domainSpecifics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteContextAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CoordinatesAdapter extends TypeAdapter<Coordinates> {
  @override
  final int typeId = 13;

  @override
  Coordinates read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Coordinates(
      lat: fields[0] as double,
      lon: fields[1] as double,
      elevationM: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Coordinates obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.lat)
      ..writeByte(1)
      ..write(obj.lon)
      ..writeByte(2)
      ..write(obj.elevationM);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoordinatesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EnvironmentalDataAdapter extends TypeAdapter<EnvironmentalData> {
  @override
  final int typeId = 14;

  @override
  EnvironmentalData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnvironmentalData(
      ambientTempC: fields[0] as double,
      barometricPressurePa: fields[1] as double,
      relativeHumidityPct: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, EnvironmentalData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.ambientTempC)
      ..writeByte(1)
      ..write(obj.barometricPressurePa)
      ..writeByte(2)
      ..write(obj.relativeHumidityPct);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnvironmentalDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DomainSpecificsAdapter extends TypeAdapter<DomainSpecifics> {
  @override
  final int typeId = 15;

  @override
  DomainSpecifics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DomainSpecifics(
      agriculture: (fields[0] as Map).cast<String, dynamic>(),
      arctic: (fields[1] as Map).cast<String, dynamic>(),
      maritime: (fields[2] as Map).cast<String, dynamic>(),
      volcanology: (fields[3] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, DomainSpecifics obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.agriculture)
      ..writeByte(1)
      ..write(obj.arctic)
      ..writeByte(2)
      ..write(obj.maritime)
      ..writeByte(3)
      ..write(obj.volcanology);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainSpecificsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MeasurementCycleAdapter extends TypeAdapter<MeasurementCycle> {
  @override
  final int typeId = 16;

  @override
  MeasurementCycle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementCycle(
      cycleId: fields[0] as String,
      timestampStart: fields[1] as DateTime,
      chamberVolumeM3: fields[2] as double,
      systemVolumeM3: fields[3] as double,
      systemVitals: fields[4] as SystemVitals,
      channels: (fields[5] as List).cast<FluxChannel>(),
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementCycle obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.cycleId)
      ..writeByte(1)
      ..write(obj.timestampStart)
      ..writeByte(2)
      ..write(obj.chamberVolumeM3)
      ..writeByte(3)
      ..write(obj.systemVolumeM3)
      ..writeByte(4)
      ..write(obj.systemVitals)
      ..writeByte(5)
      ..write(obj.channels);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementCycleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SystemVitalsAdapter extends TypeAdapter<SystemVitals> {
  @override
  final int typeId = 17;

  @override
  SystemVitals read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SystemVitals(
      batteryMv: fields[0] as int,
      pumpPwmDutyPct: fields[1] as int,
      chamberTiltPitch: fields[2] as double,
      chamberTiltRoll: fields[3] as double,
      shockDetected: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SystemVitals obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.batteryMv)
      ..writeByte(1)
      ..write(obj.pumpPwmDutyPct)
      ..writeByte(2)
      ..write(obj.chamberTiltPitch)
      ..writeByte(3)
      ..write(obj.chamberTiltRoll)
      ..writeByte(4)
      ..write(obj.shockDetected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemVitalsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FluxChannelAdapter extends TypeAdapter<FluxChannel> {
  @override
  final int typeId = 18;

  @override
  FluxChannel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FluxChannel(
      targetGas: fields[0] as String,
      sensorReference: fields[1] as String,
      calibration: fields[2] as CalibrationData,
      algorithms: (fields[3] as Map).cast<String, dynamic>(),
      rawData: fields[4] as ChannelData,
      filteredData: fields[5] as ChannelData,
    );
  }

  @override
  void write(BinaryWriter writer, FluxChannel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.targetGas)
      ..writeByte(1)
      ..write(obj.sensorReference)
      ..writeByte(2)
      ..write(obj.calibration)
      ..writeByte(3)
      ..write(obj.algorithms)
      ..writeByte(4)
      ..write(obj.rawData)
      ..writeByte(5)
      ..write(obj.filteredData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FluxChannelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CalibrationDataAdapter extends TypeAdapter<CalibrationData> {
  @override
  final int typeId = 19;

  @override
  CalibrationData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalibrationData(
      curveId: fields[0] as String,
      type: fields[1] as String,
      coefficients: (fields[2] as List).cast<double>(),
      saturationThresholdPpm: fields[3] as double,
      lastCalibrated: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CalibrationData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.curveId)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.coefficients)
      ..writeByte(3)
      ..write(obj.saturationThresholdPpm)
      ..writeByte(4)
      ..write(obj.lastCalibrated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalibrationDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChannelDataAdapter extends TypeAdapter<ChannelData> {
  @override
  final int typeId = 20;

  @override
  ChannelData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChannelData(
      sampleFormat: (fields[0] as List).cast<String>(),
      sampleCount: fields[1] as int?,
      fileSha256: fields[2] as String?,
      samples: (fields[3] as List)
          .map((dynamic e) => (e as List).cast<dynamic>())
          .toList(),
      calculatedFlux: fields[4] as CalculatedFlux,
    );
  }

  @override
  void write(BinaryWriter writer, ChannelData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.sampleFormat)
      ..writeByte(1)
      ..write(obj.sampleCount)
      ..writeByte(2)
      ..write(obj.fileSha256)
      ..writeByte(3)
      ..write(obj.samples)
      ..writeByte(4)
      ..write(obj.calculatedFlux);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CalculatedFluxAdapter extends TypeAdapter<CalculatedFlux> {
  @override
  final int typeId = 21;

  @override
  CalculatedFlux read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalculatedFlux(
      boundaryLeftS: fields[0] as double,
      boundaryRightS: fields[1] as double,
      slopePpmS: fields[2] as double,
      fluxRateMgM2H: fields[3] as double,
      fluxError: fields[4] as double,
      rSquared: fields[5] as double,
      qaQcFlag: fields[6] as int,
      qaQcReason: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CalculatedFlux obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.boundaryLeftS)
      ..writeByte(1)
      ..write(obj.boundaryRightS)
      ..writeByte(2)
      ..write(obj.slopePpmS)
      ..writeByte(3)
      ..write(obj.fluxRateMgM2H)
      ..writeByte(4)
      ..write(obj.fluxError)
      ..writeByte(5)
      ..write(obj.rSquared)
      ..writeByte(6)
      ..write(obj.qaQcFlag)
      ..writeByte(7)
      ..write(obj.qaQcReason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculatedFluxAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
