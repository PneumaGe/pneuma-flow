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
import '../models/app_settings.dart';
import '../models/device_settings.dart';
import '../services/settings_service.dart';
import 'ble_provider.dart';

/// Provider for the settings service singleton
/// Phase 2: Initialize service to run migration on first access
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final service = SettingsService();
  // Initialize in background (runs migration if needed)
  service.initialize();
  return service;
});

/// Provider for app-level settings
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final service = ref.watch(settingsServiceProvider);
  return await service.loadAppSettings();
});

/// Provider for device-specific settings (for the currently connected device)
final deviceSettingsProvider = FutureProvider<DeviceSettings>((ref) async {
  final service = ref.watch(settingsServiceProvider);
  final deviceInfo = ref.watch(deviceInfoProvider);
  
  // If no device connected, return default settings
  if (deviceInfo == null) {
    return const DeviceSettings(deviceId: 'unknown');
  }
  
  return await service.loadDeviceSettings(deviceInfo.deviceId);
});

/// Provider for pump speed setting (convenience accessor)
final pumpSpeedProvider = Provider<String>((ref) {
  final deviceSettings = ref.watch(deviceSettingsProvider);
  return deviceSettings.maybeWhen(
    data: (settings) => settings.pumpSpeed,
    orElse: () => 'MEDIUM', // Default while loading or on error
  );
});

/// Provider that determines if any filters are enabled
/// Returns true if Alpha-Beta or Kalman filters are enabled for any channel
final filtersEnabledProvider = Provider<bool>((ref) {
  final deviceSettings = ref.watch(deviceSettingsProvider);
  return deviceSettings.maybeWhen(
    data: (settings) {
      // Check if any Alpha-Beta filter is enabled
      final alphaBetaEnabled = settings.filterConfigs?.values
          .any((config) => config.enabled) ?? false;
      
      // Check if any Kalman filter is enabled
      final kalmanEnabled = settings.kalmanConfigs?.values
          .any((config) => config.enabled) ?? false;
      
      return alphaBetaEnabled || kalmanEnabled;
    },
    orElse: () => false, // Default: no filters enabled
  );
});
