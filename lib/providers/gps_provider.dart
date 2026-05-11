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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/gps_service.dart';

/// Provider for the GPS service singleton
final gpsServiceProvider = Provider<GpsService>((ref) {
  final service = GpsService();
  
  // Initialize GPS tracking and start listening to service status changes
  service.initialize();
  
  // Dispose the service when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for GPS quality stream
/// Quality values:
/// - 3: Excellent (< 10m accuracy)
/// - 2: Good (10-50m accuracy)
/// - 1: Fair (50-100m accuracy)
/// - 0: Poor (> 100m or no signal)
final gpsQualityProvider = StreamProvider<int>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  return gpsService.qualityStream;
});

/// Provider for GPS enabled state stream
final gpsEnabledProvider = StreamProvider<bool>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  return gpsService.enabledStream;
});

/// Provider for current GPS position stream
final gpsPositionProvider = StreamProvider<Position>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  return gpsService.positionStream;
});

/// Provider for current position (non-stream getter)
final currentPositionProvider = Provider<Position?>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  return gpsService.currentPosition;
});
