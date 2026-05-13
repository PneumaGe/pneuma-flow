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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../config/mapbox_config.dart';
import '../providers/gps_provider.dart';
import '../providers/project_provider.dart';
import '../providers/offline_map_provider.dart';
import '../models/measurement.dart';

/// Interactive map widget displaying measurement locations and current GPS position
/// 
/// Features:
/// - Satellite imagery with street overlay
/// - Current position marker (live GPS tracking)
/// - Measurement location markers from all projects
/// - Pan, zoom, rotate gestures
/// - Offline tile caching support
class InteractiveMapWidget extends ConsumerStatefulWidget {
  const InteractiveMapWidget({super.key});

  @override
  ConsumerState<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends ConsumerState<InteractiveMapWidget> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  bool _hasCenteredOnGps = false; // Track if we've already centered on user position
  // Note: No longer need manual marker - using Mapbox location component instead

  @override
  Widget build(BuildContext context) {
    // Watch GPS position for GPS accuracy indicator display
    final currentPosition = ref.watch(currentPositionProvider);

    // Listen to GPS position changes and center map on first valid position
    ref.listen<AsyncValue<geo.Position>>(gpsPositionProvider, (previous, next) {
      next.whenData((position) {
        if (!_hasCenteredOnGps && _mapboxMap != null) {
          _centerOnUserPosition(position);
          _hasCenteredOnGps = true;
        }
      });
    });

    // Note: Mapbox location component automatically updates the location puck
    // No need to manually update markers - the built-in component handles it

    return Stack(
      children: [
        // Mapbox widget
        MapWidget(
          key: const ValueKey('mapbox'),
          cameraOptions: CameraOptions(
            center: Point(
              coordinates: Position(
                MapboxConfig.initialLongitude,
                MapboxConfig.initialLatitude,
              ),
            ),
            zoom: MapboxConfig.initialZoom,
          ),
          styleUri: MapboxConfig.defaultStyleUrl,
          textureView: true,
          onMapCreated: _onMapCreated,
        ),

        // Cache Area button
        Positioned(
          top: 16,
          right: 16,
          child: ElevatedButton.icon(
            onPressed: _handleCacheCurrentArea,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Cache Area'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 4,
            ),
          ),
        ),

        // GPS accuracy indicator (when tracking)
        if (currentPosition != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildGpsAccuracyIndicator(currentPosition),
          ),
      ],
    );
  }

  /// Called when map is created and ready
  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Enable Mapbox location component (blue puck for current location)
    try {
      await mapboxMap.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          puckBearingEnabled: true,  // Shows direction arrow
          pulsingEnabled: true,       // Pulsing circle around location
        ),
      );
      print('[Map] Location component enabled');
    } catch (e) {
      print('[Map] Failed to enable location component: $e');
    }

    // Create annotation manager for markers
    _annotationManager = await mapboxMap.annotations.createPointAnnotationManager();

    // Load measurement markers from all projects
    await _loadMeasurementMarkers();

    // Center on user position if GPS is already available
    final currentPosition = ref.read(currentPositionProvider);
    if (currentPosition != null && !_hasCenteredOnGps) {
      _centerOnUserPosition(currentPosition);
      _hasCenteredOnGps = true;
    }
  }

  /// Center the map camera on the user's current position
  void _centerOnUserPosition(geo.Position position) {
    if (_mapboxMap == null) return;

    final point = Point(
      coordinates: Position(
        position.longitude,
        position.latitude,
      ),
    );

    // Animate camera to user position with a nice zoom level
    _mapboxMap!.flyTo(
      CameraOptions(
        center: point,
        zoom: 15.0, // Zoomed in for better detail
      ),
      MapAnimationOptions(duration: 1500), // Smooth 1.5s animation
    );

    print('[Map] Centered on user position: ${position.latitude}, ${position.longitude}');
  }

  // DEPRECATED: Manual marker approach replaced by Mapbox location component
  // The location component automatically shows a blue puck at the user's location
  // No need to manually create/update markers anymore
  /*
  /// Update or create the current position marker on the map
  Future<void> _updateCurrentPositionMarker(geo.Position position) async {
    if (_annotationManager == null) return;

    final point = Point(
      coordinates: Position(
        position.longitude,
        position.latitude,
      ),
    );

    // Remove old marker if it exists
    if (_currentPositionMarker != null) {
      await _annotationManager!.delete(_currentPositionMarker!);
    }

    // Create new marker at current position
    _currentPositionMarker = await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: point,
        iconImage: 'marker-15', // Built-in Mapbox marker
        iconColor: Colors.blue.value,
        iconSize: 1.5,
      ),
    );

    // Pan camera to current position (gentle animation)
    _mapboxMap?.flyTo(
      CameraOptions(
        center: point,
        zoom: 15.0, // Zoom in closer when tracking
      ),
      MapAnimationOptions(duration: 1000),
    );
  }
  */

  /// Load markers for all measurements from all projects
  Future<void> _loadMeasurementMarkers() async {
    if (_annotationManager == null) return;

    final projectsAsync = ref.read(projectsProvider);
    
    projectsAsync.when(
      data: (projects) async {
        for (final project in projects) {
          final measurementsAsync = ref.read(
            projectMeasurementsProvider(project.id),
          );

          measurementsAsync.when(
            data: (measurements) async {
              await _addMeasurementMarkers(measurements);
            },
            loading: () {},
            error: (_, __) {},
          );
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  /// Add markers for a list of measurements
  Future<void> _addMeasurementMarkers(List<Measurement> measurements) async {
    if (_annotationManager == null) return;

    for (final measurement in measurements) {
      final location = measurement.location;

      final point = Point(
        coordinates: Position(
          location.longitude,
          location.latitude,
        ),
      );

      // Create marker for measurement location
      await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: point,
          iconImage: 'marker-15',
          iconColor: Colors.green.value,
          iconSize: 1.2,
        ),
      );
    }
  }

  /// Handle caching the current visible map area
  Future<void> _handleCacheCurrentArea() async {
    if (_mapboxMap == null) return;

    final offlineService = ref.read(offlineMapServiceProvider);

    try {
      // Get current camera position
      final cameraState = await _mapboxMap!.getCameraState();
      final center = cameraState.center;

      // Calculate bounds for current view (approximate visible area)
      // Using 0.009° offset creates ~2km × 2km area = 4 km² (~70 MB at zoom 10-16)
      // Note: 0.009° from center = 0.018° total span = 2 km (at equator)
      final latOffset = 0.009; // ~1 km radius, 2 km total
      final lngOffset = 0.009;

      final bounds = CoordinateBounds(
        southwest: Point(
          coordinates: Position(
            center.coordinates.lng - lngOffset,
            center.coordinates.lat - latOffset,
          ),
        ),
        northeast: Point(
          coordinates: Position(
            center.coordinates.lng + lngOffset,
            center.coordinates.lat + latOffset,
          ),
        ),
        infiniteBounds: false,
      );

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Downloading map tiles...'),
              ],
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      // Download the region with progress tracking
      double lastProgress = 0.0;
      final region = await offlineService.downloadRegion(
        bounds: bounds,
        minZoom: 10,
        maxZoom: 16,
        onProgress: (progress, loadedBytes, totalBytes) {
          // Update every 20%
          if (progress - lastProgress >= 0.2 || progress >= 1.0) {
            lastProgress = progress;
            if (mounted) {
              final loadedMB = (loadedBytes / (1024 * 1024)).toStringAsFixed(1);
              final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
              
              // Clear previous toast and show new progress
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Downloading... ${(progress * 100).toStringAsFixed(0)}% ($loadedMB MB / $totalMB MB)',
                  ),
                  duration: const Duration(seconds: 2), // Longer duration so it's visible
                ),
              );
            }
          }
        },
      );

      // Show result
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        if (region != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cached: ${region.name} (${region.sizeDisplay})'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          // Invalidate providers to refresh offline regions list
          ref.invalidate(offlineRegionsProvider);
          ref.invalidate(offlineTotalStorageProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        
        // Extract user-friendly error message
        String errorMessage = 'Failed to cache map area';
        if (e is Exception) {
          // Exception.toString() returns "Exception: message"
          final exceptionStr = e.toString();
          if (exceptionStr.startsWith('Exception: ')) {
            errorMessage = exceptionStr.substring('Exception: '.length);
          } else {
            errorMessage = exceptionStr;
          }
        } else {
          errorMessage = e.toString();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Build GPS accuracy indicator widget
  Widget _buildGpsAccuracyIndicator(geo.Position position) {
    final accuracy = position.accuracy;
    Color color;
    String quality;

    if (accuracy < 10) {
      color = Colors.green;
      quality = 'Excellent';
    } else if (accuracy < 50) {
      color = Colors.amber;
      quality = 'Good';
    } else if (accuracy < 100) {
      color = Colors.orange;
      quality = 'Fair';
    } else {
      color = Colors.red;
      quality = 'Poor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.my_location, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$quality (${accuracy.toStringAsFixed(1)}m)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'RobotoMono',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _annotationManager?.deleteAll();
    super.dispose();
  }
}
