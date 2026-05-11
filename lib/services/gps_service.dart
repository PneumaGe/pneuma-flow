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
import 'package:geolocator/geolocator.dart';

/// GPS/Location service for tracking device position and quality
/// 
/// Provides:
/// - Current GPS position
/// - Location accuracy (quality indicator)
/// - Permission management
/// - Continuous position updates when tracking is enabled
class GpsService {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  bool _isEnabled = false;
  
  final _positionController = StreamController<Position>.broadcast();
  final _qualityController = StreamController<int>.broadcast();
  final _enabledController = StreamController<bool>.broadcast();
  
  // Public streams
  Stream<Position> get positionStream => _positionController.stream;
  Stream<int> get qualityStream => _qualityController.stream;
  Stream<bool> get enabledStream => _enabledController.stream;
  
  // Public getters
  Position? get currentPosition => _currentPosition;
  bool get isEnabled => _isEnabled;
  
  /// GPS quality indicator (0-3):
  /// - 3: Excellent (< 10m accuracy)
  /// - 2: Good (10-50m accuracy)
  /// - 1: Fair (50-100m accuracy)
  /// - 0: Poor (> 100m or no signal)
  int get quality {
    if (_currentPosition == null) return 0;
    final accuracy = _currentPosition!.accuracy;
    if (accuracy < 10) return 3;
    if (accuracy < 50) return 2;
    if (accuracy < 100) return 1;
    return 0;
  }
  
  /// Initialize GPS service with reactive monitoring
  void initialize() {
    // Start listening to GPS service status changes
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) {
        print('[GPS] Service status changed: $status');
        if (status == ServiceStatus.enabled) {
          print('[GPS] GPS enabled - attempting to start tracking');
          startTracking();
        } else {
          print('[GPS] GPS disabled - stopping tracking');
          _isEnabled = false;
          if (!_enabledController.isClosed) {
            _enabledController.add(false);
          }
          stopTracking();
        }
      },
      onError: (error) {
        print('[GPS] Service status stream error: $error');
      },
    );
    
    // Try to start tracking immediately if GPS is already on
    startTracking();
  }
  
  /// Check if location services are enabled and permissions granted
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[GPS] Location services are disabled');
      _isEnabled = false;
      if (!_enabledController.isClosed) {
        _enabledController.add(false);
      }
      return false;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('[GPS] Location permission denied');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('[GPS] Location permission permanently denied');
      _isEnabled = false;
      if (!_enabledController.isClosed) {
        _enabledController.add(false);
      }
      return false;
    }
    
    print('[GPS] Location permissions granted');
    _isEnabled = true;
    if (!_enabledController.isClosed) {
      _enabledController.add(true);
    }
    return true;
  }
  
  /// Start tracking GPS position
  Future<void> startTracking() async {
    if (_positionSubscription != null) {
      print('[GPS] Already tracking');
      return;
    }
    
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      print('[GPS] Cannot start tracking - no permission');
      return;
    }
    
    print('[GPS] Starting position tracking...');
    
    // Get initial position
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('[GPS] Initial position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude} (±${_currentPosition!.accuracy}m)');
      _positionController.add(_currentPosition!);
      _qualityController.add(quality);
    } catch (e) {
      print('[GPS] Error getting initial position: $e');
    }
    
    // Start continuous tracking
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      _currentPosition = position;
      print('[GPS] Position update: ${position.latitude}, ${position.longitude} (±${position.accuracy}m)');
      
      if (!_positionController.isClosed) {
        _positionController.add(position);
      }
      if (!_qualityController.isClosed) {
        _qualityController.add(quality);
      }
    }, onError: (error) {
      print('[GPS] Position stream error: $error');
    });
  }
  
  /// Stop tracking GPS position
  void stopTracking() {
    if (_positionSubscription != null) {
      print('[GPS] Stopping position tracking');
      _positionSubscription?.cancel();
      _positionSubscription = null;
    }
  }
  
  /// Clean up resources
  void dispose() {
    print('[GPS] Disposing service');
    stopTracking();
    _positionController.close();
    _serviceStatusSubscription?.cancel();
    _qualityController.close();
    _enabledController.close();
  }
}
