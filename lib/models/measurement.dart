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

import 'package:hive/hive.dart';

part 'measurement.g.dart';

// ==========================================
// TOP-LEVEL RECORD (PneumaGe Master Schema v1.9.0)
// ==========================================

/// Top-level API wrapper for the PneumaGe Master Schema v1.9.0
@HiveType(typeId: 1)
class PneumaGeRecord {
  @HiveField(0)
  final String version;
  
  @HiveField(1)
  final String recordUuid;
  
  @HiveField(2)
  final Provenance provenance;
  
  @HiveField(3)
  final SiteContext siteContext;
  
  @HiveField(4)
  final MeasurementCycle measurementCycle;

  const PneumaGeRecord({
    required this.version,
    required this.recordUuid,
    required this.provenance,
    required this.siteContext,
    required this.measurementCycle,
  });

  factory PneumaGeRecord.fromJson(Map<String, dynamic> json) => PneumaGeRecord(
    version: json['version'] ?? '1.9.0',
    recordUuid: json['record_uuid'] ?? '',
    provenance: Provenance.fromJson(json['provenance'] ?? {}),
    siteContext: SiteContext.fromJson(json['site_context'] ?? {}),
    measurementCycle: MeasurementCycle.fromJson(json['measurement_cycle'] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    'version': version,
    'record_uuid': recordUuid,
    'provenance': provenance.toJson(),
    'site_context': siteContext.toJson(),
    'measurement_cycle': measurementCycle.toJson(),
  };
}

// ==========================================
// PROVENANCE & HARDWARE METADATA
// ==========================================

@HiveType(typeId: 22)
class Provenance {
  @HiveField(0)
  final String creator;
  
  @HiveField(1)
  final String organization;
  
  @HiveField(2)
  final String project;
  
  @HiveField(3)
  final String operatorId;
  
  @HiveField(4)
  final String systemId;
  
  @HiveField(5)
  final String computePlatform;
  
  @HiveField(6)
  final String firmwareVersion;
  
  @HiveField(7)
  final List<SensorPayload> sensorPayload;

  const Provenance({
    required this.creator,
    required this.organization,
    required this.project,
    required this.operatorId,
    required this.systemId,
    required this.computePlatform,
    required this.firmwareVersion,
    required this.sensorPayload,
  });

  factory Provenance.fromJson(Map<String, dynamic> json) => Provenance(
    creator: json['creator'] ?? '',
    organization: json['organization'] ?? '',
    project: json['project'] ?? '',
    operatorId: json['operator_id'] ?? '',
    systemId: json['system_id'] ?? '',
    computePlatform: json['compute_platform'] ?? '',
    firmwareVersion: json['firmware_version'] ?? '',
    sensorPayload: (json['sensor_payload'] as List?)
        ?.map((item) => SensorPayload.fromJson(item))
        .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'creator': creator,
    'organization': organization,
    'project': project,
    'operator_id': operatorId,
    'system_id': systemId,
    'compute_platform': computePlatform,
    'firmware_version': firmwareVersion,
    'sensor_payload': sensorPayload.map((e) => e.toJson()).toList(),
  };
}

@HiveType(typeId: 23)
class SensorPayload {
  @HiveField(0)
  final String type;
  
  @HiveField(1)
  final String model;
  
  @HiveField(2)
  final String? serial;
  
  @HiveField(3)
  final String? precision;

  const SensorPayload({
    required this.type,
    required this.model,
    this.serial,
    this.precision,
  });

  factory SensorPayload.fromJson(Map<String, dynamic> json) => SensorPayload(
    type: json['type'] ?? '',
    model: json['model'] ?? '',
    serial: json['serial'],
    precision: json['precision'],
  );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'type': type, 'model': model};
    if (serial != null) map['serial'] = serial;
    if (precision != null) map['precision'] = precision;
    return map;
  }
}

// ==========================================
// SITE CONTEXT & DOMAINS
// ==========================================

@HiveType(typeId: 24)
class SiteContext {
  @HiveField(0)
  final String activeDomain;
  
  @HiveField(1)
  final List<String> standardsCompliance;
  
  @HiveField(2)
  final Coordinates coordinates;
  
  @HiveField(3)
  final EnvironmentalData environmentalData;
  
  @HiveField(4)
  final DomainSpecifics domainSpecifics;

  const SiteContext({
    required this.activeDomain,
    required this.standardsCompliance,
    required this.coordinates,
    required this.environmentalData,
    required this.domainSpecifics,
  });

  factory SiteContext.fromJson(Map<String, dynamic> json) => SiteContext(
    activeDomain: json['active_domain'] ?? 'Agriculture',
    standardsCompliance: List<String>.from(json['standards_compliance'] ?? []),
    coordinates: Coordinates.fromJson(json['coordinates'] ?? {}),
    environmentalData: EnvironmentalData.fromJson(json['environmental_data'] ?? {}),
    domainSpecifics: DomainSpecifics.fromJson(json['domain_specifics'] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    'active_domain': activeDomain,
    'standards_compliance': standardsCompliance,
    'coordinates': coordinates.toJson(),
    'environmental_data': environmentalData.toJson(),
    'domain_specifics': domainSpecifics.toJson(),
  };
}

@HiveType(typeId: 25)
class Coordinates {
  @HiveField(0)
  final double lat;
  
  @HiveField(1)
  final double lon;
  
  @HiveField(2)
  final double elevationM;

  const Coordinates({
    required this.lat,
    required this.lon,
    required this.elevationM,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) => Coordinates(
    lat: (json['lat'] ?? 0).toDouble(),
    lon: (json['lon'] ?? 0).toDouble(),
    elevationM: (json['elevation_m'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lon': lon,
    'elevation_m': elevationM,
  };
}

@HiveType(typeId: 26)
class EnvironmentalData {
  @HiveField(0)
  final double ambientTempC;
  
  @HiveField(1)
  final double barometricPressurePa;
  
  @HiveField(2)
  final double relativeHumidityPct;

  const EnvironmentalData({
    required this.ambientTempC,
    required this.barometricPressurePa,
    required this.relativeHumidityPct,
  });

  factory EnvironmentalData.fromJson(Map<String, dynamic> json) => EnvironmentalData(
    ambientTempC: (json['ambient_temp_c'] ?? 0).toDouble(),
    barometricPressurePa: (json['barometric_pressure_pa'] ?? 0).toDouble(),
    relativeHumidityPct: (json['relative_humidity_pct'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'ambient_temp_c': ambientTempC,
    'barometric_pressure_pa': barometricPressurePa,
    'relative_humidity_pct': relativeHumidityPct,
  };
}

@HiveType(typeId: 27)
class DomainSpecifics {
  @HiveField(0)
  final Map<String, dynamic> agriculture;
  
  @HiveField(1)
  final Map<String, dynamic> arctic;
  
  @HiveField(2)
  final Map<String, dynamic> maritime;
  
  @HiveField(3)
  final Map<String, dynamic> volcanology;

  const DomainSpecifics({
    required this.agriculture,
    required this.arctic,
    required this.maritime,
    required this.volcanology,
  });

  factory DomainSpecifics.fromJson(Map<String, dynamic> json) => DomainSpecifics(
    agriculture: json['agriculture'] ?? {},
    arctic: json['arctic'] ?? {},
    maritime: json['maritime'] ?? {},
    volcanology: json['volcanology'] ?? {},
  );

  Map<String, dynamic> toJson() => {
    'agriculture': agriculture,
    'arctic': arctic,
    'maritime': maritime,
    'volcanology': volcanology,
  };
}

// ==========================================
// MEASUREMENT CYCLE & MULTI-CHANNEL DATA
// ==========================================

@HiveType(typeId: 28)
class MeasurementCycle {
  @HiveField(0)
  final String cycleId;
  
  @HiveField(1)
  final DateTime timestampStart;
  
  @HiveField(2)
  final double chamberVolumeM3;
  
  @HiveField(3)
  final double systemVolumeM3;
  
  @HiveField(4)
  final SystemVitals systemVitals;
  
  @HiveField(5)
  final List<FluxChannel> channels;

  const MeasurementCycle({
    required this.cycleId,
    required this.timestampStart,
    required this.chamberVolumeM3,
    required this.systemVolumeM3,
    required this.systemVitals,
    required this.channels,
  });

  factory MeasurementCycle.fromJson(Map<String, dynamic> json) => MeasurementCycle(
    cycleId: json['cycle_id'] ?? '',
    timestampStart: DateTime.tryParse(json['timestamp_start'] ?? '') ?? DateTime.now(),
    chamberVolumeM3: (json['chamber_volume_m3'] ?? 0).toDouble(),
    systemVolumeM3: (json['system_volume_m3'] ?? 0).toDouble(),
    systemVitals: SystemVitals.fromJson(json['system_vitals'] ?? {}),
    channels: (json['channels'] as List?)
        ?.map((item) => FluxChannel.fromJson(item))
        .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'cycle_id': cycleId,
    'timestamp_start': timestampStart.toUtc().toIso8601String(),
    'chamber_volume_m3': chamberVolumeM3,
    'system_volume_m3': systemVolumeM3,
    'system_vitals': systemVitals.toJson(),
    'channels': channels.map((e) => e.toJson()).toList(),
  };
}

@HiveType(typeId: 29)
class SystemVitals {
  @HiveField(0)
  final int batteryMv;
  
  @HiveField(1)
  final int pumpPwmDutyPct;
  
  @HiveField(2)
  final double chamberTiltPitch;
  
  @HiveField(3)
  final double chamberTiltRoll;
  
  @HiveField(4)
  final bool shockDetected;

  const SystemVitals({
    required this.batteryMv,
    required this.pumpPwmDutyPct,
    required this.chamberTiltPitch,
    required this.chamberTiltRoll,
    required this.shockDetected,
  });

  factory SystemVitals.fromJson(Map<String, dynamic> json) => SystemVitals(
    batteryMv: json['battery_mv'] ?? 0,
    pumpPwmDutyPct: json['pump_pwm_duty_pct'] ?? 0,
    chamberTiltPitch: (json['chamber_tilt_pitch'] ?? 0).toDouble(),
    chamberTiltRoll: (json['chamber_tilt_roll'] ?? 0).toDouble(),
    shockDetected: json['shock_detected'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'battery_mv': batteryMv,
    'pump_pwm_duty_pct': pumpPwmDutyPct,
    'chamber_tilt_pitch': chamberTiltPitch,
    'chamber_tilt_roll': chamberTiltRoll,
    'shock_detected': shockDetected,
  };
}

@HiveType(typeId: 30)
class FluxChannel {
  @HiveField(0)
  final String targetGas;
  
  @HiveField(1)
  final String sensorReference;
  
  @HiveField(2)
  final CalibrationData calibration;
  
  @HiveField(3)
  final Map<String, dynamic> algorithms;
  
  @HiveField(4)
  final ChannelData rawData;
  
  @HiveField(5)
  final ChannelData filteredData;

  const FluxChannel({
    required this.targetGas,
    required this.sensorReference,
    required this.calibration,
    required this.algorithms,
    required this.rawData,
    required this.filteredData,
  });

  factory FluxChannel.fromJson(Map<String, dynamic> json) => FluxChannel(
    targetGas: json['target_gas'] ?? '',
    sensorReference: json['sensor_reference'] ?? '',
    calibration: CalibrationData.fromJson(json['calibration'] ?? {}),
    algorithms: json['algorithms'] ?? {},
    rawData: ChannelData.fromJson(json['raw_data'] ?? {}),
    filteredData: ChannelData.fromJson(json['filtered_data'] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    'target_gas': targetGas,
    'sensor_reference': sensorReference,
    'calibration': calibration.toJson(),
    'algorithms': algorithms,
    'raw_data': rawData.toJson(),
    'filtered_data': filteredData.toJson(),
  };
}

@HiveType(typeId: 31)
class CalibrationData {
  @HiveField(0)
  final String curveId;
  
  @HiveField(1)
  final String type;
  
  @HiveField(2)
  final List<double> coefficients;
  
  @HiveField(3)
  final double saturationThresholdPpm;
  
  @HiveField(4)
  final DateTime lastCalibrated;

  const CalibrationData({
    required this.curveId,
    required this.type,
    required this.coefficients,
    required this.saturationThresholdPpm,
    required this.lastCalibrated,
  });

  factory CalibrationData.fromJson(Map<String, dynamic> json) => CalibrationData(
    curveId: json['curve_id'] ?? '',
    type: json['type'] ?? '',
    coefficients: (json['coefficients'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    saturationThresholdPpm: (json['saturation_threshold_ppm'] ?? 0).toDouble(),
    lastCalibrated: DateTime.tryParse(json['last_calibrated'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'curve_id': curveId,
    'type': type,
    'coefficients': coefficients,
    'saturation_threshold_ppm': saturationThresholdPpm,
    'last_calibrated': lastCalibrated.toUtc().toIso8601String(),
  };
}

@HiveType(typeId: 32)
class ChannelData {
  @HiveField(0)
  final List<String> sampleFormat;
  
  @HiveField(1)
  final int? sampleCount;
  
  @HiveField(2)
  final String? fileSha256;
  
  @HiveField(3)
  final List<List<dynamic>> samples;
  
  @HiveField(4)
  final CalculatedFlux calculatedFlux;

  const ChannelData({
    required this.sampleFormat,
    this.sampleCount,
    this.fileSha256,
    required this.samples,
    required this.calculatedFlux,
  });

  factory ChannelData.fromJson(Map<String, dynamic> json) => ChannelData(
    sampleFormat: List<String>.from(json['sample_format'] ?? []),
    sampleCount: json['sample_count'],
    fileSha256: json['file_sha256'],
    samples: (json['samples'] as List?)?.map((e) => List<dynamic>.from(e)).toList() ?? [],
    calculatedFlux: CalculatedFlux.fromJson(json['calculated_flux'] ?? {}),
  );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'sample_format': sampleFormat,
      'samples': samples,
      'calculated_flux': calculatedFlux.toJson(),
    };
    if (sampleCount != null) map['sample_count'] = sampleCount;
    if (fileSha256 != null) map['file_sha256'] = fileSha256;
    return map;
  }
}

@HiveType(typeId: 33)
class CalculatedFlux {
  @HiveField(0)
  final double boundaryLeftS;
  
  @HiveField(1)
  final double boundaryRightS;
  
  @HiveField(2)
  final double slopePpmS;
  
  @HiveField(3)
  final double fluxRateMgM2H;
  
  @HiveField(4)
  final double fluxError;
  
  @HiveField(5)
  final double rSquared;
  
  @HiveField(6)
  final int qaQcFlag;
  
  @HiveField(7)
  final String qaQcReason;

  const CalculatedFlux({
    required this.boundaryLeftS,
    required this.boundaryRightS,
    required this.slopePpmS,
    required this.fluxRateMgM2H,
    required this.fluxError,
    required this.rSquared,
    required this.qaQcFlag,
    required this.qaQcReason,
  });

  factory CalculatedFlux.fromJson(Map<String, dynamic> json) => CalculatedFlux(
    boundaryLeftS: (json['boundary_left_s'] ?? 0).toDouble(),
    boundaryRightS: (json['boundary_right_s'] ?? 0).toDouble(),
    slopePpmS: (json['slope_ppm_s'] ?? 0).toDouble(),
    fluxRateMgM2H: (json['flux_rate_mg_m2_h'] ?? 0).toDouble(),
    fluxError: (json['flux_error'] ?? 0).toDouble(),
    rSquared: (json['r_squared'] ?? 0).toDouble(),
    qaQcFlag: json['qa_qc_flag'] ?? 0,
    qaQcReason: json['qa_qc_reason'] ?? 'unknown',
  );

  Map<String, dynamic> toJson() => {
    'boundary_left_s': boundaryLeftS,
    'boundary_right_s': boundaryRightS,
    'slope_ppm_s': slopePpmS,
    'flux_rate_mg_m2_h': fluxRateMgM2H,
    'flux_error': fluxError,
    'r_squared': rSquared,
    'qa_qc_flag': qaQcFlag,
    'qa_qc_reason': qaQcReason,
  };
}

// ==========================================
// COMPATIBILITY LAYER & HELPERS
// ==========================================

/// Backward-compatible Sample class for UI components
/// Represents a single timestamped measurement with all channel values
class Sample {
  final DateTime timestamp;
  final Map<String, double> channelValues;

  const Sample({
    required this.timestamp,
    required this.channelValues,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'channelValues': channelValues,
  };

  factory Sample.fromJson(Map<String, dynamic> json) => Sample(
    timestamp: DateTime.parse(json['timestamp'] as String),
    channelValues: (json['channelValues'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble())),
  );
}

/// Extension methods to provide Measurement-like interface on PneumaGeRecord
extension PneumaGeRecordHelpers on PneumaGeRecord {
  /// Get measurement ID (uses recordUuid)
  String get id => recordUuid;

  /// Get project ID (from provenance)
  String get projectId => provenance.project;

  /// Get device ID (from provenance)
  String get deviceId => provenance.systemId;

  /// Get start time
  DateTime get startTime => measurementCycle.timestampStart;

  /// Get end time (computed from last sample if available)
  DateTime? get endTime {
    DateTime? lastTime;
    for (final channel in measurementCycle.channels) {
      final samples = channel.filteredData.samples.isNotEmpty 
          ? channel.filteredData.samples 
          : channel.rawData.samples;
      if (samples.isNotEmpty) {
        final lastSample = samples.last;
        if (lastSample.isNotEmpty) {
          final timestamp = startTime.add(Duration(milliseconds: (lastSample[0] as num).toInt()));
          if (lastTime == null || timestamp.isAfter(lastTime)) {
            lastTime = timestamp;
          }
        }
      }
    }
    return lastTime;
  }

  /// Get duration
  Duration? get duration => endTime?.difference(startTime);

  /// Get sample count (from first channel)
  int get sampleCount {
    if (measurementCycle.channels.isEmpty) return 0;
    final channel = measurementCycle.channels.first;
    return channel.filteredData.samples.isNotEmpty 
        ? channel.filteredData.samples.length 
        : channel.rawData.samples.length;
  }

  /// Get latitude
  double get latitude => siteContext.coordinates.lat;

  /// Get longitude
  double get longitude => siteContext.coordinates.lon;

  /// Get elevation
  double get elevation => siteContext.coordinates.elevationM;

  /// Extract samples in backward-compatible format
  /// If useFiltered is true, uses filtered data; otherwise uses raw data
  List<Sample> getSamples({bool useFiltered = true}) {
    final samples = <Sample>[];
    
    // Determine max sample count across all channels
    int maxSamples = 0;
    for (final channel in measurementCycle.channels) {
      final data = useFiltered ? channel.filteredData : channel.rawData;
      if (data.samples.length > maxSamples) {
        maxSamples = data.samples.length;
      }
    }

    // Build samples by timestamp
    for (int i = 0; i < maxSamples; i++) {
      DateTime? timestamp;
      final channelValues = <String, double>{};

      for (final channel in measurementCycle.channels) {
        final data = useFiltered ? channel.filteredData : channel.rawData;
        if (i < data.samples.length) {
          final sample = data.samples[i];
          if (sample.isNotEmpty) {
            // First element is timestamp_ms
            final timestampMs = (sample[0] as num).toInt();
            timestamp = startTime.add(Duration(milliseconds: timestampMs));
            
            // Find concentration value (second element based on sample_format)
            // sample_format varies by channel type:
            // - Gas channels: ["timestamp_ms", "concentration_ppm", ...]
            // - Temperature: ["timestamp_ms", "temperature_c"]
            // - Pressure: ["timestamp_ms", "pressure_pa"]
            if (sample.length > 1 && data.sampleFormat.length > 1) {
              // Try to find the appropriate field based on channel type
              int valueIdx = -1;
              
              if (channel.targetGas == 'Temperature') {
                valueIdx = data.sampleFormat.indexOf('temperature_c');
              } else if (channel.targetGas == 'Pressure') {
                valueIdx = data.sampleFormat.indexOf('pressure_pa');
              } else {
                // Gas channels - look for concentration_ppm
                valueIdx = data.sampleFormat.indexOf('concentration_ppm');
              }
              
              if (valueIdx >= 0 && valueIdx < sample.length) {
                channelValues[channel.targetGas] = (sample[valueIdx] as num).toDouble();
              } else if (sample.length > 1) {
                // Fallback: use second element
                channelValues[channel.targetGas] = (sample[1] as num).toDouble();
              }
            }
          }
        }
      }

      if (timestamp != null && channelValues.isNotEmpty) {
        samples.add(Sample(timestamp: timestamp, channelValues: channelValues));
      }
    }

    return samples;
  }

  /// Get fit boundaries for a specific channel (returns sample indices)
  List<int>? getFitBoundaries(String channelName) {
    for (final channel in measurementCycle.channels) {
      if (channel.targetGas == channelName) {
        // Convert time boundaries to sample indices
        final flux = channel.rawData.calculatedFlux;
        final startMs = (flux.boundaryLeftS * 1000).toInt();
        final endMs = (flux.boundaryRightS * 1000).toInt();
        
        // Find corresponding sample indices
        final samples = channel.rawData.samples;
        int? startIdx;
        int? endIdx;
        
        for (int i = 0; i < samples.length; i++) {
          if (samples[i].isNotEmpty) {
            final sampleMs = (samples[i][0] as num).toInt();
            if (startIdx == null && sampleMs >= startMs) {
              startIdx = i;
            }
            if (sampleMs <= endMs) {
              endIdx = i;
            }
          }
        }
        
        if (startIdx != null && endIdx != null) {
          return [startIdx, endIdx];
        }
      }
    }
    return null;
  }

  /// Get statistics for a specific channel
  MeasurementStats? getStatistics(String channelName) {
    for (final channel in measurementCycle.channels) {
      if (channel.targetGas == channelName) {
        final flux = channel.rawData.calculatedFlux;
        return MeasurementStats(
          flux: flux.fluxRateMgM2H,
          fluxError: flux.fluxError,
          rSquared: flux.rSquared,
          slope: flux.slopePpmS,
          inlierCount: channel.rawData.samples.length, // Approximation
        );
      }
    }
    return null;
  }
}

/// Backward-compatible MeasurementStats for UI components
class MeasurementStats {
  final double flux;
  final double fluxError;
  final double rSquared;
  final double slope;
  final int inlierCount;

  const MeasurementStats({
    required this.flux,
    required this.fluxError,
    required this.rSquared,
    required this.slope,
    required this.inlierCount,
  });

  Map<String, dynamic> toJson() => {
    'flux': flux,
    'fluxError': fluxError,
    'rSquared': rSquared,
    'slope': slope,
    'inlierCount': inlierCount,
  };

  factory MeasurementStats.fromJson(Map<String, dynamic> json) => MeasurementStats(
    flux: (json['flux'] as num).toDouble(),
    fluxError: (json['fluxError'] as num).toDouble(),
    rSquared: (json['rSquared'] as num).toDouble(),
    slope: (json['slope'] as num).toDouble(),
    inlierCount: json['inlierCount'] as int,
  );
}

/// Helper factory to create PneumaGeRecord from live capture data
class PneumaGeRecordFactory {
  /// Create a minimal PneumaGeRecord for live data capture
  static PneumaGeRecord createLiveMeasurement({
    required String projectId,
    required String operatorId,
    required String systemId,
    required double latitude,
    required double longitude,
    double elevation = 0.0,
    String? deviceId,
    List<String> channelNames = const ['CO2', 'CH4'],
    String? activeDomain,
    Map<String, dynamic>? domainMetadata,
  }) {
    final now = DateTime.now();
    final recordUuid = '${projectId}_${now.millisecondsSinceEpoch}';

    // Determine active domain and populate appropriate domain map
    final domain = activeDomain ?? 'NONE';
    final agriculture = (domain == 'AGRICULTURE' && domainMetadata != null) ? domainMetadata : <String, dynamic>{};
    final arctic = (domain == 'ARCTIC' && domainMetadata != null) ? domainMetadata : <String, dynamic>{};
    final maritime = (domain == 'MARITIME' && domainMetadata != null) ? domainMetadata : <String, dynamic>{};
    final volcanology = (domain == 'VOLCANOLOGY' && domainMetadata != null) ? domainMetadata : <String, dynamic>{};

    return PneumaGeRecord(
      version: '1.9.0',
      recordUuid: recordUuid,
      provenance: Provenance(
        creator: operatorId,
        organization: 'PneumaGe',
        project: projectId,
        operatorId: operatorId,
        systemId: deviceId ?? systemId,
        computePlatform: 'Flutter App',
        firmwareVersion: '1.0.0',
        sensorPayload: [],
      ),
      siteContext: SiteContext(
        activeDomain: domain,
        standardsCompliance: [],
        coordinates: Coordinates(
          lat: latitude,
          lon: longitude,
          elevationM: elevation,
        ),
        environmentalData: EnvironmentalData(
          ambientTempC: 20.0,
          barometricPressurePa: 101325.0,
          relativeHumidityPct: 50.0,
        ),
        domainSpecifics: DomainSpecifics(
          agriculture: agriculture,
          arctic: arctic,
          maritime: maritime,
          volcanology: volcanology,
        ),
      ),
      measurementCycle: MeasurementCycle(
        cycleId: recordUuid,
        timestampStart: now,
        chamberVolumeM3: 0.0152,
        systemVolumeM3: 0.0005,
        systemVitals: SystemVitals(
          batteryMv: 3700,
          pumpPwmDutyPct: 85,
          chamberTiltPitch: 0.0,
          chamberTiltRoll: 0.0,
          shockDetected: false,
        ),
        channels: channelNames.map((name) {
          // Determine appropriate sample format based on channel type
          List<String> rawFormat;
          List<String> filteredFormat;
          
          if (name == 'Temperature') {
            rawFormat = ['timestamp_ms', 'temperature_c'];
            filteredFormat = ['timestamp_ms', 'temperature_c'];
          } else if (name == 'Pressure') {
            rawFormat = ['timestamp_ms', 'pressure_pa'];
            filteredFormat = ['timestamp_ms', 'pressure_pa'];
          } else {
            // CO2, CH4, or other gas channels
            rawFormat = ['timestamp_ms', 'raw_sensor_val', 'sensor_temp_c', 'chamber_pressure_pa'];
            filteredFormat = ['timestamp_ms', 'concentration_ppm', 'chamber_temp_c', 'chamber_pressure_pa'];
          }
          
          return FluxChannel(
            targetGas: name,
            sensorReference: 'Unknown',
            calibration: CalibrationData(
              curveId: 'FACTORY',
              type: 'linear',
              coefficients: [1.0, 0.0],
              saturationThresholdPpm: 100000.0,
              lastCalibrated: now,
            ),
            algorithms: {'filter_type': 'None', 'fitting_method': 'RANSAC_LS'},
            rawData: ChannelData(
              sampleFormat: rawFormat,
              samples: [],
              calculatedFlux: CalculatedFlux(
                boundaryLeftS: 0.0,
                boundaryRightS: 0.0,
                slopePpmS: 0.0,
                fluxRateMgM2H: 0.0,
                fluxError: 0.0,
                rSquared: 0.0,
                qaQcFlag: 0,
                qaQcReason: 'pending',
              ),
            ),
            filteredData: ChannelData(
              sampleFormat: filteredFormat,
              samples: [],
              calculatedFlux: CalculatedFlux(
                boundaryLeftS: 0.0,
                boundaryRightS: 0.0,
                slopePpmS: 0.0,
                fluxRateMgM2H: 0.0,
                fluxError: 0.0,
                rSquared: 0.0,
                qaQcFlag: 0,
                qaQcReason: 'pending',
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Add a sample to a PneumaGeRecord (creates a new instance)
  static PneumaGeRecord addSample(
    PneumaGeRecord record,
    DateTime timestamp,
    Map<String, double> channelValues,
    {bool useFiltered = true}
  ) {
    final timestampMs = timestamp.difference(record.startTime).inMilliseconds;
    final updatedChannels = record.measurementCycle.channels.map((channel) {
      final value = channelValues[channel.targetGas];
      if (value == null) return channel;

      // Create sample array based on channel type
      final List<dynamic> newSample;
      if (channel.targetGas == 'Temperature' || channel.targetGas == 'Pressure') {
        // Simple 2-element array for temperature and pressure
        newSample = [timestampMs, value];
      } else {
        // 4-element array for gas channels with chamber conditions
        final temp = channelValues['Temperature'] ?? 20.0;
        final pressure = channelValues['Pressure'] ?? 101325.0;
        newSample = [timestampMs, value, temp, pressure];
      }
      
      if (useFiltered) {
        final updatedSamples = [...channel.filteredData.samples, newSample];
        return FluxChannel(
          targetGas: channel.targetGas,
          sensorReference: channel.sensorReference,
          calibration: channel.calibration,
          algorithms: channel.algorithms,
          rawData: channel.rawData,
          filteredData: ChannelData(
            sampleFormat: channel.filteredData.sampleFormat,
            sampleCount: updatedSamples.length,
            fileSha256: channel.filteredData.fileSha256,
            samples: updatedSamples,
            calculatedFlux: channel.filteredData.calculatedFlux,
          ),
        );
      } else {
        final updatedSamples = [...channel.rawData.samples, newSample];
        return FluxChannel(
          targetGas: channel.targetGas,
          sensorReference: channel.sensorReference,
          calibration: channel.calibration,
          algorithms: channel.algorithms,
          rawData: ChannelData(
            sampleFormat: channel.rawData.sampleFormat,
            sampleCount: updatedSamples.length,
            fileSha256: channel.rawData.fileSha256,
            samples: updatedSamples,
            calculatedFlux: channel.rawData.calculatedFlux,
          ),
          filteredData: channel.filteredData,
        );
      }
    }).toList();

    return PneumaGeRecord(
      version: record.version,
      recordUuid: record.recordUuid,
      provenance: record.provenance,
      siteContext: record.siteContext,
      measurementCycle: MeasurementCycle(
        cycleId: record.measurementCycle.cycleId,
        timestampStart: record.measurementCycle.timestampStart,
        chamberVolumeM3: record.measurementCycle.chamberVolumeM3,
        systemVolumeM3: record.measurementCycle.systemVolumeM3,
        systemVitals: record.measurementCycle.systemVitals,
        channels: updatedChannels,
      ),
    );
  }

  /// Update fit boundaries and statistics for a channel
  static PneumaGeRecord updateChannelStats(
    PneumaGeRecord record,
    String channelName,
    int startIdx,
    int endIdx,
    MeasurementStats stats,
  ) {
    final updatedChannels = record.measurementCycle.channels.map((channel) {
      if (channel.targetGas != channelName) return channel;

      // Convert sample indices to time boundaries
      final samples = channel.rawData.samples;
      final startMs = startIdx < samples.length && samples[startIdx].isNotEmpty 
          ? (samples[startIdx][0] as num).toDouble() 
          : 0.0;
      final endMs = endIdx < samples.length && samples[endIdx].isNotEmpty 
          ? (samples[endIdx][0] as num).toDouble() 
          : 0.0;

      final updatedFlux = CalculatedFlux(
        boundaryLeftS: startMs / 1000.0,
        boundaryRightS: endMs / 1000.0,
        slopePpmS: stats.slope,
        fluxRateMgM2H: stats.flux,
        fluxError: stats.fluxError,
        rSquared: stats.rSquared,
        qaQcFlag: 0,
        qaQcReason: 'nominal',
      );

      return FluxChannel(
        targetGas: channel.targetGas,
        sensorReference: channel.sensorReference,
        calibration: channel.calibration,
        algorithms: channel.algorithms,
        rawData: ChannelData(
          sampleFormat: channel.rawData.sampleFormat,
          sampleCount: channel.rawData.sampleCount,
          fileSha256: channel.rawData.fileSha256,
          samples: channel.rawData.samples,
          calculatedFlux: updatedFlux,
        ),
        filteredData: channel.filteredData,
      );
    }).toList();

    return PneumaGeRecord(
      version: record.version,
      recordUuid: record.recordUuid,
      provenance: record.provenance,
      siteContext: record.siteContext,
      measurementCycle: MeasurementCycle(
        cycleId: record.measurementCycle.cycleId,
        timestampStart: record.measurementCycle.timestampStart,
        chamberVolumeM3: record.measurementCycle.chamberVolumeM3,
        systemVolumeM3: record.measurementCycle.systemVolumeM3,
        systemVitals: record.measurementCycle.systemVitals,
        channels: updatedChannels,
      ),
    );
  }
}
