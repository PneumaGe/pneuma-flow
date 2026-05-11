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

/// Statistics calculated from RANSAC analysis on measurement data
@HiveType(typeId: 9)
class MeasurementStats {
  @HiveField(0)
  final double flux; // ppm/s or g/m²/d depending on conversion
  
  @HiveField(1)
  final double fluxError; // uncertainty estimate
  
  @HiveField(2)
  final double rSquared; // goodness of fit (0.0 to 1.0)
  
  @HiveField(3)
  final double slope; // ppm/s - rate of concentration change
  
  @HiveField(4)
  final int inlierCount; // number of points in consensus set

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

@HiveType(typeId: 3)
class GpsLocation {
  @HiveField(0)
  final double latitude;
  @HiveField(1)
  final double longitude;
  @HiveField(2)
  final double? altitude;
  @HiveField(3)
  final int? quality;

  const GpsLocation({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.quality,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (altitude != null) 'altitude': altitude,
    if (quality != null) 'quality': quality,
  };

  factory GpsLocation.fromJson(Map<String, dynamic> json) => GpsLocation(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    altitude: (json['altitude'] as num?)?.toDouble(),
    quality: json['quality'] as int?,
  );
}

/// A single sample captured from the device at a point in time.
@HiveType(typeId: 2)
class Sample {
  @HiveField(0)
  final DateTime timestamp;
  @HiveField(1)
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

/// A measurement is a recording session at a single GPS location,
/// consisting of many samples over time.
@HiveType(typeId: 1)
class Measurement {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String projectId;
  @HiveField(2)
  final GpsLocation location;
  @HiveField(3)
  final DateTime startTime;
  @HiveField(4)
  final DateTime? endTime;
  @HiveField(5)
  final String deviceId;
  @HiveField(6)
  final List<Sample> samples;
  @HiveField(7)
  final String? notes;
  @HiveField(8)
  final Map<String, List<int>>? fitBoundaries; // Per-channel RANSAC fit boundaries: channelName -> [startIdx, endIdx]
  @HiveField(9)
  final Map<String, MeasurementStats>? statistics; // Per-channel calculated statistics

  const Measurement({
    required this.id,
    required this.projectId,
    required this.location,
    required this.startTime,
    this.endTime,
    required this.deviceId,
    this.samples = const [],
    this.notes,
    this.fitBoundaries,
    this.statistics,
  });

  Duration? get duration => endTime?.difference(startTime);

  int get sampleCount => samples.length;

  /// Helper: Get fit boundaries for a specific channel
  List<int>? getFitBoundaries(String channel) => fitBoundaries?[channel];

  /// Helper: Set fit boundaries for a specific channel
  Measurement setFitBoundaries(String channel, int startIdx, int endIdx) {
    final updatedBoundaries = Map<String, List<int>>.from(fitBoundaries ?? {});
    updatedBoundaries[channel] = [startIdx, endIdx];
    return copyWith(fitBoundaries: updatedBoundaries);
  }

  /// Helper: Clear fit boundaries for a specific channel
  Measurement clearFitBoundaries(String channel) {
    if (fitBoundaries == null || !fitBoundaries!.containsKey(channel)) {
      return this;
    }
    final updatedBoundaries = Map<String, List<int>>.from(fitBoundaries!);
    updatedBoundaries.remove(channel);
    return copyWith(fitBoundaries: updatedBoundaries.isEmpty ? null : updatedBoundaries);
  }

  /// Helper: Get statistics for a specific channel
  MeasurementStats? getStatistics(String channel) => statistics?[channel];

  /// Helper: Set statistics for a specific channel
  Measurement setStatistics(String channel, MeasurementStats stats) {
    final updatedStats = Map<String, MeasurementStats>.from(statistics ?? {});
    updatedStats[channel] = stats;
    return copyWith(statistics: updatedStats);
  }

  /// Helper: Clear statistics for a specific channel
  Measurement clearStatistics(String channel) {
    if (statistics == null || !statistics!.containsKey(channel)) {
      return this;
    }
    final updatedStats = Map<String, MeasurementStats>.from(statistics!);
    updatedStats.remove(channel);
    return copyWith(statistics: updatedStats.isEmpty ? null : updatedStats);
  }

  Measurement copyWith({
    String? id,
    String? projectId,
    GpsLocation? location,
    DateTime? startTime,
    DateTime? endTime,
    String? deviceId,
    List<Sample>? samples,
    String? notes,
    Map<String, List<int>>? fitBoundaries,
    Map<String, MeasurementStats>? statistics,
  }) => Measurement(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    location: location ?? this.location,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    deviceId: deviceId ?? this.deviceId,
    samples: samples ?? this.samples,
    notes: notes ?? this.notes,
    fitBoundaries: fitBoundaries ?? this.fitBoundaries,
    statistics: statistics ?? this.statistics,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'location': location.toJson(),
    'startTime': startTime.toIso8601String(),
    if (endTime != null) 'endTime': endTime!.toIso8601String(),
    'deviceId': deviceId,
    'samples': samples.map((s) => s.toJson()).toList(),
    if (notes != null) 'notes': notes,
    if (fitBoundaries != null) 'fitBoundaries': fitBoundaries,
    if (statistics != null) 'statistics': statistics!.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
  };

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    location: GpsLocation.fromJson(json['location'] as Map<String, dynamic>),
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null
        ? DateTime.parse(json['endTime'] as String)
        : null,
    deviceId: json['deviceId'] as String,
    samples: (json['samples'] as List?)
        ?.map((s) => Sample.fromJson(s as Map<String, dynamic>))
        .toList() ?? [],
    notes: json['notes'] as String?,
    fitBoundaries: json['fitBoundaries'] != null
        ? (json['fitBoundaries'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, (v as List).cast<int>()))
        : null,
    statistics: json['statistics'] != null
        ? (json['statistics'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, MeasurementStats.fromJson(v as Map<String, dynamic>)))
        : null,
  );
}
