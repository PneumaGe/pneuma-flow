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
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:pneumage_offline_maps/pneumage_offline_maps.dart';
import '../models/offline_region.dart';

/// Service for managing offline map tile caching using Mapbox
/// 
/// Provides functionality to download, store, and delete offline map regions
/// for use in areas with no network connectivity.
/// 
/// Uses the pneumage_offline_maps plugin for native Mapbox offline functionality.
class OfflineMapService {
  static const String _boxName = 'offline_regions';
  static const int _defaultMinZoom = 10;
  static const int _defaultMaxZoom = 16;
  static const int _maxStorageBytes = 1000 * 1024 * 1024; // 1 GB limit
  
  Box<OfflineRegion>? _box;
  final Map<String, bool> _activeDownloads = {};
  
  /// Initialize the service and open Hive box
  Future<void> initialize() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<OfflineRegion>(_boxName);
    }
  }

  /// Get all cached offline regions
  Future<List<OfflineRegion>> getAllRegions() async {
    await initialize();
    return _box!.values.toList();
  }

  /// Get a specific region by ID
  Future<OfflineRegion?> getRegion(String id) async {
    await initialize();
    return _box!.get(id);
  }

  /// Download a new offline region from current map view
  /// 
  /// [bounds] - The geographic bounding box to download  
  /// [name] - Optional custom name (auto-generated if null)
  /// [minZoom] - Minimum zoom level to cache (default: 10)
  /// [maxZoom] - Maximum zoom level to cache (default: 16)
  /// [onProgress] - Callback for download progress (percentage, loaded bytes, total bytes)
  /// 
  /// Returns the created OfflineRegion on success
  /// 
  /// Throws [Exception] with descriptive message on failure:
  /// - "Storage limit reached. Please delete old regions." - when storage is full
  /// - "Download cancelled" - if download was interrupted
  /// - Other platform-specific errors during download
  /// 
  /// Implementation note: This method uses platform-specific offline tile
  /// downloading on Android/iOS. On unsupported platforms, it simulates the
  /// download for UI testing purposes.
  Future<OfflineRegion?> downloadRegion({
    required CoordinateBounds bounds,
    String? name,
    int minZoom = _defaultMinZoom,
    int maxZoom = _defaultMaxZoom,
    Function(double progress, int loadedBytes, int totalBytes)? onProgress,
  }) async {
    try {
      await initialize();

      // Check storage limits
      final currentStorage = await getTotalStorageBytes();
      if (currentStorage >= _maxStorageBytes) {
        debugPrint('Storage limit reached: $currentStorage bytes / $_maxStorageBytes bytes');
        throw Exception('Storage limit reached. Please delete old regions.');
      }

      // Check if this download would exceed storage
      final area = _calculateArea(bounds);
      final estimatedBytes = _estimateSizeBytes(area, minZoom, maxZoom);
      final availableBytes = _maxStorageBytes - currentStorage;
      
      // Check if download is larger than total storage limit
      if (estimatedBytes > _maxStorageBytes) {
        final neededMB = (estimatedBytes / (1024 * 1024)).toStringAsFixed(0);
        final limitMB = (_maxStorageBytes / (1024 * 1024)).toStringAsFixed(0);
        final areaKm2 = area.toStringAsFixed(1);
        throw Exception('Region too large ($areaKm2 km² = $neededMB MB). Maximum downloadable size is $limitMB MB. Try zooming in to cache a smaller area.');
      }
      
      // Check if enough space available for this download
      if (currentStorage + estimatedBytes > _maxStorageBytes) {
        final availableMB = (availableBytes / (1024 * 1024)).toStringAsFixed(0);
        final neededMB = (estimatedBytes / (1024 * 1024)).toStringAsFixed(0);
        throw Exception('Not enough storage. Need $neededMB MB but only $availableMB MB available. Delete old regions first.');
      }

      // Generate region metadata
      final regionName = name ?? _generateRegionName(bounds);
      final regionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Mark as active download
      _activeDownloads[regionId] = true;

      try {
        // Attempt platform-specific offline download
        // This would use MethodChannel on Android/iOS to call native Mapbox SDK
        // For now, we simulate the download with realistic behavior
        final region = await _downloadTiles(
          regionId: regionId,
          name: regionName,
          bounds: bounds,
          minZoom: minZoom,
          maxZoom: maxZoom,
          onProgress: onProgress,
        );

        _activeDownloads.remove(regionId);
        return region;
      } catch (e) {
        _activeDownloads.remove(regionId);
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('Error downloading region: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Internal method to download tiles using pneumage_offline_maps plugin
  Future<OfflineRegion> _downloadTiles({
    required String regionId,
    required String name,
    required CoordinateBounds bounds,
    required int minZoom,
    required int maxZoom,
    Function(double, int, int)? onProgress,
  }) async {
    StreamSubscription<DownloadProgress>? progressSub;
    
    try {
      if (onProgress != null) {
        progressSub = PneumageOfflineMaps.getProgressStream(regionId).listen(
          (progress) {
            if (!(_activeDownloads[regionId] ?? false)) return;
            onProgress(
              progress.progress,
              progress.loadedBytes,
              progress.totalBytes,
            );
          },
          onError: (e) => debugPrint('Progress stream error: $e'),
        );
      }

      // Call plugin to download tiles
      final result = await PneumageOfflineMaps.downloadRegion(
        north: bounds.northeast.coordinates.lat.toDouble(),
        south: bounds.southwest.coordinates.lat.toDouble(),
        east: bounds.northeast.coordinates.lng.toDouble(),
        west: bounds.southwest.coordinates.lng.toDouble(),
        minZoom: minZoom,
        maxZoom: maxZoom,
        regionId: regionId,
      );

      // Get actual size from plugin result
      final actualSizeBytes = result.sizeBytes;

      // Create and persist region
      final region = OfflineRegion(
        id: regionId,
        name: name,
        northLat: bounds.northeast.coordinates.lat.toDouble(),
        southLat: bounds.southwest.coordinates.lat.toDouble(),
        eastLng: bounds.northeast.coordinates.lng.toDouble(),
        westLng: bounds.southwest.coordinates.lng.toDouble(),
        minZoom: minZoom,
        maxZoom: maxZoom,
        downloadedAt: DateTime.now(),
        sizeBytes: actualSizeBytes,
        mapboxRegionId: regionId,
      );

      await _box!.put(regionId, region);
      return region;
    } catch (e) {
      debugPrint('Plugin error downloading tiles: $e');
      rethrow;
    } finally {
      await progressSub?.cancel();
    }
  }

  /// Delete an offline region
  /// 
  /// Removes the database record and calls platform to delete cached tiles
  Future<bool> deleteRegion(String id) async {
    try {
      await initialize();
      
      final region = await getRegion(id);
      if (region == null) return false;

      // Cancel if download is in progress
      _activeDownloads.remove(id);

      debugPrint('Deleting region: ${region.name} (${region.sizeDisplay})');

      // Call plugin to delete tiles
      try {
        await PneumageOfflineMaps.deleteRegion(id);
      } catch (e) {
        debugPrint('Plugin error deleting region: $e');
        // Continue with metadata deletion even if plugin call fails
      }

      // Remove from Hive
      await _box!.delete(id);
      return true;
    } catch (e) {
      debugPrint('Error deleting offline region: $e');
      return false;
    }
  }

  /// Delete all offline regions
  Future<bool> deleteAllRegions() async {
    try {
      await initialize();
      
      // Cancel all active downloads
      _activeDownloads.clear();
      
      debugPrint('Clearing all cached regions');
      
      // Call plugin to delete all tiles
      try {
        await PneumageOfflineMaps.clearAllRegions();
      } catch (e) {
        debugPrint('Plugin error clearing regions: $e');
        // Continue with metadata deletion even if plugin call fails
      }
      
      // Clear Hive box
      await _box!.clear();
      return true;
    } catch (e) {
      debugPrint('Error deleting all offline regions: $e');
      return false;
    }
  }

  /// Cancel an in-progress download
  Future<void> cancelDownload(String regionId) async {
    _activeDownloads.remove(regionId);
    
    // Call platform plugin to delete any partially downloaded native tiles
    try {
      await PneumageOfflineMaps.deleteRegion(regionId);
    } catch (e) {
      debugPrint('Failed to clean up cancelled native download: $e');
    }
    
    // Remove partial record from database
    await _box?.delete(regionId);
    
    debugPrint('Cancelled download: $regionId');
  }

  /// Get total storage used by all cached regions
  Future<int> getTotalStorageBytes() async {
    await initialize();
    final regions = await getAllRegions();
    return regions.fold<int>(0, (sum, region) => sum + region.sizeBytes);
  }

  /// Generate auto name for region based on coordinates
  String _generateRegionName(CoordinateBounds bounds) {
    final center = Position(
      (bounds.northeast.coordinates.lng + bounds.southwest.coordinates.lng) / 2,
      (bounds.northeast.coordinates.lat + bounds.southwest.coordinates.lat) / 2,
    );
    final lat = center.lat.toStringAsFixed(3);
    final lng = center.lng.toStringAsFixed(3);
    final date = DateTime.now().toIso8601String().split('T')[0];
    return 'Region_${lat}_${lng}_$date';
  }

  /// Calculate area in square kilometers
  double _calculateArea(CoordinateBounds bounds) {
    // Simplified area calculation (not accounting for Earth curvature)
    final latDiff = (bounds.northeast.coordinates.lat - bounds.southwest.coordinates.lat).abs();
    final lngDiff = (bounds.northeast.coordinates.lng - bounds.southwest.coordinates.lng).abs();
    
    // Approximate km per degree at equator
    const kmPerLatDegree = 111.0;
    const kmPerLngDegree = 111.0;
    
    return latDiff * lngDiff * kmPerLatDegree * kmPerLngDegree;
  }

  /// Estimate storage size based on area and zoom levels
  int _estimateSizeBytes(double areaKm2, int minZoom, int maxZoom) {
    // Rough estimate: ~2-3 MB per square kilometer per zoom level
    const mbPerKm2PerZoom = 2.5;
    final zoomLevels = (maxZoom - minZoom + 1);
    final estimatedMB = areaKm2 * mbPerKm2PerZoom * zoomLevels;
    return (estimatedMB * 1024 * 1024).toInt();
  }

  /// Dispose resources and cancel any in-progress downloads
  Future<void> dispose() async {
    // Cancel all active downloads
    _activeDownloads.clear();
    
    // Box will be closed when app terminates
    // Don't close here as other parts of app might need it
  }
}
