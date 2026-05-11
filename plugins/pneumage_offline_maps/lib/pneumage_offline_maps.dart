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


import 'dart:async';
import 'package:flutter/services.dart';

/// Plugin for downloading and managing offline map tiles using Mapbox TileStore
class PneumageOfflineMaps {
  static const MethodChannel _channel = MethodChannel('pneumage_offline_maps');

  /// Download a map region for offline use
  /// 
  /// Parameters:
  /// - [north], [south], [east], [west]: Bounding box coordinates
  /// - [minZoom], [maxZoom]: Zoom level range to cache (e.g., 10-16)
  /// - [regionId]: Unique identifier for this cached region
  /// 
  /// Returns [OfflineRegionResult] with actual download statistics
  /// Throws [PlatformException] if download fails
  static Future<OfflineRegionResult> downloadRegion({
    required double north,
    required double south,
    required double east,
    required double west,
    required int minZoom,
    required int maxZoom,
    required String regionId,
  }) async {
    try {
      final result = await _channel.invokeMethod('downloadRegion', {
        'north': north,
        'south': south,
        'east': east,
        'west': west,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'regionId': regionId,
      });
      
      return OfflineRegionResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw PneumageOfflineMapsException(
        'Failed to download region: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Delete a cached offline region
  /// 
  /// Removes tiles from device storage and clears cache
  static Future<void> deleteRegion(String regionId) async {
    try {
      await _channel.invokeMethod('deleteRegion', {'regionId': regionId});
    } on PlatformException catch (e) {
      throw PneumageOfflineMapsException(
        'Failed to delete region: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Clear all cached offline regions
  /// 
  /// Removes all tiles from device storage
  static Future<void> clearAllRegions() async {
    try {
      await _channel.invokeMethod('clearAllRegions');
    } on PlatformException catch (e) {
      throw PneumageOfflineMapsException(
        'Failed to clear regions: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Get real-time download progress updates
  /// 
  /// Returns a stream of [DownloadProgress] events during download
  /// Stream completes when download finishes or fails
  static Stream<DownloadProgress> getProgressStream(String regionId) {
    return EventChannel('pneumage_offline_maps/progress_$regionId')
        .receiveBroadcastStream()
        .map((data) => DownloadProgress.fromMap(Map<String, dynamic>.from(data)));
  }
}

/// Result of a successful offline region download
class OfflineRegionResult {
  /// Unique identifier for the cached region
  final String id;
  
  /// Total size in bytes of the cached tiles
  final int sizeBytes;
  
  /// Number of tiles downloaded
  final int tileCount;
  
  /// Number of resources successfully downloaded
  final int completedResourceCount;
  
  /// Total number of resources requested
  final int requiredResourceCount;

  OfflineRegionResult({
    required this.id,
    required this.sizeBytes,
    required this.tileCount,
    required this.completedResourceCount,
    required this.requiredResourceCount,
  });

  factory OfflineRegionResult.fromMap(Map<String, dynamic> map) {
    return OfflineRegionResult(
      id: map['id'] as String,
      sizeBytes: map['sizeBytes'] as int,
      tileCount: map['tileCount'] as int,
      completedResourceCount: map['completedResourceCount'] as int,
      requiredResourceCount: map['requiredResourceCount'] as int,
    );
  }

  @override
  String toString() => 'OfflineRegionResult(id: $id, size: $sizeBytes bytes, tiles: $tileCount)';
}

/// Real-time download progress information
class DownloadProgress {
  /// Progress fraction from 0.0 to 1.0
  final double progress;
  
  /// Bytes downloaded so far
  final int loadedBytes;
  
  /// Total bytes to download (estimated)
  final int totalBytes;
  
  /// Number of tiles completed
  final int completedTiles;
  
  /// Total tiles to download
  final int totalTiles;

  DownloadProgress({
    required this.progress,
    required this.loadedBytes,
    required this.totalBytes,
    required this.completedTiles,
    required this.totalTiles,
  });

  factory DownloadProgress.fromMap(Map<String, dynamic> map) {
    return DownloadProgress(
      progress: (map['progress'] as num).toDouble(),
      loadedBytes: map['loadedBytes'] as int,
      totalBytes: map['totalBytes'] as int,
      completedTiles: map['completedTiles'] as int,
      totalTiles: map['totalTiles'] as int,
    );
  }

  /// Format progress as percentage string (e.g., "45%")
  String get percentageString => '${(progress * 100).toStringAsFixed(0)}%';

  /// Format progress as "X MB / Y MB"
  String get sizeString {
    final loadedMB = (loadedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    return '$loadedMB MB / $totalMB MB';
  }

  @override
  String toString() => 'DownloadProgress($percentageString, $sizeString, $completedTiles/$totalTiles tiles)';
}

/// Exception thrown by offline maps operations
class PneumageOfflineMapsException implements Exception {
  final String message;
  final String? code;

  PneumageOfflineMapsException(this.message, {this.code});

  @override
  String toString() => code != null 
      ? 'PneumageOfflineMapsException($code): $message'
      : 'PneumageOfflineMapsException: $message';
}
