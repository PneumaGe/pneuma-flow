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

/// A single data channel reported by a sensor.
class ChannelDefinition {
  final String id;
  final String name;
  final String unit;
  final String? gasType;
  final double? rangeMin;
  final double? rangeMax;
  final double? precision;
  final double? resolution;
  final double? sampleRate; // Hz
  final bool isStandard;

  const ChannelDefinition({
    required this.id,
    required this.name,
    required this.unit,
    this.gasType,
    this.rangeMin,
    this.rangeMax,
    this.precision,
    this.resolution,
    this.sampleRate,
    this.isStandard = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    if (gasType != null) 'gasType': gasType,
    if (rangeMin != null) 'rangeMin': rangeMin,
    if (rangeMax != null) 'rangeMax': rangeMax,
    if (precision != null) 'precision': precision,
    if (resolution != null) 'resolution': resolution,
    if (sampleRate != null) 'sampleRate': sampleRate,
    'isStandard': isStandard,
  };

  factory ChannelDefinition.fromJson(Map<String, dynamic> json) =>
      ChannelDefinition(
        id: json['id'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        gasType: json['gasType'] as String?,
        rangeMin: (json['rangeMin'] as num?)?.toDouble(),
        rangeMax: (json['rangeMax'] as num?)?.toDouble(),
        precision: (json['precision'] as num?)?.toDouble(),
        resolution: (json['resolution'] as num?)?.toDouble(),
        sampleRate: (json['sampleRate'] as num?)?.toDouble(),
        isStandard: json['isStandard'] as bool? ?? true,
      );

  static const List<ChannelDefinition> standardChannels = [
    ChannelDefinition(id: 'co2', name: 'CO2', unit: 'ppm', gasType: 'CO2'),
    ChannelDefinition(id: 'ch4', name: 'CH4', unit: 'ppm', gasType: 'CH4'),
    ChannelDefinition(id: 'temp_chamber', name: 'T_Chamber', unit: '°C'),
    ChannelDefinition(id: 'press_chamber', name: 'P_Chamber', unit: 'mBar'),
    ChannelDefinition(id: 'rh_chamber', name: 'RH_Chamber', unit: '%'),
    ChannelDefinition(id: 'temp_air', name: 'T_Air', unit: '°C'),
    ChannelDefinition(id: 'press_air', name: 'P_Air', unit: 'mBar'),
    ChannelDefinition(id: 'rh_air', name: 'RH_Air', unit: '%'),
  ];
}

/// A physical sensor installed in the device.
class SensorInfo {
  final String id;
  final String make;
  final String model;
  final String serialNumber;
  final String sensorType; // NDIR, TDLA, thermistor, barometer, etc.
  final List<ChannelDefinition> channels;

  const SensorInfo({
    required this.id,
    required this.make,
    required this.model,
    required this.serialNumber,
    required this.sensorType,
    required this.channels,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'make': make,
    'model': model,
    'serialNumber': serialNumber,
    'sensorType': sensorType,
    'channels': channels.map((ch) => ch.toJson()).toList(),
  };

  factory SensorInfo.fromJson(Map<String, dynamic> json) => SensorInfo(
    id: json['id'] as String,
    make: json['make'] as String,
    model: json['model'] as String,
    serialNumber: json['serialNumber'] as String,
    sensorType: json['sensorType'] as String,
    channels: (json['channels'] as List)
        .map((ch) => ChannelDefinition.fromJson(ch as Map<String, dynamic>))
        .toList(),
  );
}

/// The device's pump hardware.
class PumpInfo {
  final String make;
  final String model;
  final String serialNumber;
  final double flowRateMin; // L/min
  final double flowRateMax; // L/min

  const PumpInfo({
    required this.make,
    required this.model,
    required this.serialNumber,
    required this.flowRateMin,
    required this.flowRateMax,
  });

  Map<String, dynamic> toJson() => {
    'make': make,
    'model': model,
    'serialNumber': serialNumber,
    'flowRateMin': flowRateMin,
    'flowRateMax': flowRateMax,
  };

  factory PumpInfo.fromJson(Map<String, dynamic> json) => PumpInfo(
    make: json['make'] as String,
    model: json['model'] as String,
    serialNumber: json['serialNumber'] as String,
    flowRateMin: (json['flowRateMin'] as num).toDouble(),
    flowRateMax: (json['flowRateMax'] as num).toDouble(),
  );
}

/// Complete device descriptor, reported by the device on connection
/// and cached locally by the app.
class DeviceInfo {
  final String deviceId; // device-level UUID, survives component swaps
  final String deviceName;
  final int descriptorVersion;
  final String? macAddress;
  final String processorMake;
  final String processorModel;
  final String processorSerial;
  final String firmwareVersion;
  final String? dataModelVersion; // Schema version from device
  final DateTime? lastSeen; // set by app on cache
  final PumpInfo pump;
  final List<SensorInfo> sensors;
  final Set<String> capabilities; // e.g. 'gps'

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.descriptorVersion,
    this.macAddress,
    required this.processorMake,
    required this.processorModel,
    required this.processorSerial,
    required this.firmwareVersion,
    this.dataModelVersion,
    this.lastSeen,
    required this.pump,
    required this.sensors,
    this.capabilities = const {},
  });

  /// All channels across all sensors.
  List<ChannelDefinition> get allChannels =>
      sensors.expand((s) => s.channels).toList();

  /// Check if device data model version is compatible with app
  bool isDataModelCompatible({String appVersion = '1.9.0'}) {
    if (dataModelVersion == null) {
      // Legacy firmware without version field - assume compatible for now
      return true;
    }
    
    // Parse semantic versions
    final deviceParts = dataModelVersion!.split('.').map((s) {
      try {
        return int.parse(s);
      } catch (e) {
        return 0;
      }
    }).toList();
    final appParts = appVersion.split('.').map((s) {
      try {
        return int.parse(s);
      } catch (e) {
        return 0;
      }
    }).toList();
    
    if (deviceParts.length < 2 || appParts.length < 2) {
      return false; // Invalid version format
    }
    
    // Major version must match
    if (deviceParts[0] != appParts[0]) {
      return false;
    }
    
    // Minor version: app must be >= device version
    if (appParts[1] < deviceParts[1]) {
      return false; // App is too old
    }
    
    return true;
  }

  /// Get human-readable compatibility message
  String getCompatibilityMessage({String appVersion = '1.9.0'}) {
    if (dataModelVersion == null) {
      return 'Legacy firmware detected (no schema version)';
    }
    
    if (isDataModelCompatible(appVersion: appVersion)) {
      return 'Schema compatible: Device $dataModelVersion, App $appVersion';
    }
    
    return 'INCOMPATIBLE: Device schema $dataModelVersion does not match app $appVersion';
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'descriptorVersion': descriptorVersion,
    if (macAddress != null) 'macAddress': macAddress,
    'processorMake': processorMake,
    'processorModel': processorModel,
    'processorSerial': processorSerial,
    'firmwareVersion': firmwareVersion,
    if (dataModelVersion != null) 'dataModelVersion': dataModelVersion,
    if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
    'pump': pump.toJson(),
    'sensors': sensors.map((s) => s.toJson()).toList(),
    'capabilities': capabilities.toList(),
  };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
    deviceId: json['deviceId'] as String,
    deviceName: json['deviceName'] as String,
    descriptorVersion: json['descriptorVersion'] as int,
    macAddress: json['macAddress'] as String?,
    processorMake: json['processorMake'] as String,
    processorModel: json['processorModel'] as String,
    processorSerial: json['processorSerial'] as String,
    firmwareVersion: json['firmwareVersion'] as String,
    dataModelVersion: json['dataModelVersion'] as String?,
    lastSeen: json['lastSeen'] != null
        ? DateTime.parse(json['lastSeen'] as String)
        : null,
    pump: PumpInfo.fromJson(json['pump'] as Map<String, dynamic>),
    sensors: (json['sensors'] as List)
        .map((s) => SensorInfo.fromJson(s as Map<String, dynamic>))
        .toList(),
    capabilities: (json['capabilities'] as List?)
        ?.cast<String>()
        .toSet() ?? {},
  );
}
