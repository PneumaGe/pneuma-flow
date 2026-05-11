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
import '../services/data_service.dart';
import '../models/device.dart';
import 'ble_provider.dart';

/// Provider for the Data service singleton
/// Depends on BLE service provider
final dataServiceProvider = Provider<DataService>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  final service = DataService(bleService);
  
  // Dispose the service when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for chamber stats stream
final chamberStatsProvider = StreamProvider((ref) {
  final dataService = ref.watch(dataServiceProvider);
  return dataService.chamberStatsStream;
});

/// Provider for battery level stream
final batteryLevelProvider = StreamProvider<double>((ref) {
  final dataService = ref.watch(dataServiceProvider);
  return dataService.batteryLevelStream;
});

/// Provider for gas concentration stream from BLE service
final gasConcentrationProvider = StreamProvider<double>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.gasConcentrationStream;
});

/// Provider for system status stream from BLE service
final systemStatusProvider = StreamProvider<int>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.systemStatusStream;
});

/// Provider for device info stream from BLE service
final deviceInfoStreamProvider = StreamProvider<DeviceInfo>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.deviceInfoStream;
});
