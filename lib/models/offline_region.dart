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

part 'offline_region.g.dart';

/// Represents a cached offline map region for field use
@HiveType(typeId: 10)
class OfflineRegion {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double northLat;

  @HiveField(3)
  final double southLat;

  @HiveField(4)
  final double eastLng;

  @HiveField(5)
  final double westLng;

  @HiveField(6)
  final int minZoom;

  @HiveField(7)
  final int maxZoom;

  @HiveField(8)
  final DateTime downloadedAt;

  @HiveField(9)
  final int sizeBytes;

  @HiveField(10)
  final String? mapboxRegionId; // Internal Mapbox identifier for deletion

  const OfflineRegion({
    required this.id,
    required this.name,
    required this.northLat,
    required this.southLat,
    required this.eastLng,
    required this.westLng,
    required this.minZoom,
    required this.maxZoom,
    required this.downloadedAt,
    required this.sizeBytes,
    this.mapboxRegionId,
  });

  /// Get human-readable size display
  String get sizeDisplay {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get center point of region
  Map<String, double> get center => {
    'lat': (northLat + southLat) / 2,
    'lng': (eastLng + westLng) / 2,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'northLat': northLat,
    'southLat': southLat,
    'eastLng': eastLng,
    'westLng': westLng,
    'minZoom': minZoom,
    'maxZoom': maxZoom,
    'downloadedAt': downloadedAt.toIso8601String(),
    'sizeBytes': sizeBytes,
    'mapboxRegionId': mapboxRegionId,
  };

  factory OfflineRegion.fromJson(Map<String, dynamic> json) => OfflineRegion(
    id: json['id'] as String,
    name: json['name'] as String,
    northLat: (json['northLat'] as num).toDouble(),
    southLat: (json['southLat'] as num).toDouble(),
    eastLng: (json['eastLng'] as num).toDouble(),
    westLng: (json['westLng'] as num).toDouble(),
    minZoom: json['minZoom'] as int,
    maxZoom: json['maxZoom'] as int,
    downloadedAt: DateTime.parse(json['downloadedAt'] as String),
    sizeBytes: json['sizeBytes'] as int,
    mapboxRegionId: json['mapboxRegionId'] as String?,
  );
}
