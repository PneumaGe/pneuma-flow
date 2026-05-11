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
import '../services/ble_service.dart';

/// Provider for the BLE service singleton
/// This ensures a single instance persists across the entire app lifecycle
final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService();
  
  // Dispose the service when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for connection state
final connectionStateProvider = StreamProvider<bool>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.connectionStateStream;
});

/// Provider for device info
final deviceInfoProvider = Provider((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.deviceInfo;
});

/// Provider to check if device is connected
final isConnectedProvider = Provider<bool>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.isConnected;
});
