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
import 'ble_service.dart';
import '../models/device.dart';

/// Central data management service for the app.
/// 
/// This service owns all application data and provides a clean separation
/// between the transport layer (BleService) and the data layer.
/// 
/// **Responsibilities:**
/// - Listen to BLE streams and cache relevant data
/// - Re-broadcast streams for UI consumption
/// - Provide read-only access to current data values
/// - Future: Persist data to local storage
/// - Future: Manage Projects, Measurements, Samples, etc.
class DataService {
  final BleService _bleService;
  
  // Cached device info
  DeviceInfo? _deviceInfo;
  DeviceInfo? get deviceInfo => _deviceInfo;
  
  // Cached real-time sensor values
  double _gasConcentration = 0.0;
  double _batteryLevel = 0.0;
  double _chamberTemp = 0.0;
  double _chamberPressure = 0.0;
  double _chamberHumidity = 0.0;
  bool _isConnected = false;
  
  // Public getters for current values
  double get gasConcentration => _gasConcentration;
  double get batteryLevel => _batteryLevel;
  double get chamberTemp => _chamberTemp;
  double get chamberPressure => _chamberPressure;
  double get chamberHumidity => _chamberHumidity;
  bool get isConnected => _isConnected;
  
  // Stream controllers for re-broadcasting
  final _gasConcentrationController = StreamController<double>.broadcast();
  final _batteryLevelController = StreamController<double>.broadcast();
  final _chamberStatsController = StreamController<ChamberStats>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  
  // Public streams
  Stream<double> get gasConcentrationStream => _gasConcentrationController.stream;
  Stream<double> get batteryLevelStream => _batteryLevelController.stream;
  Stream<ChamberStats> get chamberStatsStream => _chamberStatsController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  
  // Stream subscriptions
  List<StreamSubscription> _subscriptions = [];
  
  DataService(this._bleService) {
    _setupListeners();
  }
  
  void _setupListeners() {
    // Listen to device info stream from BLE service
    _subscriptions.add(
      _bleService.deviceInfoStream.listen((info) {
        _deviceInfo = info;
        print('[DATA] Device info cached: ${info.deviceName}');
        // Future: persist to local storage, trigger UI updates, etc.
      }),
    );
    
    // Listen to gas concentration stream
    _subscriptions.add(
      _bleService.gasConcentrationStream.listen((concentration) {
        print('[DATA] Gas concentration received: $concentration ppm');
        _gasConcentration = concentration;
        if (!_gasConcentrationController.isClosed) {
          _gasConcentrationController.add(concentration);
          print('[DATA] Gas concentration re-broadcasted');
        } else {
          print('[DATA] WARNING: gasConcentration controller is closed!');
        }
      }),
    );
    
    // Listen to battery level stream
    _subscriptions.add(
      _bleService.batteryLevelStream.listen((level) {
        print('[DATA] Battery level received: $level%');
        _batteryLevel = level;
        if (!_batteryLevelController.isClosed) {
          _batteryLevelController.add(level);
          print('[DATA] Battery level re-broadcasted');
        } else {
          print('[DATA] WARNING: batteryLevel controller is closed!');
        }
      }),
    );
    
    // Listen to chamber stats stream
    _subscriptions.add(
      _bleService.chamberStatsStream.listen((stats) {
        print('[DATA] Chamber stats received: T=${stats.temperature}°C, P=${stats.pressure}hPa');
        _chamberTemp = stats.temperature;
        _chamberPressure = stats.pressure;
        _chamberHumidity = stats.humidity;
        if (!_chamberStatsController.isClosed) {
          _chamberStatsController.add(stats);
          print('[DATA] Chamber stats re-broadcasted');
        } else {
          print('[DATA] WARNING: chamberStats controller is closed!');
        }
      }),
    );
    
    // Listen to connection state stream
    _subscriptions.add(
      _bleService.connectionStateStream.listen((isConnected) {
        print('[DATA] Connection state changed: $isConnected');
        _isConnected = isConnected;
        if (!_connectionStateController.isClosed) {
          _connectionStateController.add(isConnected);
          print('[DATA] Connection state re-broadcasted');
        } else {
          print('[DATA] WARNING: connectionState controller is closed!');
        }
      }),
    );
    
    // If already connected, grab existing device info and state
    if (_bleService.deviceInfo != null) {
      _deviceInfo = _bleService.deviceInfo;
      print('[DATA] Initial device info loaded: ${_deviceInfo!.deviceName}');
    }
    _isConnected = _bleService.isConnected;
  }
  
  /// Clear cached data (e.g., on disconnect)
  void clear() {
    _deviceInfo = null;
    _gasConcentration = 0.0;
    _batteryLevel = 0.0;
    _chamberTemp = 0.0;
    _chamberPressure = 0.0;
    _chamberHumidity = 0.0;
    _isConnected = false;
    print('[DATA] Cache cleared');
  }
  
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _gasConcentrationController.close();
    _batteryLevelController.close();
    _chamberStatsController.close();
    _connectionStateController.close();
  }
}
